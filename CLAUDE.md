# Radical Concepts — AI Podcast Pipeline

## What This Is
Modular AI content platform for Brett Moore. Originally 3 separate concepts, now unified: shared foundation (source ingestion → AI curation → Brett's editorial gate) with three output paths (daily podcast, curiosity game, weekly deep dive). Sprint 2 focus: curation dashboard + podcast MVP.

## Client
**Brett Moore** — Australian entrepreneur in Barcelona. Law/business/tech background, 6 startups (MedTech). Passionate about politics, science, and journalism. Reads 2+ newspapers daily. Wants: "I read something interesting this morning" → "it's live on five platforms" in under an hour of his time.

**Brett's #1 concern:** Accuracy and trust. Red-teams everything 2-3 times. Has 7 pages of legal guidelines.

## Team
- **Chris (Kris)** — Technical lead. Data Science masters, Business Informatics. AI/ML, data pipelines, automation. 6 years corporate.
- **Hamid** — Business & operations. Import/export and logistics in Dubai/Spain. Market research.
- **Angelo** — Creative & production lead. Runs a creative studio. Video production, content formats.
- **Kalina** — Strategy & analysis. Bocconi + Deloitte M&A. Structured research, due diligence.
- **Roxy** — Marketing & product. BMW product management, Estée Lauder marketing. Social media, branding.

**Advisor:** Farid (ESADE mentor)

## Current Sprint
**Sprint 2** (Mar 10 – Mar 23): Build MVP. Modular platform architecture defined. Building curation dashboard prototype. Setting up podcast pipeline. Weekly Friday check-ins with Brett established.

## Modular Platform (Post-Pivot)
```
SHARED FOUNDATION (all paths):
📥 Sources (928 RSS feeds) → 🤖 AI Filter → 📝 Summarize → 🎭 Persona → 👆 Brett Picks

PATH A — Daily Podcast (C1, Sprint 2-3): Script → Record → Distribute ← GREEN
PATH B — Curiosity Game (C2, Phase 2): Quiz → Streaks → Share ← ORANGE
PATH C — Dinner Table Drop (C3, Phase 2): Mon/Wed/Fri → Spaced Repetition ← ORANGE
```

## Key Decisions (Active)
| Decision | Reasoning |
|---|---|
| **n8n self-hosted on Oracle Cloud Always Free** | $0 platform cost, no execution limits, visual builder for whole team. Make.com credit-limited, Zapier 3-min timeout, custom Python has bus factor risk. |
| **Jina Reader API for full-text extraction** | Free 10M tokens, HTTP GET from any platform, returns clean markdown. |
| **FigJam for mind mapping** | Team has education Figma accounts. Free and accessible. |
| **Audio-only for Sprint 1** | No video avatars. Mentor: "avatar is nothing without the audio." |
| **Quality-driven schedule** | Not fixed twice-a-week. Publish when material is good. |
| **TTS: Testing Fish Audio + ElevenLabs** | Angelo running side-by-side voice cloning tests. Fish Audio = best cost/quality, ElevenLabs = quality benchmark. |
| **Modular platform over 3 separate concepts** | Farid recommendation after Meeting #8. Brett's concept is core, team innovations are expansion modules. Reduces scope, respects client's vision. |
| **Product Backlog added** | Features DB (5 modules) + Tasks DB. Sprint Board for daily execution, Product Backlog for product vision. |
| **Hume AI evaluation** | Farid recommended. Comparing against ElevenLabs and Fish Audio for voice quality. |

## Tool Stack
- **Orchestration:** n8n (self-hosted, Oracle Cloud Always Free: 4 vCPU, 24GB RAM)
- **Full-text extraction:** Jina Reader API (free 10M tokens)
- **AI processing:** Claude Haiku (filtering, cheap) + Claude Sonnet (summarization/scripts, quality)
- **TTS:** Fish Audio ($11/mo) or ElevenLabs ($5-11/mo) — testing in progress
- **Dev methodology:** Compound Engineering plugin (Every.to) — brainstorm/plan/review/compound loop
- **Project management:** Notion (Sprint Board + Knowledge Base + Decision Log)
- **Mind mapping:** FigJam (edu Figma accounts)

## Pipeline Design (from Meeting #2 whiteboards)
```
CONTENT PIPELINE (Sprint 1 focus):
📥 Gather → ✅ Validate → 📄 Extract Text → 🤖 AI Filter ("Is this Brett-worthy?")
→ 📝 Summarize → 🎭 Persona Transform → 👆 Brett Picks → ✍️ Script → ✅ Approved

PRODUCTION PIPELINE (Sprint 2+):
🎙️ Voice Clone → 🤖 AI Generate → ⚡ Combine → 🎬 Demo → 👀 Brett Review
→ 📤 Auto-Upload → 📱 Distribute → 📊 Analytics
```

## Three Shows
| Show | Topic | Approach |
|---|---|---|
| Politics | Current affairs, geopolitics | Brett hosts. Synthesis + analysis with personal overlay. |
| Science | Evolution, deep ocean, animal behavior | Brett's voice. More curiosity, less opinion. |
| Quirky | Human interest stories | Hardest to automate. Serendipitous stories. |

**Episode format:** Multi-topic, 5-7 min, 3 topics with section markers. Each section becomes a standalone clip.

## Budget
~€200 total for 2 months. n8n and Jina Reader are free. Budget goes to AI APIs (~€30-60) and TTS (~€20-60). Buffer: €50-120.

## Notion Workspace (use MCP to access)
- Project Hub: https://www.notion.so/3104d347036281189f3bc8d70bcbfd69
- Sprint Board: https://www.notion.so/9b827c7dadeb4114be1722bbdc9350d0
- Knowledge Base: https://www.notion.so/869e4a58c7e44df1b6234fdc8b6047bb
- Decision Log: https://www.notion.so/95c98cc886ec448ba1d34be313cf32f3
- Pipeline Diagrams: https://www.notion.so/3124d347036281dd9a8ef8087432f63b
- Brett Kickoff Brief: https://www.notion.so/3104d34703628156ab96f5e23700217d
- Product Backlog: https://www.notion.so/8304d347036283f7981b819cf684f990
- Deliverables: https://www.notion.so/1d95fcfd9f6d416c81898f48e7c627ef

## Brett-Facing Deliverables (HTML)
All in /deliverables/ and repo root:
- deliverables/index.html — Project hub (Brett's entry point)
- radical-concepts-all-pitches.html — 3 concept pitches (Deliverable #1)
- i2p-brainstorming-board.html — Design thinking process
- radical-concepts-modular-platform.html — Modular platform architecture

## Context Files
See `/context/` for distilled reference material:
- `pipeline-design.md` — Full pipeline with Mermaid diagrams + open questions
- `tool-stack.md` — All tool decisions with reasoning
- `brett-profile.md` — Client profile, preferences, concerns, content vision
- `team.md` — Team profiles and strengths

See `/learnings/` for compounded knowledge from past Claude sessions.

## Working Conventions
- Notion is the living workspace (source of truth for tasks, research, meetings)
- This repo is the distilled context snapshot for Claude sessions
- Update context files after major decisions or research completions
- `/workflows:compound` output goes in `/learnings/`
