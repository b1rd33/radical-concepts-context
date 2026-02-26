# Tool Stack — Radical Concepts

Source: [Automation Platform Comparison KB](https://www.notion.so/3134d34703628179a5e0ec2035533fd1)

## Orchestration: n8n (self-hosted)
- **What:** Open-source workflow automation with visual builder
- **Hosting:** Oracle Cloud Always Free Tier (4 vCPU, 24GB RAM, 200GB — free forever)
- **Why:** $0 platform cost, unlimited executions, no timeout limits, visual for whole team, native AI nodes (LangChain), native Jina node
- **Alternatives rejected:** Make.com (credit-limited $10.59/mo), Zapier (3-min timeout $29.99/mo), custom Python (bus factor risk)

## Full-Text Extraction: Jina Reader API
- **How:** `GET https://r.jina.ai/{article_url}` → returns clean Markdown
- **Free tier:** 10M tokens (thousands of articles)
- **Why:** Simplest option, works from any platform via HTTP GET
- **Limitation:** Does not bypass paywalls or render JavaScript

## AI Processing: Claude API
- **Filtering:** Claude Haiku or GPT-4o-mini (cheap, yes/no task)
- **Summarization + Scripts:** Claude Sonnet or GPT-4o (quality-critical)
- **Budget:** ~€30-60 for 2 months at ~10 articles/day

## TTS (Testing — Sprint 1)
- **Fish Audio:** $11/mo, ~15 sec min sample, unified API, best cost/quality ratio
- **ElevenLabs:** $5-11/mo, ~1 min min sample (Instant), top-tier quality
- **Qwen3-TTS:** Free (open source), ~3 sec min sample, requires self-hosting
- **Status:** Angelo running side-by-side tests. Results TBD.
- Source: [Audio Generations Platform KB](https://www.notion.so/3134d347036280579472ca8887bd17cf)

## Dev Methodology: Compound Engineering
- **Plugin:** Every.to Compound Engineering (29 agents, 13 slash commands)
- **Key workflows:** `/workflows:brainstorm` → `/workflows:plan` → `/workflows:compound`
- **Why:** 4-step loop (Plan → Work → Review → Compound) creates a learning loop
- Source: [Farid's Recommended Tools KB](https://www.notion.so/3124d347036281d5abb3edb1ca63d549)

## Project Management: Notion
- Sprint Board, Knowledge Base, Decision Log, Meeting Notes
- MCP integration for Claude access during sessions

## Mind Mapping: FigJam
- Team has education Figma accounts (free)
- Replaced MindNode recommendation from advisor

## Paywall Strategy
1. Start with free sources (BBC, Reuters, AP, Guardian, tech blogs)
2. Check ESADE library for Factiva/LexisNexis API access
3. Check if Brett's subscriptions offer full-text RSS
4. Add paywalled sources incrementally
