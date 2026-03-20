# Podcast Pipeline Full Build — Implementation Plan v2

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

---

## Current Status (2026-03-20)

### 12 Workflows Deployed to Local n8n

| ID | Workflow | Status |
|---|---|---|
| `06kwfj6v3drpkzWv` | [WF-00] Error Handler | ✅ Deployed |
| `pW847d2oQEND8j8p` | [WF-01] RSS Score & Curate | ✅ Deployed (cleaned) |
| `ZeQEEZzKcUM3V2HS` | [WF-02] Morning Curation | ✅ Deployed |
| `9wj3BiCrA4HVOVw8` | [WF-03] Approval Collector | ✅ Deployed |
| `tNDOTw7dM2K0gmUR` | [WF-04] Script Generator | ✅ Deployed |
| `p1CLAXby7nKB52l8` | [WF-05] Audio Production | ✅ Deployed |
| `Wj1QddPLjPlULmXk` | [WF-06] Distribution | ✅ Deployed |
| `BWQH7WuVuZAn4acO` | [WF-07] Brett Link Forward | ✅ Deployed |
| `sTCe0Xqwyw9boenD` | [WF-08] Newsletter Ingestion | ✅ Deployed |
| `ZUPOBmYJ94da9U0y` | [WF-09] Fallback Content | ✅ Deployed |
| `Nellt9AMDzaNM2Yk` | [WF-10] Auto-Clipping | ✅ Deployed |
| `kKMT4ml8FEdmoFCJ` | [WF-11] Quality Scoring | ✅ Deployed |

### 5 Context Files Written
- `n8n/context/brett-persona.md`
- `n8n/context/scoring-rubric.md`
- `n8n/context/style-guide.md`
- `n8n/context/script-templates.md`
- `n8n/context/feeds.md`

### Codex Audit
- GPT-5.4 Codex audited all 12 workflows
- **5 issues found**: secrets in source, context files not wired, no Supabase nodes, mock data, no durable handoffs
- **2 fixed**: Task 16 Step 1 (secrets moved to .env), Task 1 (WF-01 cleaned)
- **3 pending Supabase**: Tasks 18-20 (require Supabase project creation first)
- Task 17 (wire context files) IN PROGRESS — agents fixing WF-01, WF-04, WF-09, WF-10, WF-11

### n8n CLI
- `n8n-cli.sh` working with `.env` secrets (no more hardcoded API key)

### What Remains
1. **Supabase project creation** (human action — Step 0.1-0.3)
2. **Wire Supabase into all workflows** (Tasks 18-20)
3. **TTS credentials** (Fish Audio / Hume AI account setup)
4. **Durable handoffs** between workflows via Supabase status fields
5. **End-to-end integration test** (Task 13)
6. **Demo prep** (Task 14-15)

---

**Goal:** Build the complete "Fasten Your Seatbelt" AI podcast pipeline — 39 product backlog features across 6 modules — as modular, swappable n8n workflows with Supabase as the state store. Every component can be tested independently and swapped without breaking the pipeline.

**Architecture:** Modular n8n workflows communicating via Supabase (NOT direct connections). Each module is a separate workflow with clear inputs/outputs. Swap any service (LLM, TTS, audio processor, distribution platform) by changing one node — the rest of the pipeline doesn't care.

**Modularity Principle:** Every external service is wrapped in a single HTTP Request node with a standardized output format. To swap Fish Audio → Hume AI, you change ONE node. To swap OpenRouter → Anthropic direct, you change ONE node. The data flows through Supabase status fields, not direct n8n connections between workflows.

**Tech Stack (all swappable):**
| Layer | Primary | Backup/Alternative | Swap Effort |
|---|---|---|---|
| Orchestration | n8n (local Docker) | n8n Cloud | Export/import JSON |
| Database | Supabase (free) | Google Sheets | Change Supabase nodes to Sheets |
| LLM Scoring | OpenRouter (GPT-5.4-mini) | Anthropic Claude Haiku | Change model ID in node |
| LLM Scripts | OpenRouter (Claude Sonnet) | Anthropic direct API | Change HTTP endpoint |
| Full-text extraction | Jina Reader API | Trafilatura microservice | Change HTTP URL |
| TTS | Fish Audio ($11/mo) | Hume AI Octave ($3-14/mo) | Change HTTP endpoint + body |
| Audio cleanup | Auphonic (free 2hrs/mo) | Cleanvoice (n8n community node) | Swap node |
| Bot interface | Telegram | WhatsApp Business API | Swap Telegram nodes |
| Podcast hosting | RSS.com (free) | Castopod (self-hosted) | Change upload endpoint |
| Social distribution | Direct API (YouTube, LinkedIn, X) | Buffer ($6/channel/mo) | Change to Buffer API |

**Deadline:** April 14, 2026 (25 days from today)
**Budget:** EUR 200 total (~EUR 21-49/month operating)

---

## Credentials (local n8n at localhost:5678)

| Service | n8n Credential ID | Type |
|---|---|---|
| OpenRouter | `1HjiTjhZTVqv5vLc` | openRouterApi |
| Telegram | `V1Z3rnsrUvXf0TPr` | telegramApi |
| Jina Reader | Hardcoded in HTTP header | httpHeaderAuth |
| Supabase | **TO CREATE** | supabaseApi |
| Fish Audio | **TO CREATE** | httpHeaderAuth |
| Hume AI | **TO CREATE** | httpHeaderAuth |
| Auphonic | **TO CREATE** | httpHeaderAuth |
| YouTube | **TO CREATE** | youTubeOAuth2Api |

**Workflow IDs:**
- `06kwfj6v3drpkzWv` — [WF-00] Error Handler
- `pW847d2oQEND8j8p` — [WF-01] RSS Score & Curate
- `ZeQEEZzKcUM3V2HS` — [WF-02] Morning Curation
- `9wj3BiCrA4HVOVw8` — [WF-03] Approval Collector
- `tNDOTw7dM2K0gmUR` — [WF-04] Script Generator
- `p1CLAXby7nKB52l8` — [WF-05] Audio Production
- `Wj1QddPLjPlULmXk` — [WF-06] Distribution
- `BWQH7WuVuZAn4acO` — [WF-07] Brett Link Forward
- `sTCe0Xqwyw9boenD` — [WF-08] Newsletter Ingestion
- `ZUPOBmYJ94da9U0y` — [WF-09] Fallback Content
- `Nellt9AMDzaNM2Yk` — [WF-10] Auto-Clipping
- `kKMT4ml8FEdmoFCJ` — [WF-11] Quality Scoring

**CLI:** `/Users/christiannikolov/Projects/radical-concepts-context/n8n/n8n-cli.sh`
**Telegram Chat ID:** `1240314255`

---

## Modular Workflow Architecture (7 workflows)

```
[WF-00] Error Handler ← catches errors from ALL workflows

[WF-01] Source & Score        → writes to Supabase: articles (status=scored)
  RSS feeds → Jina extract → LLM score → filter ≥7 → save to DB

[WF-02] Morning Curation      → reads Supabase: articles (status=scored)
  7 AM trigger → top articles → Telegram with ✅❌ buttons

[WF-03] Approval Collector     → reads Telegram callbacks → writes Supabase: articles (status=approved)
  Telegram Trigger → collect approvals → when 3+ → trigger script gen

[WF-04] Script Generator       → reads Supabase: articles (status=approved)
  Aggregate approved articles → LLM script → save to DB → send to Brett for review

[WF-05] Audio Production       → reads Supabase: episodes (status=script_approved)
  TTS (Fish Audio OR Hume AI) → Auphonic cleanup → save audio URL

[WF-06] Distribution           → reads Supabase: episodes (status=audio_ready)
  Upload to podcast RSS + YouTube + social → mark as published
```

**Key design: Supabase status fields drive the flow.**
Each workflow queries for items in a specific status, processes them, advances the status. If one workflow crashes, items stay in their current status and get picked up on the next run.

```
Article status flow:
  new → extracted → scored → presented → approved/rejected → scripted → used

Episode status flow:
  draft → script_review → script_approved → tts_generating → audio_processing → audio_ready → published
```

---

## Phase 0: Prerequisites (Human Actions Required)

These MUST be done by a human before the pipeline can be fully built:

- [ ] **Step 0.1: Create Supabase project** — go to supabase.com, create free project, get URL + anon key + service role key
- [ ] **Step 0.2: Run schema SQL** — execute `docs/supabase-schema.sql` in Supabase SQL Editor
- [ ] **Step 0.3: Create Supabase credential in n8n** — Settings → Credentials → New → Supabase
- [ ] **Step 0.4: Create Fish Audio account** — fish.audio, get API key, create voice model from Brett sample
- [ ] **Step 0.5: Create Hume AI account** — hume.ai, get API key (backup TTS option)
- [ ] **Step 0.6: Create Auphonic account** — auphonic.com, get API key, create podcast preset
- [ ] **Step 0.7: Get Brett voice sample** — 1-3 minutes of clean speech for voice cloning
- [ ] **Step 0.8: Ensure ngrok is running** — `ngrok http 5678` for Telegram webhook support
- [ ] **Step 0.9: Restart n8n with WEBHOOK_URL** — `docker stop n8n && docker rm n8n && docker run -d --name n8n -p 5678:5678 -e N8N_SECURE_COOKIE=false -e WEBHOOK_URL=https://YOUR_NGROK_URL/ -v n8n_data:/home/node/.n8n n8nio/n8n`

---

## Phase 1: Foundation — Clean & Connect (Day 1-2)

### Task 1: Clean WF-01 (remove orphan nodes) ✅ DONE

**Files:** `n8n/workflows/wf-01-rss-score.json`

- [x] **Step 1:** Get current JSON: `./n8n/n8n-cli.sh json pW847d2oQEND8j8p > n8n/workflows/wf-01-rss-score.json`
- [x] **Step 2:** Python script to remove orphan nodes (RSS Read1, Basic LLM Chain1, OpenRouter Chat Model1)
- [x] **Step 3:** Push: `./n8n/n8n-cli.sh update pW847d2oQEND8j8p n8n/workflows/wf-01-rss-score.json`
- [x] **Step 4:** Verify: `./n8n/n8n-cli.sh get pW847d2oQEND8j8p` — expect 7 nodes

### Task 2: Create WF-00 Error Handler ✅ DONE

**Files:** `n8n/workflows/wf-00-error-handler.json`

- [x] **Step 1:** Write JSON (Error Trigger → Telegram alert with workflow name + error message)
- [x] **Step 2:** Create: `./n8n/n8n-cli.sh create n8n/workflows/wf-00-error-handler.json`
- [x] **Step 3:** Activate: `./n8n/n8n-cli.sh activate <ID>`

**Backlog features covered:** Infrastructure safety net

### Task 3: Set up Supabase (requires human for Step 0.1-0.3)

- [ ] **Step 1:** After human creates project, run `docs/supabase-schema.sql` in SQL Editor
- [ ] **Step 2:** Verify tables: feeds, articles, approval_decisions, episodes, episode_articles, distributions, voice_profiles, pipeline_runs
- [ ] **Step 3:** Import Hamid's 928 RSS feeds (or start with 50 for MVP)
- [ ] **Step 4:** Test from n8n: add a Supabase node in WF-01, verify connection

**Backlog features covered:** #1 Passive/Automated Ingestion (database layer)

---

## Phase 2: Source Intelligence (Day 2-4)

### Task 4: Rebuild WF-01 with Supabase + Multi-Feed

**Backlog features:** #1 Passive Ingestion, #4 Persona-Based Scoring, #5 Trend Detection, #6 Cross-Domain Synthesis

New flow:
```
Manual/Schedule Trigger
  → Supabase: get feeds WHERE batch_number = current_hour AND is_active = true
  → Loop Over Items (batch 5)
    → RSS Feed Read (URL from current feed)
    → Code: filter new articles (compare against last_item_date)
    → HTTP Request: Jina Reader (full text, with Continue on Fail)
    → Supabase: upsert articles (dedup by url_hash)
  → Supabase: update feed.last_polled_at
  → Basic LLM Chain: score articles (persona-based, returns JSON with score + category + reason)
  → Supabase: update articles with scores, set status = 'scored'
```

**LLM Scoring Prompt (covers features #4, #5, #6):**
```
Score this article for Brett Moore's podcast. Brett is an Australian entrepreneur who connects geopolitics, tech, science, and economics with sharp analysis.

Return ONLY valid JSON:
{
  "relevance": 1-10,
  "novelty": 1-10,
  "cross_domain": 1-10,
  "category": "geopolitics|science|tech|economics|culture",
  "reason": "one sentence",
  "connections": "any cross-domain angles"
}

Article: {{ $json.data.title }}
{{ $json.data.content }}
```

- [ ] **Step 1:** Write workflow JSON with all nodes
- [ ] **Step 2:** Push: `./n8n/n8n-cli.sh update pW847d2oQEND8j8p n8n/workflows/wf-01-rss-score.json`
- [ ] **Step 3:** Test with 5 feeds, verify articles in Supabase

### Task 5: Add Schedule Trigger (7 AM daily)

**Backlog feature:** #8 Morning Batch

- [ ] **Step 1:** Add Schedule Trigger node (cron `0 7 * * *`, timezone Europe/Madrid)
- [ ] **Step 2:** Both Manual and Schedule triggers connect to the same feed reader
- [ ] **Step 3:** Push and verify

---

## Phase 3: Brett Interaction (Day 4-6)

### Task 6: Rebuild WF-02 as Morning Curation Delivery

**Backlog features:** #7 Binary Swipe, #8 Morning Batch, #14 One-Tap Approve

New flow:
```
Schedule Trigger (7:05 AM, after WF-01 finishes)
  → Supabase: get articles WHERE status = 'scored' AND composite_score >= 7 AND discovered_at > yesterday
  → Loop Over Items
    → Telegram: send message with ✅ Include / ❌ Skip buttons
    → Supabase: update article status = 'presented'
```

- [ ] **Step 1:** Write workflow JSON
- [ ] **Step 2:** Create as new workflow (separate from current WF-02)
- [ ] **Step 3:** Activate with ngrok webhook URL

### Task 7: Rebuild WF-03 Approval Collector

**Backlog features:** #7 Binary Swipe, #14 One-Tap Approve

New flow:
```
Telegram Trigger (callback_query)
  → IF callback_data starts with "approve"
    → Supabase: update article status = 'approved'
    → Supabase: insert approval_decision
    → Telegram: reply "✅ Included"
    → Supabase: count articles WHERE status = 'approved' AND date = today
    → IF count >= 3
      → trigger WF-04 (script generation)
  → ELSE
    → Supabase: update article status = 'rejected'
    → Telegram: reply "❌ Skipped"
```

- [ ] **Step 1:** Write workflow JSON
- [ ] **Step 2:** Create: `./n8n/n8n-cli.sh create n8n/workflows/wf-03-approval.json`
- [ ] **Step 3:** Activate

### Task 8: Brett Link Forwarding

**Backlog feature:** #2 Brett's Active Sharing

New flow:
```
Telegram Trigger (message, not callback_query)
  → Code: extract URL from message text
  → IF has URL
    → HTTP Request: Jina Reader
    → Supabase: insert article (source_type = 'brett_forward', status = 'extracted')
    → Telegram: reply "Got it — queued for scoring"
  → ELSE
    → Telegram: reply "Send me a URL and I'll add it to the pipeline"
```

- [ ] **Step 1:** Write workflow JSON
- [ ] **Step 2:** Create and activate

---

## Phase 4: Script Engine (Day 6-8)

### Task 9: WF-04 Script Generator

**Backlog features:** #9 Full AI Draft, #10 Template-Based, #11 Word-for-Word Read-Ready, #12 Persona Lite, #13 Reference Library

New flow:
```
Webhook Trigger (called from WF-03 when 3+ approved) OR Manual Trigger
  → Supabase: get articles WHERE status = 'approved' AND date = today
  → Supabase: get voice_profiles WHERE is_active = true (Brett's style guide)
  → Code: aggregate articles + style guide into prompt context
  → Basic LLM Chain (stronger model: Claude Sonnet via OpenRouter)
    System: Brett's persona + style guide
    Prompt: episode structure template + today's approved articles
  → Supabase: insert episode (status = 'draft')
  → Supabase: insert episode_articles (link articles to episode)
  → Telegram: send script to Brett with [✅ Approve] [✏️ Edit] [❌ Reject] buttons
  → Supabase: update episode status = 'script_review'
```

**Script Generation Prompt (covers #9, #10, #11, #12):**
```
You are the scriptwriter for "Fasten Your Seatbelt" hosted by Brett Moore.

BRETT'S VOICE:
{{ $json.styleGuide }}

EPISODE STRUCTURE (follow exactly):
[HOOK - 20 seconds] Provocative question connecting today's stories
[STORY 1 - 2 minutes] Full narrative
[BRETT'S TAKE - 45 seconds] Analysis, what it really means
[STORY 2 - 2 minutes] Different domain, unexpected angle
[BRETT'S TAKE - 45 seconds] Cross-domain connection
[CLOSE - 20 seconds] Synthesize, leave with a question

RULES:
- Write every sentence as Brett would speak it
- No bullet points. Complete spoken sentences.
- Include [PAUSE] markers for dramatic effect
- End with "I'm Brett Moore, and that was Fasten Your Seatbelt."

TODAY'S APPROVED ARTICLES:
{{ $json.allArticles }}
```

- [ ] **Step 1:** Write workflow JSON
- [ ] **Step 2:** Create: `./n8n/n8n-cli.sh create n8n/workflows/wf-04-script.json`
- [ ] **Step 3:** Test with mock approved articles

---

## Phase 5: Audio Production (Day 8-10)

### Task 10: WF-05 Audio Production (MODULAR — swap TTS provider)

**Backlog features:** #15-21 (Recording), #22 Basic Cleanup, #25 Quality Scoring, #17 AI Voice Clone

**Architecture: TTS is a single swappable node.**

```
Webhook Trigger (called when Brett approves script) OR Manual
  → Supabase: get episode WHERE status = 'script_approved'
  → Code: prepare text for TTS (strip [PAUSE] → SSML breaks)

  → [TTS NODE - SWAPPABLE] ← This is the modular part
     Option A: Fish Audio
       POST https://api.fish.audio/v1/tts
       Body: {"text": "...", "reference_id": "BRETT_MODEL", "format": "mp3"}
       Response: binary audio

     Option B: Hume AI Octave
       POST https://dev.hume.ai/v0/tts
       Body: {"text": "...", "voice": "BRETT_CLONE_ID"}
       Response: binary audio

     Option C: ElevenLabs
       POST https://api.elevenlabs.io/v1/text-to-speech/{voice_id}
       Body: {"text": "...", "model_id": "eleven_multilingual_v2"}
       Response: binary audio

  → Supabase: upload audio to Storage (or external host)
  → Supabase: update episode audio_tts_url, status = 'tts_complete'

  → [AUDIO PROCESSOR - SWAPPABLE]
     Option A: Auphonic
       POST https://auphonic.com/api/simple/productions.json
       Form: preset + audio file + action=start
       Poll/webhook until done
       Download processed audio

     Option B: Cleanvoice (n8n community node)
       Create Edit → Watch Completions trigger

  → Supabase: update episode audio_processed_url, status = 'audio_ready'
  → Telegram: send audio to Brett with [✅ Publish] [❌ Redo] buttons
```

- [ ] **Step 1:** Write workflow JSON with Fish Audio as default TTS
- [ ] **Step 2:** Write alternative node configs for Hume AI and ElevenLabs (save as separate JSON snippets)
- [ ] **Step 3:** Create workflow, test with a sample script

### How to swap TTS providers:

```bash
# To switch from Fish Audio to Hume AI:
python3 -c "
import json
with open('n8n/workflows/wf-05-audio.json') as f: wf = json.load(f)
for node in wf['nodes']:
    if node['name'] == 'TTS Generate':
        node['parameters']['url'] = 'https://dev.hume.ai/v0/tts'
        node['parameters']['body'] = '{\"text\": \"={{ \$json.scriptText }}\", \"voice\": \"HUME_VOICE_ID\"}'
with open('n8n/workflows/wf-05-audio.json','w') as f: json.dump(wf,f)
"
./n8n/n8n-cli.sh update <WF05_ID> n8n/workflows/wf-05-audio.json
```

---

## Phase 6: Distribution (Day 10-12)

### Task 11: WF-06 Distribution

**Backlog features:** #30 Podcast RSS, #31 YouTube, #33 One-Size-Fits-All, #34 Automated Scheduling

New flow:
```
Webhook Trigger (called when Brett approves audio) OR Manual
  → Supabase: get episode WHERE status = 'audio_ready' (or 'publish_approved')

  → [PARALLEL BRANCHES]
    Branch 1: Podcast RSS
      → HTTP Request: upload to RSS.com (or generate RSS XML)
      → Supabase: insert distribution (platform = 'spotify')

    Branch 2: YouTube
      → YouTube Upload node (native n8n)
      → Supabase: insert distribution (platform = 'youtube')

    Branch 3: Social (optional)
      → Code: generate platform-adapted captions
      → LinkedIn post (native node)
      → X/Twitter post (native node)

  → Supabase: update episode status = 'published'
  → Telegram: "🎙️ Episode published! Spotify: [link] YouTube: [link]"
```

- [ ] **Step 1:** Write workflow JSON (start with podcast RSS only)
- [ ] **Step 2:** Add YouTube upload (requires OAuth credential — human action)
- [ ] **Step 3:** Add social media branches later

---

## Phase 7: Populate Style Guide + Test (Day 12-14)

### Task 12: Brett's Voice Profile in Supabase

**Backlog feature:** #13 Reference Library / Style Guide

- [ ] **Step 1:** Insert voice_profiles entries from Brett persona research:
  - Tone rules (conversational, warm, substantive, not academic)
  - Example phrases from meetings
  - Anti-patterns (never: bland AI narrator, clickbait, guesses as facts)
  - Topic preferences (geopolitics, science, tech, economics)
  - Closing patterns ("Here's what I'm watching next...", "The question this raises...")

### Task 13: End-to-End Integration Test

- [ ] **Step 1:** Run WF-01 (source & score) — verify articles in Supabase
- [ ] **Step 2:** Run WF-02 (morning curation) — verify Telegram messages with buttons
- [ ] **Step 3:** Tap ✅ on 3+ articles — verify WF-03 catches callbacks
- [ ] **Step 4:** Verify WF-04 generates script and sends to Telegram
- [ ] **Step 5:** Approve script — verify WF-05 generates audio
- [ ] **Step 6:** Approve audio — verify WF-06 publishes

---

## Phase 8: Codex Audit Fixes — Harden the Pipeline (Day 12-14)

> These tasks address the 5 high-severity issues found by the GPT-5.4 Codex audit.

### Task 16: Move secrets out of source code (Step 1 ✅ DONE)

**Codex finding:** n8n API key hardcoded in n8n-cli.sh, Jina token hardcoded in workflow JSONs.

- [x] **Step 1:** Update `n8n-cli.sh` to read API key from `.env` instead of hardcoding:
```bash
# Replace hardcoded key with:
N8N_API_KEY=$(grep N8N_API_KEY /Users/christiannikolov/Projects/radical-concepts-context/.env | cut -d= -f2)
```

- [ ] **Step 2:** Create a Jina Reader credential in n8n (HTTP Header Auth type) and update WF-01, WF-07, WF-08 to reference it instead of hardcoded headers

- [ ] **Step 3:** Add `n8n-cli.sh` and all workflow JSONs to `.gitignore` or strip secrets before committing

### Task 17: Wire context files into workflows — IN PROGRESS

**Codex finding:** Brett persona, scoring rubric, style guide exist as files but no workflow reads them.
**Status:** Agents currently fixing WF-01, WF-04, WF-09, WF-10, WF-11.

- [ ] **Step 1:** In WF-01 (scoring), add a Code node at the start that reads `n8n/context/scoring-rubric.md` and injects it into the scoring prompt's system message

- [ ] **Step 2:** In WF-04 (script generator), add a Code node that reads `n8n/context/brett-persona.md` + `n8n/context/style-guide.md` + `n8n/context/script-templates.md` and injects them into the script generation prompt

- [ ] **Step 3:** Update all LLM chain system messages to use `{{ $json.systemPrompt }}` from the Code node output instead of hardcoded text

- [ ] **Step 4:** Push updated workflows via CLI

**Note:** On n8n Cloud, Code nodes can't read local files. Alternative: paste context directly into system messages, or use Supabase to store the context and read via Supabase node.

### Task 18: Add Supabase nodes to core workflows

**Codex finding:** Zero Supabase nodes across all 12 workflows. No durable state.

**Prerequisite:** Supabase project created, schema deployed, credential added to n8n.

- [ ] **Step 1:** WF-01 — Add Supabase upsert after Jina extraction (save articles with status='extracted'), and after scoring (update with scores, status='scored')

- [ ] **Step 2:** WF-02 — Replace mock Code node with Supabase query: get articles WHERE status='scored' AND composite_score >= 7 AND discovered_at > 24h ago

- [ ] **Step 3:** WF-03 — Add Supabase update on approval: set article status='approved', insert into approval_decisions table

- [ ] **Step 4:** WF-04 — Replace mock Code node with Supabase query: get articles WHERE status='approved' AND date=today. After script generation, insert into episodes table.

- [ ] **Step 5:** WF-05 — Read episode WHERE status='script_approved', update with audio URLs after TTS

- [ ] **Step 6:** WF-06 — Read episode WHERE status='audio_ready', update status='published' after distribution

- [ ] **Step 7:** Push all updated workflows via CLI

### Task 19: Replace mock data with real sources

**Codex finding:** 8 of 12 workflows use mock/manual data.

- [ ] **Step 1:** WF-02 — reads from Supabase instead of mock (covered by Task 18)
- [ ] **Step 2:** WF-04 — reads from Supabase instead of mock (covered by Task 18)
- [ ] **Step 3:** WF-05 — reads from Supabase/WF-04 output instead of mock
- [ ] **Step 4:** WF-06 — reads from Supabase/WF-05 output instead of mock
- [ ] **Step 5:** WF-08 — replace mock email with IMAP Email Trigger (when email access is set up)
- [ ] **Step 6:** WF-09 — replace mock with Schedule Trigger + Supabase check (did Brett record today?)
- [ ] **Step 7:** WF-10 — accept real transcript from WF-05 audio output
- [ ] **Step 8:** WF-11 — accept real script from WF-04 output

### Task 20: Add durable handoffs between workflows

**Codex finding:** No coherent handoff from WF-01→02→03→04→05→06.

- [ ] **Step 1:** Define the status flow in Supabase:
```
Article: new → extracted → scored → presented → approved/rejected → scripted → used
Episode: draft → script_review → script_approved → tts_generating → audio_ready → published
```

- [ ] **Step 2:** Each workflow queries for items in ITS specific status and advances to the NEXT status

- [ ] **Step 3:** Add Execute Workflow nodes where synchronous handoff is needed (WF-03 triggers WF-04 when 3+ approved)

- [ ] **Step 4:** Test the full chain: create a test article in Supabase with status='new', run WF-01, verify it progresses through all statuses

---

## Phase 9: Polish & Demo Prep (Day 14-25)

### Task 14: Pre-generate 3 backup episodes

**For presentation contingency:**
1. Episode 1: "The Standard Run" — geopolitics story, full pipeline
2. Episode 2: "Cross-Domain Synthesis" — politics + science connection
3. Episode 3: "The Weekly Batch" — 3-4 stories in one 15-min episode

### Task 15: Presentation Materials

- [ ] **Step 1:** Record screen capture of successful pipeline run
- [ ] **Step 2:** Create demo-backup/ folder with all offline assets
- [ ] **Step 3:** Prepare slides (Kalina + Roxi)
- [ ] **Step 4:** Rehearse demo (Christian)

---

## Feature-to-Workflow Mapping (All 39 Features)

| Feature | Workflow | Status |
|---|---|---|
| #1 Passive/Automated Ingestion | WF-01 | Task 4 |
| #2 Brett's Active Sharing | WF-03 (Brett forward) | Task 8 |
| #3 Newsletter Forwarding | WF-03 (email variant) | Phase 2+ |
| #4 Persona-Based Scoring | WF-01 (scoring prompt) | Task 4 |
| #5 Trend/Novelty Detection | WF-01 (scoring prompt novelty dimension) | Task 4 |
| #6 Cross-Domain Synthesis | WF-01 (scoring prompt) + WF-04 (script prompt) | Task 4+9 |
| #7 Binary Swipe | WF-02 + WF-03 (Telegram buttons) | Task 6+7 |
| #8 Morning Batch | WF-02 (7 AM schedule) | Task 6 |
| #9 Full AI Draft | WF-04 (script generator) | Task 9 |
| #10 Template-Based Generation | WF-04 (structured prompt) | Task 9 |
| #11 Word-for-Word Read-Ready | WF-04 (prompt: "complete spoken sentences") | Task 9 |
| #12 Persona Lite (Prompt-Based) | WF-04 (style guide in system prompt) | Task 9 |
| #13 Reference Library | Supabase voice_profiles table | Task 12 |
| #14 One-Tap Approve | WF-03 (Telegram inline keyboard) | Task 7 |
| #15 100% Brett's Real Voice | WF-05 (recording path, not TTS) | Demo-only |
| #16 Content-Type Split | WF-05 (IF: politics→Brett records, science→TTS) | Phase 2+ |
| #17 AI Voice Clone | WF-05 (Fish Audio / Hume AI) | Task 10 |
| #18 Short Standalone Clips | WF-05 (segment-based TTS) | Task 10 |
| #19 Audio-Only | WF-05 (default — no video) | Task 10 |
| #20 Teleprompter/Script Display | External app (not n8n) | Demo-only |
| #21 One-Tap Recording Trigger | Telegram → recording link | Phase 2+ |
| #22 Basic Cleanup | WF-05 (Auphonic) | Task 10 |
| #23 Auto-Clipping | Whisper + Claude + FFmpeg | Phase 2+ |
| #24 Compilation/Best-Of | Weekly batch script from top clips | Phase 2+ |
| #25 Automated Quality Scoring | WF-05 (Auphonic quality report) | Task 10 |
| #26 Brett Final Approval Gate | WF-05 (Telegram approve before publish) | Task 10 |
| #27 No Approval (Full Auto) | WF-05 (skip approval IF, auto-publish) | Phase 2+ |
| #28 Fallback Content | WF-05 (auto-generate if Brett doesn't record) | Phase 2+ |
| #29 Brett on Camera | External (future) | Cut |
| #30 Podcast RSS | WF-06 (RSS.com upload) | Task 11 |
| #31 YouTube | WF-06 (native YouTube node) | Task 11 |
| #32 TikTok + Instagram | WF-06 (via Buffer) | Phase 2+ |
| #33 One-Size-Fits-All | WF-06 (same clip, all platforms) | Task 11 |
| #34 Automated Scheduling | WF-06 (Schedule Trigger) | Task 11 |
| #35 Platform-Optimized Timing | WF-06 (per-platform cron) | Phase 2+ |
| #36 Existing Automation Tools | Buffer/TubeBuddy integration | Phase 2+ |
| #37 Content Performance Metrics | Supabase distributions table | Phase 2+ |
| #38 Comment/Reply Management | Separate workflow | Phase 2+ |
| #39 Gamification | Future (12-18 months) | Cut |

**V0 coverage: 22 features built, 8 demo-only, 9 deferred to Phase 2+**

---

## Sprint Timeline (Updated 2026-03-20)

| Sprint | Dates | Phases | Key Deliverable |
|---|---|---|---|
| Sprint 2 (NOW) | Mar 20-23 | Phase 0-2 | All 12 workflows built ✅, context files done ✅, Codex audit done ✅. **REMAINING:** Supabase project setup, wire Supabase into workflows |
| Sprint 3 | Mar 24 - Apr 6 | Phase 3-6 | Connect workflows via Supabase, TTS integration (Fish Audio/Hume), end-to-end testing |
| Sprint 4 | Apr 7-13 | Phase 7-8 | Demo prep, 3 backup episodes, presentation rehearsal |
| **PRESENTATION** | **Apr 14** | | **Ship it** |

---

## Execution: Subagent-Driven Development

Each phase dispatches a fresh subagent per task. The subagent:
1. Reads the task from this plan
2. Reads the JSON reference at `n8n/n8n-workflow-json-reference.md`
3. Builds the workflow as a JSON file
4. Pushes via `n8n-cli.sh`
5. Tests and reports back

Start with: **Task 1 (clean WF-01) → Task 2 (error handler) → Task 3 (Supabase setup)**
