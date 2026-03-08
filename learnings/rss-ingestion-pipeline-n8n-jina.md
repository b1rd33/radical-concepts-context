# RSS News Ingestion + Full-Text Extraction Pipeline

Best practices for building an AI podcast pipeline using n8n, Jina Reader API, and Claude.

**Pipeline overview:** 928 RSS feeds -> Jina Reader full-text extraction -> Claude Haiku filtering -> Claude Sonnet summarization -> ~10 articles/day output.

---

## 1. RSS Management at Scale (928 Feeds)

### The Core Problem

n8n's built-in RSS Feed Trigger node is designed for single feeds. It creates one trigger per feed URL. Running 928 separate trigger nodes is not viable -- it would overload the scheduler, create massive execution logs, and is unmaintainable.

### Recommended Architecture: Scheduled Batch Polling

Instead of 928 trigger nodes, use a single **Schedule Trigger** that reads feed URLs from a database/spreadsheet and polls them in batches.

```
Schedule Trigger (every 15 min)
  -> Read feed URLs from DB (batch of ~50)
  -> Loop: RSS Read node per URL
  -> Deduplicate against seen articles
  -> Forward new articles to extraction
```

**Feed list storage:** Store the 928 feed URLs in a database table (Supabase/Postgres) or Google Sheet with columns:
- `feed_url` -- the RSS URL
- `category` -- news, science, general interest (useful for filtering later)
- `last_polled` -- timestamp of last successful poll
- `poll_priority` -- high-frequency feeds (breaking news) vs. daily feeds
- `enabled` -- toggle feeds on/off without editing workflows

### Batch Scheduling Strategy

Do NOT poll all 928 feeds at once. Stagger them:

| Priority     | Feed count | Poll interval | Batches          |
|-------------|-----------|---------------|------------------|
| Breaking news | ~50       | Every 15 min  | 1 batch of 50    |
| Daily news    | ~400      | Every 2 hours | 8 batches of 50  |
| Weekly/slow   | ~478      | Every 6 hours | 10 batches of 50 |

This means ~19 batches total, spread across the day. Each batch processes 50 feeds sequentially (RSS Read node in a loop), which takes roughly 1-3 minutes depending on feed response times.

**Cron expression examples for n8n Schedule Trigger:**
- Breaking news: `*/15 * * * *` (every 15 min)
- Daily news batch 1: `0 */2 * * *` (every 2 hours, offset 0)
- Daily news batch 2: `15 */2 * * *` (every 2 hours, offset 15 min)

### Rate Limiting Feed Requests

- Add a **Wait node** (1-2 seconds) between each RSS Read in the loop to avoid hammering servers
- Respect `<sy:updatePeriod>` and `<sy:updateFrequency>` RSS tags when available
- Handle HTTP 429 (rate limited) responses gracefully with exponential backoff
- Set a timeout of 10 seconds per feed; skip and log failures rather than blocking the batch

### Feed Health Monitoring

Track feed failures in the database:
- `consecutive_failures` counter -- auto-disable feeds after 10 consecutive failures
- `last_error` -- store the error message for debugging
- `avg_items_per_poll` -- detect feeds that never return new items

---

## 2. Jina Reader API

### How It Works

Prepend `https://r.jina.ai/` to any URL to get clean markdown output:

```
GET https://r.jina.ai/https://example.com/article
```

Returns the article content as clean markdown, stripped of navigation, ads, and boilerplate.

### Rate Limits

| Tier                   | Rate limit           |
|------------------------|---------------------|
| No API key             | 20 requests/minute  |
| Free API key           | 200 requests/minute |
| Paid                   | Higher (contact sales) |

**For this pipeline:** Always use a free API key (set `Authorization: Bearer jina_xxx` header). 200 req/min is plenty for batch processing.

### Free Token Budget (10M tokens)

Every new API key gets 10 million free tokens. Rough estimates:
- Average news article: ~2,000-5,000 tokens of extracted text
- At 3,000 tokens average: 10M tokens = ~3,333 articles
- At 10 articles/day final output, but maybe 50-100 articles/day extracted before filtering: **10M tokens lasts roughly 1-3 months**

**Important:** ReaderLM-v2 mode consumes 3x tokens. Avoid it unless you specifically need its HTML-to-markdown capabilities. The standard mode is sufficient for article extraction.

After the free tier, top-up pricing is approximately $0.02 per million tokens -- extremely cheap. Budget roughly $2-5/month for ongoing use.

### What Jina Reader Cannot Do

1. **Paywalled content** -- NYT, WSJ, FT, Bloomberg behind paywalls return truncated text or login pages. No workaround short of having a subscription and using authenticated requests.
2. **Heavy JavaScript-rendered pages** -- SPAs that load content via JS after page load may return empty or partial content. Most news sites server-render, so this is rarely an issue for news articles.
3. **Anti-bot protected sites** -- Sites with aggressive Cloudflare challenges or CAPTCHAs will fail.
4. **PDFs and non-HTML content** -- Limited support; not designed for this.
5. **Very long articles** -- Token output may be truncated on extremely long pages.

### Handling Failures

```
Article URL
  -> Jina Reader API call
  -> IF status != 200 OR content too short (<100 chars):
       -> Log failure
       -> Try fallback: RSS <content:encoded> or <description> field
  -> ELSE: proceed with extracted text
```

Many RSS feeds include full or partial article text in their XML. Use this as a fallback when Jina fails. Check for `<content:encoded>` (often full text) before `<description>` (often summary only).

### Alternatives Worth Knowing

| Tool         | Strengths                                    | Weaknesses                        | Cost          |
|-------------|----------------------------------------------|-----------------------------------|---------------|
| **Firecrawl** | Better markdown quality, handles JS rendering, structured JSON output | More expensive, overkill for simple articles | $19/mo starter |
| **Crawl4AI**  | Open source, self-hosted, LLM-optimized      | Requires hosting, more setup      | Free          |
| **Playwright** | Handles any JS-rendered page                 | Slow, resource-heavy, requires hosting | Free        |

**Recommendation:** Stick with Jina Reader as the primary extractor. It covers 90%+ of news articles. For the remaining failures, fall back to RSS content fields. Only add Firecrawl/Crawl4AI if you hit a pattern of specific important sources that Jina consistently fails on.

---

## 3. n8n Workflow Architecture

### One Massive Workflow vs. Multiple Chained Workflows

**Use multiple workflows.** A single workflow with 928 feeds, extraction, filtering, and summarization would be:
- Impossible to debug
- Prone to timeout failures cascading
- Unmaintainable

### Recommended Workflow Structure

```
Workflow 1: "Feed Poller" (scheduled)
  - Schedule Trigger
  - Read feed URLs batch from DB
  - Loop: RSS Read per feed
  - Deduplicate (check DB for existing article URLs)
  - Write new article URLs + metadata to DB (status: "pending_extraction")

Workflow 2: "Article Extractor" (scheduled, every 5 min)
  - Read pending articles from DB (batch of 20)
  - Loop: Jina Reader API per URL
  - Write extracted text to DB (status: "pending_filter")
  - Handle failures: mark as "extraction_failed", log error

Workflow 3: "AI Filter" (scheduled, every 30 min)
  - Read pending_filter articles from DB (batch of 50)
  - Loop: Claude Haiku call per article
  - Mark as "selected" or "rejected" in DB
  - Track token usage

Workflow 4: "AI Summarizer" (scheduled, every hour)
  - Read selected articles from DB
  - Claude Sonnet call per article (or batch)
  - Write summaries to DB (status: "summarized")
  - Output to final destination (Notion, email, etc.)

Workflow 5: "Error Handler" (error workflow)
  - Receives failure notifications from all other workflows
  - Logs errors, sends alerts (Slack/email/Telegram)
  - Retries failed items if appropriate
```

### Why This Architecture Works

- **Each workflow has one job** -- easy to test, debug, and monitor independently
- **Database as the glue** -- articles move through statuses: `pending_extraction -> pending_filter -> selected/rejected -> summarized`
- **Decoupled timing** -- polling runs frequently, AI calls run less often (saves budget)
- **Partial failures don't cascade** -- if the extractor fails, the poller and filter keep working
- **Sub-workflow executions don't count** toward n8n plan limits

### n8n Execute Sub-Workflow Node

For operations within a workflow that repeat (e.g., "extract and validate one article"), extract them into sub-workflows:

- **"Run once for each item"** mode processes items sequentially -- safer for rate-limited APIs
- **"Run once with all items"** mode passes everything at once -- faster but risks timeouts
- Sub-workflows can be called by ID, which means you can version them independently

### Error Handling Best Practices

1. **Set a global Error Workflow** (Workflow 5 above) in each workflow's settings
2. **Use "Continue On Fail"** on nodes that call external APIs (Jina, Claude) so one failure doesn't kill the batch
3. **Add IF nodes after API calls** to check response status and route failures to a "log error" branch
4. **Implement retry logic** using the built-in retry settings on HTTP Request nodes (2 retries, 5-second delay)
5. **Dead letter pattern** -- after 3 retries, mark the article as permanently failed and move on

### Naming Conventions

- Workflows: `[Pipeline] Feed Poller`, `[Pipeline] Article Extractor`
- Nodes: `Read Pending Articles`, `Call Jina Reader`, `Check Extraction Success`
- Sticky notes in each workflow explaining what it does and how it connects to others

---

## 4. Content Deduplication

### The Problem

With 928 feeds, the same article (e.g., an AP/Reuters wire story) will appear in dozens of feeds with different URLs but identical or near-identical content.

### Multi-Layer Deduplication Strategy

#### Layer 1: URL Canonicalization (cheapest, do first)

Before storing any article:
1. Strip tracking parameters (`utm_source`, `utm_medium`, `utm_campaign`, `fbclid`, etc.)
2. Normalize the URL (lowercase hostname, remove trailing slashes, resolve redirects)
3. Check if the canonical URL already exists in the database

```javascript
// In n8n Function node
function canonicalizeUrl(url) {
  const u = new URL(url);
  // Remove tracking params
  ['utm_source','utm_medium','utm_campaign','utm_content',
   'utm_term','fbclid','gclid','ref','source'].forEach(p => {
    u.searchParams.delete(p);
  });
  // Normalize
  u.hostname = u.hostname.toLowerCase();
  u.pathname = u.pathname.replace(/\/+$/, '');
  return u.toString();
}
```

#### Layer 2: Title + Publication Date Matching

Same-story syndication often has identical titles but different URLs:
- Hash the normalized title (lowercase, strip punctuation)
- Check for matching title hash within a +/-12 hour window of publish date
- If match found, it is likely a duplicate

```javascript
// In n8n Function node
const crypto = require('crypto');
function titleHash(title) {
  const normalized = title.toLowerCase()
    .replace(/[^\w\s]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
  return crypto.createHash('sha256').update(normalized).digest('hex').substring(0, 16);
}
```

#### Layer 3: Content Fingerprinting (for near-duplicates)

For articles that have been lightly rewritten:
- After Jina extraction, compute a SimHash or MinHash of the article text
- Compare against existing fingerprints with a similarity threshold (e.g., >85% similar = duplicate)
- This catches AP/Reuters wire stories republished with minor edits

**Practical shortcut:** If Layer 1 + Layer 2 catch 95% of duplicates (likely for news), skip Layer 3 to reduce complexity. Add it only if you notice significant duplicate content getting through.

#### Database Schema for Deduplication

```sql
CREATE TABLE articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  canonical_url TEXT UNIQUE NOT NULL,
  title_hash TEXT NOT NULL,
  content_hash TEXT,  -- SHA-256 of extracted text
  source_feed_url TEXT NOT NULL,
  title TEXT NOT NULL,
  published_at TIMESTAMPTZ,
  extracted_text TEXT,
  status TEXT DEFAULT 'pending_extraction',
  -- pending_extraction, pending_filter, selected, rejected, summarized, failed
  summary TEXT,
  brett_score FLOAT,  -- from Haiku filtering
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_articles_title_hash ON articles(title_hash);
CREATE INDEX idx_articles_status ON articles(status);
CREATE INDEX idx_articles_published ON articles(published_at);
```

### Monitoring Duplicate Rates

Track how many duplicates each feed generates. If a feed produces >80% duplicates, it is likely a syndication source already covered by other feeds -- consider disabling it.

---

## 5. Storage Between Pipeline Stages

### Recommended: Supabase (PostgreSQL)

Supabase is the best fit for this pipeline because:
- **Native n8n integration** -- Supabase node works out of the box
- **PostgreSQL underneath** -- full SQL, indexes, UPSERT for deduplication
- **Free tier is generous** -- 500MB database, 50K monthly active users, sufficient for this scale
- **Row-level security** -- not critical here but nice to have
- **Realtime subscriptions** -- could trigger downstream workflows when articles change status
- **API auto-generated** -- can query articles from other tools/dashboards

### Schema Design

Use the articles table from Section 4 above, plus:

```sql
CREATE TABLE feeds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  url TEXT UNIQUE NOT NULL,
  name TEXT,
  category TEXT,  -- news, science, general
  poll_priority TEXT DEFAULT 'daily',  -- breaking, daily, weekly
  enabled BOOLEAN DEFAULT true,
  last_polled_at TIMESTAMPTZ,
  consecutive_failures INT DEFAULT 0,
  last_error TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE pipeline_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow_name TEXT NOT NULL,
  article_id UUID REFERENCES articles(id),
  stage TEXT NOT NULL,  -- polling, extraction, filtering, summarization
  status TEXT NOT NULL,  -- success, failure, skipped
  error_message TEXT,
  tokens_used INT,
  duration_ms INT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Why Not Other Options

| Option         | Verdict  | Reason                                              |
|---------------|----------|-----------------------------------------------------|
| n8n variables  | No       | Not designed for large datasets, no querying         |
| Google Sheets  | No       | Too slow at scale, API rate limits, no real indexing  |
| Notion DB      | Maybe    | Good for final output/dashboard, too slow for pipeline state |
| Raw PostgreSQL | Fine     | Works, but Supabase adds free hosting + API + dashboard |
| Airtable       | No       | Row limits on free tier, API rate limits              |

**Hybrid approach:** Use Supabase for pipeline state (all intermediate stages) and Notion for the final curated output (the ~10 daily articles with summaries that Brett sees).

---

## 6. Rate Limiting Claude API Calls

### Pricing Reality Check

Current Claude API pricing (2026):

| Model            | Input (per 1M tokens) | Output (per 1M tokens) |
|-----------------|----------------------|------------------------|
| Haiku 4.5        | $1.00                | $5.00                  |
| Sonnet 4.5/4.6   | $3.00                | $15.00                 |

**Batch API gives 50% discount on all models.**

### Budget Estimation (~10 articles/day final output)

Assume the pipeline processes:
- **100 articles/day** through Haiku filtering (the rest are duplicates or from low-priority feeds)
- **10 articles/day** through Sonnet summarization

**Haiku filtering cost per article:**
- Input: ~3,000 tokens (article text) + ~200 tokens (system prompt) = ~3,200 tokens
- Output: ~100 tokens (yes/no + brief reasoning)
- Cost per article: (3,200 * $1.00 / 1M) + (100 * $5.00 / 1M) = $0.0037
- Daily: 100 articles * $0.0037 = $0.37/day
- Monthly: ~$11/month

**Sonnet summarization cost per article:**
- Input: ~4,000 tokens (article + prompt)
- Output: ~500 tokens (summary)
- Cost per article: (4,000 * $3.00 / 1M) + (500 * $15.00 / 1M) = $0.0195
- Daily: 10 articles * $0.0195 = $0.195/day
- Monthly: ~$6/month

**Total monthly estimate: ~$17/month** (~34 EUR for 2 months)

This fits comfortably within the 30-60 EUR / 2-month budget. You have headroom to process more articles or use longer prompts.

### Cost Optimization Strategies

1. **Use the Batch API** for non-urgent processing (50% discount). Since the podcast is daily, you can batch articles and submit them all at once rather than one-by-one. Batch results return within 24 hours.

2. **Prompt caching** -- if you use the same system prompt across all Haiku calls (likely), enable prompt caching. Cache reads cost only 10% of normal input pricing. For 100 calls/day with the same ~200-token system prompt, this saves marginal cost but adds up.

3. **Pre-filter before AI** -- before sending to Haiku, apply cheap rule-based filters:
   - Skip articles shorter than 200 words (likely stubs or link posts)
   - Skip articles older than 48 hours
   - Skip articles with titles matching known low-value patterns (listicles, sponsored content)
   - This could reduce Haiku calls from 100/day to 50/day

4. **Batch multiple articles per Haiku call** -- instead of one API call per article, send 5-10 article titles + first paragraphs in a single call asking Haiku to rate them all. This amortizes the system prompt cost and reduces total API calls.

### Rate Limit Management in n8n

- Add **Wait nodes** (1-2 seconds) between Claude API calls in loops
- Use the **"Run once for each item"** mode on sub-workflows to process sequentially
- Monitor daily token usage via the `pipeline_logs` table
- Set up alerts if daily spend exceeds a threshold

### Haiku Filtering Prompt Template

```
You are a news curator for a daily podcast. The host is Brett, who covers
technology, science, geopolitics, economics, and culture.

Rate this article on a scale of 1-5 for "Brett-worthiness":
5 = Must cover -- breaking, consequential, or deeply fascinating
4 = Strong candidate -- interesting angle, good story
3 = Maybe -- depends on what else is available today
2 = Weak -- generic or already well-covered
1 = Skip -- off-topic, clickbait, or trivial

Respond with ONLY a JSON object:
{"score": N, "reason": "one sentence explanation"}

Article title: {{title}}
Article source: {{source}}
Article text (first 1000 chars): {{text_preview}}
```

---

## 7. Real-World n8n + RSS Examples

### Community Templates (directly relevant)

1. **"Automate RSS content with AI: summarize, notify & archive"**
   - Reads RSS links from Google Sheets, fetches content, summarizes with GPT, sends to Discord, archives to Sheets
   - Template: https://n8n.io/workflows/4503

2. **"Automated RSS monitoring with Gemini AI summaries and deduplication to Google Sheets"**
   - Filters new articles, checks for duplicates, generates structured AI summaries
   - Template: https://n8n.io/workflows/5778

3. **"RSS feed news processing and distribution workflow"**
   - Multi-feed processing with distribution to multiple channels
   - Template: https://n8n.io/workflows/2785

4. **"Daily AI news digest with RSS, Llama 3.2 summarization & Telegram delivery"**
   - Privacy-focused, can run on local AI (Raspberry Pi)
   - Template: https://n8n.io/workflows/6011

5. **"Personalized AI tech newsletter using RSS, OpenAI and Gmail"**
   - Weekly newsletter from RSS with vector DB for personalization
   - Template: https://n8n.io/workflows/3986

### Key Patterns from Community Workflows

- Most use Google Sheets for feed management (fine for <50 feeds, not for 928)
- Deduplication is universally done via URL matching against a spreadsheet/database
- AI summarization is the most common use case, filtering is less common
- Error handling is often missing in community templates -- add your own

### DEV Community Guide

A detailed walkthrough of building RSS subscription management with AI reading in n8n was published on DEV Community, covering feed management, content extraction, and AI processing in a self-hosted setup.

Reference: https://dev.to/yeshan333/building-your-own-rss-feed-subscription-management-ai-large-model-reading-workflow-with-n8n-2lia

---

## 8. Implementation Roadmap

### Phase 1: Foundation (Day 1-2)
- Set up Supabase project with the schema above
- Import 928 feed URLs into the `feeds` table with categories and priorities
- Build Workflow 1 (Feed Poller) with a small batch (10 feeds) for testing
- Verify deduplication works (URL canonicalization + title hashing)

### Phase 2: Extraction (Day 3-4)
- Get Jina Reader API key
- Build Workflow 2 (Article Extractor)
- Test with 50 articles, verify markdown quality
- Add RSS content fallback for Jina failures
- Monitor token consumption

### Phase 3: AI Pipeline (Day 5-6)
- Build Workflow 3 (AI Filter) with Claude Haiku
- Test filtering prompt, calibrate "Brett-worthiness" scores
- Build Workflow 4 (AI Summarizer) with Claude Sonnet
- Test summary quality and length

### Phase 4: Production (Day 7)
- Build Workflow 5 (Error Handler)
- Scale Feed Poller to full 928 feeds with batch scheduling
- Set up monitoring dashboard (Supabase dashboard or simple n8n workflow that reports daily stats)
- Run for 3-5 days and tune filtering thresholds

### Key Metrics to Track
- Articles discovered per day (should be hundreds to thousands)
- Duplicate rate (expect 30-60% across 928 feeds)
- Jina extraction success rate (target >95%)
- Haiku filter pass rate (target 10-20% of extracted articles)
- Daily Claude API spend
- End-to-end latency (article published -> summary available)

---

## Sources

- [n8n RSS Feed Trigger docs](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.rssfeedreadtrigger/)
- [n8n RSS Read docs](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.rssfeedread/)
- [n8n community: monitoring 50+ RSS feeds](https://community.n8n.io/t/what-would-be-the-best-practice-method-to-monitor-50-rss-feeds/12629)
- [n8n community: workflow structuring for scale](https://community.n8n.io/t/best-practices-for-structuring-n8n-workflows-for-scale-and-long-term-maintainability/248671)
- [n8n error handling docs](https://docs.n8n.io/flow-logic/error-handling/)
- [n8n sub-workflows docs](https://docs.n8n.io/flow-logic/subworkflows/)
- [Seven n8n Workflow Best Practices for 2026](https://michaelitoback.com/n8n-workflow-best-practices/)
- [n8n best practices for complex workflows](https://n8n.expert/it-automation/best-practices-designing-n8n-workflows/)
- [Jina Reader API](https://jina.ai/reader/)
- [Jina AI vs Firecrawl comparison](https://blog.apify.com/jina-ai-vs-firecrawl/)
- [Jina Reader alternatives 2026](https://scrapegraphai.com/blog/jina-alternatives)
- [Claude API Pricing](https://platform.claude.com/docs/en/about-claude/pricing)
- [Claude API pricing breakdown 2026](https://www.metacto.com/blogs/anthropic-api-pricing-a-full-breakdown-of-costs-and-integration)
- [n8n + Supabase integration](https://n8n.io/integrations/postgres/and/supabase/)
- [RSS deduplication methods](https://www.alibaba.com/product-insights/call-for-help-stop-repeating-rss-feed-items-proven-deduplication-methods.html)
- [n8n workflow template: RSS + AI summarize + archive](https://n8n.io/workflows/4503)
- [n8n workflow template: RSS monitoring + Gemini + dedup](https://n8n.io/workflows/5778)
- [DEV Community: RSS + AI reading with n8n](https://dev.to/yeshan333/building-your-own-rss-feed-subscription-management-ai-large-model-reading-workflow-with-n8n-2lia)
