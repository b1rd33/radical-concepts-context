# n8n Podcast Pipeline Audit

Date: 2026-03-20

Scope reviewed:
- 12 workflow files in `n8n/workflows/`
- 5 context files in `n8n/context/`
- build plan in `docs/superpowers/plans/2026-03-20-podcast-pipeline-full-build.md`
- helper script `n8n/n8n-cli.sh`

## Executive Verdict

This is not a production podcast pipeline yet. It is a collection of mostly importable n8n workflow stubs.

What is true:
- All 12 workflow files are valid JSON.
- I found no dangling node references or broken connection targets.
- Telegram credential IDs are consistent where used: `V1Z3rnsrUvXf0TPr`.
- OpenRouter credential IDs are consistent where used: `1HjiTjhZTVqv5vLc`.
- The LangChain model wiring is present in every workflow that uses `Basic LLM Chain`.

What is not true:
- The repo does not implement the Supabase-driven modular architecture in the plan.
- The workflows are not end-to-end connected by durable state.
- Most workflows are mock/demo flows, not pipeline components.
- Several prompts are brittle or malformed for machine parsing.
- Secrets are exposed in the repo.

Bottom line:
- Importability: mostly yes.
- Execution readiness: mostly no.
- Architectural alignment with the plan: poor.
- Security hygiene: poor.

## High-Severity Cross-Cutting Findings

1. No workflow uses Supabase at all.
The plan is explicit that Supabase status fields are the backbone of orchestration. Actual count in the reviewed workflows: zero Supabase nodes. That means there is no durable state machine, no article lifecycle, no episode lifecycle, no restart safety, and no modular handoff.

2. The workflows are mostly mocks, not implementations.
`wf-02`, `wf-04`, `wf-05`, `wf-06`, `wf-08`, `wf-09`, `wf-10`, and `wf-11` all rely on mock/manual code inputs instead of real sources, database state, or prior workflow output.

3. Secrets are hardcoded in source.
- `n8n/n8n-cli.sh` contains a real n8n API key.
- `wf-01`, `wf-07`, and `wf-08` contain a hardcoded Jina bearer token.
- These should not be committed.

4. Context files exist but are not wired into the workflows.
The repo has decent prompt context files, but the workflows do not read or embed them. The persona/style/rubric/templates are effectively documentation, not active system behavior.

5. The current files do not form a coherent pipeline.
There is no durable handoff from:
- WF-01 scoring to WF-02 curation
- WF-02 curation to WF-03 approval with article identity
- WF-03 approval to WF-04 script generation
- WF-04 script approval to WF-05 audio
- WF-05 audio approval to WF-06 distribution

## Workflow Audit

### WF-00: `n8n/workflows/wf-00-error-handler.json`

Status:
- JSON valid: Yes
- Likely imports into recent n8n: Yes
- Credential IDs correct: Yes
- Broken references: None

Issues:
- Minimal implementation only. It sends a Telegram alert, but does not include execution URL, workflow ID, stack trace, retry hint, or rate limiting.
- Fixed chat ID makes it brittle outside Brett's current chat.

Verdict:
- Structurally fine.
- Operationally too bare-bones for a serious error handler, but not the main problem in this repo.

### WF-01: `n8n/workflows/wf-01-rss-score.json`

Status:
- JSON valid: Yes
- Likely imports into recent n8n: Yes
- Credential IDs correct: Yes
- LangChain `ai_languageModel` wiring: Correct
- Broken references: None

Issues:
- It is not the planned WF-01. It reads a single hardcoded BBC RSS feed, not the feed list and not Supabase.
- `RSS Read` uses `https://feeds.bbci.co.uk/news/rss.xml ` with a trailing space. Sloppy and unnecessary.
- Hardcoded Jina bearer token in the workflow.
- No schedule trigger.
- No Supabase feed lookup.
- No dedupe.
- No article persistence.
- No status transition to `scored`.
- No `continueOnFail` on Jina despite the technical reference and plan calling for it.
- It already sends articles to Telegram, which is WF-02's responsibility in the plan. That is architectural overlap.
- The scoring prompt asks for "valid JSON" but shows invalid JSON syntax: `{"score": 1-10, ...}`. That is not valid JSON.
- The category set is inconsistent with the repo taxonomy. The feeds file uses `general` and `quirky`; the prompt uses `culture`.
- `If` only handles the true branch. Low-scoring items are silently dropped with no audit trail.
- Telegram `callback_data` is just `approve` or `skip`. No article ID, URL hash, or record key is attached, so downstream approval cannot identify which article was tapped.
- The Telegram message omits source, URL, and article title context strong enough for curation.
- The workflow assumes a specific Jina response shape via `$json.data.title` and `$json.data.content`, but the internal technical reference is built around `full_text`. The mapping is inconsistent with repo guidance.

Verdict:
- Imports, but it is a brittle prototype and not the planned scoring pipeline.

### WF-02: `n8n/workflows/wf-02-morning-curation.json`

Status:
- JSON valid: Yes
- Likely imports: Yes
- Credential IDs correct: Yes
- Broken references: None

Issues:
- The core node is literally `Generate Top Articles` with mock articles in code. No DB read. No real scored-article query.
- No Supabase read of `status='scored'`.
- No status update to `presented`.
- Schedule is 07:00, but the plan says 07:05 after WF-01 completes.
- No timezone is set in the node, while the plan explicitly calls for Europe/Madrid behavior.
- `callback_data` is again just `approve` or `skip`, with no article identity.
- This workflow duplicates functionality that WF-01 is already partially doing because WF-01 also messages Telegram directly.

Verdict:
- Importable demo only. Not a real morning curation workflow.

### WF-03: `n8n/workflows/wf-03-approval-collector.json`

Status:
- JSON valid: Yes
- Likely imports: Yes
- Credential IDs correct: Yes
- IF true/false wiring on `Is Approved?`: Correct
- Broken references: None

Issues:
- It does not identify articles. Because upstream `callback_data` has no article ID, this workflow can only inspect message text.
- Approved items are stored in workflow static data, not Supabase.
- Workflow static data is the wrong persistence layer here. It is opaque, hard to inspect, not query-friendly, and not aligned with the plan.
- `approvedArticles` never resets by day or batch. It will keep accumulating across runs unless manually cleared.
- Duplicate taps can inflate the count.
- Rejections are not persisted anywhere.
- `3+ Articles?` only has a true branch. When under threshold, it silently does nothing.
- When threshold is reached, it does not trigger WF-04. It only sends a Telegram message telling someone to run WF-04 manually.
- No `approval_decisions` insert.
- No article status update to `approved` or `rejected`.

Verdict:
- Structurally sound, logically wrong for the planned pipeline.

### WF-04: `n8n/workflows/wf-04-script-generator.json`

Status:
- JSON valid: Yes
- Likely imports: Yes
- Credential IDs correct: Yes
- LangChain `ai_languageModel` wiring: Correct
- Broken references: None

Issues:
- Manual trigger only. The plan calls for webhook or manual, tied to approval threshold.
- Input is mock article text, not approved articles from Supabase.
- No read from `voice_profiles`.
- No use of `brett-persona.md`, `style-guide.md`, or `script-templates.md`.
- No template selection logic.
- No episode row creation.
- No `episode_articles` linking.
- No status update to `draft` or `script_review`.
- No approve/edit/reject buttons sent back to Telegram.
- It uses `openai/gpt-5.4-mini` for script generation, while the plan calls for a stronger script model.
- Telegram delivery is risky: a full 5-minute script can exceed Telegram's message length limit and fail or truncate.

Verdict:
- Importable, but still a prompt demo, not a script engine.

### WF-05: `n8n/workflows/wf-05-audio-production.json`

Status:
- JSON valid: Yes
- Likely imports: Yes
- Telegram credential ID correct: Yes
- Broken references: None

Issues:
- Manual trigger only.
- Input is mock script text.
- Fish Audio auth is not using an n8n credential; it is a hardcoded placeholder string in the workflow.
- No Supabase episode lookup.
- No status transitions.
- No `[PAUSE]` to SSML or pause handling step, despite the plan explicitly calling for text prep before TTS.
- No storage upload step.
- No Auphonic or other audio cleanup processor.
- No approve/redo buttons before distribution.
- The request body is fragile. `jsonBody` interpolates raw script text inside a JSON string. Quotes or line breaks in the script can break the JSON payload.
- This is not actually modular in the plan's sense because the TTS swap is a sticky note instruction, not a standardized node contract with surrounding persistence and handoff.

Verdict:
- Bare demo of a single TTS call, not a production audio workflow.

### WF-06: `n8n/workflows/wf-06-distribution.json`

Status:
- JSON valid: Yes
- Likely imports: Yes
- Credential IDs correct: Telegram only, yes
- Broken references: None

Issues:
- Manual trigger only.
- Input is mock episode data.
- No Supabase read of `audio_ready` episodes.
- No actual upload to RSS.com.
- No YouTube branch.
- No social branch.
- No status transition to `published`.
- `Generate RSS XML` only produces an `<item>` fragment, not a complete feed and not an RSS.com upload.
- The generated XML does not escape special characters in title or description. `&`, `<`, and `>` can break the XML.
- For podcast publishing, this is far too incomplete. No enclosure length, GUID, podcast metadata, or hosting integration.

Verdict:
- This is not distribution. It is a notification stub.

### WF-07: `n8n/workflows/wf-07-brett-forward.json`

Status:
- JSON valid: Yes
- Likely imports: Yes
- Credential IDs correct: Yes
- IF true/false wiring: Correct
- Broken references: None

Issues:
- Hardcoded Jina bearer token in the workflow.
- It fetches the URL through Jina and then only sends a Telegram confirmation. It does not actually queue anything into the pipeline.
- No Supabase insert for `source_type='brett_forward'`.
- No score trigger.
- No dedupe.
- No persistence at all.
- Replies go to hardcoded chat ID `1240314255`, not the sender. That is fine for a single-user toy bot, not for a robust bot workflow.
- URL extraction is simplistic and may capture trailing punctuation.

Verdict:
- Importable, but functionally misleading. The success message claims the article is queued when it is not.

### WF-08: `n8n/workflows/wf-08-newsletter-ingestion.json`

Status:
- JSON valid: Yes
- Likely imports: Yes
- Credential IDs correct: Telegram only, yes
- Broken references: None

Issues:
- Manual trigger only.
- Input is a mock email.
- Hardcoded Jina bearer token in the workflow.
- No Gmail/IMAP/email trigger.
- No persistence of extracted URLs or article content.
- No scoring handoff.
- No dedupe.
- No newsletter/source record keeping.

Verdict:
- Prototype only. Not a real ingestion workflow.

### WF-09: `n8n/workflows/wf-09-fallback-content.json`

Status:
- JSON valid: Yes
- Likely imports: Yes
- Credential IDs correct: Yes
- LangChain `ai_languageModel` wiring: Correct
- Broken references: None

Issues:
- Manual trigger only.
- Brett status is mocked.
- If Brett has recorded, the workflow just stops. No explicit no-op notification or downstream state handling.
- No episode persistence.
- No audio generation.
- No publish path.
- In the plan, fallback content is tied into the production flow under audio/approval logic, not isolated as a disconnected manual draft generator.

Verdict:
- Reasonable idea, disconnected implementation.

### WF-10: `n8n/workflows/wf-10-auto-clipping.json`

Status:
- JSON valid: Yes
- Likely imports: Yes
- Credential IDs correct: Yes
- LangChain `ai_languageModel` wiring: Correct
- Broken references: None

Issues:
- Manual trigger only.
- Transcript is mocked.
- No transcription step.
- No clipping engine.
- No FFmpeg.
- No rendered clips.
- Output is just a Telegram suggestion message.
- The plan's phase-2 description for auto-clipping implies actual media operations. This file does none of them.

Verdict:
- Idea stub only.

### WF-11: `n8n/workflows/wf-11-quality-scoring.json`

Status:
- JSON valid: Yes
- Likely imports: Yes
- Credential IDs correct: Yes
- LangChain `ai_languageModel` wiring: Correct
- IF true/false wiring: Correct
- Broken references: None

Issues:
- Manual trigger only.
- Input is mocked.
- The prompt asks for JSON but shows invalid JSON syntax with placeholder `N` values. That is not valid JSON.
- The workflow then immediately does `JSON.parse($json.text)`. That is brittle and likely to fail if the model returns anything except perfectly parseable JSON.
- No structured output parser is used even though the repo's n8n references explicitly discuss safer prompt/node shapes.
- No persistence of quality results.
- Not integrated into the script or audio approval flow.

Verdict:
- Structurally fine, operationally brittle, architecturally disconnected.

## Context File Audit

### `n8n/context/brett-persona.md`

Assessment:
- Good baseline persona file.
- Not sufficient as the sole system prompt for a high-trust production pipeline.

What is good:
- Strong background and worldview framing.
- Clear voice/tone guidance.
- Good red flags.
- Trusted source list is useful.

What is missing:
- No machine-readable prompt contract.
- No explicit uncertainty handling protocol beyond general advice.
- No citation format rules.
- No fact-checking hierarchy.
- No audience definition.
- No episode-length adaptation rules.
- No examples of good and bad generated output.

Verdict:
- Strong editorial brief.
- Not comprehensive enough by itself for high-stakes system prompting.

### `n8n/context/scoring-rubric.md`

Assessment:
- This is the strongest context file.
- It does cover 5 dimensions with clear criteria.

What is good:
- Clear weights.
- Clear 1-10 definitions for each dimension.
- Tie-break rules are useful.
- Domain diversity constraint is smart.
- JSON output contract is explicit.

What is weak:
- It is not aligned with the actual WF-01 prompt, which ignores most of this file.
- Category taxonomy is not perfectly aligned with the feed taxonomy.
- No calibration examples with sample articles and expected scores.
- No operational freshness rule beyond prose.

Verdict:
- Good file.
- Poorly integrated into the workflows.

### `n8n/context/script-templates.md`

Assessment:
- Practical as editorial guidance.
- Not yet practical as an automated prompt component without more structure.

What is good:
- Realistic durations.
- Clear section purposes.
- Good episode-shape variety.
- Good section-level rules.

What is weak:
- It is prose, not machine-ready prompt scaffolding.
- No explicit template selection logic.
- No variable placeholders for article inputs.
- No source-grounding enforcement format.
- No TTS-specific normalization guidance.

Verdict:
- Useful writing guide.
- Not directly operationalized.

### `n8n/context/style-guide.md`

Assessment:
- Generally actionable.
- Again, not wired into the workflows.

What is good:
- Strong anti-AI-language guardrails.
- Clear voice instructions.
- Useful signature phrase limits.
- Useful pronunciation note convention.

What is weak:
- No explicit source attribution template.
- No hard fail checklist before publish.
- No example transformed paragraphs.
- No operational rules for controversial or uncertain claims.

Verdict:
- Good style brief.
- Missing enforcement hooks and not used by WF-04.

### `n8n/context/rss-feeds-mvp.json`

Assessment:
- Valid JSON.
- The structure is clean.
- The list is not trustworthy enough as a "validated working feed set."

What is good:
- 50 feeds.
- No duplicate URLs.
- No duplicate names.
- Batches are distributed across 0-23.

Issues:
- The feed list is unused by WF-01.
- Several entries are legacy or fragile distribution paths, especially FeedBurner-based ones.
- `AP News World` uses `rss.app`, which is a third-party feed generator, not a first-party AP endpoint.
- `TechCrunch` uses `https://feeds.feedburner.com/TechCrunch/` even though TechCrunch's current subscription page points readers to its own feed endpoint.
- `VentureBeat` uses FeedBurner.
- `Foreign Affairs` uses FeedBurner.
- `Popular Mechanics` uses a suspicious path with a trailing slash: `https://www.popularmechanics.com/rss/all.xml/`.
- There is no `last_verified_at`, `is_active`, `priority`, or fallback URL metadata.
- Taxonomy mismatch: feeds use `general` and `quirky`, while WF-01 scoring categories use a different schema.

Live verification note:
- I could not programmatically fetch all 50 feed URLs from this environment.
- I did spot-check current external evidence on 2026-03-20 and confirmed at least some entries rely on third-party or legacy feed paths rather than clean first-party endpoints.

Verdict:
- Good starting inventory.
- Not a vetted production feed registry.

## Plan Coverage: Missing or Misplaced Workflows

Answer to "Are any workflows missing based on the plan?":
- No core numbered files are missing. `WF-00` through `WF-06` all exist on disk.
- The real problem is not missing filenames. The problem is missing planned logic inside those workflows.

What is missing from the actual implementation:
- Supabase state-store orchestration across all core workflows
- feed polling from `feeds` table
- article persistence and dedupe
- article status transitions
- approval decision persistence
- automatic trigger from WF-03 to WF-04
- script approval loop
- episode persistence
- episode/article linking
- audio cleanup processor
- storage upload
- publish approval loop
- actual RSS.com upload
- actual YouTube distribution
- actual social distribution
- end-to-end integration path

What is architecturally off:
- The plan says 7 modular workflows anchored on Supabase.
- The repo contains 12 workflows, but the extra workflows are mostly disconnected experiments.
- WF-01 and WF-02 overlap in responsibility.
- Features that the plan places inside WF-05 or WF-06 are split into separate side workflows without integration.

## `n8n/n8n-cli.sh` Audit

Verdict:
- Useful convenience script.
- Not robust enough and not safe enough to keep as-is.

Issues:
- Real n8n API key is hardcoded in the file.
- No `set -euo pipefail`.
- No dependency checks for `curl` or `python3`.
- No argument validation for required positional parameters.
- No `curl --fail` or HTTP status handling. API failures can fall through to Python JSON parsing and fail badly.
- No timeout values.
- `rename` and `set-node` rebuild workflows with a reduced payload and force `settings={'executionOrder':'v1'}`. That risks discarding workflow metadata/settings.
- `rename` and `set-node` interpolate shell variables directly into inline Python code. Names containing quotes or special characters can break the command or do the wrong thing.
- The help text still only lists WF-01 and WF-02 IDs and is out of date relative to the repo contents.

Recommended fixes:
- Move URL and API key to environment variables.
- Add strict shell mode.
- Add argument checks and usage errors.
- Add `curl --fail --show-error --silent` plus timeout/retry.
- Stop reconstructing partial workflow payloads in `rename` and `set-node`; preserve all fields returned by the API.

## Security Findings

Critical:
- `n8n/n8n-cli.sh` exposes a real n8n API key.
- `wf-01`, `wf-07`, and `wf-08` expose a Jina bearer token.

High:
- External-service auth is being handled in workflow JSON instead of n8n credentials or environment-backed headers.
- Hardcoded chat IDs and webhook IDs make the flows environment-specific and harder to rotate safely.

Medium:
- No evidence of secret rotation strategy.
- No evidence of `.gitignore` or templating approach for secret-bearing workflow variants.

## Final Assessment

If the question is "Will these JSON files import into n8n?", the answer is mostly yes.

If the question is "Do these workflows implement the podcast pipeline described in the plan?", the answer is no.

If the question is "Is this safe to keep in the repo as-is?", the answer is also no.

The repo currently contains:
- one acceptable minimal error handler
- one partially wired scoring demo
- several disconnected Telegram/LLM/TTS mock flows
- context files that are better than the workflows that are supposed to use them

The immediate priorities are obvious:
1. Remove committed secrets.
2. Rebuild WF-01 through WF-06 around Supabase state transitions.
3. Pass article and episode identity through every interaction.
4. Stop using mock code nodes as stand-ins for pipeline state.
5. Wire the context files into the actual prompts.
