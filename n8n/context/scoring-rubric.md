# Scoring Rubric

Used by the n8n scoring node to rank candidate articles against Brett Moore's persona. Each article receives a score across 5 dimensions, then a weighted composite score determines selection.

---

## Dimension 1: Relevance (Weight: 0.25)

How well does this article match Brett's topic pillars (geopolitics, technology, science, economics)?

| Score | Label | Criteria |
|-------|-------|----------|
| 10 | Essential | Core topic, breaking news, directly affects one of Brett's primary interest areas. Brett would read this immediately. |
| 9 | Highly relevant | Core topic with significant new information. Would be a leading candidate for any episode. |
| 8 | Strong fit | Clearly within Brett's wheelhouse. Timely and substantive. |
| 7 | Good fit | Relevant to one or more pillars. Has enough substance for Brett to comment on. |
| 6 | Moderate | Related to Brett's interests but not central. Could serve as a secondary story or context piece. |
| 5 | Peripheral | Touches on Brett's topics tangentially. Would need to be paired with a stronger story. |
| 4 | Weak | Only loosely connected. Brett might skim this but wouldn't feature it. |
| 3 | Tangential | Requires significant stretching to connect to Brett's pillars. |
| 2 | Poor fit | Almost no connection to Brett's interests or expertise. |
| 1 | Irrelevant | Completely outside Brett's scope (celebrity gossip, sports scores, lifestyle content). |

### Relevance scoring signals
- Mentions of state actors, international institutions, or treaty frameworks: +2-3 points.
- Involves AI, quantum, climate, or medical-science developments: +2-3 points.
- Economic data with geopolitical implications (trade balances, sanctions effects, supply-chain shifts): +2 points.
- Pure domestic policy with no international dimension: cap at 5 unless the domestic story has global implications.
- Quirky/outlier stories that are intellectually rich: score on the merit of the insight, not the topic label.

---

## Dimension 2: Novelty (Weight: 0.20)

Is this article presenting new information, or is it a rehash of something already widely covered?

| Score | Label | Criteria |
|-------|-------|----------|
| 10 | Breaking | First report of a significant event. No other outlet has this yet. |
| 9 | Near-breaking | Published within hours of the event. Very few outlets covering it. |
| 8 | Fresh angle | New reporting, data, or perspective on a developing story. Adds genuine new information. |
| 7 | New development | An update that materially changes the understanding of an ongoing story. |
| 6 | Timely update | Routine update on a tracked story. Useful but not surprising. |
| 5 | Moderate | Competent coverage of a known story. No new revelations. |
| 4 | Rehash | Summarises what other outlets have already reported. Adds little new. |
| 3 | Stale | The core information has been public for 48+ hours and widely discussed. |
| 2 | Old news | Story is days to weeks old with no new angle. |
| 1 | Archive | Historical or evergreen content with no news peg. |

### Novelty scoring signals
- Exclusive data, leaked documents, or first-hand reporting: +3 points.
- "Sources say" or "according to officials not authorised to speak publicly": +1-2 points (indicates original reporting).
- Article mostly cites other media outlets: cap at 5.
- Headline uses "What you need to know about...": likely a roundup, cap at 4.
- Publication timestamp matters: same-day stories score higher than day-old stories on the same topic.

---

## Dimension 3: Cross-Domain Potential (Weight: 0.15)

Does this article naturally bridge multiple domains? Cross-domain stories are Brett's signature — they let him connect dots other commentators miss.

| Score | Label | Criteria |
|-------|-------|----------|
| 10 | Triple bridge | Clearly connects geopolitics + technology + economics (or science). Rare and extremely valuable. |
| 9 | Strong bridge | Explicitly links two major domains with concrete evidence. |
| 8 | Clear bridge | The article itself connects two domains, even if it doesn't fully explore the connection. |
| 7 | Implicit bridge | The cross-domain connection is obvious to a systems thinker but not stated in the article. Brett could make it. |
| 6 | Suggestive | One clear domain with hints of another. Brett would need to draw the connection himself. |
| 5 | Single-domain plus | Primarily one domain but has a secondary implication Brett could develop. |
| 4 | Single domain | Solid story within one domain. No natural bridge to others. |
| 3 | Narrow | Very focused within one sub-domain. Limited connection potential. |
| 2 | Isolated | Niche topic with almost no cross-domain potential. |
| 1 | Siloed | Pure single-domain, single-issue story with no broader implications. |

### Cross-domain pairing signals
- Geopolitics + Technology: chip export controls, AI governance treaties, cyber operations, space militarisation.
- Technology + Economics: automation and labour markets, platform regulation and market structure, fintech and monetary policy.
- Science + Geopolitics: pandemic preparedness, climate negotiations, Arctic access, resource competition.
- Economics + Geopolitics: sanctions regimes, BRICS de-dollarisation, energy-transition trade flows, rare-earth supply chains.
- Quirky + Any: if the outlier story illuminates a larger pattern in any other domain, score it 7+.

---

## Dimension 4: Storytelling Potential (Weight: 0.20)

Is there a compelling narrative in this article that will hold a listener's attention? Podcasts are an audio medium; stories must work as spoken narrative.

| Score | Label | Criteria |
|-------|-------|----------|
| 10 | Riveting | Human drama, high stakes, surprising twist, or counterintuitive finding. Listeners would tell friends about this. |
| 9 | Compelling | Strong narrative arc with clear characters, conflict, and resolution (or unresolved tension). |
| 8 | Engaging | Good story with interesting details. Easy to narrate. Has at least one memorable moment. |
| 7 | Solid | Decent narrative potential. Has concrete details Brett can build a segment around. |
| 6 | Workable | Informative but needs Brett's storytelling skill to make it engaging. The facts are there but the narrative isn't obvious. |
| 5 | Functional | Can be told as a story but won't be the highlight of the episode. Adequate for a secondary segment. |
| 4 | Dry | Mostly data, policy language, or institutional process. Hard to narrate engagingly without significant reframing. |
| 3 | Abstract | Theoretical or conceptual with few concrete details. Difficult to make vivid. |
| 2 | Technical | Dense jargon, methodology-heavy, or chart-dependent. Does not translate well to audio. |
| 1 | Untellable | Pure data table, press release boilerplate, or procedural update. No narrative available. |

### Storytelling scoring signals
- Named individuals with agency (made a decision, discovered something, defied expectations): +2 points.
- A surprising or counterintuitive fact: +2 points.
- Visual or sensory details that can be described: +1 point.
- Timeline/sequence of events (not just a static report): +1 point.
- Pure statistics without human context: -2 points.
- Legal/regulatory text without clear consequences: -2 points.

---

## Dimension 5: Controversy / "Brett Would Have a Take" (Weight: 0.20)

Would Brett have a strong, specific opinion on this? The best episodes are the ones where Brett's analysis adds something you can't get from just reading the article.

| Score | Label | Criteria |
|-------|-------|----------|
| 10 | Brett would lead with this | He has deep expertise, strong views, and unique perspective. This is his kind of fight. |
| 9 | Strong opinion territory | Multiple legitimate sides to the argument. Brett has a clear position and can defend it with evidence. |
| 8 | Debatable | Reasonable people disagree. Brett can articulate why one interpretation is more likely than others. |
| 7 | Angle-rich | Several interesting perspectives available. Brett can pick one and argue it compellingly. |
| 6 | Moderate take | Brett would have something to say, but it's more observational than argumentative. |
| 5 | Mild take | Interesting but Brett's view wouldn't differ dramatically from informed consensus. |
| 4 | Low controversy | Most informed people would agree on the interpretation. Brett adds context but not a distinctive take. |
| 3 | Consensus topic | Very little room for disagreement. Brett would report, not argue. |
| 2 | Obvious take | The "correct" interpretation is clear. Brett has nothing distinctive to add. |
| 1 | No take possible | Pure factual reporting with no analytical angle (weather events, obituaries, sports results). |

### Controversy scoring signals
- Geopolitical decisions where Western media has a consensus Brett would challenge: +3 points.
- Technology governance questions with no clear right answer: +2 points.
- Economic orthodoxy being tested by real-world outcomes: +2 points.
- Stories where Brett's Asia experience gives him a non-obvious perspective: +2 points.
- Stories where the "obvious" take is probably wrong: +2 points.
- Human-interest stories with no analytical hook: cap at 3.

---

## Composite Score Calculation

```
composite = (relevance * 0.25) + (novelty * 0.20) + (cross_domain * 0.15) + (storytelling * 0.20) + (controversy * 0.20)
```

### Score interpretation

| Composite | Action |
|-----------|--------|
| 8.0 - 10.0 | **Must use.** Feature as a lead story. Consider deep-dive treatment. |
| 6.5 - 7.9 | **Strong candidate.** Include in story selection pool. |
| 5.0 - 6.4 | **Maybe.** Use if the top pool is thin or if it pairs well with a stronger story. |
| 3.5 - 4.9 | **Unlikely.** Only use if nothing better is available and it fills a needed domain gap. |
| 1.0 - 3.4 | **Skip.** Do not include in any episode. |

### Tie-breaking rules
When two articles have the same composite score:
1. Prefer the article with the higher relevance score.
2. If still tied, prefer the article with the higher novelty score.
3. If still tied, prefer the article from a source Brett trusts more (see persona file).
4. If still tied, prefer the more recent article.

### Domain diversity constraint
Regardless of scores, an episode should not feature two stories from the same sub-domain unless they present genuinely opposing perspectives. The scoring pipeline should flag when the top-N stories all come from the same pillar.

---

## LLM Scoring Prompt Format

When asking the LLM to score an article, provide the article text and request a response in this exact JSON structure:

```json
{
  "relevance": 7,
  "relevance_reason": "One sentence explaining the score.",
  "novelty": 6,
  "novelty_reason": "One sentence explaining the score.",
  "cross_domain": 8,
  "cross_domain_reason": "One sentence explaining the score.",
  "storytelling": 7,
  "storytelling_reason": "One sentence explaining the score.",
  "controversy": 5,
  "controversy_reason": "One sentence explaining the score.",
  "composite": 6.55,
  "suggested_pillar": "geopolitics",
  "suggested_pair_with": "Optional: topic or domain this would pair well with."
}
```
