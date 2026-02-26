# Pipeline Design — Radical Concepts

Source: [Pipeline Workflow — Whiteboard Diagrams (Meeting #2)](https://www.notion.so/3124d347036281dd9a8ef8087432f63b)

## Content Pipeline (Sprint 1 Focus)

```mermaid
flowchart TD
    A["📥 1. GATHER MATERIAL\nSource Collection: News / Science / General\n+ Manual Additions from Brett"] --> B["✅ 2. VALIDATE SOURCES\nAccuracy & Reliability"]
    B --> C["📄 3. EXTRACT TEXT\nJina Reader API (free 10M tokens)\nRSS = metadata only, need full text"]
    C --> D["🤖 4. AI CHOOSING CRITERIA\n'Is this what Brett would talk about?'\nClaude Haiku (cheap model for yes/no)"]
    D --> E["📝 5. AI SUMMARIZES\nBy News / By Topics\nClaude Sonnet (quality matters)\nAccuracy verification step"]
    E --> F["🎭 6. ENGAGING OUTPUT\nBrett's Persona / Voice Profile\nPriority: High / Medium / Low"]
    F --> G["👆 7. BRETT CHOOSES\nSelects core topics\nApproval via Notion/Sheet"]
    G --> H["✍️ 8. AI SCRIPT WRITING\nClaude Sonnet\nText script → Brett approval"]
    H --> I["✅ SCRIPT APPROVED → TO PRODUCTION"]
```

## Production Pipeline (Sprint 2+)

```mermaid
flowchart TD
    J["🎙️ INPUTS\nAI-Approved Script\nOR Voice Over"] --> K["🤖 AI GENERATES\nAudio: voice clone (Fish Audio / ElevenLabs)\nVideo: avatar/stock footage (Sprint 3)\nImaging: backgrounds"]
    K --> L["⚡ SYNERGY\nCombine all elements\n📱 Format: 9:16"]
    L --> M["🎬 DEMO VIDEO\nMultiple variations OR iterative?"]
    M --> N["👀 REVIEW PROCESS\nBrett reviews"]
    N --> O["📤 AUTO-UPLOAD"]
    O --> P["📱 DISTRIBUTION\nInstagram Reels | YT Shorts | TikTok"]
    P --> Q["📊 POST-PRODUCTION\nCommunity Mgmt | Engagement | Analytics"]
```

## n8n Implementation Plan (Sprint 1)

| Pipeline Step | Tool/Service | n8n Node |
|---|---|---|
| RSS Ingestion | RSS protocol | RSS Feed Trigger (built-in) |
| Full-Text Extraction | Jina Reader API | HTTP Request (`GET r.jina.ai/{url}`) |
| AI Filtering | Claude Haiku / GPT-4o-mini | Anthropic/OpenAI node |
| AI Summarization | Claude Sonnet / GPT-4o | Anthropic/OpenAI node |
| Persona Transform | Claude Sonnet / GPT-4o | Anthropic/OpenAI node |
| Brett Approval | Notion or Google Sheet | Webhook / manual trigger |
| Script Generation | Claude Sonnet / GPT-4o | Anthropic/OpenAI node |

## Open Questions

- [ ] Can RSS access paid sources (FT, NYT)? → Check ESADE library Factiva/LexisNexis API
- [ ] Is AI reliable for topic selection? Hallucination risk?
- [ ] What if it's quiet and no news on a topic?
- [ ] Multiple video variations upfront OR iterative feedback loop?
- [ ] Brett records vs AI voice for each content stream?
- [ ] Copyright implications of summarizing paywalled articles for podcast?
