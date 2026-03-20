# Radical Concepts — AI Podcast Pipeline

## What This Is
AI-powered content platform for Brett Moore. ESADE I2P university project. Helps Brett turn his daily news reading into published content across multiple platforms with minimal manual effort.

## Client
**Brett Moore** — Australian entrepreneur in Barcelona. Law/business/tech background. Passionate about politics, science, journalism. Reads 2+ newspapers daily.
**Brett's #1 concern:** Accuracy and trust. Red-teams everything 2-3 times.

## Team
- **Chris (Kris)** — Technical lead (you)
- **Hamid** — Business & operations
- **Angelo** — Creative & production
- **Kalina** — Strategy & analysis
- **Roxy** — Marketing & product
- **Farid** — ESADE mentor/advisor

## Notion Workspace
- Sprint Board: https://www.notion.so/9b827c7dadeb4114be1722bbdc9350d0
- Knowledge Base: https://www.notion.so/869e4a58c7e44df1b6234fdc8b6047bb
- Decision Log: https://www.notion.so/95c98cc886ec448ba1d34be313cf32f3
- Project Hub: https://www.notion.so/3104d347036281189f3bc8d70bcbfd69

## Brett-Facing Deliverables (HTML)
- `deliverables/index.html` — Project hub (Brett's entry point)
- `radical-concepts-all-pitches.html` — 3 concept pitches
- `pipeline.html` — Interactive pipeline builder (V0/V1 module decisions)
- `i2p-brainstorming-board.html` — Design thinking process

## n8n Pipeline (local Docker at localhost:5678)

### Workflows (12 total)
| ID | Name | Function |
|---|---|---|
| `06kwfj6v3drpkzWv` | [WF-00] Error Handler | Telegram alerts on failures |
| `pW847d2oQEND8j8p` | [WF-01] RSS Score & Curate | RSS → Jina → LLM score → Telegram |
| `ZeQEEZzKcUM3V2HS` | [WF-02] Morning Curation | 7 AM top articles to Brett |
| `9wj3BiCrA4HVOVw8` | [WF-03] Approval Collector | Catches ✅/❌ button taps |
| `tNDOTw7dM2K0gmUR` | [WF-04] Script Generator | Articles → podcast script |
| `p1CLAXby7nKB52l8` | [WF-05] Audio Production | TTS (Fish Audio/Hume AI) |
| `Wj1QddPLjPlULmXk` | [WF-06] Distribution | RSS + YouTube + social |
| `BWQH7WuVuZAn4acO` | [WF-07] Brett Link Forward | Brett sends URL → ingest |
| `sTCe0Xqwyw9boenD` | [WF-08] Newsletter Ingestion | Email → pipeline |
| `ZUPOBmYJ94da9U0y` | [WF-09] Fallback Content | Auto-episode if Brett skips |
| `Nellt9AMDzaNM2Yk` | [WF-10] Auto-Clipping | Long → short clips |
| `kKMT4ml8FEdmoFCJ` | [WF-11] Quality Scoring | Pre-publish quality check |

### CLI
`n8n/n8n-cli.sh` — manages workflows via REST API. Reads secrets from `.env`.
Commands: `list`, `get <id>`, `json <id>`, `update <id> <file>`, `create <file>`, `activate <id>`, `run <id>`, `rename <id> <name>`

### Context Files (n8n/context/)
- `brett-persona.md` — persona for LLM system prompts
- `script-templates.md` — 3 episode structures
- `scoring-rubric.md` — 5-dimension scoring criteria
- `style-guide.md` — Brett's tone rules + signature phrases
- `rss-feeds-mvp.json` — 50 curated feeds
- `rss-feeds-full.json` — 93 feeds from Notion (Brett-relevant categories)

### Key Files
- `docs/superpowers/plans/2026-03-20-podcast-pipeline-full-build.md` — Implementation plan (v2)
- `docs/audit-report.md` — Codex GPT-5.4 audit of all workflows
- `docs/supabase-schema.sql` — Database schema (8 tables)
- `docs/supabase-setup.md` — Supabase setup guide
- `n8n/scripts/import-feeds-to-supabase.py` — Feed import script
- `n8n/n8n-technical-reference.md` — Full technical reference
- `n8n/n8n-workflow-json-reference.md` — JSON patterns for all node types

### Credentials in n8n
- OpenRouter: `1HjiTjhZTVqv5vLc` ✅
- Telegram: `V1Z3rnsrUvXf0TPr` ✅
- Supabase: TO CREATE
- Fish Audio / Hume AI: TO CREATE
- Auphonic: TO CREATE

## Working Conventions
- Notion = living workspace (source of truth)
- This repo = HTML deliverables for Brett + n8n pipeline code + session context

## Versioning
After any change to the HTML deliverables, create a GitHub release:
- **Patch** (x.x.1) — small fixes, copy tweaks, styling
- **Minor** (x.1.0) — new section, new page, significant content update
- **Major** (1.0.0) — new deliverable, major redesign, sprint milestone
Use `gh release create vX.Y.Z --title "..." --notes "..."`
