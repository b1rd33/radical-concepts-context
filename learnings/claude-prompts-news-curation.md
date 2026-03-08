# AI News Curation Pipeline: Best Practices Guide

## Claude API for Automated Podcast Production

**Target**: ~928 RSS feeds -> Haiku filters -> Sonnet summarizes -> Sonnet scripts
**Budget**: ~EUR 30-60 over 2 months
**Models**: Claude Haiku 4.5 (filtering), Claude Sonnet 4.5 or 4.6 (summarization + scripting)

---

## 1. Architecture Overview

```
RSS Feeds (~928)
    |
    v
[Article Ingestion] -- truncate to ~800 tokens each
    |
    v
[Stage 1: Haiku Filter] -- "Would Brett cover this?" -> yes/no + score
    |  ~50-100 articles/day pass
    v
[Stage 2: Sonnet Summarize] -- 10 selected articles -> Brett-voice summaries
    |
    v
[Stage 3: Sonnet Script] -- 3 best topics -> podcast script (5-7 min)
    |
    v
[TTS / Human Review]
```

---

## 2. Filtering: Stage 1 (Haiku)

### Binary vs. Scored: Use a Hybrid Approach

Pure binary (yes/no) is cheaper but loses nuance. Pure numeric (1-10) is unreliable -- LLMs are not well-calibrated scorers and struggle to distinguish a 6 from a 7. The best approach for this pipeline is a **tiered classification with 3-4 buckets**:

- **MUST_COVER**: Breaking news or core topic Brett would definitely discuss
- **STRONG**: Clearly relevant, good fit for the show
- **MAYBE**: Tangentially relevant or interesting angle
- **SKIP**: Not relevant

This gives you a reliable relevance signal without asking the model to produce false precision. In practice you filter on MUST_COVER + STRONG, and dip into MAYBE when you need more content.

### Why Not Pure Binary?

Binary works if your daily volume after filtering is predictable. But with 928 feeds, some days you might get 200 "yes" results and need to pick the best 10. The tiered approach gives you that ranking without a separate scoring pass.

### System Prompt for Filtering

```
You are a news relevance classifier for "The Brett Show," a daily tech/business podcast.

<brett_profile>
{{BRETT_PERSONA}}
</brett_profile>

<task>
Classify whether Brett would cover this article on his show. Respond with EXACTLY one of: MUST_COVER, STRONG, MAYBE, SKIP.

Then provide a single sentence explaining why.
</task>

<classification_rules>
- MUST_COVER: Directly hits Brett's core topics (AI policy, startup funding rounds, big tech antitrust, open source drama). Breaking news he cannot ignore.
- STRONG: Clearly relevant to his audience. He would have an opinion. Good for a segment.
- MAYBE: Tangentially related. Could work as a "quick hits" mention or if paired with a stronger story.
- SKIP: Outside his beat entirely, or too niche/local/old.
</classification_rules>

<edge_cases>
- Opinion pieces: Classify based on the TOPIC, not the author's take. Brett forms his own opinions.
- Press releases / product launches: SKIP unless it is a major platform (>10M users) or directly impacts his audience.
- Evergreen / explainer content: SKIP. Brett covers news, not tutorials.
- Paywalled content: Classify based on the headline and available excerpt. Note if content is paywalled.
</edge_cases>

<output_format>
CLASSIFICATION: [MUST_COVER|STRONG|MAYBE|SKIP]
REASON: [one sentence]
</output_format>
```

### Few-Shot Examples for Filtering

Include 4-6 examples directly in the system prompt to anchor the model's calibration. This is more effective than long instructions for classification tasks.

```xml
<examples>
<example>
<article>
<title>EU passes AI Act enforcement guidelines, mandating transparency for foundation models</title>
<source>TechCrunch</source>
<excerpt>The European Commission released binding enforcement guidelines for the AI Act today, requiring all foundation model providers to publish training data summaries and red-team reports by Q3 2026...</excerpt>
</article>
<classification>MUST_COVER</classification>
<reason>Core AI policy topic with direct impact on the companies Brett covers daily.</reason>
</example>

<example>
<article>
<title>Best standing desks for 2026: our top picks</title>
<source>The Verge</source>
<excerpt>We tested 15 standing desks over 3 months to find the best options for your home office...</excerpt>
</article>
<classification>SKIP</classification>
<reason>Product review / buying guide, not news and outside Brett's beat.</reason>
</example>

<example>
<article>
<title>Stripe acquires AI billing startup for $200M</title>
<source>Bloomberg</source>
<excerpt>Stripe has agreed to acquire BillBot, a startup using AI to automate invoice reconciliation, in a deal valued at approximately $200 million...</excerpt>
</article>
<classification>STRONG</classification>
<reason>Significant fintech acquisition with AI angle, fits Brett's startup/funding coverage.</reason>
</example>

<example>
<article>
<title>How one farmer is using drones to monitor crop health in Iowa</title>
<source>Des Moines Register</source>
<excerpt>Local farmer Jim Henderson has been experimenting with consumer drones to check on his 400-acre corn operation...</excerpt>
</article>
<classification>SKIP</classification>
<reason>Local interest story, too niche and outside tech/business scope.</reason>
</example>
</examples>
```

### Input Optimization for Filtering

**Truncate articles before sending.** For a yes/no relevance decision, the model does not need the full article. Send:

- Title (always)
- Source name (always)
- First 500-800 tokens of the article body (or the RSS excerpt)
- Publication date

This keeps input to roughly **900-1,100 tokens per article** including the system prompt overhead (which you cache).

---

## 3. Summarization: Stage 2 (Sonnet)

### Direct Summarization vs. Chain-of-Thought

For news summarization, **direct summarization with grounding instructions** outperforms chain-of-thought. CoT adds tokens without meaningfully improving factual accuracy on straightforward news articles. CoT is useful when the source material is ambiguous or contradictory -- which is rare for news articles from reputable outlets.

Reserve CoT for the script generation stage where creative decisions benefit from explicit reasoning.

### Persona Injection Without Hallucinated Opinions

The critical risk: Claude will happily fabricate opinions Brett never expressed. The solution is to separate **voice/style** (which the model can emulate) from **positions/opinions** (which it must not invent).

```
You are a news summarizer writing for "The Brett Show" podcast. Your job is to summarize articles in Brett's voice and style, but you must NOT fabricate opinions, predictions, or reactions that Brett has not expressed.

<brett_voice>
{{BRETT_VOICE_GUIDE}}
</brett_voice>

<task>
Summarize the following article for podcast use. Write 150-250 words.
</task>

<rules>
- Write in Brett's conversational style: direct, slightly irreverent, uses analogies from everyday life.
- State FACTS from the article. Do not add analysis or predictions unless they come directly from a source quoted in the article.
- Where Brett would naturally react (surprise, skepticism, excitement), use HEDGED framing:
  - "This is the kind of move that raises eyebrows" (observation, not opinion)
  - "You have to wonder whether..." (invites thought, does not assert)
  - "The numbers here are wild" (reaction to facts, not fabricated stance)
- Do NOT write: "Brett thinks...", "I believe...", "This is clearly good/bad..."
- Preserve key numbers, names, dates, and direct quotes from the article.
- End with a 1-sentence "so what" that frames why the audience should care, grounded in the article's facts.
</rules>

<accuracy_requirements>
- Every claim must trace back to the source article. If you cannot find it in the article, do not include it.
- Preserve attribution: "according to [source]", "the company said", "[Person] told [Publication]".
- If the article contains conflicting claims, present both sides.
- Flag if the article relies heavily on anonymous sources or unverified claims.
</accuracy_requirements>

<article>
{{ARTICLE_FULL_TEXT}}
</article>
```

### Citation Preservation Pattern

Add this to the summarization prompt when accuracy is paramount:

```xml
<citation_format>
When referencing specific data points, use inline attribution:
- "[Company] reported [metric]" -- not just "[metric] happened"
- "According to [Publication], ..." -- when the claim is not independently verified
- Direct quotes: keep them short and attributed

At the end of the summary, include:
SOURCE: [article title] | [publication] | [date]
</citation_format>
```

---

## 4. Script Generation: Stage 3 (Sonnet)

### Multi-Topic Episode Structure

The script prompt should enforce a consistent structure that downstream TTS or human hosts can follow reliably.

```
You are a podcast script writer for "The Brett Show," a daily 5-7 minute tech news podcast.

<brett_voice>
{{BRETT_VOICE_GUIDE}}
</brett_voice>

<episode_structure>
The episode has exactly this structure:

[COLD_OPEN] -- 15-20 seconds
A punchy hook from the strongest story. One or two sentences that make the listener want to stay.
No "welcome to the show" -- jump straight into the hook.

[INTRO] -- 10-15 seconds
"Hey, it's Brett. [Day of week] edition. Three stories today: [one-line teaser for each]."

[TOPIC_1] -- 90-120 seconds
The lead story. The one from the cold open. Full treatment.
End with a clear takeaway or provocative question.

[TRANSITION_1] -- 5-10 seconds
A bridging sentence. Can be thematic ("Speaking of companies making big moves...") or contrastive ("On a completely different note...").

[TOPIC_2] -- 60-90 seconds
Second story. Slightly shorter. Keep momentum.

[TRANSITION_2] -- 5-10 seconds

[TOPIC_3] -- 60-90 seconds
Third story. Can be lighter, more speculative, or a "quick take."

[OUTRO] -- 15-20 seconds
Brief wrap. Can callback to the cold open. "That's it for [day]. See you tomorrow."
No long recaps. No calls to action longer than one sentence.
</episode_structure>

<writing_rules>
- Write for the EAR, not the eye. Short sentences. Conversational rhythm.
- Use contractions: "it's", "they've", "wouldn't".
- Avoid jargon unless Brett would naturally use it (and then explain it briefly).
- Include [PAUSE] markers where Brett would naturally take a breath or let something land.
- Include [EMPHASIS] markers on words Brett would stress.
- Do NOT include sound effect cues or music notes unless specifically asked.
- Total word count: 800-1,100 words (targets 5-7 minutes at conversational pace).
</writing_rules>

<red_team_check>
Before finalizing the script, verify:
1. Every factual claim traces to one of the source summaries below.
2. No opinions are attributed to Brett that were not in the summaries.
3. No company or person is characterized in a way not supported by the sources.
4. Numbers and names are accurate.
If any check fails, revise that section before outputting the final script.
</red_team_check>

<source_summaries>
{{SUMMARY_1}}
---
{{SUMMARY_2}}
---
{{SUMMARY_3}}
</source_summaries>
```

### Transition Patterns

Give the model a small library of transition styles to rotate through, preventing repetitive episode structure:

```xml
<transition_styles>
Use varied transitions between topics. Rotate through styles -- do not use the same style twice in one episode:
- Thematic link: "And speaking of [shared theme]..."
- Contrast: "Now, completely different energy here..."
- Callback: "Remember when we talked about [related past topic]? Well..."
- Geographic: "Meanwhile, over in [location]..."
- Temporal: "And just this morning..."
- Rhetorical: "So what happens when [topic 2 theme]?"
</transition_styles>
```

---

## 5. Persona Profile Structure

The persona document is referenced by both the summarization and script prompts via the `{{BRETT_VOICE_GUIDE}}` and `{{BRETT_PERSONA}}` variables. Structure it as follows:

```xml
<persona>
<identity>
Name: Brett [Last Name]
Show: The Brett Show (daily, 5-7 min, tech/business news)
Audience: Tech professionals, startup founders, investors, curious generalists
Years active: [X] years in tech media
</identity>

<topics_of_interest>
<!-- Ranked by priority. The filter uses this to classify. -->
<tier_1>AI/ML policy and regulation, major funding rounds (Series B+), big tech antitrust and competition, open source ecosystem drama, developer tools and platforms</tier_1>
<tier_2>Crypto/web3 (only major regulatory or market moves), cybersecurity breaches (major ones), social media platform changes, hardware launches (Apple, NVIDIA, major players)</tier_2>
<tier_3>Space tech, climate tech, biotech -- only when there is a clear business/tech angle</tier_3>
<not_covered>Consumer product reviews, lifestyle, local news, sports, entertainment industry, partisan political commentary</not_covered>
</topics_of_interest>

<communication_style>
- Direct and confident, but not arrogant
- Uses everyday analogies ("That's like telling your landlord you're renovating while the building's on fire")
- Slightly irreverent -- will call out corporate BS but stays professional
- Explains complex topics without being condescending
- Favors short declarative sentences, then occasionally a longer one for rhythm
- Uses rhetorical questions to engage: "So what does this actually mean for you?"
- Comfortable with silence / pauses for emphasis
</communication_style>

<intellectual_approach>
- Red-teams everything: considers "what if this goes wrong?" and "who benefits?"
- Skeptical of hype cycles but not cynical -- genuinely excited about real breakthroughs
- Follows the money: always asks who is funding this, what the business model is
- Historical context: often references past tech cycles for perspective
- Does NOT: take partisan political sides, make investment recommendations, predict stock prices
</intellectual_approach>

<phrases_and_patterns>
<!-- Real phrases Brett uses, to anchor the model's voice -->
- "Here's the thing..."
- "Let's unpack this."
- "The quiet part out loud: ..."
- "Follow the money on this one."
- "This is a 'watch this space' situation."
- "[X] is doing [X] because [real reason], not because [stated reason]."
</phrases_and_patterns>

<absolute_boundaries>
- Never fabricate a position Brett has not publicly stated
- Never make investment or financial advice
- Never speculate about individuals' personal lives
- Never present rumors as facts
- When uncertain, frame as a question, not a statement
</absolute_boundaries>
</persona>
```

### How to Build This Persona Document

1. Collect 10-20 real podcast transcripts or writings from Brett
2. Extract recurring phrases, sentence structures, and topic preferences
3. Note what Brett explicitly avoids or disclaims
4. Keep the document under 1,500 tokens -- it will be cached and included in every request

---

## 6. Cost Optimization

### Current Pricing (March 2026, USD)

| Model | Input (per MTok) | Output (per MTok) | Batch Input | Batch Output |
|-------|------------------|--------------------|-------------|--------------|
| Haiku 4.5 | $1.00 | $5.00 | $0.50 | $2.50 |
| Sonnet 4.5/4.6 | $3.00 | $15.00 | $1.50 | $7.50 |

**Prompt caching** (critical for this pipeline):
- 5-min cache write: 1.25x base input price
- Cache hit (read): 0.1x base input price
- A cache hit on Haiku costs $0.10/MTok instead of $1.00/MTok

### Daily Cost Estimate

**Assumptions:**
- 100 articles/day pass initial RSS dedup (from 928 feeds, many overlap)
- System prompt for filtering: ~800 tokens (cached)
- Article input per filter call: ~1,000 tokens
- Filter output: ~30 tokens
- 10 articles selected for summarization
- Full article for summarization: ~2,500 tokens
- Summary output: ~350 tokens
- 3 summaries fed to script generation
- Script output: ~1,200 tokens

#### Stage 1: Haiku Filtering (100 articles/day)

With prompt caching (system prompt cached across all 100 calls):

| Component | Tokens | Price | Daily Cost |
|-----------|--------|-------|------------|
| System prompt (1 cache write + 99 cache reads) | 800 x 100 = 80K total, but 800 write + 79,200 cached | Write: $0.001, Reads: $0.008 | ~$0.009 |
| Article input (not cached) | 1,000 x 100 = 100K | $1.00/MTok | $0.10 |
| Output | 30 x 100 = 3K | $5.00/MTok | $0.015 |
| **Stage 1 total** | | | **~$0.12/day** |

**With Batch API (50% off), this drops to ~$0.06/day.**

#### Stage 2: Sonnet Summarization (10 articles/day)

| Component | Tokens | Price | Daily Cost |
|-----------|--------|-------|------------|
| System prompt (cached) | ~1,200 tokens, 1 write + 9 reads | ~$0.005 | $0.005 |
| Article input | 2,500 x 10 = 25K | $3.00/MTok | $0.075 |
| Output | 350 x 10 = 3.5K | $15.00/MTok | $0.053 |
| **Stage 2 total** | | | **~$0.13/day** |

**With Batch API: ~$0.065/day.**

#### Stage 3: Sonnet Script Generation (1 script/day)

| Component | Tokens | Price | Daily Cost |
|-----------|--------|-------|------------|
| System prompt + summaries input | ~3,500 tokens | $3.00/MTok | $0.011 |
| Script output | ~1,200 tokens | $15.00/MTok | $0.018 |
| **Stage 3 total** | | | **~$0.03/day** |

#### Total Daily Cost

| Scenario | Daily | Monthly (30 days) | 2 Months |
|----------|-------|-------------------|----------|
| Standard API + caching | ~$0.28 | ~$8.40 | ~$16.80 |
| Batch API + caching | ~$0.16 | ~$4.70 | ~$9.40 |
| Standard, no caching | ~$0.42 | ~$12.60 | ~$25.20 |

**Your EUR 30-60 budget is extremely comfortable.** Even the most expensive scenario (standard API, no caching, no batching) lands well under EUR 30 for 2 months. This leaves significant room for:

- Experimentation and prompt iteration during development
- Running the filter on all 928 feeds (not just 100 deduplicated)
- Adding a second Sonnet pass for fact-checking or red-teaming
- Generating multiple script drafts and picking the best one

### Key Cost Optimization Strategies

1. **Always cache system prompts.** The persona document + instructions stay the same across all calls. At $0.10/MTok for cache reads vs $1.00/MTok for fresh input on Haiku, this is a 10x savings on the most repeated content.

2. **Use the Batch API for filtering.** Filtering is not time-sensitive -- you can collect a day's articles and send them all at once. 50% discount, and batches complete within ~1 hour typically.

3. **Truncate articles for filtering.** Headline + first 500-800 tokens is sufficient for relevance classification. Do NOT send full articles to Haiku.

4. **Deduplicate before filtering.** 928 RSS feeds will have massive overlap. Deduplicate by URL and by headline similarity (fuzzy match at >85%) before sending to Claude. This could easily cut your volume from 928 feeds x N articles to 100-200 unique articles per day.

5. **Batch summarization requests.** Same logic as filtering -- collect your 10 selected articles, send as a batch.

6. **Use Haiku for filtering, not Sonnet.** Haiku is 3x cheaper on input and 3x cheaper on output. For binary/tiered classification with a good prompt, Haiku 4.5 performs comparably to Sonnet.

---

## 7. Accuracy Safeguards

### Hallucination Prevention

News summarization is high-stakes because factual errors damage credibility. Apply these patterns in order of priority:

**1. Grounding Instructions (in every summarization prompt)**

Already included in the summarization prompt above. The key phrases:
- "Every claim must trace back to the source article"
- "Preserve attribution"
- "If you cannot find it in the article, do not include it"

**2. Quote-First Pattern**

For critical articles, ask the model to extract relevant quotes before summarizing:

```xml
<task>
First, extract the 3-5 most important direct quotes or data points from this article. Place them in <key_facts> tags.

Then, write your summary using ONLY information that appears in your extracted facts.
</task>
```

This forces the model to ground itself in the source material before generating prose.

**3. Red-Team Pass (Optional Second Call)**

For maximum accuracy, add a verification step using a second Sonnet call:

```
You are a fact-checker for a podcast. Compare the following summary against the source article.

<summary>
{{GENERATED_SUMMARY}}
</summary>

<source_article>
{{ORIGINAL_ARTICLE}}
</source_article>

<task>
Check for:
1. Claims in the summary that do not appear in the source article
2. Numbers, dates, or names that are incorrect or imprecise
3. Misleading framing (e.g., presenting speculation as fact)
4. Missing attribution for claims that need it

For each issue found, output:
ISSUE: [description]
LOCATION: [quote from summary]
FIX: [corrected text]

If no issues found, output: CLEAN
</task>
```

Cost for this extra pass: ~$0.05/day for 10 articles. Well within budget.

**4. Brett's Red-Team Approach (Built Into Script Generation)**

The script generation prompt already includes a `<red_team_check>` section. This mirrors Brett's own approach of red-teaming content 2-3 times. For the automated pipeline, this means:

- The summarization prompt grounds in source material
- The script prompt verifies against summaries
- The optional fact-check pass verifies summaries against sources

Three layers of verification, each catching different error types.

### What Cannot Be Automated

Be honest about limitations:
- **Emerging stories with conflicting reports**: The model cannot verify which sources are correct when outlets disagree. Flag these for human review.
- **Satire and parody**: The model may not reliably distinguish satire from news. Include source reputation data in your RSS feed metadata.
- **Deeply technical claims**: If an article claims "NVIDIA's new chip is 10x faster," the model cannot verify the benchmark methodology. Preserve the claim with attribution.

---

## 8. Implementation Recommendations

### Prompt Caching Setup

For the filtering stage (100 calls/day with the same system prompt), implement automatic caching:

```python
import anthropic

client = anthropic.Anthropic()

# The system prompt is identical across all filtering calls.
# With cache_control, subsequent calls within 5 minutes read from cache.

FILTER_SYSTEM_PROMPT = """[Your filtering system prompt here, including persona
and few-shot examples -- ~800 tokens total]"""

def filter_article(title, source, excerpt):
    response = client.messages.create(
        model="claude-haiku-4-5-20250929",
        max_tokens=60,
        cache_control={"type": "auto"},  # automatic caching
        system=FILTER_SYSTEM_PROMPT,
        messages=[{
            "role": "user",
            "content": f"<article>\n<title>{title}</title>\n<source>{source}</source>\n<excerpt>{excerpt}</excerpt>\n</article>"
        }]
    )
    return response.content[0].text
```

### Batch API Setup

For non-time-sensitive processing (which all three stages are, since this is a daily pipeline):

```python
import anthropic
import json

client = anthropic.Anthropic()

# Prepare batch requests
requests = []
for i, article in enumerate(todays_articles):
    requests.append({
        "custom_id": f"filter-{i}",
        "params": {
            "model": "claude-haiku-4-5-20250929",
            "max_tokens": 60,
            "system": FILTER_SYSTEM_PROMPT,
            "messages": [{
                "role": "user",
                "content": f"<article>\n<title>{article['title']}</title>\n<source>{article['source']}</source>\n<excerpt>{article['excerpt'][:800]}</excerpt>\n</article>"
            }]
        }
    })

# Submit batch
batch = client.batches.create(requests=requests)

# Poll for completion (typically <1 hour)
# batch.id gives you the ID to check status
```

### Model Selection Rationale

| Stage | Model | Why |
|-------|-------|-----|
| Filtering | Haiku 4.5 | Classification task. Haiku handles tiered labeling well. 3x cheaper than Sonnet. Speed is not critical since you batch daily. |
| Summarization | Sonnet 4.5 or 4.6 | Requires nuance: persona voice, factual grounding, appropriate hedging. Haiku tends to be too terse and loses nuance. |
| Script Generation | Sonnet 4.5 or 4.6 | Creative writing with structural constraints. Needs the intelligence to maintain voice consistency across a 1,000-word script. |
| Fact-checking (optional) | Sonnet 4.5 or 4.6 | Comparison task requiring careful reading of two texts. |

**Do not use Opus for this pipeline.** The tasks are well-defined and constrained. Sonnet provides equivalent quality for summarization and scripting at this complexity level. Opus would cost ~1.7x more with no meaningful improvement.

### Effort Settings

For Sonnet 4.6 specifically, set effort appropriately per stage:

```python
# Filtering with Haiku -- no thinking needed
# (Haiku 4.5 does not support effort parameter)

# Summarization -- low effort is sufficient for factual summarization
response = client.messages.create(
    model="claude-sonnet-4-6-20250929",
    max_tokens=500,
    output_config={"effort": "low"},
    system=SUMMARIZE_SYSTEM_PROMPT,
    messages=[{"role": "user", "content": article_text}]
)

# Script generation -- medium effort for creative structure
response = client.messages.create(
    model="claude-sonnet-4-6-20250929",
    max_tokens=2000,
    output_config={"effort": "medium"},
    system=SCRIPT_SYSTEM_PROMPT,
    messages=[{"role": "user", "content": summaries_text}]
)
```

---

## 9. Testing and Iteration

### Evaluation Framework

Before running the pipeline in production, test each stage independently:

**Filtering Accuracy**: Take 50 articles you have already manually classified. Run them through the filter prompt. Measure:
- Precision: Of articles marked MUST_COVER/STRONG, how many would Brett actually cover?
- Recall: Of articles Brett would cover, how many did the filter catch?
- Target: >90% recall (missing a story is worse than including a weak one)

**Summarization Quality**: Generate summaries for 10 articles. Check each for:
- Factual accuracy (every claim traceable to source)
- Voice consistency (sounds like Brett, not generic AI)
- Appropriate length (150-250 words)
- No fabricated opinions

**Script Quality**: Generate 5 test scripts. Evaluate:
- Timing (read aloud -- does it hit 5-7 minutes?)
- Transitions (natural, not repetitive)
- Cold open (compelling hook?)
- Voice consistency across all three topics

### Prompt Versioning

Keep your prompts in version control. When you change a prompt:
1. Run it against your test set of 50 filtered articles / 10 summarized articles
2. Compare outputs side-by-side with the previous version
3. Only deploy if metrics improve or stay neutral

---

## 10. Summary of Recommendations

| Decision | Recommendation | Rationale |
|----------|---------------|-----------|
| Filter scoring | 4-tier (MUST/STRONG/MAYBE/SKIP) | More reliable than numeric; provides ranking without false precision |
| Filter model | Haiku 4.5 | Sufficient for classification; 3x cheaper than Sonnet |
| Summarization approach | Direct with grounding rules | CoT adds cost without improving factual accuracy for news |
| Persona handling | Voice/style separate from opinions | Prevents hallucinated positions |
| Script structure | Fixed segment template with varied transitions | Consistency for production; variety for listener experience |
| Cost optimization | Batch API + prompt caching | Brings 2-month cost under EUR 10 |
| Accuracy | 3-layer verification (grounding + script check + optional fact-check) | Matches Brett's red-teaming philosophy |
| Budget risk | Very low | Even worst-case is under EUR 30 for 2 months |

---

## Sources

- [Claude API Pricing (Official)](https://platform.claude.com/docs/en/about-claude/pricing)
- [Claude Prompting Best Practices (Official)](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)
- [Claude Batch Processing (Official)](https://platform.claude.com/docs/en/build-with-claude/batch-processing)
- [Claude Prompt Caching (Official)](https://platform.claude.com/docs/en/build-with-claude/prompt-caching)
- [Anthropic Claude API Pricing 2026 (MetaCTO)](https://www.metacto.com/blogs/anthropic-api-pricing-a-full-breakdown-of-costs-and-integration)
- [Claude API Pricing Calculator (CostGoat)](https://costgoat.com/pricing/claude-api)
- [AI Batch Processing: OpenAI, Claude, and Gemini](https://adhavpavan.medium.com/ai-batch-processing-openai-claude-and-gemini-2025-94107c024a10)
- [Newsrooms on Generating AI Summaries (Nieman Lab)](https://www.niemanlab.org/2025/06/lets-get-to-the-point-three-newsrooms-on-generating-ai-summaries-for-news/)
- [Ontology-based Prompt Tuning for News Summarization (Frontiers)](https://www.frontiersin.org/journals/artificial-intelligence/articles/10.3389/frai.2025.1520144/full)
- [Podcast Script Prompt Engineering (HackerNoon)](https://hackernoon.com/i-built-an-ai-prompt-that-turns-podcast-ideas-into-professional-scriptsand-it-actually-work)
- [Building PDF-to-Podcast Pipeline (Featherless.ai)](https://featherless.ai/blog/building-a-pdf-to-podcast-pipeline-with-open-source-ai-from-text-extraction-to-voice-synthesis)
- [LLM Relevance Evaluation via Confusion Matrix (MDPI)](https://www.mdpi.com/2076-3417/15/9/5198)
- [Prompt Engineering in 2025 (Aakash Gupta)](https://www.news.aakashg.com/p/prompt-engineering)
