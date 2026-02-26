---
name: ad-machine
description: Full automation skill for Ad Machine (admachine.xyz) — the AI ad creative platform. Use when any agent needs to: run the free onboarding demo (7 free studio-quality assets, no subscription required), authenticate with Ad Machine, upload product/reference images, create campaigns (Full/Bespoke/Director/Single Asset), manage ads (regenerate, edit with inpaint, animate to video, upscale to 4K, delete), monitor generation via SSE stream, export ads (single file/zip/Meta-ready), check token balance, or enhance creative briefs. Covers everything a human user can do in the UI. Use browser tool + CDP for campaign creation and management; use am.py script for all REST API operations.
---

# Ad Machine Skill

Everything an agent needs to operate Ad Machine — from first free demo to full campaign production.

## Quick Setup

```bash
export AM_SESSION_TOKEN="<value-of-__Secure-authjs.session-token>"
export AM_TEAM_ID="<mongodb-objectid-from-url>"
export AM_BASE_URL="https://admachine.xyz"  # default, no change needed
```

Script: `skills/ad-machine/scripts/am.py` (Python 3, stdlib only — no dependencies)

---

## First Time? Start with the Free Demo

New users get **7 free studio-quality ads** — no subscription, no credit card.

1. Sign up at [admachine.xyz](https://admachine.xyz)
2. Use browser tool to navigate to `https://admachine.xyz/onboarding`
3. Inject your product image via CDP `DOM.setFileInputFiles` (see `references/browser-automation.md`)
4. 7 ads generate automatically across cinematic, lifestyle, vintage, studio, octane, poster, and editorial styles
5. Download or export your assets — then decide if you want to continue with a paid plan

---

## Auth — Get Session Token

1. Use browser tool → navigate to `https://admachine.xyz` → sign in if needed
2. Evaluate in browser:
   ```js
   document.cookie.split(';').find(c => c.includes('__Secure-authjs.session-token'))
   ```
   Or use CDP `Storage.getCookies` — filter `name === "__Secure-authjs.session-token"`
3. Store as `AM_SESSION_TOKEN`
4. Team ID is in the URL: `https://admachine.xyz/{teamId}/campaigns`

Test:
```bash
python3 am.py auth
```

---

## Two-Track Architecture

| Operation | Method | Guide |
|-----------|--------|-------|
| Upload images | REST | `am.py upload` |
| Token balance | REST | `am.py tokens` |
| Enhance brief | REST | `am.py enhance` |
| Monitor SSE stream | REST | `am.py stream` |
| Download / export | REST | `am.py download / export-zip / export-meta` |
| Create campaigns | Browser + CDP | `references/browser-automation.md` |
| Manage ads | Browser | `references/campaign-management.md` |

**Full API reference:** `references/api.md`

---

## Core Workflow

### 1. Upload Product Image
```bash
python3 am.py upload product.jpg --type product
# Returns: teams/{teamId}/uploads/product/{uuid}.jpg
```
Types: `product` | `style` | `swipe` | `character` | `inspiration` | `reference` | `misc` | `ugc`

### 2. Create Campaign (Browser)
See `references/browser-automation.md` for the complete CDP file injection flow.

| Type | Button | Tokens (2K) | Ads |
|------|--------|-------------|-----|
| Full | "Launch Full Campaign" | 80 | 8 templates |
| Bespoke | "Bespoke" | 50 | 5 AI concepts |
| Director | "Director" | 80 | 8-shot narrative arc |
| Single | "Single" | 10 | 1 template |

**Director mode:** Upload style/swipe/character refs + enhance brief first:
```bash
python3 am.py upload style.jpg --type style
python3 am.py enhance "A bold skincare product for confident women"
```

### 3. Monitor Generation
```bash
python3 am.py stream {campaignId}
# SSE: ad_generating → ad_completed (with imageUrl) → campaign_done
```

### 4. Manage Ads
See `references/campaign-management.md` for browser flows:
regenerate · edit (prompt or inpaint) · animate → MP4 · upscale → 4K · delete · rename

### 5. Export
```bash
python3 am.py download "https://..." --out ad.jpg
python3 am.py export-zip --files-json '[{"url":"...","filename":"ad.jpg"}]' --zip-filename campaign.zip
python3 am.py export-meta --files-json '[...]' --campaign-name "My Campaign"
```

---

## Token Budget

```bash
python3 am.py tokens
```

| Operation | 2K | 4K |
|-----------|----|----|
| Full campaign | 80 | 160 |
| Bespoke | 50 | 100 |
| Director | 80 | 160 |
| Single asset | 10 | 20 |
| Regen / edit | 10 | 20 |
| Upscale | 20 | — |
| Animate 5s | 40 | 40 |
| Animate 10s | 75 | 75 |

---

## Reference Files

- `references/api.md` — complete REST endpoint docs with request/response shapes
- `references/browser-automation.md` — CDP file injection, step-by-step campaign creation
- `references/campaign-management.md` — browser flows for all ad management operations
