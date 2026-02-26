# Ad Machine — OpenClaw Skill

> Give your AI agent full control of [Ad Machine](https://admachine.xyz) — the platform that transforms a single product photo into a complete studio-quality ad campaign.

[![OpenClaw](https://img.shields.io/badge/OpenClaw-Skill-blue)](https://openclaw.ai)
[![Ad Machine](https://img.shields.io/badge/Ad%20Machine-admachine.xyz-black)](https://admachine.xyz)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## What This Skill Does

Install this skill and your OpenClaw agent can do **everything a human can do on Ad Machine** — without touching the UI:

- 🆓 **Run the free onboarding demo** — 7 studio-quality ads from one product photo, no subscription required
- 📤 **Upload product photos and reference images** directly to Ad Machine's storage
- 🎬 **Create campaigns** — Full (8 templates), Bespoke (5 AI concepts), Director (8-shot narrative arc), or Single Asset
- ♻️ **Manage ads** — regenerate, edit with a prompt, inpaint specific areas, animate to MP4, upscale to 4K
- 📡 **Monitor generation** in real-time via SSE stream
- 📦 **Export** — single files, zip archives, or Meta Ads Manager–ready packs with manifest
- 💰 **Check token balance** and subscription status
- ✨ **Enhance creative briefs** using AI before passing to Director Mode

---

## Prerequisites

1. **OpenClaw** installed — [openclaw.ai](https://openclaw.ai)
2. An **Ad Machine account** — [admachine.xyz](https://admachine.xyz) (free to sign up, first 7 ads are on them)
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

# Copy skill files into OpenClaw
SKILLS_DIR=$(dirname $(which openclaw))/../lib/node_modules/openclaw/skills
cp -r . "$SKILLS_DIR/ad-machine"

openclaw gateway restart
```

---

## Quick Start

### Step 1 — Get your session token

Your agent needs a session cookie to authenticate API calls. After signing in to Ad Machine, your agent can extract it:

```
browser → navigate to https://admachine.xyz → sign in
browser → evaluate:
  document.cookie.split(';').find(c => c.includes('__Secure-authjs.session-token'))
```

Or use CDP `Storage.getCookies` (see `references/browser-automation.md` for exact steps).

Store it:
```bash
export AM_SESSION_TOKEN="your-token-here"
export AM_TEAM_ID="your-team-id-from-url"  # e.g. admachine.xyz/{teamId}/campaigns
```

Test it:
```bash
python3 skills/ad-machine/scripts/am.py auth
```

### Step 2 — Run the free demo (first time)

New accounts get **7 free ads** from one product photo — no subscription, no tokens deducted.

```bash
# Upload your product photo
python3 am.py upload product.jpg --type product
# → teams/{teamId}/uploads/product/abc123.jpg

# Navigate to onboarding in browser, inject the image, let it generate
# See references/browser-automation.md for the exact CDP flow
```

7 styles generate automatically: Cinematic · Lifestyle · Vintage · Studio · Octane · Poster · Editorial

### Step 3 — Create a full campaign

Once you have a subscription:

```bash
# Upload product image
PRODUCT_KEY=$(python3 am.py upload product.jpg --type product)

# Create campaign via browser (see browser-automation.md for full flow)
# Then monitor generation
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

| Type | What it creates | Token cost (2K) | Token cost (4K) | Ad count |
|------|----------------|-----------------|-----------------|----------|
| **Full** | 8 template-based ads across proven creative formats | 80 | 160 | 8 |
| **Bespoke** | 5 AI-generated concepts unique to your product | 50 | 100 | 5 |
| **Director** | 8-shot narrative arc with brief + optional style/swipe/character refs | 80 | 160 | 8 |
| **Single Asset** | 1 specific template ad | 10 | 20 | 1 |

**Director Mode** is the most powerful — it builds a full cinematic story arc around your product. You can pass:
- A **style reference** (sets palette, lighting, and vibe)
- A **swipe reference** (guides composition and layout)
- A **character reference** (locks in a face/model across shots)

---

## Ad Management

All management operations use the browser tool (they're Next.js Server Actions). See `references/campaign-management.md` for the exact browser flows.

| Operation | Token cost |
|-----------|-----------|
| Regenerate | Same as original (10 or 20) |
| Edit (prompt) | Same as original |
| Edit (inpaint mask) | Same as original |
| Animate → MP4 (5s) | 40 |
| Animate → MP4 (10s) | 75 |
| Upscale → 4K | 20 |
| Delete | Free |
| Rename | Free |

---

## Export Options

| Format | Command | Best for |
|--------|---------|---------|
| Single file | `am.py download` | Quick saves |
| Zip archive | `am.py export-zip` | Sharing all ads at once |
| Meta pack | `am.py export-meta` | Uploading directly to Meta Ads Manager — includes `manifest.csv` + `README.txt` |

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

The stream also **triggers generation** — ads don't generate without an active stream connection. Always connect after creating a campaign.

---

## File Structure

```
ad-machine/
├── SKILL.md                          # Skill trigger + quick reference
├── scripts/
│   └── am.py                         # Python CLI for all REST operations
└── references/
    ├── api.md                        # Complete REST API reference
    ├── browser-automation.md         # CDP file injection + campaign creation flow
    └── campaign-management.md        # Browser flows for ad management operations
```

---

## How It Works

Ad Machine's campaign creation and ad management use **Next.js Server Actions**, not traditional REST endpoints. This skill uses a two-track approach:

1. **REST API** (`am.py`) — for upload, tokens, export, streaming, and prompt enhancement
2. **Browser tool + CDP** — for campaign creation and ad management, which require UI interaction

The `DOM.setFileInputFiles` CDP method is the critical piece — it's the only reliable way to inject files into React file inputs from an agent.

---

## Get an Ad Machine Account

→ [admachine.xyz](https://admachine.xyz) — sign up free, get 7 demo ads on the house.

After the demo, plans start at $X/month. Your agent can check subscription and token status anytime:

```bash
python3 am.py tokens
```

---

## Contributing

PRs welcome. If you've found an endpoint, added a new export format, or improved the browser automation flow — open a PR.

Please don't include any credentials, internal API keys, or account-specific data in contributions.

---

## License

MIT — use it, fork it, build on it.

---

*Built with ❤️ by the Ad Machine team. Powered by [OpenClaw](https://openclaw.ai).*
