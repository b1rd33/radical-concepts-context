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
%% C3 Branch      (gold)    — Dinner Table Drop path
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
        GENCLIPS["Generate Clips"]

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

        DEC_SCHED{"Schedule: fixed<br/>or quality-driven?"}
        DEC_CLIP{"Video: 30s<br/>or 60s clips?"}
        DEC_CAP{"Captions: auto<br/>or styled?"}

        PUBLISH --> RSS_OUT
        PUBLISH --> YOUTUBE
        PUBLISH --> SOCIAL
        PUBLISH --> PUBLISHED --> ANALYTICS --> INSIGHTS
        DEC_SCHED -.- PUBLISH
        DEC_CLIP -.- YOUTUBE
        DEC_CAP -.- SOCIAL
    end

    %% ═══════════════════════════════════════════════
    %% CROSS-LANE CONNECTIONS
    %% ═══════════════════════════════════════════════
    GENSUMMARY --> SUMMARIZED
    APPROVED --> GENCLIPS
    GENCLIPS --> PUBLISH
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
    classDef event fill:#FED7AA,stroke:#EA580C,color:#9A3412,stroke-width:2px
    classDef command fill:#BFDBFE,stroke:#2563EB,color:#1E3A8A,stroke-width:2px
    classDef readmodel fill:#BBF7D0,stroke:#16A34A,color:#14532D,stroke-width:2px
    classDef policy fill:#E9D5FF,stroke:#9333EA,color:#581C87,stroke-width:2px
    classDef aggregate fill:#FEF08A,stroke:#CA8A04,color:#713F12,stroke-width:2px
    classDef hotspot fill:#FECACA,stroke:#DC2626,stroke-dasharray:5 5,color:#991B1B,stroke-width:2px
    classDef external fill:#E5E7EB,stroke:#6B7280,color:#374151,stroke-width:2px
    classDef gate fill:#BFDBFE,stroke:#4682B4,stroke-width:4px,color:#1E3A5F
    classDef c2branch fill:#FECDD3,stroke:#E11D48,color:#881337,stroke-width:2px
    classDef c3branch fill:#FDE68A,stroke:#B45309,color:#78350F,stroke-width:2px
    classDef decision fill:#FEF3C7,stroke:#F59E0B,color:#92400E,stroke-width:2px

    %% ═══════════════════════════════════════════════
    %% STYLE ASSIGNMENTS
    %% ═══════════════════════════════════════════════

    %% Events (orange)
    class INGESTED,VALIDATED,SCORED,SELECTED,SUMMARIZED,SCRIPTREADY,ASSEMBLED,APPROVED,PUBLISHED,INSIGHTS event

    %% Commands (blue)
    class INGEST,SCORE,GENSUMMARY,FORMATSCRIPT,VOICE,GENCLIPS,PUBLISH command

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

    %% Decisions (amber diamond)
    class DEC_SCHED,DEC_CLIP,DEC_CAP decision
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
| **Decision** | Amber (diamond) | Open architectural or product decision |
| **C2 Branch** | Coral | Curiosity Game expansion path (future) |
| **C3 Branch** | Gold | Dinner Table Drop expansion path (future) |
