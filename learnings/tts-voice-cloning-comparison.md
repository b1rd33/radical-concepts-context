# TTS Voice Cloning Services: Comprehensive Comparison for Podcast Automation

**Date:** March 2026
**Use case:** Clone Brett Moore's Australian male voice for automated podcast generation
**Shows:** Science (cloned voice), Quirky human interest (cloned voice), Politics (real voice only)
**Volume:** ~15-20 episodes/month, 5-7 minutes each (~75-140 minutes of generated audio/month)

---

## Table of Contents

1. [Executive Summary & Recommendation](#executive-summary--recommendation)
2. [Service Comparison Matrix](#service-comparison-matrix)
3. [Detailed Service Analysis](#detailed-service-analysis)
4. [Cost Modeling for Our Use Case](#cost-modeling-for-our-use-case)
5. [Voice Sample Recording Best Practices](#voice-sample-recording-best-practices)
6. [Quality Evaluation Methodology](#quality-evaluation-methodology)
7. [Legal & Ethical Considerations](#legal--ethical-considerations)
8. [Implementation Recommendation](#implementation-recommendation)

---

## Executive Summary & Recommendation

**Primary recommendation: Fish Audio (Plus Plan, ~$11/mo)**
**Backup/comparison: ElevenLabs (Creator Plan, $11/mo)**
**Worth testing: Qwen3-TTS (free, self-hosted) if you have GPU access**
**Skip: Hume AI (excellent tech, but optimized for conversational AI, not batch podcast TTS)**

Fish Audio wins on price-to-quality ratio for this specific use case. Their S1 model holds the #1 position on TTS-Arena2 (the industry's primary blind-test leaderboard), requires only 10-30 seconds of voice sample for cloning, and their Story Studio feature is purpose-built for long-form podcast/audiobook content. At ~$11/month, the Plus plan provides ~200 minutes of S1 generation -- more than enough for 10-14 episodes of Science and Quirky content.

ElevenLabs remains the emotional depth benchmark, particularly relevant for Quirky episodes that need warmth and humor. Its Australian accent support is explicitly marketed and well-tested. But it costs more per minute at equivalent quality tiers.

The critical nuance: Brett's instinct about Politics is correct. Listener tolerance for AI voice varies dramatically by content type. Science and Quirky content are more forgiving because listeners engage with the information/story, not the parasocial relationship with the host. Political commentary demands trust, and trust requires authenticity.

---

## Service Comparison Matrix

| Feature | Fish Audio | ElevenLabs | Hume AI (Octave) | Qwen3-TTS | PlayHT | Resemble AI |
|---|---|---|---|---|---|---|
| **Monthly cost (our volume)** | ~$11 (Plus) | $11-99 (Creator/Pro) | $14-70 (Creator/Pro) | $0 (self-host) | $31-99 | $19+ or $0.03/min |
| **Min voice sample** | 10-30 sec | 1-5 min (instant), 30+ min (pro) | 5-30 sec | 3 sec | 30 sec | 10 sec-1 min |
| **Clone creation time** | <30s instant, ~5min HQ | Minutes (instant), hours (pro) | Near-instant | Seconds | Minutes | ~1 min |
| **Long-form quality** | Excellent (Story Studio) | Excellent (benchmark) | Excellent (emotional) | Good-Very Good | Good | Good |
| **Australian accent** | Via cloning (preserves accent) | Explicit support + audio tags | Via cloning | Via cloning | Via cloning | Via cloning |
| **Emotional range** | Fine-grained emotion markers | Industry benchmark | Best-in-class (emotion-native) | Good | Moderate | Good (emotion controls) |
| **API quality** | REST, streaming, simple | Mature REST API, well-documented | REST + WebSocket | Self-hosted, full control | REST API | REST API |
| **Latency (first byte)** | Fast | 150-300ms | Fast | 97ms (self-hosted) | Moderate | Moderate |
| **Languages** | 30+ | 32+ | 11+ (100+ for cloned) | 10 | 140+ | 50+ |
| **Commercial license** | All paid plans | Starter+ ($5+/mo) | Creator+ ($14/mo) | Apache 2.0 (unrestricted) | Creator+ ($31/mo) | All paid plans |
| **TTS Arena ranking** | #1 (S1 model) | Top 3 | Strong (beat ElevenLabs in blind study) | Competitive | Mid-tier | Mid-tier |

---

## Detailed Service Analysis

### 1. Fish Audio

**Pricing tiers:**
- Free: 8,000 credits/month (~7 min S1 audio) -- testing only
- Plus: ~$11/month ($132/year billed annually) -- 250,000 credits, ~200 min S1/month
- Pro: $75/month -- 2,000,000 credits, ~27 hours S1/month

**Voice cloning specifics:**
- Minimum sample: 10 seconds of clean audio
- Recommended: 1-3 minutes for optimal quality
- Instant mode: <30 seconds processing
- High-quality mode: ~5 minutes processing, better prosody and emotional range for long-form
- No fine-tuning required -- zero-shot cloning
- Cloned voices work across all 30+ supported languages

**Long-form content:**
- Story Studio: dedicated workspace for podcast scripts and audiobooks
- Supports multi-character dialogue, chapter-level organization
- ACX-compliant export formats (relevant for audiobook crossover)
- Emotion control via explicit markers: (angry), (sad), (excited), etc.

**Quality metrics:**
- #1 on TTS-Arena2 (blind listening tests, third-party evaluation)
- Character Error Rate (CER): ~0.4%
- Word Error Rate (WER): ~0.8%

**Australian accent handling:**
Fish Audio preserves the source accent from the cloning sample. If Brett records a clean Australian-accented sample, the clone will maintain that accent. No explicit "Australian mode" -- it learns from the reference audio, which is actually preferable for natural results.

**API:**
- REST API with streaming support
- Same endpoint for cloned and catalog voices (no integration complexity)
- Same pricing tier for cloned voice TTS as standard TTS
- Pay-as-you-go API option at ~$15 per million UTF-8 bytes (~$0.80/hour)

**Strengths:** Best quality-to-price ratio, purpose-built long-form tools, simple API, top benchmark scores.
**Weaknesses:** Community voice catalog has inconsistent quality (irrelevant for our cloned-voice use case). Less explicit accent control compared to ElevenLabs audio tags.

---

### 2. ElevenLabs

**Pricing tiers:**
- Free: Limited, no commercial use
- Starter: $5/month -- 30,000 credits (~30 min), instant voice cloning, commercial license
- Creator: $11/month -- 100,000 credits (~100 min), Professional Voice Cloning, 192kbps audio
- Pro: $99/month -- 500,000 credits (~500 min), 44.1kHz PCM output via API

**Voice cloning: two tiers:**

*Instant Voice Cloning (Starter+):*
- 1-5 minutes of audio sample
- Quick turnaround
- Good quality, suitable for testing and lighter content
- Available from $5/month

*Professional Voice Cloning (Creator+):*
- 30+ minutes of audio recommended (2-3 hours optimal)
- Significantly higher quality -- "nearly indistinguishable from original"
- Best for broadcast-quality, commercial audio
- Requires identity verification (you can only clone your own voice)
- Available from $11/month

**Australian accent:**
- Explicitly marketed Australian accent support
- Eleven v3 Audio Tags allow fine-grained accent control: `[Australian accent]`
- Pre-built Australian voices in the Voice Library
- Best-in-class for English accent variants

**Long-form content:**
- Strong emotional depth and prosody for extended content
- Considered the benchmark for audiobook and podcast narration
- Projects feature for managing long-form content

**API:**
- Mature, well-documented REST API
- Credit system: ~1,000 credits per minute of output
- Overage rates: $0.24-0.60/min depending on plan tier

**Commercial use policy:**
- Commercial license from Starter ($5/mo) and above
- Must confirm rights/permissions before cloning any voice
- Professional Voice Cloning requires identity verification
- Misuse (cloning without consent) results in permanent ban

**Strengths:** Best Australian accent support, mature API, emotional depth benchmark, strong brand trust.
**Weaknesses:** More expensive per minute than Fish Audio (45-70% more by independent comparisons). Professional cloning requires significant recording investment (30+ min). Credit system can be confusing.

---

### 3. Hume AI (Octave)

**Pricing tiers:**
- Free: $0 -- 10,000 characters/month (very limited)
- Starter: $3/month -- 30,000 characters
- Creator: $14/month -- commercial rights, larger limits
- Pro: $70/month -- 1,200 min EVI included, $0.06/min overage
- Scale: $200/month
- Business: $500/month
- Enterprise: Custom

**Voice cloning:**
- Minimum sample: 5 seconds of audio (industry-leading minimum)
- Instant cloning with good quality
- Cloned voice maintains identity across 100+ languages
- Voice cloning was launched relatively recently -- still maturing

**What makes Hume unique: emotion-native architecture.**
Octave is not a traditional TTS engine. It is a voice-based LLM that *understands the semantic and emotional content* of what it is saying. This means:
- It naturally adjusts tone for questions, exclamations, sarcasm, whispering
- Acting instructions can control delivery style
- In blind studies with 180 raters, Octave was preferred over ElevenLabs on audio quality (71.6%), naturalness (51.7%), and voice matching (57.7%)

**Long-form content:**
- Projects feature for audiobooks/podcasts with automatic chunking
- Preserves emotional consistency across chapters/scenes
- Multi-character dialogue support

**Why I am NOT recommending Hume as primary:**
Despite impressive technology, Hume AI is primarily optimized for conversational AI (their Empathic Voice Interface) rather than batch TTS generation for podcasts. Their pricing is character-based at lower tiers, and the per-minute costs on higher plans ($0.06/min on Pro) make it expensive at volume compared to Fish Audio. The emotion understanding is genuinely best-in-class, but for scripted podcast content where you control the writing, you can achieve similar results with Fish Audio's explicit emotion markers or ElevenLabs' audio tags.

**When Hume WOULD be the right choice:**
If the podcast format evolved to include AI-hosted Q&A segments, live interaction, or real-time emotional adaptation, Hume's EVI (Empathic Voice Interface) would be unmatched.

---

### 4. Qwen3-TTS (Open Source)

**Models available (Apache 2.0 license):**
- Qwen3-TTS-12Hz-0.6B-Base (lightweight, edge devices)
- Qwen3-TTS-12Hz-1.7B-Base (standard)
- Qwen3-TTS-12Hz-1.7B-CustomVoice (voice cloning optimized)
- VoiceDesign variants for creating new voices from prompts

**Hardware requirements:**
- 0.6B model: 1-5 GB VRAM (GTX 1070 or equivalent minimum)
- 1.7B model: 2-7 GB VRAM (RTX 3060 minimum, RTX 4080+ recommended for production)
- Production setup: 16+ GB VRAM recommended
- FlashAttention 2 recommended for memory efficiency
- BFloat16 precision provides 5-8% VRAM savings on Ampere+ GPUs

**Voice cloning:**
- 3-second minimum sample (industry-leading)
- Zero-shot cloning captures timbre, speaking style, emotional tendencies
- Speaker similarity score: 0.95 (vs competitor average of 0.87, per Qwen benchmarks)
- CustomVoice model specifically optimized for cloning tasks

**Performance:**
- First-packet latency: 97ms (faster than all commercial options)
- 10 languages supported (Chinese, English, Japanese, Korean, German, French, Russian, Portuguese, Spanish, Italian)
- Streaming output supported

**Cost:**
- $0 for the models (Apache 2.0, fully permissive)
- Cloud GPU hosting: ~$0.50-2.00/hour depending on provider (RunPod, Vast.ai, Lambda)
- For 75-140 min/month of generation, you might need ~2-4 hours of GPU time = $1-8/month
- Self-hosted on own hardware: truly $0 ongoing

**Realistic assessment:**
The benchmarks are impressive, but self-reported. In practice, Qwen3-TTS excels at Chinese/Asian language TTS and is competitive but not yet top-tier for English emotional range in long-form content. The 10-language limitation (vs 30+ for Fish Audio) is not an issue for English podcasts, but the English prosody and naturalness -- while good -- trails Fish Audio S1 and ElevenLabs in independent blind tests for extended content.

**When Qwen3-TTS makes sense:**
- If you want zero ongoing cost and have GPU access (even a gaming PC with an RTX 3060)
- As a backup/fallback if commercial API goes down
- For experimentation and rapid prototyping
- If privacy/data sovereignty is a concern (all processing stays local)

**When it does NOT make sense:**
- If you want "set and forget" reliability without DevOps overhead
- If English emotional range is the top priority
- If you do not have access to a GPU (cloud GPU costs erode the free advantage)

---

### 5. Other Notable Options

**PlayHT:**
- Creator: $31.20/month (annual) or $39/month -- 600,000 chars/year, 10 instant voice clones
- Unlimited: $99/month -- 2.5M character monthly fair-use cap
- 30 seconds minimum for voice cloning
- 140+ languages (most of any platform)
- Verdict: Overpriced for our use case. No compelling quality advantage over Fish Audio at 3x the cost.

**Resemble AI:**
- Pay-as-you-go: $0.03/min with 150 seconds free
- Creator: $19/month
- 10-second minimum for rapid voice cloning
- Strong emotion and tone controls
- Voice security features (watermarking, detection)
- Verdict: Decent option if you need voice security/watermarking. Otherwise, not competitive on price or quality benchmarks vs Fish Audio.

**Descript Overdub:**
- Bundled with Descript ($24/month for Pro)
- Designed for corrections/pickups, not full episode generation
- Verdict: Wrong tool for this use case. Good for fixing mistakes in real recordings, not generating episodes from scratch.

---

## Cost Modeling for Our Use Case

**Assumptions:**
- 10-14 episodes/month (Science + Quirky only; Politics uses real voice)
- 5-7 minutes per episode
- ~60-100 minutes of generated audio per month
- Some regeneration/iteration: assume 1.5x multiplier = 90-150 minutes actual usage

| Service | Plan | Monthly Cost | Included Minutes | Sufficient? | Cost/Episode |
|---|---|---|---|---|---|
| Fish Audio | Plus | ~$11 | ~200 min (S1) | Yes, with headroom | ~$0.79-1.10 |
| ElevenLabs | Starter ($5) | $5 | ~30 min | No -- too tight | N/A |
| ElevenLabs | Creator ($11) | $11 | ~100 min | Borderline | ~$0.79-1.10 |
| ElevenLabs | Pro ($99) | $99 | ~500 min | Yes, with excess | ~$7.07-9.90 |
| Hume AI | Creator ($14) | $14 | Character-based | Likely tight | ~$1.00-1.40 |
| Hume AI | Pro ($70) | $70 | 1,200 min EVI | Overkill for batch TTS | ~$5.00-7.00 |
| Qwen3-TTS | Self-hosted | $0-8 | Unlimited | Yes | ~$0.00-0.57 |
| PlayHT | Creator ($39) | $39 | Character-limited | Possibly | ~$2.79-3.90 |
| Resemble AI | PAYG | $2.70-4.50 | Pay per minute | Yes | ~$0.19-0.45 |

**Winner on cost:** Qwen3-TTS (if you have hardware) or Resemble AI PAYG (lowest commercial cost)
**Winner on cost-adjusted quality:** Fish Audio Plus at ~$11/month

---

## Voice Sample Recording Best Practices

Brett should record samples following these guidelines to maximize clone quality across all platforms.

### Recording Setup

**Microphone:**
- Use a quality external condenser microphone (e.g., Audio-Technica AT2020, Rode NT1-A, or Shure SM7B)
- Unidirectional/cardioid pattern to reject room noise
- Position 6-8 inches from mouth
- Use a pop filter to reduce plosives
- Do NOT use laptop built-in microphone

**Environment:**
- Quiet room with minimal echo
- At least 2 feet from any wall
- Soft furnishings help (carpet, curtains, bookshelves)
- Preferred wall materials: drywall, MDF, unpolished wood
- Close windows, turn off AC/fans during recording
- Record a "room tone" sample (10 seconds of silence) for reference

**Technical settings:**
- Format: WAV (RIFF PCM)
- Sample rate: 44.1kHz or 48kHz
- Bit depth: 24-bit
- Mono channel (not stereo)

### What to Record

**For Instant Cloning (Fish Audio, Hume):**
- Minimum: 30 seconds of clean speech
- Recommended: 2-3 minutes
- Read naturally, as if hosting a podcast (not reading a script robotically)
- Include a range of sentences: questions, statements, exclamations
- Vary emotional tone: calm explanation, excited discovery, thoughtful reflection

**For Professional Cloning (ElevenLabs PVC):**
- Minimum: 30 minutes
- Recommended: 2-3 hours
- Read diverse content: news, stories, technical explanations, casual conversation
- Include all phonemes of English (use a phonetically balanced script)
- Maintain consistent energy and mic distance throughout

**For Maximum Flexibility (record once, use everywhere):**
Create a single high-quality recording session of 30-45 minutes that covers:
1. 5 minutes of natural podcast-style monologue (Science topic)
2. 5 minutes of conversational, warm delivery (Quirky topic)
3. 5 minutes of reading diverse sentences with varied emotion
4. 15-20 minutes of phonetically balanced reading material

This gives you:
- The first 30 seconds for Fish Audio instant clone
- The first 2-3 minutes for Fish Audio high-quality clone
- The first 5 minutes for ElevenLabs instant clone
- The full 30+ minutes for ElevenLabs Professional Voice Cloning
- Any 3-second snippet for Qwen3-TTS

### Recording Tips

- Pronounce each word clearly but naturally (do not over-enunciate)
- Avoid filler sounds (sighs, throat clearing, lip smacking)
- No unnaturally long pauses mid-sentence
- Keep clips between 5-15 seconds each if recording in segments
- Maintain consistent volume and distance from mic
- Take breaks every 10 minutes to maintain voice consistency
- Hydrate before and during the session
- Record in the same session to maintain tonal consistency

---

## Quality Evaluation Methodology

### Metrics to Use

**1. Mean Opinion Score (MOS) -- Subjective**
- Scale: 1 (bad) to 5 (excellent)
- Have 5-10 listeners rate naturalness, clarity, and "does this sound like Brett?"
- Test both cold listeners (never heard Brett) and warm listeners (know his voice)
- Aim for MOS >= 4.0 for production use

**2. Speaker Similarity -- Objective**
- Use a speaker verification model (e.g., ECAPA-TDNN or Resemblyzer)
- Compute cosine similarity between Brett's real voice embedding and the clone
- Target: >= 0.85 cosine similarity (0.95 is near-perfect)

**3. A/B Testing Protocol**
- Create 5 short clips (30 seconds each) with each service using the same script
- Randomize order, do not label which is which
- Ask listeners: "Which sounds more natural?" and "Which sounds more like a real podcast host?"
- Include one real Brett recording as a control
- Sample size: minimum 10 listeners, ideally 20-30
- Use a simple Google Form for data collection

**4. Long-Form Fatigue Test**
- Generate a full 5-7 minute episode with each finalist
- Have listeners rate whether they would listen to the full episode
- Check for artifacts that appear only in longer content: monotony, rhythm drift, pronunciation errors
- This is the most important test -- short demos can be misleading

### Suggested Evaluation Process

1. Record Brett's voice samples (one session, 30-45 min)
2. Create clones on Fish Audio, ElevenLabs, and optionally Qwen3-TTS
3. Generate the same 60-second script on all platforms
4. Run blind A/B test with 10+ listeners
5. Eliminate any service scoring below MOS 3.5
6. Generate a full 5-7 minute episode on the top 2 finalists
7. Run the long-form fatigue test
8. Make final selection based on quality + cost + API reliability

---

## Legal & Ethical Considerations

### Disclosure Requirements

**FTC Guidelines (US, 2025-2026):**
- AI-generated voice content must be disclosed to listeners
- For podcasts (audio-only): disclosures must be spoken aloud, not just in show notes
- Recommended: state disclosure at both the beginning and end of each episode
- Suggested wording: "This episode is narrated using an AI-generated voice cloned from Brett Moore with his permission"

**General Disclosure Best Practices:**
- Be transparent, not defensive ("We use AI narration for Science and Quirky episodes so we can bring you more content, more often")
- Brett should personally record a disclosure intro explaining the approach
- Consider a brief real-voice intro/outro on cloned episodes for authenticity
- Update podcast description on all platforms to note AI voice usage

### Consent and Rights

**Voice cloning consent:**
- Brett must explicitly consent to his voice being cloned (written agreement recommended)
- ElevenLabs requires identity verification for Professional Voice Cloning
- All platforms require confirmation that you have rights to clone the voice
- Document the consent in writing, even if the platform does not require it

**Recommended consent agreement should cover:**
- Explicit permission to clone Brett's voice
- Which shows/content types the clone may be used for
- Who controls the voice clone (ownership)
- Right to revoke consent and delete the clone
- Whether the clone can be used if Brett leaves the project

### Platform-Specific Policies

- **ElevenLabs:** Strict consent verification, permanent ban for misuse, commercial use requires paid plan
- **Fish Audio:** Commercial use on paid plans, consent required for cloning others' voices
- **Hume AI:** Commercial rights from Creator plan ($14/mo)
- **Qwen3-TTS:** Apache 2.0, no platform restrictions (but legal obligations still apply)

### Australian-Specific Considerations

- Australia does not have a specific "voice rights" law equivalent to some US states
- However, misleading or deceptive conduct laws (Australian Consumer Law) could apply if listeners are deceived
- The Australian Communications and Media Authority (ACMA) may issue guidance on AI-generated media
- Best practice: disclose proactively regardless of current legal requirements

### Ethical Framing

Brett's instinct to keep Politics episodes in his real voice is ethically sound. Political commentary carries implicit trust. Listeners form parasocial relationships with hosts, and that trust is the product. For Science and Quirky shows, the value proposition is the content itself -- the voice is a delivery mechanism. This distinction should be communicated to listeners honestly.

---

## Implementation Recommendation

### Phase 1: Validation (Week 1-2)

1. **Record voice samples:** Brett records a 30-45 minute session following the guidelines above
2. **Create free-tier clones:** Test on Fish Audio (free, 7 min), ElevenLabs (free, limited), and Hume AI (free, 10,000 chars)
3. **Generate test clips:** Same 60-second script on all three platforms
4. **Run blind A/B test:** 10+ listeners compare quality

### Phase 2: Selection (Week 2-3)

5. **Subscribe to top 2 finalists:** Likely Fish Audio Plus ($11) and ElevenLabs Creator ($11)
6. **Generate full episodes:** One Science and one Quirky episode on each
7. **Run long-form fatigue test:** Which holds up over 5-7 minutes?
8. **Final selection:** Choose primary service, keep second as backup

### Phase 3: Production Pipeline (Week 3-4)

9. **API integration:** Connect chosen service to your script-to-audio pipeline
10. **Disclosure recording:** Brett records a real-voice intro/outro for cloned episodes
11. **Quality gate:** Establish a review step before publishing (Brett listens to each episode)
12. **Launch:** Start with 2-3 episodes, gather listener feedback

### Phase 4: Optimization (Ongoing)

13. **Monitor listener feedback:** Track skip rates on Science/Quirky vs Politics
14. **A/B test disclosure approaches:** Does a real-voice intro reduce AI detection complaints?
15. **Re-evaluate quarterly:** TTS quality is improving rapidly; reassess options every 3 months
16. **Consider Qwen3-TTS:** If GPU access becomes available, test as a zero-cost alternative

### Primary Recommendation: Fish Audio Plus (~$11/month)

**Why Fish Audio over ElevenLabs:**
- #1 on TTS-Arena2 (quality benchmark)
- 2x the included minutes at the same price point (~200 vs ~100)
- Story Studio purpose-built for podcast/audiobook content
- Simpler pricing (no confusing credit system)
- Explicit emotion control markers for different show tones
- 10-30 second sample requirement vs 1-5 min (or 30+ min for ElevenLabs PVC)

**Why not ElevenLabs:**
- ElevenLabs is excellent, but you pay a premium for the brand
- At the $11 Creator tier, you only get ~100 minutes (borderline for our volume with iteration)
- Professional Voice Cloning (their best quality) requires 30+ min of recording and identity verification
- The Pro plan ($99/mo) is overkill for our volume

**When to switch to ElevenLabs:**
- If blind testing reveals ElevenLabs handles Brett's specific Australian accent significantly better
- If Fish Audio API reliability proves problematic
- If the Eleven v3 Audio Tags for accent control prove essential for consistency

---

## Sources

- [Fish Audio - Pricing & Plans](https://fish.audio/plan/)
- [Fish Audio - Cheapest TTS API Cost Breakdown](https://fish.audio/blog/cheapest-text-to-speech-api-developers/)
- [Fish Audio - Voice Cloning Guide 2026](https://fish.audio/blog/ai-voice-cloning-complete-guide-2026/)
- [Fish Audio - TTS API Comparison](https://fish.audio/blog/text-to-speech-api-comparison-pricing-features/)
- [Fish Audio - Voice Cloning from Short Samples](https://fish.audio/blog/voice-cloning-software-short-sample/)
- [ElevenLabs - Pricing](https://elevenlabs.io/pricing)
- [ElevenLabs - Voice Cloning](https://elevenlabs.io/voice-cloning)
- [ElevenLabs - Australian Accent TTS](https://elevenlabs.io/text-to-speech/australian-accent)
- [ElevenLabs - Eleven v3 Audio Tags for Accents](https://elevenlabs.io/blog/eleven-v3-audio-tags-emulating-accents-with-precision)
- [ElevenLabs - Professional Voice Cloning Docs](https://elevenlabs.io/docs/creative-platform/voices/voice-cloning/professional-voice-cloning)
- [ElevenLabs - 7 Tips for Pro Voice Clones](https://elevenlabs.io/blog/7-tips-for-creating-a-professional-grade-voice-clone-in-elevenlabs)
- [ElevenLabs - Terms of Service](https://elevenlabs.io/terms-of-use)
- [ElevenLabs - Prohibited Use Policy](https://elevenlabs.io/use-policy)
- [Hume AI - Pricing](https://www.hume.ai/pricing)
- [Hume AI - Octave TTS Overview](https://www.hume.ai/blog/octave-the-first-text-to-speech-model-that-understands-what-its-saying)
- [Hume AI - Voice Cloning Docs](https://dev.hume.ai/docs/voice/voice-cloning)
- [Hume AI vs ElevenLabs Comparison](https://murf.ai/blog/hume-ai-vs-elevenlabs)
- [Qwen3-TTS GitHub Repository](https://github.com/QwenLM/Qwen3-TTS)
- [Qwen3-TTS Complete Guide (DEV Community)](https://dev.to/czmilo/qwen3-tts-the-complete-2026-guide-to-open-source-voice-cloning-and-ai-speech-generation-1in6)
- [Qwen3-TTS Performance Benchmarks & Hardware Guide](https://qwen3-tts.app/blog/qwen3-tts-performance-benchmarks-hardware-guide-2026)
- [Qwen3-TTS Hugging Face - CustomVoice Model](https://huggingface.co/Qwen/Qwen3-TTS-12Hz-1.7B-CustomVoice)
- [Resemble AI - Voice Cloning](https://www.resemble.ai/voice-cloning/)
- [Resemble AI - Recording Best Practices](https://knowledge.resemble.ai/how-do-i-make-sure-my-voice-clone-actually-sounds-good)
- [Resemble AI - Script Guidelines](https://www.resemble.ai/script-to-read-for-voice-cloning-guidelines/)
- [PlayHT vs Resemble AI Comparison](https://unrealspeech.com/compare/resemble-ai-vs-playht)
- [FTC Disclosure Rules for AI Likeness 2025](https://www.influencers-time.com/ftc-disclosure-rules-for-ai-likeness-in-2025-what-to-know/)
- [AI Legislation - State and Federal 2026](https://drata.com/blog/artificial-intelligence-regulations-state-and-federal-ai-laws-2026)
- [Speechmatics - Best TTS APIs 2026](https://www.speechmatics.com/company/articles-and-news/best-tts-apis-in-2025-top-12-text-to-speech-services-for-developers)
- [TTS Quality Evaluation Metrics (Zilliz)](https://zilliz.com/ai-faq/what-are-the-standard-evaluation-metrics-for-tts-quality)
- [MOS Test Methodology Critical Analysis (OpenReview)](https://openreview.net/forum?id=bnVBXj-mOc)
