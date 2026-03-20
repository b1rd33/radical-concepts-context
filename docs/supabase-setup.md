# Supabase Setup — Radical Concepts Pipeline

## 1. Create the Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign in (GitHub OAuth is fastest)
2. Click **New Project**
3. Settings:
   - **Organization**: Create one or use existing
   - **Project name**: `radical-concepts`
   - **Database password**: Generate a strong one, save it in 1Password / `.env`
   - **Region**: EU West (Frankfurt) — closest to Barcelona
   - **Plan**: Free (500 MB database, 1 GB file storage)
4. Wait ~2 minutes for provisioning

## 2. Get API Credentials

1. In the Supabase dashboard, go to **Settings → API**
2. Copy these three values:

| Value | Where to find | What it's for |
|-------|--------------|---------------|
| **Project URL** | `https://xxxxx.supabase.co` | Base API endpoint |
| **anon (public) key** | Under "Project API keys" | Public-facing reads (future dashboard) |
| **service_role key** | Under "Project API keys" (click reveal) | n8n automation — bypasses RLS |

3. Add to your `.env`:
```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...
```

**IMPORTANT**: The `service_role` key bypasses Row Level Security. Never expose it in client-side code. It's safe in n8n (server-side).

## 3. Run the Schema

1. In the Supabase dashboard, go to **SQL Editor**
2. Click **New query**
3. Paste the entire contents of `docs/supabase-schema.sql`
4. Click **Run** (or Cmd+Enter)
5. Verify: go to **Table Editor** — you should see 8 tables:
   - `feeds`, `articles`, `approval_decisions`, `episodes`
   - `episode_articles`, `distributions`, `voice_profiles`, `pipeline_runs`

## 4. Create Supabase Credential in n8n

### Option A: n8n Cloud (your current setup)

1. In n8n, open any workflow → add a **Supabase** node
2. Click **Credential to connect with** → **Create New**
3. Fill in:
   - **Host**: `https://xxxxx.supabase.co` (your Project URL)
   - **Service Role Secret**: paste the `service_role` key
4. Click **Save**
5. Name it: `Radical Concepts Supabase`

### Option B: Direct Postgres (for complex queries)

For queries the Supabase node can't handle (joins, functions, bulk inserts):

1. Add a **Postgres** node
2. Click **Credential to connect with** → **Create New**
3. Fill in:
   - **Host**: `db.xxxxx.supabase.co` (note the `db.` prefix)
   - **Database**: `postgres`
   - **User**: `postgres`
   - **Password**: your database password (from project creation)
   - **Port**: `5432` (or `6543` for connection pooler / transaction mode)
   - **SSL**: enable (required for Supabase cloud)
4. Click **Save**
5. Name it: `Radical Concepts Postgres`

**When to use which:**
- **Supabase node**: Simple CRUD (insert article, update status, get rows by filter)
- **Postgres node**: Calling functions (`SELECT get_feeds_for_current_batch()`), bulk operations, joins

## 5. Supabase Storage Setup (Optional)

If storing short audio previews in Supabase Storage:

1. Go to **Storage** in the dashboard
2. Click **New bucket**
3. Create bucket: `audio-previews`
   - **Public**: No (private — access via signed URLs)
   - **Allowed MIME types**: `audio/mpeg, audio/wav, audio/mp4`
   - **Max file size**: 50 MB (free tier limit)

**For full episodes**: Use an external host (Podbean, Cloudflare R2, or S3). At ~14 MB per 15-min episode, 365 episodes/year = 5 GB — exceeds the 1 GB free storage.

## 6. Free Tier Budget

| Resource | Limit | Our Usage (Year 1) | Status |
|----------|-------|---------------------|--------|
| Database storage | 500 MB | ~85 MB | OK |
| File storage | 1 GB | ~0 (external audio) | OK |
| Database egress | 2 GB/month | ~200 MB/month | OK |
| Storage egress | 2 GB/month | ~0 | OK |
| Auth users | 50,000 MAU | ~1 (service role) | OK |
| Edge functions | 500K/month | 0 (using n8n) | OK |

**Key constraint**: Free projects pause after 7 days of inactivity. The hourly feed polling from n8n keeps the project alive. If n8n workflows are paused for >7 days, the Supabase project will auto-pause and need manual reactivation.

## 7. Testing the Connection

Quick test from n8n after setup:

```sql
-- In a Postgres node, run:
SELECT NOW() AS server_time, current_database(), version();
```

Then test a function:
```sql
SELECT * FROM get_daily_stats();
```

## 8. Import Initial Feeds

After the schema is created, populate the `feeds` table from the curated RSS feeds list:

```bash
cd n8n/scripts
pip install -r requirements.txt
python import-feeds-to-supabase.py
```

This reads from `n8n/context/rss-feeds-full.json` (if it exists, otherwise `rss-feeds-mvp.json`), assigns round-robin `batch_number` (0-23), and upserts into the `feeds` table. Safe to re-run — duplicates are skipped via upsert on URL.

**Prerequisites**: `SUPABASE_URL` and `SUPABASE_KEY` (service_role) must be set in the repo root `.env`.

## 9. Schema Tables Reference

| Table | Purpose | Est. rows/year |
|-------|---------|---------------|
| `feeds` | 928 RSS source URLs with batch assignment | ~930 |
| `articles` | Extracted articles with scores & dedup | ~50,000 |
| `approval_decisions` | Brett's approve/skip per article | ~15,000 |
| `episodes` | Generated scripts, audio URLs, status | ~365 |
| `episode_articles` | Which articles in which episode | ~1,100 |
| `distributions` | Platform publishing + metrics | ~2,500 |
| `voice_profiles` | Brett's style guide entries | ~50 |
| `pipeline_runs` | n8n execution log | ~25,000 |

## 10. Key Database Functions

| Function | Purpose | Called by |
|----------|---------|----------|
| `get_feeds_for_current_batch()` | Returns ~39 feeds for current hour | Feed poll workflow |
| `get_articles_for_curation(limit, min_score)` | Top scored articles for Brett | Curation workflow |
| `mark_articles_presented(article_ids[])` | Update status after showing to Brett | Curation workflow |
| `record_decision(article_id, decision, source, note)` | Save Brett's approval + update article | Telegram bot workflow |
| `update_feed_poll_status(feed_id, success, ...)` | Track feed health, auto-disable after 72 failures | Feed poll workflow |
| `get_daily_stats(date)` | Dashboard summary | Reporting workflow |
| `get_voice_profile(category)` | Get style rules for prompt building | Script generation workflow |
