# Content Strategy — Social Distribution Playbook

Source: [Ruben Hassid — "1,000,000." (Substack)](https://ruben.substack.com/p/1000000), shared by Farid.
Notion KB: [Content Formatting Patterns](https://www.notion.so/3134d347036281e99388eb599aa41b7c)

---

## Core Principle

**Content must be useful to the READER, not about you.**

People don't follow because of your achievements — they follow because you help them. Frame everything as "here's what this means for *you*" not "here's what *I* think."

For Brett: His podcast social posts should frame insights as valuable to the listener — geopolitics that affects *your* life, tech disruption *you* need to understand. Brett's legal/analytical credibility is the *why they trust it*, not the *why they click*.

---

## Hooks — The Only Part That Matters

A LinkedIn hook = **2 sentences, ~55 characters** before the "...more" button. If they don't click, nothing else matters.

### Rules
- Must be about the READER or a universal tension — never about you
- Create an open loop: unanswered question, contradiction, or bold claim
- No personal achievements, no emojis, no hashtags, no jargon
- Should feel like a friend's text that makes you reply "wait, explain"

### 5 Hook Techniques

| # | Technique | How it works | Example |
|---|---|---|---|
| 1 | Contradiction | Say something that sounds wrong | "The worst LinkedIn posts get the most followers." |
| 2 | Specific number + unexpected context | Data point that surprises | "I mass-unfollowed 2,000 people. My engagement tripled." |
| 3 | Direct accusation | Call the reader out | "You're writing posts for your mom, not your audience." |
| 4 | Stolen thought | Say what reader secretly thinks | "You know your posts are boring. So does everyone scrolling past them." |
| 5 | Absurd reframe | Make something mundane dramatic | "Your post has 1.2 seconds to live. Most die instantly." |

### AI Workflow for Hooks
Claude won't write the perfect hook in one shot. Generate 100 variations → taste picks one → post → experience sharpens taste over time.

**Pipeline implication:** Every podcast episode clip and social post should go through a hook generation step. Claude produces variations using these 5 techniques, team or Brett picks the best one.

---

## Media Strategy

The image takes **80% of the screen** on LinkedIn. The hook takes 20%. The rest of the text: 0%.

### What Works
- **1080 x 1350** single image
- Looks **scrappy, unbranded** — not polished or corporate
- Useful enough to save or send to a colleague

### What Doesn't Work
- "Text is what matters" → No, only hook + media matter
- "Videos are the best format" → No, people on LinkedIn are at work, not binge-watching
- "I need strong branding" → No, the more it looks like an ad, the worse it performs

### Media Creation Workflow
1. Pinterest → search "[topic] + infographic" or "cheat sheet"
2. Download a reference infographic
3. Gemini → upload → reverse-prompt to extract design brief
4. Find a "handwritten style" infographic on Pinterest (organic, NOT ad-like)
5. Gemini → combine data brief + handwritten style → remakes it

**Pipeline implication:** Podcast visuals should look like hand-drawn infographics or notebook-style summaries, not polished graphics. Angelo's visual research should follow this direction.

---

## Consistency

No secret AI prompt makes you consistent. Post daily, 30 min total:
- 20 min: prepare the post
- 10 min: engage with comments and DMs

Action produces information. Posting more gives you the keys to post better.

**Pipeline implication:** The n8n automation must support a reliable, consistent publishing cadence — not sporadic bursts.

---

## How This Connects to Our Pipeline

| Pipeline Stage | What This Article Adds |
|---|---|
| Step 5: Script Writing | Frame content as useful to listener, not about Brett |
| Step 6: Engaging Output | Hook generation step — 5 techniques, 100 variations |
| Step 7: Brett Review | Brett's taste picks the best hook/angle |
| Visual creation | Scrappy infographic style, Pinterest→Gemini workflow |
| Social distribution | Consistent cadence, daily or multi-weekly |
| Claude context | `brett-profile.md` = Ruben's "about me" file — already built |
