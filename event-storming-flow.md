# Radical Concepts -- Event Storming Flow

Full architecture flow from source to audience. Domain-Driven Design notation with every event, command, policy, and decision point across three pipeline lanes.

```mermaid
%% ──────────────────────────────────────────────────
%% LEGEND
%% ──────────────────────────────────────────────────
%% Domain Event   (orange)  — Something that happened
%% Command        (blue)    — An action triggered
%% Read Model     (green)   — A queryable view of data
%% Policy         (purple)  — Automated rule / process
%% Aggregate      (yellow)  — Domain entity cluster
%% Hotspot        (red dash)— Open question / risk
%% External       (grey)    — External system
%% Human Gate     (steel)   — Brett's manual approval
%% C2 Branch      (coral)   — Curiosity Game path
%% C3 Branch      (gold)    — Weekly Deep Dive path
%% ──────────────────────────────────────────────────

flowchart TD

    %% ═══════════════════════════════════════════════
    %% LANE 1 — CONTENT PIPELINE (Curation)
    %% ═══════════════════════════════════════════════
    subgraph L1["Content Pipeline"]
        direction TB

        RSS["RSS Feeds & APIs"]
        INGEST["Ingest Sources"]
        INGESTED["Sources Ingested"]
        VALIDATE(["Auto-Validate & Dedup"])
        VALIDATED["Content Validated"]
        SCORE["Score with Persona"]
        SCORED["Content Scored"]
        GATE1["Brett's Gate 1\nTopic Selection & Curation"]
        SELECTED["Topics Selected"]
        GENSUMMARY["Generate Summary"]

        CORPUS["Validated Corpus"]
        RANKED["Ranked Feed"]
        PERSONA["Persona Profile"]

        HS_TASTE["How do we encode\nBrett's taste?"]
        HS_DASH["Dashboard or\nWhatsApp?"]

        RSS --> INGEST --> INGESTED --> VALIDATE --> VALIDATED --> SCORE
        SCORE --> SCORED --> GATE1 --> SELECTED --> GENSUMMARY

        VALIDATED --> CORPUS
        SCORE --> PERSONA
        SCORED --> RANKED

        HS_TASTE -.- SCORE
        HS_DASH -.- GATE1
    end

    %% ═══════════════════════════════════════════════
    %% LANE 2 — PRODUCTION PIPELINE
    %% ═══════════════════════════════════════════════
    subgraph L2["Production Pipeline"]
        direction TB

        SUMMARIZED["Summary Generated"]
        FORMATSCRIPT["Format Script"]
        SCRIPTREADY["Script Ready"]
        VOICE["Record / Clone Voice"]
        ASSEMBLE(["Auto-Assemble Episode"])
        ASSEMBLED["Episode Assembled"]
        GATE2["Brett's Gate 2\nFinal Production Review"]
        APPROVED["Episode Approved"]

        C3_SNIPPET["C3: Generate Snippets"]
        C2_QUIZ["C2: Generate Quiz"]

        PREVIEW["Episode Preview"]

        HS_VOICE["Brett records or\nAI clone?"]

        SUMMARIZED --> FORMATSCRIPT --> SCRIPTREADY --> VOICE --> ASSEMBLE --> ASSEMBLED --> GATE2 --> APPROVED

        SUMMARIZED --> C3_SNIPPET
        SCRIPTREADY --> C2_QUIZ

        ASSEMBLED --> PREVIEW

        HS_VOICE -.- VOICE
    end

    %% ═══════════════════════════════════════════════
    %% LANE 3 — DISTRIBUTION & INTELLIGENCE
    %% ═══════════════════════════════════════════════
    subgraph L3["Distribution & Intelligence"]
        direction TB

        PUBLISH["Publish to Platforms"]
        RSS_OUT["Podcast RSS"]
        YOUTUBE["YouTube"]
        SOCIAL["Social Platforms"]
        PUBLISHED["Content Published"]
        ANALYTICS(["Track Analytics"])
        INSIGHTS["Insights Generated"]

        C2_FUTURE["C2: Quiz Engagement"]
        C3_FUTURE["C3: Knowledge Cards"]

        PUBLISH --> RSS_OUT
        PUBLISH --> YOUTUBE
        PUBLISH --> SOCIAL
        PUBLISH --> PUBLISHED --> ANALYTICS --> INSIGHTS
    end

    %% ═══════════════════════════════════════════════
    %% CROSS-LANE CONNECTIONS
    %% ═══════════════════════════════════════════════
    GENSUMMARY --> SUMMARIZED
    APPROVED --> PUBLISH
    C2_QUIZ -.-> C2_FUTURE
    C3_SNIPPET -.-> C3_FUTURE

    %% ═══════════════════════════════════════════════
    %% FEEDBACK LOOPS
    %% ═══════════════════════════════════════════════
    INSIGHTS -.->|refine sources| RSS
    INSIGHTS -.->|refine persona| PERSONA

    %% ═══════════════════════════════════════════════
    %% STYLE DEFINITIONS
    %% ═══════════════════════════════════════════════
    classDef event fill:rgba(249,115,22,0.2),stroke:#F97316,color:#F97316
    classDef command fill:rgba(59,130,246,0.15),stroke:#3B82F6,color:#3B82F6
    classDef readmodel fill:rgba(34,197,94,0.15),stroke:#22C55E,color:#22C55E
    classDef policy fill:rgba(168,85,247,0.15),stroke:#A855F7,color:#A855F7
    classDef aggregate fill:rgba(234,179,8,0.15),stroke:#EAB308,color:#EAB308
    classDef hotspot fill:rgba(239,68,68,0.1),stroke:#EF4444,stroke-dasharray:5 5,color:#EF4444
    classDef external fill:rgba(107,114,128,0.15),stroke:#6B7280,color:#6B7280
    classDef gate fill:rgba(70,130,180,0.12),stroke:#4682B4,stroke-width:3px,color:#4682B4
    classDef c2branch fill:rgba(255,107,107,0.1),stroke:#FF6B6B,color:#FF6B6B
    classDef c3branch fill:rgba(201,169,110,0.1),stroke:#C9A96E,color:#C9A96E

    %% ═══════════════════════════════════════════════
    %% STYLE ASSIGNMENTS
    %% ═══════════════════════════════════════════════

    %% Events (orange)
    class INGESTED,VALIDATED,SCORED,SELECTED,SUMMARIZED,SCRIPTREADY,ASSEMBLED,APPROVED,PUBLISHED,INSIGHTS event

    %% Commands (blue)
    class INGEST,SCORE,GENSUMMARY,FORMATSCRIPT,VOICE,PUBLISH command

    %% Read Models (green)
    class CORPUS,RANKED,PREVIEW readmodel

    %% Policies (purple)
    class VALIDATE,ASSEMBLE,ANALYTICS policy

    %% Aggregates (yellow)
    class PERSONA aggregate

    %% Hotspots (red dashed)
    class HS_TASTE,HS_DASH,HS_VOICE hotspot

    %% External Systems (grey)
    class RSS,RSS_OUT,YOUTUBE,SOCIAL external

    %% Human Gates (steel blue, thick border)
    class GATE1,GATE2 gate

    %% C2 Branches (coral)
    class C2_QUIZ,C2_FUTURE c2branch

    %% C3 Branches (gold)
    class C3_SNIPPET,C3_FUTURE c3branch
```

## Node Type Legend

| Type | Color | Description |
|------|-------|-------------|
| **Domain Event** | Orange | Something that happened in the system |
| **Command** | Blue | An action triggered by a user or policy |
| **Read Model** | Green | A queryable view or projection of data |
| **Policy** | Purple | Automated rule or process (no human input) |
| **Aggregate** | Yellow | Domain entity cluster that enforces invariants |
| **Hotspot** | Red (dashed) | Open question, risk, or unresolved decision |
| **External System** | Grey | System outside the domain boundary |
| **Human Gate** | Steel Blue (thick) | Brett's manual approval checkpoint |
| **C2 Branch** | Coral | Curiosity Game expansion path (future) |
| **C3 Branch** | Gold | Weekly Deep Dive expansion path (future) |
