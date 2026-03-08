# Automated Podcast Distribution Guide

> Practical guide for programmatic podcast publishing from an n8n workflow.
> Budget target: EUR 200 total project cost.

---

## Table of Contents

1. [Podcast Hosting Platforms with APIs](#1-podcast-hosting-platforms-with-apis)
2. [Self-Hosted RSS Feed Option](#2-self-hosted-rss-feed-option)
3. [Distribution to Major Platforms](#3-distribution-to-major-platforms)
4. [YouTube Integration](#4-youtube-integration)
5. [Short-Form Clip Generation](#5-short-form-clip-generation)
6. [Social Media Auto-Posting](#6-social-media-auto-posting)
7. [Metadata and SEO](#7-metadata-and-seo)
8. [Recommended Budget Stack](#8-recommended-budget-stack)
9. [n8n Workflow Architecture](#9-n8n-workflow-architecture)

---

## 1. Podcast Hosting Platforms with APIs

### Comparison Matrix

| Platform | Free Tier | Paid From | API for Upload | Distribution | Analytics API |
|----------|-----------|-----------|----------------|-------------|---------------|
| **RSS.com** | Unlimited episodes, unlimited storage | EUR 11/mo | Yes - full CRUD | Auto to all majors | Yes |
| **Buzzsprout** | 2hrs/mo, 90-day hosting | EUR 17/mo | Yes - REST/JSON | Manual submit | Yes |
| **Podbean** | 5hrs total | EUR 14/mo | Yes - OAuth + upload | Auto to majors | Yes |
| **Transistor.fm** | None (14-day trial) | EUR 19/mo | Yes - REST/JSON | Auto to majors | Yes |
| **Spotify for Podcasters** | Unlimited, free | Free | No public API* | Spotify only + RSS | Limited |
| **Acast** | Free tier available | Free/EUR 15/mo | Distribution API only | Auto to majors | Yes |
| **Castopod** | Free (self-hosted) | Free | Yes - REST | Via RSS feed | Built-in |

*Spotify for Podcasters has no official upload API. A third-party automation tool exists (github.com/papsl/spotify-podcaster-uploader) but it's fragile and unsupported.

### Platform API Details

#### RSS.com (Best Budget Option with API)

- **API Key**: Generate up to 10 keys under Account Settings > API Access
- **Capabilities**: Upload audio, create/retrieve episodes, pull podcast data, generate transcripts and chapters, manage categories
- **Key advantage**: Every dashboard action can be triggered via API
- **Free tier**: Unlimited episodes and storage with auto-distribution to Apple Podcasts, Spotify, Amazon Music, and others
- **Limitation on free tier**: Branded "RSS.com" watermark, no custom domain

#### Buzzsprout

- **Base URL**: `https://www.buzzsprout.com/api/{podcast_id}/episodes.json`
- **Auth**: Token-based HTTP Authentication (`Authorization: Token token=your_api_token`)
- **Content-Type**: `application/json; charset=utf-8`
- **Create episode**: `POST /api/{podcast_id}/episodes.json`
- **Free tier limitation**: Episodes deleted after 90 days, 2 hours/month upload

#### Podbean

- **Docs**: `https://developers.podbean.com/podbean-api-docs/`
- **Auth**: OAuth 2.0 (access key + secret)
- **Upload flow**:
  1. Get access token via Authentication API
  2. Upload media file via File Upload API -> returns `media_key`
  3. Optionally upload episode logo -> returns `logo_key`
  4. Publish episode via Episode Publishing API using `media_key` + `logo_key`
- **Auto-social share**: Built-in auto-post to Facebook, Twitter, LinkedIn on new episodes

#### Transistor.fm

- **Docs**: `https://developers.transistor.fm/`
- **Auth**: API key in header
- **Create episode with remote audio**:
  - Use `episode[audio_url]` field with a publicly accessible URL
  - No need to upload the file separately
- **Upload flow** (if hosting audio yourself):
  1. `GET /v1/episodes/authorize_upload` -> returns presigned URL
  2. `PUT` audio file to presigned URL with correct `content_type` header
  3. Create episode referencing the uploaded file
- **Transcript support**: Add via API at creation or update time
- **Pricing**: Starts at EUR 19/mo, no free tier (only 14-day trial)

#### Castopod (Self-Hosted, Free)

- **Stack**: PHP + MySQL (like WordPress)
- **Install**: Docker or manual Linux setup
- **API**: REST API for programmatic podcast/episode management
- **Features**: Podcasting 2.0 support (chapters, transcripts, funding, persons), ActivityPub federation (your podcast becomes a Fediverse account), premium subscriptions, ad insertion
- **Hosting requirement**: Your own server (Oracle Cloud free tier works)
- **Best for**: Full control, zero recurring cost

### Verdict for Budget Projects

**RSS.com free tier** is the winner for a budget project: unlimited episodes, auto-distribution, and full API access. If you want maximum control and already have Oracle Cloud, **Castopod** is the self-hosted alternative.

---

## 2. Self-Hosted RSS Feed Option

If you want zero dependency on any hosting platform, you can generate and serve your own podcast RSS feed.

### Minimal RSS Feed Structure

```xml
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0"
     xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd"
     xmlns:podcast="https://podcastindex.org/namespace/1.0"
     xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>Your Podcast Name</title>
    <link>https://yoursite.com</link>
    <language>en</language>
    <description>Podcast description here</description>
    <atom:link href="https://yoursite.com/feed.xml" rel="self" type="application/rss+xml"/>

    <itunes:author>Author Name</itunes:author>
    <itunes:summary>Podcast summary</itunes:summary>
    <itunes:image href="https://yoursite.com/artwork.jpg"/>
    <itunes:category text="Technology"/>
    <itunes:explicit>false</itunes:explicit>
    <itunes:owner>
      <itunes:name>Owner Name</itunes:name>
      <itunes:email>owner@example.com</itunes:email>
    </itunes:owner>

    <item>
      <title>Episode 1: Title Here</title>
      <description>Episode description</description>
      <enclosure url="https://yoursite.com/episodes/ep001.mp3"
                 length="12345678"
                 type="audio/mpeg"/>
      <guid isPermaLink="false">ep001-unique-id</guid>
      <pubDate>Mon, 01 Jan 2026 08:00:00 +0000</pubDate>
      <itunes:duration>00:25:30</itunes:duration>
      <itunes:summary>Episode summary</itunes:summary>
      <itunes:image href="https://yoursite.com/ep001-art.jpg"/>
      <itunes:explicit>false</itunes:explicit>

      <!-- Podcast 2.0 namespace extras -->
      <podcast:transcript url="https://yoursite.com/episodes/ep001.srt" type="application/srt"/>
      <podcast:chapters url="https://yoursite.com/episodes/ep001-chapters.json" type="application/json+chapters"/>
    </item>
  </channel>
</rss>
```

### Technical Requirements

- **Artwork**: Square 1400x1400 to 3000x3000 pixels, PNG or JPG
- **Encoding**: UTF-8, plain text (no HTML in fields unless CDATA-wrapped)
- **Server**: Must support HTTP HEAD requests and byte-range requests for audio streaming
- **HTTPS**: Required by Apple Podcasts and Spotify
- **Enclosure**: Each episode needs `url`, `length` (file size in bytes), and `type` (MIME type)

### Hosting on Oracle Cloud Free Tier

- Serve the XML feed and MP3 files from an Oracle Cloud object storage bucket or an Always Free compute instance running Nginx
- Use n8n to regenerate the XML feed whenever a new episode is produced
- Total cost: EUR 0

### Useful Tool

- **podcast-rss-generator** (github.com/vpetersson/podcast-rss-generator): A simple script that generates Apple Podcasts / Amazon Podcasts compatible RSS feeds for self-hosted audio

### Trade-offs vs Hosted Platform

| | Self-Hosted RSS | RSS.com Free |
|---|---|---|
| Cost | EUR 0 | EUR 0 |
| Setup effort | High (XML gen, server config) | Low (dashboard + API) |
| Auto-distribution submission | Manual (one-time per platform) | Automatic |
| Analytics | DIY (parse server logs) | Built-in dashboard |
| Reliability | Your responsibility | Managed |
| Vendor lock-in | None | Low (RSS is portable) |

**Recommendation**: Use RSS.com free tier for ease. Self-host only if you need full control or want to avoid any third-party dependency.

---

## 3. Distribution to Major Platforms

### How Podcast Distribution Actually Works

All major podcast platforms consume your RSS feed. You submit the feed URL once, and they poll it for new episodes. There is no need to "upload" to each platform separately.

### Platform-by-Platform Breakdown

| Platform | Submission Method | Update Mechanism | Typical Delay | Notes |
|----------|------------------|-----------------|---------------|-------|
| **Apple Podcasts** | Manual via Podcasts Connect | RSS poll | 24-48hrs first time, then ~1hr | Review required for first submission; up to 10 business days |
| **Spotify** | Manual via Spotify for Podcasters, or Distribution API via partner hosts | RSS poll | Minutes to hours | Email verification required; Distribution API for Acast/Libsyn/Omny/Audioboom/Podigee partners |
| **Amazon Music** | Manual via Amazon Music for Podcasters | RSS poll | 24-48hrs | One-time submission |
| **Google Podcasts** | Deprecated (migrated to YouTube Music) | N/A | N/A | Use YouTube podcast uploads instead |
| **YouTube Music** | Via YouTube Studio (mark as podcast) | RSS import or manual upload | Hours | Set playlist as "podcast" type |
| **Pocket Casts** | Submit RSS URL on their site | RSS poll | Minutes | Very fast indexing |
| **Podcast Index** | Submit RSS URL | RSS poll | Minutes | Powers many smaller apps |
| **Overcast, Castro, etc.** | Auto-discovered via Apple Podcasts or Podcast Index | RSS poll | Hours | No manual submission needed |

### Key Insight

**You submit your RSS feed once per platform (manual, ~30 minutes total for all platforms). After that, everything is automatic -- new episodes appear when platforms poll your feed.** The only "API integration" needed is keeping your RSS feed updated. RSS.com and Castopod handle this automatically when you publish via their API.

### Spotify Distribution API (Partner Hosts Only)

As of January 2026, Spotify's Distribution API is limited to partner hosting platforms (Acast, Audioboom, Libsyn, Omny, Podigee). It primarily enables video podcast distribution. For audio-only podcasts, standard RSS submission works fine.

---

## 4. YouTube Integration

### Why YouTube Matters for Podcasts

YouTube is now the #1 podcast consumption platform. YouTube Music also indexes podcast playlists. A simple static-image video for each episode captures this audience.

### Generating Podcast Videos with FFmpeg

#### Basic: Static Image + Audio

```bash
ffmpeg -loop 1 -i cover.jpg -i episode.mp3 \
  -c:v libx264 -tune stillimage \
  -c:a aac -b:a 192k \
  -pix_fmt yuv420p \
  -shortest \
  output.mp4
```

#### With Waveform Audiogram

```bash
ffmpeg -y -i episode.mp3 -loop 1 -i cover.png \
  -filter_complex \
    "[0:a]showwaves=s=1920x200:colors=0x4488ff:mode=cline,format=rgba[wave]; \
     [1:v]scale=1920:1080[bg]; \
     [bg][wave]overlay=0:880[outv]" \
  -map "[outv]" -map 0:a \
  -c:v libx264 -c:a aac -b:a 192k \
  -pix_fmt yuv420p -shortest \
  audiogram.mp4
```

#### With Title Card Overlay

```bash
ffmpeg -loop 1 -i cover.jpg -i episode.mp3 \
  -vf "drawtext=text='Episode 1 - Title Here': \
       fontcolor=white:fontsize=48: \
       x=(w-text_w)/2:y=h-100: \
       box=1:boxcolor=black@0.6:boxborderw=10" \
  -c:v libx264 -tune stillimage \
  -c:a aac -b:a 192k \
  -pix_fmt yuv420p -shortest \
  titled_output.mp4
```

### YouTube Data API v3 - Automated Upload

#### Setup

1. Go to Google Cloud Console -> APIs & Services -> Enable "YouTube Data API v3"
2. Create OAuth 2.0 credentials (type: Web Application or Desktop)
3. Authorize with scopes: `https://www.googleapis.com/auth/youtube.upload`

#### API Endpoint

```
POST https://www.googleapis.com/upload/youtube/v3/videos?part=snippet,status
```

#### Quota

- Default: 10,000 units/day
- Video upload cost: **1,600 units per upload**
- This means **6 uploads per day maximum** on the default quota
- For a weekly podcast, this is more than sufficient
- Quota is free (no monetary cost for the API itself)

#### Upload via n8n

Use the **HTTP Request** node with OAuth2 credentials:

1. **Google OAuth2 credential** in n8n with YouTube upload scope
2. **HTTP Request node** configured as:
   - Method: POST
   - URL: `https://www.googleapis.com/upload/youtube/v3/videos?uploadType=resumable&part=snippet,status`
   - Headers: `Content-Type: application/json`
   - Body (JSON):
     ```json
     {
       "snippet": {
         "title": "Episode Title",
         "description": "Episode description with show notes",
         "tags": ["podcast", "your-topic"],
         "categoryId": "22"
       },
       "status": {
         "privacyStatus": "public",
         "selfDeclaredMadeForKids": false
       }
     }
     ```
3. Second HTTP Request to upload the actual video binary to the resumable upload URI returned in step 1

#### YouTube Podcast Playlist

Mark a YouTube playlist as a "Podcast" in YouTube Studio. Episodes added to this playlist will appear in YouTube Music as podcast episodes. Add each uploaded video to this playlist via:

```
POST https://www.googleapis.com/youtube/v3/playlistItems?part=snippet
```

Cost: 50 units per insert.

---

## 5. Short-Form Clip Generation

### Option A: FFmpeg-Based (Free, Full Control)

Best for budget projects. Extract segments from the full episode audio and create vertical video clips.

#### Extract Audio Segment

```bash
ffmpeg -i episode.mp3 -ss 00:05:30 -t 00:00:60 -c copy clip.mp3
```

#### Create Vertical Short (1080x1920) with Waveform

```bash
ffmpeg -y -i clip.mp3 -loop 1 -i cover_vertical.png \
  -filter_complex \
    "[0:a]showwaves=s=1080x200:colors=0xff6644:mode=cline,format=rgba[wave]; \
     [1:v]scale=1080:1920[bg]; \
     [bg][wave]overlay=0:1600[outv]" \
  -map "[outv]" -map 0:a \
  -c:v libx264 -c:a aac -b:a 128k \
  -pix_fmt yuv420p -shortest \
  short_clip.mp4
```

#### Add Subtitles (requires transcript)

```bash
ffmpeg -i short_clip.mp4 \
  -vf "subtitles=clip.srt:force_style='FontSize=24,PrimaryColour=&Hffffff&'" \
  -c:v libx264 -c:a copy \
  short_with_subs.mp4
```

#### In n8n

- Use the **Execute Command** node (self-hosted n8n only, not n8n Cloud)
- Or use the community **n8n-nodes-ffmpeg** package (npm: `@raisaroj/n8n-nodes-ffmpeg` or `@saitrogen/n8n-nodes-ffmpeg`)
- Workflow: Write Binary File -> Execute FFmpeg -> Read Binary File -> Upload

#### Automated Clip Selection with AI

Use an LLM node in n8n to analyze the transcript and identify the most engaging 60-second segments. Feed timestamps back to FFmpeg for extraction. This replaces Opus Clip's AI highlight detection at zero cost.

### Option B: Opus Clip API (Paid, AI-Powered)

- **Status**: Closed beta, requires annual Pro plan (20+ packs, approximately EUR 200+/year)
- **API capabilities**: Send long-form video, receive AI-generated short clips with captions
- **Rate limit**: ~30 requests/minute
- **Verdict for EUR 200 budget**: Too expensive. Skip.

### Option C: Headliner (Manual/Semi-Auto)

- Free tier: 5 audiograms/month with watermark
- No public API for automation
- Good for one-off clips, not for automated pipeline

### Option D: Upload-Post.com

- Free tier: 2 profiles, 10 uploads/month
- Has an official n8n node
- Built-in FFmpeg video processing (auto-resize per platform)
- Better suited as a distribution tool than a clip creation tool

### Verdict

**FFmpeg + AI transcript analysis in n8n** is the only option that fits a EUR 200 budget and is fully automatable. Use the LLM to pick highlight timestamps, FFmpeg to cut and render clips.

---

## 6. Social Media Auto-Posting

### Direct API Approach

| Platform | API | Free Tier | n8n Node | Notes |
|----------|-----|-----------|----------|-------|
| **X (Twitter)** | X API v2 | 500 posts/month (free) | Yes (built-in) | Free tier is write-only (can post, cannot read). New pay-as-you-go pricing launched Feb 2026. |
| **LinkedIn** | Posts API | Free (with developer app) | Yes (built-in) | Requires OAuth 2.0, scope `w_member_social`. Must create a LinkedIn Company Page. |
| **Instagram** | Meta Graph API | Free (business account) | Yes (via HTTP Request) | Business/Creator account required. Two-step process: create container -> publish. Supports Reels. Max 50 posts/24hrs. |
| **Facebook** | Graph API | Free (page required) | Yes (built-in) | Post to Pages only (not personal profiles). |
| **TikTok** | Content Posting API | Free (creator account) | Via HTTP Request | Limited; requires app review. |
| **Bluesky** | AT Protocol | Free | Via HTTP Request | Open protocol, easy to automate. |
| **Threads** | Meta Threads API | Free | Via HTTP Request | Relatively new API, similar to Instagram Graph API. |

### Instagram Reels Upload (Meta Graph API)

Two-step process:

```
Step 1: Create container
POST /{ig-user-id}/media
  media_type=REELS
  video_url=https://yoursite.com/clip.mp4
  caption=Episode highlight text #podcast

Step 2: Publish (after processing completes)
POST /{ig-user-id}/media_publish
  creation_id={container-id}
```

Important: Poll the container status before publishing. Video processing takes time on Meta's servers.

### Aggregator Approach: Blotato or Upload-Post

Instead of managing 5+ platform APIs individually, use an aggregator:

#### Blotato (EUR 19/mo)

- Posts to: Instagram, TikTok, YouTube, Facebook, X, LinkedIn, Threads, Bluesky, Pinterest
- Official n8n integration node
- One API call -> posts to all platforms
- 7-day free trial only, then paid

#### Upload-Post (Free tier available)

- Free: 2 profiles, 10 uploads/month
- Official n8n node
- Built-in FFmpeg processing (auto-resize per platform)
- Paid from EUR 16/mo for more profiles

#### Buffer API

- Free tier: 3 social channels, 10 scheduled posts per channel per month
- No official n8n node (use HTTP Request)
- API endpoint: `https://api.bufferapp.com/1/updates/create.json`
- Decent for low-volume posting

### n8n Social Posting Workflow Templates

Pre-built templates available at n8n.io:
- **Workflow #4637**: AI content generation + posting to Instagram, Facebook, LinkedIn, X
- **Workflow #5457**: Instagram + Facebook via Meta Graph API with System User Tokens
- **Workflow #3082**: Social media content generator + publisher for X and LinkedIn

### Recommended Approach for Budget Project

1. **X and LinkedIn**: Use direct APIs via n8n built-in nodes (free)
2. **Instagram and Facebook**: Use Meta Graph API via n8n HTTP Request node (free, but requires Business account setup)
3. **YouTube**: Already handled via YouTube Data API (see Section 4)
4. **TikTok**: Upload-Post free tier or manual posting initially
5. **Skip paid aggregators** unless posting volume justifies the cost

---

## 7. Metadata and SEO

### ID3 Tags for MP3 Files

Set metadata on your MP3 files before uploading. This ensures correct display in podcast apps even if RSS metadata fails to load.

#### Using FFmpeg

```bash
ffmpeg -i episode.mp3 \
  -metadata title="Episode 1: Title Here" \
  -metadata artist="Podcast Name" \
  -metadata album="Podcast Name" \
  -metadata date="2026" \
  -metadata genre="Podcast" \
  -metadata comment="Episode description" \
  -metadata track="1" \
  -c copy \
  episode_tagged.mp3
```

#### Add Cover Art to MP3

```bash
ffmpeg -i episode.mp3 -i cover.jpg \
  -map 0 -map 1 \
  -c copy \
  -metadata:s:v title="Album cover" \
  -metadata:s:v comment="Cover (front)" \
  episode_with_art.mp3
```

#### Using Python mutagen (for more control)

```python
from mutagen.mp3 import MP3
from mutagen.id3 import ID3, TIT2, TPE1, TALB, TDRC, TCON, COMM, APIC, TDES, WFED

audio = MP3("episode.mp3", ID3=ID3)
audio.tags.add(TIT2(encoding=3, text="Episode Title"))
audio.tags.add(TPE1(encoding=3, text="Author Name"))
audio.tags.add(TALB(encoding=3, text="Podcast Name"))
audio.tags.add(TDRC(encoding=3, text="2026"))
audio.tags.add(TCON(encoding=3, text="Podcast"))

# iTunes-specific podcast tags
audio.tags.add(TDES(encoding=3, text="Episode description"))
audio.tags.add(WFED(url="https://yoursite.com/feed.xml"))

# Embed cover art
with open("cover.jpg", "rb") as f:
    audio.tags.add(APIC(encoding=3, mime="image/jpeg", type=3, desc="Cover", data=f.read()))

audio.save()
```

### Chapter Markers

Two approaches for chapter support:

#### 1. Embedded ID3 Chapters (in MP3 file)

Supported by Apple Podcasts, Overcast, and some other players. Requires ID3v2 CHAP frames. Best set via mutagen or specialized tools.

#### 2. Podcast Namespace JSON Chapters (in RSS feed)

More widely supported in modern apps. Add to your RSS feed:

```xml
<podcast:chapters url="https://yoursite.com/ep001-chapters.json" type="application/json+chapters"/>
```

Chapter JSON format:

```json
{
  "version": "1.2.0",
  "chapters": [
    {
      "startTime": 0,
      "title": "Introduction",
      "img": "https://yoursite.com/ch1.jpg",
      "url": "https://yoursite.com/related-link"
    },
    {
      "startTime": 180,
      "title": "Main Topic"
    },
    {
      "startTime": 900,
      "title": "Wrap Up"
    }
  ]
}
```

### Transcripts in RSS

Add to each `<item>`:

```xml
<podcast:transcript url="https://yoursite.com/ep001.srt" type="application/srt"/>
```

Supported formats: SRT, VTT, JSON (podcasting 2.0 spec). Transcripts improve discoverability in Apple Podcasts and Spotify search.

### Episode Description Best Practices

- First 2 sentences are critical (shown in previews)
- Include timestamps/chapter markers in text form
- Add relevant keywords naturally
- Link to show notes, resources mentioned
- Include a call to action (subscribe, review, share)

### Show Notes Generation in n8n

Use an LLM node to generate structured show notes from the transcript:
- Summary paragraph
- Key topics with timestamps
- Links mentioned
- Guest information (if applicable)

---

## 8. Recommended Budget Stack

### Total Cost Breakdown

| Component | Solution | Cost |
|-----------|----------|------|
| Podcast hosting | RSS.com free tier | EUR 0 |
| Audio file storage | Oracle Cloud free tier (10GB object storage) | EUR 0 |
| Workflow automation | n8n self-hosted on Oracle Cloud | EUR 0 |
| YouTube upload | YouTube Data API v3 | EUR 0 |
| Video generation | FFmpeg (on n8n server) | EUR 0 |
| Social posting (X) | X API v2 free tier | EUR 0 |
| Social posting (LinkedIn) | LinkedIn API free | EUR 0 |
| Social posting (Instagram/FB) | Meta Graph API free | EUR 0 |
| Clip generation | FFmpeg + AI highlight detection | EUR 0 |
| Domain name | Optional custom domain | EUR 10-15/year |
| **Total recurring** | | **EUR 0-15/year** |

### What the EUR 200 Budget Should Go To

Since the distribution stack can be entirely free, allocate the EUR 200 budget to:

| Priority | Item | Estimated Cost |
|----------|------|---------------|
| 1 | Voice generation API credits (ElevenLabs, etc.) | EUR 80-120 |
| 2 | LLM API credits (script generation, show notes) | EUR 40-60 |
| 3 | Domain name (1 year) | EUR 10-15 |
| 4 | Buffer for unexpected costs | EUR 20-30 |
| | **Total** | **EUR 150-225** |

### Why Not Self-Hosted RSS?

While self-hosting the RSS feed on Oracle Cloud costs EUR 0, RSS.com free tier is better because:
- Automatic submission to all major directories
- Built-in analytics
- API for automated publishing
- Zero server maintenance for the feed
- You can always export your RSS and move later

---

## 9. n8n Workflow Architecture

### Complete Pipeline Overview

```
Trigger (Schedule/Webhook)
    |
    v
[Script Generation] -- LLM node (GPT/Claude)
    |
    v
[Voice Generation] -- HTTP Request to TTS API
    |
    v
[Audio Post-Processing] -- Execute Command (FFmpeg)
    |  - Normalize audio levels
    |  - Add intro/outro
    |  - Set ID3 tags
    |
    +---> [Full Episode Distribution]
    |       |
    |       +---> Upload to RSS.com via API (triggers RSS update)
    |       |       POST /episodes with audio file + metadata
    |       |
    |       +---> Generate YouTube video (FFmpeg: image + audio -> MP4)
    |       |       -> Upload via YouTube Data API v3
    |       |       -> Add to Podcast playlist
    |       |
    |       +---> Generate show notes (LLM from transcript)
    |       +---> Generate chapters JSON
    |
    +---> [Short-Form Clips]
    |       |
    |       +---> Analyze transcript for highlights (LLM node)
    |       +---> Extract clips (FFmpeg with timestamps)
    |       +---> Create vertical videos with waveform + subtitles
    |       |
    |       +---> Upload to YouTube Shorts (YouTube API)
    |       +---> Post to Instagram Reels (Meta Graph API)
    |       +---> Post to TikTok (Content Posting API or manual)
    |
    +---> [Social Media Announcements]
            |
            +---> X/Twitter post with episode link
            +---> LinkedIn post with episode summary
            +---> Facebook page post
```

### Key n8n Nodes Used

| Task | n8n Node | Notes |
|------|----------|-------|
| Schedule trigger | Cron node | Weekly or as needed |
| LLM calls | OpenAI / Anthropic node | Script, show notes, highlight detection |
| TTS API | HTTP Request node | ElevenLabs, Google TTS, etc. |
| FFmpeg processing | Execute Command node | Self-hosted n8n only |
| RSS.com upload | HTTP Request node | POST with API key auth |
| YouTube upload | HTTP Request node + OAuth2 | Google OAuth2 credentials |
| X/Twitter post | X (Twitter) node | Built-in, uses API v2 |
| LinkedIn post | LinkedIn node | Built-in, OAuth2 |
| Instagram post | HTTP Request node | Meta Graph API, two-step process |
| File handling | Read/Write Binary File | For passing files between nodes |
| Branching | Split In Batches / IF | Process clips in parallel |

### FFmpeg on n8n: Important Notes

- **Execute Command** node only works on self-hosted n8n (not n8n Cloud)
- FFmpeg must be installed on the n8n server (`apt install ffmpeg` on Ubuntu)
- Community nodes exist (`n8n-nodes-ffmpeg` on npm) but the Execute Command approach is more reliable
- For Docker deployments, use an n8n image with FFmpeg pre-installed (see github.com/yigitkonur/n8n-docker-ffmpeg)
- Watch memory: n8n loads binary data into RAM. A 50MB podcast episode is fine; a 2GB video file needs careful handling with direct file paths instead of binary data nodes

### Credential Setup Checklist

| Service | What You Need |
|---------|--------------|
| RSS.com | API key (Account Settings > API Access) |
| YouTube | Google Cloud project + OAuth2 client ID/secret + YouTube API enabled |
| X/Twitter | Developer account + API key/secret + Bearer token |
| LinkedIn | Developer app + OAuth2 client ID/secret + Company Page |
| Instagram/FB | Meta Developer account + Facebook App + Business Account + Graph API access |
| TTS service | API key (varies by provider) |
| LLM service | API key (OpenAI/Anthropic) |

---

## Quick Start Checklist

1. [ ] Sign up for RSS.com free tier, create your podcast show
2. [ ] Generate RSS.com API key
3. [ ] Submit your RSS feed URL to Apple Podcasts, Spotify, Amazon Music, Podcast Index (one-time, manual)
4. [ ] Set up Google Cloud project, enable YouTube Data API v3, create OAuth2 credentials
5. [ ] Set up X/Twitter developer account (free tier)
6. [ ] Set up LinkedIn developer app with posting permissions
7. [ ] Set up Meta developer account + Facebook App for Instagram/FB posting
8. [ ] Deploy n8n on Oracle Cloud with FFmpeg installed
9. [ ] Build the n8n workflow following the architecture above
10. [ ] Create podcast artwork (3000x3000 for RSS, 1920x1080 for YouTube, 1080x1920 for Shorts)
11. [ ] Test the full pipeline with a pilot episode
12. [ ] Monitor RSS feed polling -- first episodes may take 24-48 hours to appear on platforms

---

## Sources

### Podcast Hosting and APIs
- [RSS.com Free Podcast Hosting](https://rss.com/)
- [RSS.com API Access Documentation](https://help.rss.com/en/support/solutions/articles/44002648949-api-access)
- [RSS.com API Announcement](https://rss.com/blog/our-api-is-live-3-podcast-automation-workflows-you-can-use-right-now/)
- [Buzzsprout API (GitHub)](https://github.com/buzzsprout/buzzsprout-api)
- [Podbean API Documentation](https://developers.podbean.com/podbean-api-docs/)
- [Transistor.fm API Reference](https://developers.transistor.fm/)
- [Castopod - Open Source Podcast Host](https://castopod.org/)
- [Castopod API Documentation](https://docs.castopod.org/next/en/api/)

### RSS Feed Specifications
- [Apple Podcasts RSS Requirements](https://podcasters.apple.com/support/823-podcast-requirements)
- [Podcast RSS Feed Guide (RSS Validator)](https://rssvalidator.app/podcast-rss-guide)
- [Podcast Namespace Example XML (GitHub)](https://github.com/Podcastindex-org/podcast-namespace/blob/main/example.xml)
- [Podcast Standards Project RSS Spec](https://github.com/Podcast-Standards-Project/PSP-1-Podcast-RSS-Specification)
- [podcast-rss-generator (GitHub)](https://github.com/vpetersson/podcast-rss-generator)
- [Self-Host Your Podcast (Lime Link)](https://blog.lime.link/how-to-self-host-your-podcast/)

### YouTube Integration
- [YouTube Data API v3 - Videos Insert](https://developers.google.com/youtube/v3/docs/videos/insert)
- [YouTube Upload API Guide 2026](https://getlate.dev/blog/youtube-upload-api)
- [YouTube API Quota Calculator](https://developers.google.com/youtube/v3/determine_quota_cost)

### FFmpeg and Video Processing
- [Generating Podcast Audiograms with FFmpeg](https://talesfromtrantor.com/behind-the-scenes/generating-audiograms-with-ffmpeg/)
- [Audio to Video for YouTube (Bannerbear)](https://www.bannerbear.com/blog/how-to-convert-audio-to-video-for-youtube-upload-using-ffmpeg/)
- [n8n FFmpeg Media Processing Guide](https://logicworkflow.com/blog/n8n-ffmpeg-media-processing/)
- [n8n + FFmpeg Docker Stack (GitHub)](https://github.com/yigitkonur/n8n-docker-ffmpeg)

### Short-Form Clips
- [Automate Podcast Clips to Social Media (Upload-Post)](https://www.upload-post.com/how-to/automate-podcast-clips-to-social-media)
- [Opus Clip API Guide (Clippie)](https://clippie.ai/blog/how-to-use-the-opus-pro-api-to-power-your-clipping-workflow-in-2025)
- [Best AI Podcast Clip Makers 2026 (Choppity)](https://www.choppity.com/blog/best-ai-podcast-clip-makers-generators)

### Social Media APIs
- [n8n Social Media Automation Templates](https://n8n.io/workflows/4637-automate-social-media-content-with-ai-for-instagram-facebook-linkedin-and-x/)
- [X/Twitter API Pricing 2026](https://getlate.dev/blog/twitter-api-pricing)
- [LinkedIn Posts API (Microsoft)](https://learn.microsoft.com/en-us/linkedin/marketing/community-management/shares/posts-api)
- [Instagram Graph API - Content Publishing](https://developers.facebook.com/docs/instagram-platform/content-publishing/)
- [Instagram Reels via Graph API](https://business-automated.medium.com/posting-instagram-reels-via-instagram-facebook-graph-api-9ea192d54dfa)
- [Blotato + n8n Integration](https://n8n.io/integrations/blotato/)

### Metadata
- [Creating ID3 Tags with FFmpeg](https://jmesb.com/how_to/create_id3_tags_using_ffmpeg)
- [Podcast Chapters App - ID3 Version Support](https://chaptersapp.com/support/id3-version/)
- [Podcast Namespace Chapters (GitHub)](https://github.com/Podcastindex-org/podcast-namespace/issues/47)
