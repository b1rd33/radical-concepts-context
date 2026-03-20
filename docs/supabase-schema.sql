-- =============================================================================
-- Radical Concepts — Supabase Database Schema
-- AI Podcast Pipeline for Brett Moore
-- =============================================================================
--
-- ROW ESTIMATES (free tier: 500MB database, 1GB storage)
-- -------------------------------------------------------
-- feeds:              ~930 rows     (~100 KB)
-- feed_batches:       ~24 rows      (~5 KB)
-- articles:           ~50K/year     (~50 MB at 1KB/row avg)
-- article_scores:     ~50K/year     (~25 MB)
-- approval_decisions: ~500/day max  (~5 MB/year)
-- episodes:           ~365/year     (~2 MB)
-- episode_articles:   ~1,100/year   (~0.5 MB)
-- distributions:      ~2,500/year   (~1.5 MB)
-- voice_profiles:     ~50 entries   (~50 KB)
-- -------------------------------------------------------
-- YEAR 1 TOTAL:       ~85 MB database + audio in Storage
-- VERDICT:            Fits comfortably in free tier for 2+ years
--
-- AUDIO STORAGE: ~15 min episode @ 128kbps = ~14 MB
--   365 episodes/year = ~5 GB → exceeds 1 GB free Storage
--   RECOMMENDATION: Store audio on external host (Podbean, S3, Cloudflare R2)
--   Use Supabase Storage only for short preview clips if needed
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- for fuzzy text search


-- =============================================================================
-- 1. RSS FEEDS + BATCH MANAGEMENT
-- =============================================================================

CREATE TABLE feeds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    url TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    -- Categorization
    category TEXT NOT NULL DEFAULT 'general',  -- politics, science, tech, economics, quirky, general
    language TEXT DEFAULT 'en',
    region TEXT,                                -- AU, US, UK, EU, INTL
    -- Batch polling: 928 feeds / 24 batches = ~39 per batch (1 batch per hour)
    batch_number INT NOT NULL CHECK (batch_number BETWEEN 0 AND 23),
    -- State
    is_active BOOLEAN NOT NULL DEFAULT true,
    last_polled_at TIMESTAMPTZ,
    last_successful_at TIMESTAMPTZ,
    consecutive_failures INT NOT NULL DEFAULT 0,
    last_error TEXT,
    -- Metadata
    etag TEXT,                                 -- HTTP ETag for conditional requests
    last_modified TEXT,                        -- HTTP Last-Modified header
    avg_articles_per_day NUMERIC(5,1),
    -- Quality tracking
    total_articles_ingested INT NOT NULL DEFAULT 0,
    total_articles_approved INT NOT NULL DEFAULT 0,
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_feeds_batch ON feeds (batch_number) WHERE is_active = true;
CREATE INDEX idx_feeds_category ON feeds (category);
CREATE INDEX idx_feeds_active ON feeds (is_active);

COMMENT ON TABLE feeds IS 'RSS feed sources. 928 feeds split into 24 hourly batches of ~39.';
COMMENT ON COLUMN feeds.batch_number IS 'Hour of day (0-23) when this feed gets polled.';


-- =============================================================================
-- 2. ARTICLES (extracted content with deduplication)
-- =============================================================================

CREATE TABLE articles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    feed_id UUID NOT NULL REFERENCES feeds(id) ON DELETE CASCADE,
    -- Identity & dedup
    guid TEXT,                                 -- RSS <guid> element
    url TEXT NOT NULL,
    url_hash TEXT NOT NULL,                    -- SHA256 of normalized URL for dedup
    content_hash TEXT,                         -- SHA256 of body text for content-level dedup
    -- Content
    title TEXT NOT NULL,
    author TEXT,
    summary TEXT,                              -- RSS description / AI-generated summary
    full_text TEXT,                            -- Extracted article body
    word_count INT,
    image_url TEXT,
    -- Classification
    category TEXT,                             -- politics, science, tech, economics, quirky
    subcategory TEXT,
    topics TEXT[],                             -- array of detected topics
    entities TEXT[],                           -- named entities (people, orgs, places)
    sentiment NUMERIC(3,2),                    -- -1.0 to 1.0
    -- Scoring (set by AI scoring step)
    relevance_score NUMERIC(4,2),              -- 0-10, how relevant to Brett's interests
    novelty_score NUMERIC(4,2),               -- 0-10, how unique/novel
    composite_score NUMERIC(4,2),             -- 0-10, weighted final score
    -- State
    status TEXT NOT NULL DEFAULT 'new'
        CHECK (status IN ('new', 'scored', 'presented', 'approved', 'rejected', 'used', 'expired')),
    is_duplicate BOOLEAN NOT NULL DEFAULT false,
    duplicate_of UUID REFERENCES articles(id),
    -- Timestamps
    published_at TIMESTAMPTZ,                  -- from RSS feed
    ingested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    scored_at TIMESTAMPTZ,
    presented_at TIMESTAMPTZ,                  -- when shown to Brett
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Deduplication indexes
CREATE UNIQUE INDEX idx_articles_url_hash ON articles (url_hash);
CREATE INDEX idx_articles_content_hash ON articles (content_hash) WHERE content_hash IS NOT NULL;
CREATE INDEX idx_articles_guid ON articles (feed_id, guid) WHERE guid IS NOT NULL;

-- Query indexes
CREATE INDEX idx_articles_status ON articles (status);
CREATE INDEX idx_articles_composite_score ON articles (composite_score DESC NULLS LAST) WHERE status = 'scored';
CREATE INDEX idx_articles_feed ON articles (feed_id);
CREATE INDEX idx_articles_published ON articles (published_at DESC);
CREATE INDEX idx_articles_category ON articles (category);
CREATE INDEX idx_articles_ingested ON articles (ingested_at DESC);

-- Full-text search on title + summary
CREATE INDEX idx_articles_title_trgm ON articles USING gin (title gin_trgm_ops);

COMMENT ON TABLE articles IS 'Extracted articles from RSS feeds. ~100-200 new per day.';
COMMENT ON COLUMN articles.url_hash IS 'SHA256 of normalized URL. Primary dedup mechanism.';
COMMENT ON COLUMN articles.composite_score IS 'AI-generated score 0-10. Used for ranking in curation.';


-- =============================================================================
-- 3. BRETT'S APPROVAL DECISIONS
-- =============================================================================

CREATE TABLE approval_decisions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    article_id UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    -- Decision
    decision TEXT NOT NULL CHECK (decision IN ('approve', 'skip', 'flag', 'save_for_later')),
    -- Context (for persona learning)
    decision_source TEXT DEFAULT 'telegram'
        CHECK (decision_source IN ('telegram', 'web', 'whatsapp', 'auto')),
    time_to_decide_seconds INT,               -- how long Brett took (engagement signal)
    brett_note TEXT,                           -- optional voice note transcript or text
    -- For episode planning
    assigned_to_episode UUID,                 -- can be set later when episode is planned
    story_position INT,                       -- order within episode (1, 2, 3)
    -- Timestamps
    decided_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_approval_article ON approval_decisions (article_id);
CREATE INDEX idx_approval_decision ON approval_decisions (decision);
CREATE INDEX idx_approval_decided_at ON approval_decisions (decided_at DESC);
CREATE INDEX idx_approval_episode ON approval_decisions (assigned_to_episode) WHERE assigned_to_episode IS NOT NULL;

COMMENT ON TABLE approval_decisions IS 'Brett''s approve/skip decisions. One per article.';


-- =============================================================================
-- 4. EPISODES (generated content)
-- =============================================================================

CREATE TABLE episodes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- Identity
    episode_number INT UNIQUE,
    title TEXT NOT NULL,
    slug TEXT UNIQUE,                          -- URL-friendly title
    -- Content
    description TEXT,                          -- episode summary for RSS/podcast apps
    script_raw TEXT,                           -- AI-generated script (full text)
    script_final TEXT,                         -- after Brett's edits (if any)
    transcript TEXT,                           -- final transcript (post-recording)
    show_notes TEXT,                           -- links, references
    -- Audio
    audio_url TEXT,                            -- hosted audio URL (Podbean, S3, etc.)
    audio_duration_seconds INT,
    audio_file_size_bytes BIGINT,
    -- Metadata
    category TEXT,                             -- primary topic category
    topics TEXT[],                             -- all topics covered
    tags TEXT[],
    -- Quality
    quality_score NUMERIC(4,2),               -- automated quality assessment
    brett_rating INT CHECK (brett_rating BETWEEN 1 AND 5),
    -- State machine
    status TEXT NOT NULL DEFAULT 'planning'
        CHECK (status IN (
            'planning',        -- articles selected, not yet scripted
            'scripting',       -- AI generating script
            'script_review',   -- waiting for Brett to review script
            'approved',        -- Brett approved script
            'recording',       -- Brett is recording (or AI voice generating)
            'processing',      -- audio cleanup, editing
            'ready',           -- ready to publish
            'published',       -- live on at least one platform
            'archived'         -- old episode
        )),
    -- Timestamps
    planned_for DATE,                         -- target publish date
    scripted_at TIMESTAMPTZ,
    approved_at TIMESTAMPTZ,
    recorded_at TIMESTAMPTZ,
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_episodes_status ON episodes (status);
CREATE INDEX idx_episodes_published ON episodes (published_at DESC);
CREATE INDEX idx_episodes_planned ON episodes (planned_for) WHERE status IN ('planning', 'scripting', 'script_review');

COMMENT ON TABLE episodes IS 'Generated podcast episodes with full lifecycle tracking.';


-- Junction table: which articles appear in which episodes
CREATE TABLE episode_articles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    episode_id UUID NOT NULL REFERENCES episodes(id) ON DELETE CASCADE,
    article_id UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    position INT NOT NULL,                     -- story order within episode
    segment_type TEXT DEFAULT 'main'           -- main, brief_mention, reference
        CHECK (segment_type IN ('main', 'brief_mention', 'reference')),
    script_section TEXT,                       -- the script text for this article's segment
    duration_estimate_seconds INT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (episode_id, article_id),
    UNIQUE (episode_id, position)
);

CREATE INDEX idx_episode_articles_episode ON episode_articles (episode_id);
CREATE INDEX idx_episode_articles_article ON episode_articles (article_id);


-- =============================================================================
-- 5. DISTRIBUTION TRACKING
-- =============================================================================

CREATE TABLE distributions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    episode_id UUID NOT NULL REFERENCES episodes(id) ON DELETE CASCADE,
    -- Platform
    platform TEXT NOT NULL
        CHECK (platform IN (
            'spotify', 'apple_podcasts', 'youtube', 'youtube_shorts',
            'linkedin', 'tiktok', 'instagram', 'twitter_x',
            'substack', 'beehiiv', 'email', 'whatsapp',
            'website', 'rss', 'other'
        )),
    content_type TEXT NOT NULL DEFAULT 'full_episode'
        CHECK (content_type IN ('full_episode', 'clip', 'newsletter', 'social_post', 'audiogram')),
    -- Publishing
    platform_post_id TEXT,                     -- ID on the platform
    platform_url TEXT,                         -- direct link
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'scheduled', 'publishing', 'published', 'failed', 'removed')),
    scheduled_for TIMESTAMPTZ,
    published_at TIMESTAMPTZ,
    -- Metrics (updated periodically)
    plays INT DEFAULT 0,
    views INT DEFAULT 0,
    likes INT DEFAULT 0,
    comments INT DEFAULT 0,
    shares INT DEFAULT 0,
    click_throughs INT DEFAULT 0,
    completion_rate NUMERIC(5,2),              -- percentage
    metrics_updated_at TIMESTAMPTZ,
    -- Error tracking
    last_error TEXT,
    retry_count INT DEFAULT 0,
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_distributions_episode ON distributions (episode_id);
CREATE INDEX idx_distributions_platform ON distributions (platform);
CREATE INDEX idx_distributions_status ON distributions (status);
CREATE INDEX idx_distributions_scheduled ON distributions (scheduled_for)
    WHERE status = 'scheduled';
CREATE UNIQUE INDEX idx_distributions_platform_episode ON distributions (episode_id, platform, content_type);

COMMENT ON TABLE distributions IS 'Track where each episode is published and its metrics.';


-- =============================================================================
-- 6. VOICE PROFILE / STYLE GUIDE
-- =============================================================================

CREATE TABLE voice_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- Categorization
    profile_type TEXT NOT NULL
        CHECK (profile_type IN (
            'tone_rule',        -- "Use short, punchy sentences"
            'vocabulary',       -- preferred/avoided words
            'structure',        -- episode structure patterns
            'example',          -- sample text in Brett's voice
            'topic_register',   -- how tone changes per topic type
            'catchphrase',      -- recurring phrases Brett uses
            'anti_pattern',     -- things to NEVER say/do
            'prompt_template'   -- system prompts for AI generation
        )),
    category TEXT,                             -- politics, science, quirky, general
    -- Content
    title TEXT NOT NULL,
    content TEXT NOT NULL,                     -- the actual rule/example/template
    -- Priority & state
    priority INT NOT NULL DEFAULT 5 CHECK (priority BETWEEN 1 AND 10),
    is_active BOOLEAN NOT NULL DEFAULT true,
    -- Learning
    source TEXT,                               -- 'manual', 'learned_from_edit', 'brett_feedback'
    confidence NUMERIC(3,2),                   -- for learned entries: 0-1
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_voice_profiles_type ON voice_profiles (profile_type) WHERE is_active = true;
CREATE INDEX idx_voice_profiles_category ON voice_profiles (category) WHERE is_active = true;

COMMENT ON TABLE voice_profiles IS 'Brett''s voice/style guide. Used by AI for script generation.';


-- =============================================================================
-- 7. PIPELINE RUN LOG (for n8n observability)
-- =============================================================================

CREATE TABLE pipeline_runs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- What ran
    pipeline_step TEXT NOT NULL
        CHECK (pipeline_step IN (
            'feed_poll', 'article_extract', 'article_score',
            'curation_present', 'script_generate', 'audio_generate',
            'audio_process', 'distribute', 'metrics_collect'
        )),
    -- Context
    batch_number INT,                          -- for feed_poll
    feed_id UUID REFERENCES feeds(id),
    episode_id UUID REFERENCES episodes(id),
    -- Results
    status TEXT NOT NULL DEFAULT 'running'
        CHECK (status IN ('running', 'success', 'partial', 'failed')),
    items_processed INT DEFAULT 0,
    items_created INT DEFAULT 0,
    items_failed INT DEFAULT 0,
    error_message TEXT,
    metadata JSONB,                            -- flexible extra data
    -- Timing
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    duration_ms INT
);

CREATE INDEX idx_pipeline_runs_step ON pipeline_runs (pipeline_step, started_at DESC);
CREATE INDEX idx_pipeline_runs_status ON pipeline_runs (status) WHERE status != 'success';

COMMENT ON TABLE pipeline_runs IS 'Observability log for n8n workflow executions.';


-- =============================================================================
-- DATABASE FUNCTIONS
-- =============================================================================

-- Get the next batch of feeds to poll (based on current hour)
CREATE OR REPLACE FUNCTION get_feeds_for_current_batch()
RETURNS SETOF feeds AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM feeds
    WHERE batch_number = EXTRACT(HOUR FROM NOW())::INT
      AND is_active = true
    ORDER BY last_polled_at ASC NULLS FIRST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Get top-scored articles for Brett's review (not yet presented)
CREATE OR REPLACE FUNCTION get_articles_for_curation(
    p_limit INT DEFAULT 20,
    p_min_score NUMERIC DEFAULT 5.0
)
RETURNS TABLE (
    article_id UUID,
    title TEXT,
    summary TEXT,
    category TEXT,
    composite_score NUMERIC,
    feed_name TEXT,
    published_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.id,
        a.title,
        a.summary,
        a.category,
        a.composite_score,
        f.name AS feed_name,
        a.published_at
    FROM articles a
    JOIN feeds f ON a.feed_id = f.id
    WHERE a.status = 'scored'
      AND a.composite_score >= p_min_score
      AND a.is_duplicate = false
    ORDER BY a.composite_score DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Mark articles as presented to Brett
CREATE OR REPLACE FUNCTION mark_articles_presented(p_article_ids UUID[])
RETURNS VOID AS $$
BEGIN
    UPDATE articles
    SET status = 'presented',
        presented_at = NOW()
    WHERE id = ANY(p_article_ids)
      AND status = 'scored';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Record Brett's decision and update article status
CREATE OR REPLACE FUNCTION record_decision(
    p_article_id UUID,
    p_decision TEXT,
    p_source TEXT DEFAULT 'telegram',
    p_note TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_decision_id UUID;
    v_new_status TEXT;
BEGIN
    -- Map decision to article status
    v_new_status := CASE p_decision
        WHEN 'approve' THEN 'approved'
        WHEN 'skip' THEN 'rejected'
        WHEN 'flag' THEN 'presented'  -- stays presented, just flagged
        WHEN 'save_for_later' THEN 'presented'
    END;

    -- Insert decision
    INSERT INTO approval_decisions (article_id, decision, decision_source, brett_note)
    VALUES (p_article_id, p_decision, p_source, p_note)
    RETURNING id INTO v_decision_id;

    -- Update article status
    UPDATE articles SET status = v_new_status WHERE id = p_article_id;

    -- Update feed approval stats
    IF p_decision = 'approve' THEN
        UPDATE feeds
        SET total_articles_approved = total_articles_approved + 1
        WHERE id = (SELECT feed_id FROM articles WHERE id = p_article_id);
    END IF;

    RETURN v_decision_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Update feed poll status (success or failure)
CREATE OR REPLACE FUNCTION update_feed_poll_status(
    p_feed_id UUID,
    p_success BOOLEAN,
    p_error TEXT DEFAULT NULL,
    p_articles_found INT DEFAULT 0,
    p_etag TEXT DEFAULT NULL,
    p_last_modified TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    IF p_success THEN
        UPDATE feeds SET
            last_polled_at = NOW(),
            last_successful_at = NOW(),
            consecutive_failures = 0,
            last_error = NULL,
            etag = COALESCE(p_etag, etag),
            last_modified = COALESCE(p_last_modified, last_modified),
            total_articles_ingested = total_articles_ingested + p_articles_found,
            updated_at = NOW()
        WHERE id = p_feed_id;
    ELSE
        UPDATE feeds SET
            last_polled_at = NOW(),
            consecutive_failures = consecutive_failures + 1,
            last_error = p_error,
            -- Auto-disable after 72 consecutive failures (3 days)
            is_active = CASE WHEN consecutive_failures >= 71 THEN false ELSE is_active END,
            updated_at = NOW()
        WHERE id = p_feed_id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Dashboard: daily pipeline stats
CREATE OR REPLACE FUNCTION get_daily_stats(p_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE (
    articles_ingested BIGINT,
    articles_scored BIGINT,
    articles_presented BIGINT,
    articles_approved BIGINT,
    articles_rejected BIGINT,
    episodes_created BIGINT,
    episodes_published BIGINT,
    feeds_polled BIGINT,
    feeds_failed BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        (SELECT COUNT(*) FROM articles WHERE ingested_at::DATE = p_date),
        (SELECT COUNT(*) FROM articles WHERE scored_at::DATE = p_date),
        (SELECT COUNT(*) FROM articles WHERE presented_at::DATE = p_date),
        (SELECT COUNT(*) FROM approval_decisions WHERE decision = 'approve' AND decided_at::DATE = p_date),
        (SELECT COUNT(*) FROM approval_decisions WHERE decision = 'skip' AND decided_at::DATE = p_date),
        (SELECT COUNT(*) FROM episodes WHERE created_at::DATE = p_date),
        (SELECT COUNT(*) FROM episodes WHERE published_at::DATE = p_date),
        (SELECT COUNT(*) FROM pipeline_runs WHERE pipeline_step = 'feed_poll' AND status = 'success' AND started_at::DATE = p_date),
        (SELECT COUNT(*) FROM pipeline_runs WHERE pipeline_step = 'feed_poll' AND status = 'failed' AND started_at::DATE = p_date);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Get voice profile entries for prompt construction
CREATE OR REPLACE FUNCTION get_voice_profile(
    p_category TEXT DEFAULT NULL
)
RETURNS SETOF voice_profiles AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM voice_profiles
    WHERE is_active = true
      AND (p_category IS NULL OR category IS NULL OR category = p_category)
    ORDER BY priority DESC, profile_type;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at_feeds
    BEFORE UPDATE ON feeds
    FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

CREATE TRIGGER set_updated_at_episodes
    BEFORE UPDATE ON episodes
    FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

CREATE TRIGGER set_updated_at_distributions
    BEFORE UPDATE ON distributions
    FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

CREATE TRIGGER set_updated_at_voice_profiles
    BEFORE UPDATE ON voice_profiles
    FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();


-- =============================================================================
-- ROW LEVEL SECURITY
-- =============================================================================
-- Strategy: n8n uses the service_role key (bypasses RLS).
-- If a public-facing app is added later, enable RLS with anon read policies.
-- For now, enable RLS but allow service_role full access (which it gets by default).

ALTER TABLE feeds ENABLE ROW LEVEL SECURITY;
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE approval_decisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE episodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE episode_articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE distributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE voice_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_runs ENABLE ROW LEVEL SECURITY;

-- Service role bypasses RLS automatically.
-- Add anon read access for tables that a future web dashboard might need:
CREATE POLICY "Allow anon read on published episodes"
    ON episodes FOR SELECT
    USING (status = 'published');

CREATE POLICY "Allow anon read on distributions"
    ON distributions FOR SELECT
    USING (status = 'published');

-- All other tables: no anon access (service_role only via n8n)
