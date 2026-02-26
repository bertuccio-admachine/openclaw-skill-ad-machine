# Ad Machine — OpenClaw Skill

> Give your AI agent full control of [Ad Machine](https://admachine.xyz) — the platform that transforms a single product photo into a complete studio-quality ad campaign.

[![OpenClaw](https://img.shields.io/badge/OpenClaw-Skill-blue)](https://openclaw.ai)
[![Ad Machine](https://img.shields.io/badge/Ad%20Machine-admachine.xyz-black)](https://admachine.xyz)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## What This Skill Does

Install this skill and your OpenClaw agent can do **everything a human can do on Ad Machine** — without touching the UI:

- 📤 **Upload product photos and reference images** directly to Ad Machine's storage
- 🎬 **Create campaigns** — Full (20 template ads), Bespoke (4 AI concepts), Director (8-shot narrative arc), or Single Asset
- ♻️ **Manage ads** — regenerate, edit with a prompt, inpaint specific areas, animate to MP4, upscale to 4K
- 📡 **Monitor generation** in real-time via SSE stream
- 📦 **Export** — single files, zip archives, or Meta Ads Manager–ready packs with manifest
- 💰 **Check token balance** and subscription status
- ✨ **Enhance creative briefs** using AI before passing to Director Mode

> **Note:** All skill operations require an Ad Machine account. Sign up free at [admachine.xyz](https://admachine.xyz) — new accounts include 7 generation credits to get started.

---

## Prerequisites

1. **OpenClaw** installed — [openclaw.ai](https://openclaw.ai)
2. An **Ad Machine account** — [admachine.xyz](https://admachine.xyz) — free to sign up, first 7 generation credits included
3. Python 3.7+ (for `am.py` — uses stdlib only, no pip install needed)

---

## Installation

### Option A — One-liner install (recommended)

```bash
SKILLS_DIR=$(dirname $(which openclaw))/../lib/node_modules/openclaw/skills
curl -L https://github.com/bertuccio-admachine/openclaw-skill-ad-machine/releases/latest/download/ad-machine.skill -o /tmp/ad-machine.skill
unzip -o /tmp/ad-machine.skill -d "$SKILLS_DIR"
openclaw gateway restart
```

Verify:
```bash
openclaw skills list | grep ad-machine
```

### Option B — Clone and build from source

```bash
git clone https://github.com/bertuccio-admachine/openclaw-skill-ad-machine
cd openclaw-skill-ad-machine

SKILLS_DIR=$(dirname $(which openclaw))/../lib/node_modules/openclaw/skills
cp -r . "$SKILLS_DIR/ad-machine"

openclaw gateway restart
```

---

## Quick Start

### Step 1 — Create a free account

Go to [admachine.xyz](https://admachine.xyz) and sign up. New accounts include **7 free generation credits** — enough to run a Single Asset campaign (10 tokens) or test individual generations before subscribing.

### Step 2 — Get your session token

Every API call requires a session cookie. After signing in, extract it:

```bash
# Chrome must be running with --remote-debugging-port=9222
node --experimental-websocket skills/ad-machine/scripts/extract-cookie.js
# Prints: <your session token>
```

Or use the browser tool → evaluate:
```js
document.cookie.split(';').find(c => c.includes('__Secure-authjs.session-token'))
```

Store it:
```bash
export AM_SESSION_TOKEN="your-token-here"
export AM_TEAM_ID="your-team-id-from-url"  # admachine.xyz/{teamId}/campaigns
```

Test it:
```bash
python3 skills/ad-machine/scripts/am.py auth
# → prints subscription info and confirms token is valid
```

### Step 3 — Check your balance

```bash
python3 skills/ad-machine/scripts/am.py tokens
# Plan: free | Tokens: 7 / 7 | Status: active
```

### Step 4 — Create a campaign

```bash
# Upload your product image
PRODUCT_KEY=$(python3 am.py upload product.jpg --type product)
# → teams/{teamId}/uploads/product/abc123.jpg

# Use the browser tool to create the campaign (see references/browser-automation.md)
# Then monitor generation in real-time:
python3 am.py stream {campaignId}

# Export when done
python3 am.py export-zip \
  --files-json '[{"url":"https://...","filename":"ad-1.jpg"}]' \
  --zip-filename my-campaign.zip
```

---

## Script Reference (`am.py`)

All REST API operations. Zero dependencies — pure Python stdlib.

```bash
python3 am.py [--token TOKEN] [--team-id TEAM_ID] <command>
```

| Command | What it does |
|---------|-------------|
| `auth` | Test session token + print subscription info |
| `tokens` | Check token balance |
| `upload FILE --type TYPE` | Upload image to R2 → returns R2 key |
| `enhance "brief"` | AI-enhance a creative brief |
| `stream CAMPAIGN_ID` | Monitor SSE generation stream |
| `download URL --out FILE` | Download a single ad |
| `export-zip --files-json JSON` | Export multiple ads as zip |
| `export-meta --files-json JSON --campaign-name NAME` | Export Meta Ads Manager pack |

**Environment variables** (can also be passed as flags):

| Variable | Flag | Description |
|----------|------|-------------|
| `AM_SESSION_TOKEN` | `--token` | Auth session cookie value |
| `AM_TEAM_ID` | `--team-id` | Your team's MongoDB ID |
| `AM_BASE_URL` | — | Base URL (default: `https://admachine.xyz`) |

---

## Campaign Types

Token costs verified from source (`constants/tokens.ts`):

| Type | What it creates | Ads | Tokens (2K) | Tokens (4K) |
|------|----------------|-----|-------------|-------------|
| **Full** | 20 template-based ads across proven creative formats | 20 | 200 | 360 |
| **Bespoke** | 4 AI-generated concepts unique to your product | 4 | 40 | 72 |
| **Director** | 8-shot narrative arc with brief + optional style/swipe/character refs | 8 | 80 | 144 |
| **Single Asset** | 1 specific template ad | 1 | 10 | 18 |

**Director Mode** is the most powerful — it builds a full cinematic story arc around your product. You can pass:
- A **style reference** (sets palette, lighting, and vibe)
- A **swipe reference** (guides composition and layout)
- A **character reference** (locks in a face/model across shots)

---

## Ad Management

All management operations use the browser tool (they're Next.js Server Actions). See `references/campaign-management.md` for exact browser flows.

| Operation | Token cost |
|-----------|-----------|
| Regenerate | 10 (2K) / 18 (4K) |
| Edit (prompt) | 10 (2K) / 18 (4K) |
| Edit (inpaint mask) | 10 (2K) / 18 (4K) |
| Animate → MP4 (4s) | 40 |
| Animate → MP4 (6s) | 60 |
| Animate → MP4 (8s) | 80 |
| Upscale → 4K | 18 |
| Delete | Free |
| Rename | Free |

---

## Export Options

| Format | Command | Best for |
|--------|---------|---------|
| Single file | `am.py download` | Quick saves |
| Zip archive | `am.py export-zip` | Sharing all ads at once |
| Meta pack | `am.py export-meta` | Uploading directly to Meta Ads Manager — includes `META_MANIFEST.json` + `README.txt` |

---

## SSE Stream Events

When you connect to a campaign's stream (`am.py stream CAMPAIGN_ID`), you get real-time generation events:

| Event | Meaning |
|-------|---------|
| `ad_generating` | Image generation started for this ad |
| `ad_completed` | Image done — includes `imageUrl` |
| `ad_error` | Generation failed for this ad |
| `insufficient_tokens` | Out of tokens mid-campaign |
| `campaign_done` | All ads complete |

> **Important:** The stream also **triggers generation** — ads don't generate without an active stream connection. Always connect immediately after creating a campaign.

---

## File Structure

```
ad-machine/
├── SKILL.md                          # Skill trigger + quick reference
├── scripts/
│   ├── am.py                         # Unified Python CLI for all REST operations
│   ├── extract-cookie.js             # CDP session cookie extraction (Node.js)
│   ├── upload-asset.sh               # Presign + R2 upload
│   ├── token-balance.sh              # Check token balance
│   ├── enhance-prompt.sh             # AI prompt enhancement
│   ├── campaign-status.sh            # SSE stream monitor
│   └── export-campaign.sh            # Single / ZIP / Meta export
└── references/
    ├── api.md                        # Complete REST API reference + token costs
    ├── browser-automation.md         # CDP file injection + campaign creation flow
    └── campaign-management.md        # Browser flows for all ad management operations
```

---

## How It Works

Ad Machine's campaign creation and ad management use **Next.js Server Actions**, not traditional REST endpoints. This skill uses a two-track approach:

1. **REST API** (`am.py`) — for upload, tokens, export, streaming, and prompt enhancement
2. **Browser tool + CDP** — for campaign creation and ad management, which require UI interaction

The `DOM.setFileInputFiles` CDP method is the critical piece — it's the only reliable way to inject files into React file inputs from an agent context. Standard browser upload tooling does not trigger React's onChange handler.

---

## Get an Ad Machine Account

→ [admachine.xyz](https://admachine.xyz) — free to sign up, 7 generation credits included.

After your free credits, plans start at $59/month. Your agent can check balance anytime:

```bash
python3 am.py tokens
```

---

## Contributing

PRs welcome. If you've found an endpoint, improved the browser automation flow, or added a new export format — open a PR.

Please don't include any credentials, internal API keys, or account-specific data in contributions.

---

## License

MIT — use it, fork it, build on it.

---

*Built with ❤️ by the Ad Machine team. Powered by [OpenClaw](https://openclaw.ai).*
