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
- `radical-concepts-modular-platform.html` — Platform architecture
- `i2p-brainstorming-board.html` — Design thinking process
- `radical-concepts-event-storming.html` — DDD pipeline flow

## Working Conventions
- Notion = living workspace (source of truth)
- This repo = HTML deliverables for Brett + session context (CLAUDE.md, event-storming-flow.md)

## Versioning
After any change to the HTML deliverables, create a GitHub release:
- **Patch** (x.x.1) — small fixes, copy tweaks, styling
- **Minor** (x.1.0) — new section, new page, significant content update
- **Major** (1.0.0) — new deliverable, major redesign, sprint milestone
Use `gh release create vX.Y.Z --title "..." --notes "..."`
