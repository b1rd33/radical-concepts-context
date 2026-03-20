# n8n Podcast Pipeline — Fasten Your Seatbelt

AI-powered daily news commentary pipeline for Brett Moore.

## Quick Start

```bash
# 1. Start n8n (Docker must be running)
docker run -d --name n8n -p 5678:5678 \
  -e N8N_SECURE_COOKIE=false \
  -v n8n_data:/home/node/.n8n n8nio/n8n

# 2. Open n8n
open http://localhost:5678

# 3. List workflows
./n8n-cli.sh list

# 4. Test WF-01 (RSS scoring)
./n8n-cli.sh run pW847d2oQEND8j8p
```

## Workflows

| # | Name | Trigger | What it does |
|---|---|---|---|
| WF-00 | Error Handler | Error Trigger | Sends Telegram alert on any workflow failure |
| WF-01 | RSS Score & Curate | Manual / Schedule | Reads RSS → extracts full text → AI scores → filters ≥7 → Telegram with buttons |
| WF-02 | Morning Curation | Schedule (7 AM) | Sends top scored articles to Brett on Telegram |
| WF-03 | Approval Collector | Telegram Trigger | Catches Brett's ✅/❌ button taps, collects approved articles |
| WF-04 | Script Generator | Manual / Webhook | Takes approved articles → generates podcast script in Brett's voice |
| WF-05 | Audio Production | Manual / Webhook | Script → TTS (Fish Audio/Hume AI) → Auphonic cleanup |
| WF-06 | Distribution | Manual / Webhook | Publishes to podcast RSS, YouTube, social media |
| WF-07 | Brett Link Forward | Telegram Trigger | Brett sends URL → Jina extracts → confirms |
| WF-08 | Newsletter Ingestion | Manual / IMAP | Extracts article links from forwarded newsletters |
| WF-09 | Fallback Content | Manual / Schedule | Auto-generates episode if Brett doesn't record |
| WF-10 | Auto-Clipping | Manual | Identifies best 60-90s clip moments from transcript |
| WF-11 | Quality Scoring | Manual | Checks script quality (accuracy, engagement, voice match) |

## Architecture

Each workflow is **independent and testable**. They communicate through **Supabase status fields** (when connected) or can be triggered manually for testing.

```
WF-01 (score) → Supabase: articles.status = 'scored'
WF-02 (curate) ← reads scored articles, sends to Brett
WF-03 (approve) → Supabase: articles.status = 'approved'
WF-04 (script) ← reads approved, generates script → episodes.status = 'draft'
WF-05 (audio) ← reads approved script → episodes.status = 'audio_ready'
WF-06 (publish) ← reads audio_ready → episodes.status = 'published'
```

## Swapping Services

Every external service is a single node. Change one node to swap providers:

| Service | Default | Alternatives | Change what |
|---|---|---|---|
| TTS | Fish Audio | Hume AI, ElevenLabs | HTTP Request URL + body |
| LLM | OpenRouter (GPT-5.4-mini) | Anthropic direct, Ollama | Model ID in OpenRouter node |
| Extraction | Jina Reader | Trafilatura, Firecrawl | HTTP Request URL |
| Audio cleanup | Auphonic | Cleanvoice | Swap HTTP node for community node |
| Bot | Telegram | WhatsApp | Swap Telegram nodes |

## CLI Reference

```bash
./n8n-cli.sh status                     # Check if n8n is running
./n8n-cli.sh list                       # List all workflows
./n8n-cli.sh get <id>                   # Show workflow details
./n8n-cli.sh json <id>                  # Get full JSON
./n8n-cli.sh update <id> <json_file>    # Update workflow
./n8n-cli.sh create <json_file>         # Create new workflow
./n8n-cli.sh activate <id>             # Activate (turn on)
./n8n-cli.sh deactivate <id>           # Deactivate
./n8n-cli.sh run <id>                  # Execute workflow
./n8n-cli.sh executions [id] [limit]   # List recent executions
./n8n-cli.sh rename <id> <name>        # Rename workflow
./n8n-cli.sh set-node <id> <node> <path> <value>  # Change a node parameter
```

## Context Files

| File | Purpose |
|---|---|
| `context/brett-persona.md` | Brett's full persona for LLM system prompts |
| `context/script-templates.md` | 3 episode structures (daily, deep-dive, weekly) |
| `context/scoring-rubric.md` | 5-dimension scoring with weights |
| `context/style-guide.md` | Brett's tone rules, do/don't, signature phrases |
| `context/rss-feeds-mvp.json` | 50 curated RSS feeds for MVP |
| `context/rss-feeds-full.json` | 93 feeds exported from Notion |

## Setup Supabase (Required for Production)

1. Create free project at supabase.com
2. Run `docs/supabase-schema.sql` in SQL Editor
3. Add Supabase credential to n8n
4. Update `.env` with SUPABASE_URL and SUPABASE_KEY
5. Run `python scripts/import-feeds-to-supabase.py`

## For Telegram Webhooks (WF-02, WF-03, WF-07)

```bash
# Start ngrok tunnel
ngrok http 5678

# Restart n8n with webhook URL
docker stop n8n && docker rm n8n
docker run -d --name n8n -p 5678:5678 \
  -e N8N_SECURE_COOKIE=false \
  -e WEBHOOK_URL=https://YOUR_NGROK_URL/ \
  -v n8n_data:/home/node/.n8n n8nio/n8n

# Activate webhook-dependent workflows
./n8n-cli.sh activate <WF-03-ID>
./n8n-cli.sh activate <WF-07-ID>
```
