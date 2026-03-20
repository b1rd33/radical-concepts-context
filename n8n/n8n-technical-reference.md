# n8n Pipeline — Consolidated Technical Reference

**Compiled from:** n8n Build Guide (8 research agents), n8n Workflow JSON Reference (md+json), Modular Architecture Analysis.
**Last updated:** 2026-03-20.

---

## 1. Architecture Overview

### 7 Modular Workflows

| # | Workflow | Purpose | Trigger |
|---|----------|---------|---------|
| 1 | Orchestrator | Coordinates full pipeline daily | Schedule (6-7 AM) + Manual |
| 2 | Source Collection | RSS ingestion + full-text extraction | Called by Orchestrator |
| 3 | Summarize + Script | AI scoring, summarization, script generation | Called by Orchestrator |
| 4 | Approval | Brett reviews via Telegram/Form | Called by Orchestrator (Wait node) |
| 5 | Audio | TTS generation + audio cleanup | Called by Orchestrator |
| 6 | Distribute | Publish to YouTube, podcast RSS, social | Called by Orchestrator |
| 7 | Error Handler | Catch failures, alert via Slack/Telegram | Error Trigger (shared) |

Workflows communicate via **Execute Sub-workflow** node. Supabase is the single source of truth for pipeline state.

### Module Grouping (V0 Scope — 7 Weeks)

Per Codex review and Farid's directives, collapse to 4 systems for V0:

1. **Editorial Intake** = Source Intelligence + Editorial Control (Workflows 1-2 + part of 4)
2. **Content Factory** = Script & Text Engine + Media Production (Workflows 3 + 5)
3. **Publishing** = thin adapter, 1-2 channels max (Workflow 6)
4. **Telemetry** = lightweight analytics folded in (part of Workflow 7)

Promote to full 8-module architecture after V0 validated.

---

## 2. Infrastructure

### Oracle Cloud Always Free

- **Instance:** ARM A1.Flex — 4 OCPU, 24 GB RAM, 200 GB storage, EUR 0/month
- **Image:** Ubuntu 22.04 Minimal aarch64
- **Critical:** Upgrade to PAYG immediately (avoids capacity errors + idle reclamation). Set EUR 1 budget alert.
- **Capacity errors:** Use `oci-arm-host-capacity` GitHub script (auto-retries)
- **Networking:** Open ports 80/443 in OCI Security Lists AND OS iptables. Do NOT use UFW on OCI.
- **Fallback:** Railway (EUR 5-15/mo) or Hetzner CAX11 (EUR 3.29/mo)

### Docker Stack (docker-compose.yml)

4 containers:

| Container | Role | Notes |
|-----------|------|-------|
| n8n (pinned, e.g. 2.13.0) | Pipeline orchestration | Port 5678 (localhost only) |
| PostgreSQL 16 | Persistent data backend | NOT SQLite |
| Caddy 2 | Reverse proxy + auto-HTTPS | Let's Encrypt |
| n8n-runner | External task runner | Code node isolation |

### Critical Environment Variables

```env
DB_TYPE=postgresdb                          # NOT "postgres" — #1 misconfiguration
N8N_ENCRYPTION_KEY=<openssl rand -hex 32>   # Back up separately
GENERIC_TIMEZONE=Europe/Madrid
WEBHOOK_URL=https://n8n.yourdomain.com/
N8N_DEFAULT_BINARY_DATA_MODE=filesystem     # Prevents memory crashes with audio
N8N_CONCURRENCY_PRODUCTION_LIMIT=20
EXECUTIONS_TIMEOUT=3600                     # 1 hour safety net
```

### Backup Strategy

Daily cron at 3 AM: pg_dump + n8n data volume tar + config files. Store in OCI Object Storage (20 GB free).

---

## 3. n8n Workflow JSON Structure

### API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `POST` | `/api/v1/workflows` | Create workflow |
| `GET` | `/api/v1/workflows/{id}` | Get workflow |
| `PUT` | `/api/v1/workflows/{id}` | Update workflow (full replace) |
| `PATCH` | `/api/v1/workflows/{id}` | Activate: `{"active": true}` |
| `GET` | `/api/v1/credentials` | List credentials (get IDs) |

### Workflow Envelope

```json
{
  "name": "My Workflow",
  "nodes": [],
  "connections": {},
  "settings": {
    "executionOrder": "v1"
  }
}
```

Extra fields in exports/responses: `id`, `active`, `tags`, `pinData`, `versionId`, `meta`, `staticData`.

### Node Object Shape

```json
{
  "id": "uuid-string",
  "name": "Node Name",
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.2,
  "position": [420, 300],
  "parameters": {},
  "credentials": {}
}
```

- `name` must be unique — `connections` reference nodes by name, not ID
- Optional flags: `disabled`, `alwaysOutputData`, `continueOnFail`, `notes`, `notesInFlow`, `webhookId`

### Connection Patterns

**Linear (A -> B):**
```json
{
  "Node A": {
    "main": [[{ "node": "Node B", "type": "main", "index": 0 }]]
  }
}
```

**IF branching (output[0]=true, output[1]=false):**
```json
{
  "IF": {
    "main": [
      [{ "node": "True Handler", "type": "main", "index": 0 }],
      [{ "node": "False Handler", "type": "main", "index": 0 }]
    ]
  }
}
```

**AI sub-node (model -> chain via ai_languageModel):**
```json
{
  "OpenRouter Chat Model": {
    "ai_languageModel": [
      [{ "node": "Basic LLM Chain", "type": "ai_languageModel", "index": 0 }]
    ]
  }
}
```

**Split In Batches loop (output[0]=batch body, output[1]=done):**
```json
{
  "Split In Batches": {
    "main": [
      [{ "node": "Process Batch", "type": "main", "index": 0 }],
      [{ "node": "Done", "type": "main", "index": 0 }]
    ]
  },
  "Process Batch": {
    "main": [[{ "node": "Split In Batches", "type": "main", "index": 0 }]]
  }
}
```

**Fan-out (one node -> multiple downstream):**
```json
{
  "Trigger": {
    "main": [
      [
        { "node": "Node B", "type": "main", "index": 0 },
        { "node": "Node C", "type": "main", "index": 0 }
      ]
    ]
  }
}
```

### Credential References

```json
{
  "credentials": {
    "<credentialType>": {
      "id": "<credential-id>",
      "name": "<credential-name>"
    }
  }
}
```

Common credential types:

| Service | Credential Type Key |
|---------|-------------------|
| Supabase | `supabaseApi` |
| Telegram | `telegramApi` |
| OpenRouter | `openRouterApi` |
| HTTP Header Auth | `httpHeaderAuth` |
| HTTP Basic Auth | `httpBasicAuth` |

### Expression Reference

| Pattern | Example |
|---------|---------|
| Current item field | `={{ $json.fieldName }}` |
| Specific node's output | `={{ $('Node Name').item.json.fieldName }}` |
| All items from node | `={{ $('Node Name').all() }}` |
| First item from node | `={{ $('Node Name').first().json.fieldName }}` |
| Conditional | `={{ $json.value ? 'yes' : 'no' }}` |
| JSON stringify | `={{ JSON.stringify($json) }}` |
| Current timestamp | `={{ DateTime.now().toISO() }}` |
| Env variable | `={{ $env.MY_VAR }}` |

---

## 4. Node Type Reference (All Verified JSON Structures)

### 4.1 Schedule Trigger

```json
{
  "type": "n8n-nodes-base.scheduleTrigger",
  "typeVersion": 1.2,
  "parameters": {
    "rule": {
      "interval": [
        { "field": "cronExpression", "expression": "0 7 * * *" }
      ]
    }
  }
}
```

Alternative (every N hours):
```json
{
  "parameters": {
    "rule": {
      "interval": [
        { "field": "hours", "hoursInterval": 1, "triggerAtMinute": 0 }
      ]
    }
  }
}
```

### 4.2 Supabase

**Credential type:** `supabaseApi`

**Get all rows:**
```json
{
  "type": "n8n-nodes-base.supabase",
  "typeVersion": 1,
  "parameters": {
    "operation": "getAll",
    "tableId": "feeds",
    "returnAll": false,
    "limit": 50,
    "filters": {
      "conditions": [
        { "keyName": "batch_number", "condition": "eq", "keyValue": "1" }
      ]
    }
  },
  "credentials": { "supabaseApi": { "id": "cred-id", "name": "Supabase account" } }
}
```

**Create row:**
```json
{
  "parameters": {
    "operation": "create",
    "tableId": "articles",
    "fieldsToSend": "defineBelow",
    "fieldValues": {
      "values": [
        { "fieldName": "guid", "fieldValue": "={{ $json.guid }}" },
        { "fieldName": "title", "fieldValue": "={{ $json.title }}" },
        { "fieldName": "full_text", "fieldValue": "={{ $json.full_text }}" }
      ]
    }
  }
}
```

**Update row:**
```json
{
  "parameters": {
    "operation": "update",
    "tableId": "feeds",
    "filterType": "string",
    "filterString": "id=eq.{{ $json.id }}",
    "fieldsToSend": "defineBelow",
    "fieldValues": {
      "values": [
        { "fieldName": "last_polled_at", "fieldValue": "={{ DateTime.now().toISO() }}" }
      ]
    }
  }
}
```

**Delete row:**
```json
{
  "parameters": {
    "operation": "delete",
    "tableId": "my_table",
    "filters": {
      "conditions": [
        { "keyName": "id", "condition": "eq", "keyValue": "={{ $json.id }}" }
      ]
    }
  }
}
```

### 4.3 HTTP Request

**GET with headers (typeVersion 4.2):**
```json
{
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.2,
  "parameters": {
    "method": "GET",
    "url": "https://r.jina.ai/{{ $json.article_url }}",
    "sendHeaders": true,
    "headerParameters": {
      "parameters": [
        { "name": "Authorization", "value": "Bearer {{ $env.JINA_API_KEY }}" },
        { "name": "Accept", "value": "application/json" },
        { "name": "X-Remove-Images", "value": "true" }
      ]
    },
    "options": { "timeout": 15000 }
  }
}
```

**POST with JSON body:**
```json
{
  "parameters": {
    "method": "POST",
    "url": "https://api.anthropic.com/v1/messages",
    "sendHeaders": true,
    "headerParameters": {
      "parameters": [
        { "name": "x-api-key", "value": "{{ $env.ANTHROPIC_API_KEY }}" },
        { "name": "anthropic-version", "value": "2023-06-01" },
        { "name": "Content-Type", "value": "application/json" }
      ]
    },
    "sendBody": true,
    "specifyBody": "json",
    "jsonBody": "={{ JSON.stringify({ model: 'claude-3-5-haiku-20241022', max_tokens: 1024, messages: [{ role: 'user', content: $json.prompt }] }) }}",
    "options": {}
  }
}
```

**Binary file download:**
```json
{
  "parameters": {
    "method": "GET",
    "url": "={{ $json.file_url }}",
    "options": {
      "response": {
        "response": {
          "responseFormat": "file",
          "outputPropertyName": "data"
        }
      }
    }
  }
}
```

**With predefined credential auth:**
```json
{
  "parameters": {
    "method": "GET",
    "url": "https://api.example.com/protected",
    "authentication": "predefinedCredentialType",
    "nodeCredentialType": "httpHeaderAuth",
    "options": {}
  },
  "credentials": {
    "httpHeaderAuth": { "id": "auth-cred-id", "name": "My API Key" }
  }
}
```

### 4.4 Code Node (JavaScript)

```json
{
  "type": "n8n-nodes-base.code",
  "typeVersion": 2,
  "parameters": {
    "mode": "runOnceForAllItems",
    "language": "javaScript",
    "jsCode": "const items = $input.all();\nconst results = [];\nfor (const item of items) {\n  results.push({ json: { ...item.json, processed: true } });\n}\nreturn results;"
  }
}
```

Modes: `runOnceForAllItems` (default) | `runOnceForEachItem`
Languages: `javaScript` | `pythonNative` (v2+)

### 4.5 IF Node

```json
{
  "type": "n8n-nodes-base.if",
  "typeVersion": 2.2,
  "parameters": {
    "conditions": {
      "options": {
        "caseSensitive": true,
        "leftValue": "",
        "typeValidation": "strict",
        "version": 2
      },
      "conditions": [
        {
          "id": "condition-uuid",
          "leftValue": "={{ $json.score }}",
          "rightValue": 7,
          "operator": { "type": "number", "operation": "gte" }
        }
      ],
      "combinator": "and"
    },
    "options": {}
  }
}
```

**Operators:**
- **string:** equals, notEquals, contains, notContains, startsWith, endsWith, regex, isEmpty, isNotEmpty
- **number:** equals, notEquals, gt, gte, lt, lte, isEmpty, isNotEmpty
- **boolean:** true, false, isEmpty, isNotEmpty
- **dateTime:** after, before, equals

### 4.6 Split In Batches (Loop Over Items)

```json
{
  "type": "n8n-nodes-base.splitInBatches",
  "typeVersion": 3,
  "parameters": {
    "batchSize": 10,
    "options": { "reset": false }
  }
}
```

Output[0] = batch items (loop body). Output[1] = done (all processed).
Loop back from end of batch processing to this node's input.

### 4.7 Telegram Trigger

```json
{
  "type": "n8n-nodes-base.telegramTrigger",
  "typeVersion": 1.2,
  "webhookId": "unique-webhook-id",
  "parameters": {
    "updates": ["message", "callback_query"],
    "additionalFields": {}
  },
  "credentials": { "telegramApi": { "id": "tg-cred-id", "name": "Bot" } }
}
```

### 4.8 Telegram Send Message (with Inline Keyboard)

```json
{
  "type": "n8n-nodes-base.telegram",
  "typeVersion": 1.2,
  "parameters": {
    "operation": "sendMessage",
    "chatId": "={{ $json.message.chat.id }}",
    "text": "Choose an option:",
    "replyMarkup": "inlineKeyboard",
    "inlineKeyboard": {
      "rows": [
        {
          "row": {
            "buttons": [
              { "text": "Approve", "additionalFields": { "callback_data": "approve" } },
              { "text": "Reject", "additionalFields": { "callback_data": "reject" } }
            ]
          }
        }
      ]
    },
    "additionalFields": { "parse_mode": "HTML" }
  },
  "credentials": { "telegramApi": { "id": "tg-cred-id", "name": "Bot" } }
}
```

**Dynamic JSON keyboard (typeVersion 1.2+):**
```json
{
  "parameters": {
    "operation": "sendMessage",
    "chatId": "={{ $json.chat_id }}",
    "text": "Select:",
    "replyMarkup": "inlineKeyboard",
    "specifyKeyboard": "json",
    "inlineKeyboardJson": "={{ JSON.stringify($json.keyboard_rows) }}"
  }
}
```

**Answer callback query:**
```json
{
  "parameters": {
    "operation": "answerQuery",
    "queryId": "={{ $json.callback_query.id }}",
    "additionalFields": { "text": "Processing...", "show_alert": false }
  }
}
```

### 4.9 Basic LLM Chain

```json
{
  "type": "@n8n/n8n-nodes-langchain.chainLlm",
  "typeVersion": 1.6,
  "parameters": {
    "promptType": "define",
    "text": "={{ $json.user_message }}",
    "messages": {
      "messageValues": [
        { "message": "You are a helpful assistant." }
      ]
    },
    "hasOutputParser": false
  }
}
```

With output parser enabled: set `"hasOutputParser": true` and connect a structured output parser sub-node via `ai_outputParser` connection type.

Connect a chat model sub-node via `ai_languageModel` connection.

### 4.10 OpenRouter Chat Model (Sub-node)

```json
{
  "type": "@n8n/n8n-nodes-langchain.lmChatOpenRouter",
  "typeVersion": 1,
  "parameters": {
    "model": "anthropic/claude-sonnet-4",
    "options": {
      "temperature": 0.7,
      "maxTokens": 4096
    }
  },
  "credentials": { "openRouterApi": { "id": "or-cred-id", "name": "OpenRouter" } }
}
```

---

## 5. Service Integration Patterns

### 5.1 RSS Ingestion (928 Feeds)

**Architecture:** 10 batch-polling workflows, ~93 feeds each. Schedule Trigger every 30 min, staggered by 3 min.

**Flow per workflow:**
```
Schedule Trigger -> Supabase: get feeds WHERE batch_number=N
  -> Loop Over Items (1 feed at a time)
    -> RSS Feed Read (URL from current item)
    -> Code: filter items newer than feed.last_item_date
    -> Supabase: check existing GUIDs (dedup)
    -> IF: has content:encoded?
      YES -> Use RSS content directly (skip Jina)
      NO  -> HTTP Request: Jina Reader
    -> Supabase: upsert article
    -> Supabase: update feed.last_polled_at
```

**Key settings:** HTTP timeout 15s per feed. "Continue on fail" per node. `N8N_CONCURRENCY_PRODUCTION_LIMIT=10`.

### 5.2 Jina Reader (Full-Text Extraction)

- **Endpoint:** `GET https://r.jina.ai/{article_url}`
- **Headers:** `Authorization: Bearer {KEY}` (500 RPM), `Accept: application/json`, `X-Remove-Images: true`
- **Cost:** ~free (10M welcome tokens = ~25 days at 200 articles/day)
- **Latency:** ~7.9s average
- **Optimization:** Check RSS `content:encoded` first — saves 30-60% of API calls

**Backup:** Trafilatura microservice (20-line FastAPI wrapper in Docker, free, unlimited, F1 ~95%)

### 5.3 Anthropic API (Direct HTTP, for Prompt Caching + Batch)

n8n's native AI nodes don't expose prompt caching or batch API. Use HTTP Request node directly.

**Prompt caching (90% savings on cached inputs):**
```json
{
  "model": "claude-3-5-haiku-20241022",
  "max_tokens": 1024,
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "<persona_spec>...</persona_spec>",
          "cache_control": { "type": "ephemeral" }
        },
        {
          "type": "text",
          "text": "Score this article: {{ $json.full_text }}"
        }
      ]
    }
  ]
}
```

**Batch API (50% discount):**
- Submit: `POST https://api.anthropic.com/v1/messages/batches`
- Poll: `GET https://api.anthropic.com/v1/messages/batches/{batch_id}`

### 5.4 AI Processing Chain (3 Stages)

| Stage | Model | Cost/Day | Node Type | Details |
|-------|-------|----------|-----------|---------|
| 1. Score/Filter | Claude Haiku | ~$0.24 (100 articles) | Information Extractor or HTTP Request | Schema: `{score, category, one_line_summary}`. Temp: 0.0. Keep score >= 7 |
| 2. Summarize | Claude Sonnet | ~$0.30 (20 articles) | Basic LLM Chain or HTTP Request | 150 words max per article |
| 3. Script Gen | Claude Sonnet | ~$0.08 (1 script) | Basic LLM Chain or HTTP Request | Cross-domain synthesis, episode structure |

**Total AI cost: ~$0.68/day = $10-20/month**

**Episode structure for script prompt:**
1. HOOK (15-30s) — provocative question or fact
2. STORY 1 (2-3 min) — narrative
3. HOST TAKE (30-60s) — analysis
4. STORY 2 (2-3 min) — different domain
5. HOST TAKE (30-60s) — cross-domain connections
6. CLOSE (30-60s) — synthesize, leave with a question

### 5.5 Telegram Bot (Brett Interaction)

**Setup:** @BotFather -> `/newbot` -> get token -> paste in n8n Telegram credential. n8n must be publicly accessible via HTTPS.

**Morning curation (7 AM):**
- Schedule Trigger -> collect scored articles -> format as Telegram message -> Send and Wait for Response (Approval type)
- Timeout: auto-skip after 2 hours

**Article link ingestion:**
- Brett sends URL to bot -> Telegram Trigger -> extract URL -> Jina Reader -> feed into pipeline

**Script approval:**
- Wait node (On Form Submitted) -> generates unique URL -> send URL via Telegram
- Timeout: 24h -> reminder -> 12h more -> auto-approve with flag

### 5.6 Fish Audio (TTS / Voice Cloning)

- **Cost:** $11/mo (200 min) — covers daily episodes
- **Clone quality:** #1 on TTS-Arena (S1 model)
- **Min training data:** 15 sec (instant), 1-3 min (HQ)
- **Integration:** HTTP Request to Fish Audio API
- **Batch API available**

**Alternatives:**
| Service | Cost | Min Data | n8n Integration |
|---------|------|----------|-----------------|
| Hume Octave | $3-14/mo | 15 sec | HTTP Request |
| ElevenLabs | $5-22/mo | 1 min (instant) | Official n8n node |
| Qwen3-TTS | Free (GPU) | ~10 sec | Self-hosted API |

### 5.7 Auphonic (Audio Cleanup)

- **Cost:** Free 2 hrs/mo (= ~4 episodes), $13/9hrs
- **Integration:** HTTP Request (REST API)
- **Features:** Noise removal, leveling, filler word removal

### 5.8 Distribution Platforms

| Platform | n8n Node | Notes |
|----------|----------|-------|
| YouTube | Native YouTube node | 10K quota/day = ~6 uploads. Shorts: vertical < 60s + #Shorts |
| LinkedIn | Native LinkedIn node | Text + image only. Video requires HTTP Request to Video Upload API |
| X/Twitter | Native X node | Free tier: 1,500 tweets/mo. Media upload via separate HTTP call |
| Instagram Reels | Facebook Graph API node | 3-step process. Video must be at public URL first |
| Podcast RSS | HTTP Request | RSS.com free tier. One-time manual submission to Spotify + Apple |

**Not automatable:** WhatsApp Channels (no API), TikTok (approval takes weeks — use Buffer), TubeBuddy (browser extension only).

**Buffer as middleware:** $6/channel/mo, REST API, single call posts to multiple platforms. No native n8n node — use HTTP Request.

---

## 6. Supabase Schema

### feeds table

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | PK |
| url | text | Feed URL (unique) |
| batch_number | int | 1-10 for batch-polling assignment |
| last_polled_at | timestamptz | Last successful poll |
| last_item_date | timestamptz | Newest item date seen (for incremental) |
| status | text | active/paused/error |
| error_count | int | Consecutive failures |

### articles table

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | PK |
| guid | text | RSS GUID (unique, dedup key) |
| feed_url | text | FK to feeds |
| title | text | |
| link | text | Article URL (unique) |
| published_at | timestamptz | |
| summary | text | RSS summary |
| full_text | text | Extracted full text |
| categories | text[] | RSS categories |
| score | int | AI relevance score (1-10) |
| category | text | AI-assigned category |
| one_line_summary | text | AI one-liner |
| status | text | new/scored/approved/scripted/published |

---

## 7. Architecture Patterns

### Error Handling (3 Layers)

1. **Error Workflow (shared):** Error Trigger -> format message -> Slack alert + Supabase log
2. **Retry on Fail:** per node, 3 retries, 5s wait (for flaky APIs)
3. **Continue on Fail:** per node, for non-critical steps (one bad article shouldn't stop everything)

### Human-in-the-Loop

- **Wait node (On Form Submitted):** generates unique URL, pauses workflow
- **Limit Wait Time:** 24 hours, then timeout path (reminder or auto-approve)
- **Telegram Send and Wait:** native Approve/Decline buttons, built-in timeout

### Data Flow

- **Loop Over Items:** batch size 1-3 for rate-limited APIs (AI, TTS)
- **Merge node:** combine parallel branches (Append, Combine, SQL Query modes)
- **Switch node:** route articles by category to different prompts
- **Edit Fields (Set):** reshape data between pipeline stages

### Sub-workflow Communication

Workflows call each other via **Execute Sub-workflow** node. Pass data as input items. Each sub-workflow has its own error handling.

### Performance Settings

```env
N8N_CONCURRENCY_PRODUCTION_LIMIT=20
EXECUTIONS_TIMEOUT=3600
```

Data pruning: default 14 days, 10K executions. Start with regular mode (queue mode only if hitting concurrency limits).

---

## 8. Complete Pipeline Flow: RSS to Distribution

```
[6-7 AM Schedule Trigger]
  |
  v
[Orchestrator Workflow]
  |
  +--> [Source Collection Sub-workflow]
  |      |
  |      +---> Supabase: get feeds WHERE batch_number=N
  |      +---> Loop: RSS Feed Read per feed
  |      +---> Code: filter new items (> last_item_date)
  |      +---> Supabase: dedup check on GUID
  |      +---> IF content:encoded exists?
  |      |       YES --> use directly
  |      |       NO  --> HTTP: Jina Reader extraction
  |      +---> Supabase: upsert article
  |      +---> Supabase: update feed.last_polled_at
  |
  +--> [Summarize + Script Sub-workflow]
  |      |
  |      +---> Supabase: get new articles
  |      +---> Loop: Claude Haiku score each (temp 0.0)
  |      +---> IF score >= 7: keep
  |      +---> Loop: Claude Sonnet summarize top 20
  |      +---> Code: collect summaries, pick top stories
  |      +---> Claude Sonnet: generate episode script
  |      +---> Supabase: save script + scored articles
  |
  +--> [Approval Sub-workflow]
  |      |
  |      +---> Telegram: send scored articles to Brett (7 AM)
  |      +---> Telegram Send and Wait: Approve/Skip per story
  |      +---> Wait node (Form): script review
  |      +---> Timeout: 24h -> reminder -> 12h -> auto-approve
  |      +---> Supabase: update article statuses
  |
  +--> [Audio Sub-workflow]
  |      |
  |      +---> HTTP: Fish Audio TTS (approved script)
  |      +---> HTTP: Auphonic audio cleanup
  |      +---> Code: format metadata
  |      +---> Supabase: store audio file reference
  |
  +--> [Distribute Sub-workflow]
  |      |
  |      +---> YouTube: upload episode + metadata
  |      +---> HTTP: RSS.com podcast feed update
  |      +---> X: post announcement
  |      +---> LinkedIn: post announcement
  |      +---> Supabase: mark as published
  |
  +--> [Error Handler (shared)]
         |
         +---> Error Trigger
         +---> Code: format error details
         +---> Telegram: alert to team
         +---> Supabase: log error
```

---

## 9. Tool Stack & Monthly Budget

| Tool | Purpose | Monthly Cost |
|------|---------|-------------|
| n8n (self-hosted) | Pipeline orchestration | EUR 0 |
| Oracle Cloud | Hosting (4 OCPU, 24 GB RAM) | EUR 0 |
| Supabase (free tier) | Article DB + state management | EUR 0 |
| Jina Reader | Full-text extraction | ~EUR 0-5 |
| Claude API (Haiku + Sonnet) | Scoring, summarization, scripts | ~EUR 10-20 |
| Fish Audio Plus | Voice cloning + TTS | EUR 11 |
| Auphonic | Audio cleanup | EUR 0-13 |
| Telegram Bot | Brett interaction + approvals | EUR 0 |
| RSS.com (free tier) | Podcast hosting | EUR 0 |
| YouTube/LinkedIn/X APIs | Distribution | EUR 0 |
| **TOTAL** | | **EUR 21-49/month** |

EUR 200 total budget for 2-month project. Leaves EUR 102-158 as buffer.

---

## 10. Programmatic Workflow Generation Rules

1. Generate stable UUIDs for node IDs (e.g., `crypto.randomUUID()`)
2. Keep `name` unique and deterministic — `connections` uses names, not IDs
3. Always set exact `typeVersion` matching the `parameters` structure
4. Create credentials first via n8n API/UI, then inject credential references into node JSON
5. For AI nodes and Telegram inline keyboards, export one UI-created node from your target n8n version as the golden template for version-sensitive nested fields
6. For updates, prefer read-modify-write: GET existing workflow, modify, PUT back
7. After PUT, activate with `PATCH /api/v1/workflows/{id}` body: `{"active": true}`
8. Space nodes ~200px apart horizontally in position arrays
9. Trigger nodes with webhooks need a unique `webhookId` string

---

## 11. Architectural Decisions (From Modular Architecture Analysis)

### Resolved

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Telegram vs WhatsApp | **Telegram** | Free, native inline keyboards, 22 n8n actions, 5-min setup. WhatsApp has no native buttons, requires template approval, costs per message |
| AI Agent vs Basic LLM Chain | **Basic LLM Chain** | Single prompt -> response. Deterministic. Cheaper. Agent adds overhead + unpredictability |
| DB backend | **Supabase** (not Google Sheets) | Production reliability. Sheets only if team needs visual access |
| Voice strategy | Configurable per content type | Politics = always Brett's real voice. Science/quirky = open to AI clone |

### Open (Need Resolution)

| Decision | Options | Notes |
|----------|---------|-------|
| Domain name for n8n | TBD | Needed for Caddy HTTPS |
| TTS provider final choice | Fish Audio vs Hume vs ElevenLabs | Test all 3 with 15-sec Brett sample |
| Starting feed count | 50 for MVP, 928 for full | Suggest 50 for Sprint 2, scale in Sprint 3 |

### V0 Persona Engine ("Persona Lite")

Per Codex review — do NOT build a full queryable persona service for V0. Instead:

- Versioned persona spec (tone, values, banned patterns, preferred framing)
- Reusable prompt blocks + rubric scoring (voice fit, factuality, clarity)
- A simple `persona_score` per generated draft
- Promote to real service only after enough feedback data

### Missing Concerns (Submodules, Not Standalone)

Per Codex review, add these as submodules within existing workflows:

- **Provenance & Trust** — source traceability, citation storage, factual confidence flags
- **Orchestration & Reliability** — retries, idempotency, queue/job visibility
- **Content Asset Registry** — versioning of scripts/audio/quiz variants and approvals
