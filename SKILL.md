---
name: ad-machine
description: Full automation skill for Ad Machine (admachine.xyz). Use when any agent needs to authenticate, upload assets, create campaigns (Full/Bespoke/Director/Single Asset), manage ads (regenerate, edit, animate, upscale, delete), monitor SSE generation streams, deliver generated ads into the current chat, export ads (single/zip/Meta-ready), check token balance, or enhance creative briefs. Covers everything a human can do in the UI. Uses browser tool + CDP for campaign creation and management; am.py or shell scripts for REST API operations.
---

# Ad Machine Skill

Full operator access to Ad Machine — upload, create, manage, export.

## Quick Setup

```bash
export AM_SESSION_TOKEN="<value-of-__Secure-authjs.session-token>"
export AM_TEAM_ID="<mongodb-objectid-from-url>"
# AM_BASE_URL defaults to https://admachine.xyz
```

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/am.py` | **Unified Python CLI** — auth, tokens, upload, enhance, stream, **deliver**, download, export |
| `scripts/extract-cookie.js` | Extract session cookie via CDP — auto-detects OpenClaw port 18800 and standard port 9222 |
| `scripts/upload-asset.sh` | Presign + upload a file to R2 |
| `scripts/token-balance.sh` | Check team token balance |
| `scripts/enhance-prompt.sh` | AI-enhance a creative brief |
| `scripts/campaign-status.sh` | Monitor SSE generation stream |
| `scripts/export-campaign.sh` | Download / ZIP / Meta export |
| `scripts/create-campaign.sh` | Browser automation reference (read for flow details) |
| `scripts/manage-campaign.sh` | Campaign management reference (read for browser flows) |

---

## Auth — Get Session Token

1. Open browser → navigate to `https://admachine.xyz` → sign in
2. Extract cookie via CDP: `node --experimental-websocket scripts/extract-cookie.js`
3. Store as `AM_SESSION_TOKEN`

Team ID is in the URL: `https://admachine.xyz/{teamId}/campaigns`

Test auth:
```bash
python3 am.py auth
```

---

## Two-Track Architecture

| Operation | Method | Script/Guide |
|-----------|--------|-------------|
| Upload images | REST | `am.py upload` |
| Token balance | REST | `am.py tokens` |
| Enhance brief | REST | `am.py enhance` |
| Monitor SSE stream | REST | `am.py stream` |
| Download / export | REST | `am.py download / export-zip / export-meta` |
| Create campaigns | Browser + CDP | `references/browser-automation.md` |
| Manage ads | Browser | `references/campaign-management.md` |

**REST API full reference:** `references/api.md`

---

## Vagueness Audit & Banned Phrases

**These phrases are strictly prohibited** — replace with explicit next-step commands:

| Banned Phrase | What It Does | Correct Replacement |
|---------------|--------------|---------------------|
| "then proceed" | Vague transition | "Run: `<exact command>`" or "Next: Click [element]" or "Go to step X" |
| "follow the steps" | No specific action | List exact numbered steps with commands |
| "see reference" | No actionable path | "Open `path/to/file.md`, scroll to section 'Y', execute command Z" |
| "check the docs" | No context | "Run `python3 am.py help` to see all options" or "See `references/api.md` line 45" |
| "as described above" | Requires backtracking | Repeat the exact command/step inline |
| "in the usual way" | No standard | Specify the exact sequence (e.g., "Click button → Enter text → Press Enter") |
| "continue with step X" | No explicit start | "Run: `<command>`" or "Navigate to `<URL>`" |
| "once you finish" | Open-ended | "After step 3 completes (look for JSON output ending with `"completedCount"`), immediately run step 4:" |
| "optional" without context | Unclear when to use | "Optional: Use only if [condition]. Command: `<exact>`" |
| "as needed" | No trigger | "If [specific error], then: `<command>`" |
| "refer to [section]" | No inline instruction | Inline a 1-2 sentence summary + exact command |
| "proceed to the next step" | Vague transition | "Step 4: [Explicit action]. Run: `<command>`" |

---

## Before You Start — Step-by-Step Tool Mapping

| Step | Tool | Command | Required Inputs | Output |
|------|------|---------|-----------------|--------|
| 1. Upload Product Image | REST (am.py) | `python3 am.py upload product.jpg --type product` | Local file path, upload type | R2 key: `teams/{teamId}/uploads/product/{uuid}.jpg` |
| 2. Upload Reference Assets (if needed) | REST (am.py) | `python3 am.py upload style.jpg --type style` (repeat for swipe, character, etc.) | Local file path, type (style\|swipe\|character\|inspiration) | R2 keys for each asset |
| 2a. Enhance Brief (Director mode only) | REST (am.py) | `python3 am.py enhance "Your creative brief text"` | Brief text string | Enhanced brief text |
| 2b. Create Campaign | Browser CDP | Open `references/browser-automation.md`, follow CDP injection steps | Campaign type, uploaded asset keys, creative brief | Campaign ID from URL: `https://admachine.xyz/{teamId}/campaigns/{campaignId}` |
| 3. Monitor Generation Stream | REST (am.py) | `python3 am.py stream {campaignId}` | Campaign ID | JSON manifest with completed ads, image URLs, error list |
| 4. Deliver Ads to Chat | REST (am.py) | `python3 am.py deliver --manifest-json "$MANIFEST"` | Manifest JSON from step 3 | Local file paths in `/tmp/am_deliver/` |
| 5. Manage Ads (optional) | Browser | Open `references/campaign-management.md`, use browser flows | Campaign ID, ad ID | Updated campaign state |
| 6. Export (optional) | REST (am.py) | `python3 am.py export-zip` or `export-meta` | File URLs and metadata | ZIP archive or Meta-ready upload pack |

---

## Step-by-Step Script & Method Reference

| Core Step | Script/Method | Exact Command Syntax | Required Parameters | Expected Output | Next Action After Success |
|-----------|---------------|--------------------|-------------------|-----------------|-------------------------|
| **1. Upload Product Image** | REST: `am.py upload` | `python3 am.py upload {filepath} --type product` | `{filepath}`: absolute or relative path to image (JPG, PNG) | `Upload successful. R2 key: teams/{teamId}/uploads/product/{uuid}.jpg` | Store the R2 key. Repeat with `--type style` or `--type swipe` for reference assets. Then go to step 2. |
| **1b. Upload Reference Assets** | REST: `am.py upload` | `python3 am.py upload {filepath} --type {type}` | `{type}`: one of `style`, `swipe`, `character`, `inspiration`, `reference`, `misc`, `ugc` | `Upload successful. R2 key: teams/{teamId}/uploads/{type}/{uuid}.jpg` | Store each R2 key. Repeat for each asset. After all uploads complete, go to step 2. |
| **2a. Enhance Creative Brief (Director only)** | REST: `am.py enhance` | `python3 am.py enhance "{brief_text}"` | `{brief_text}`: quoted string | Enhanced brief text printed to stdout | Copy the enhanced output. Store it for the campaign creation form in step 2b. |
| **2b. Create Campaign** | Browser CDP | Open `references/browser-automation.md` → "CDP File Injection Flow". Execute each CDP command in order (5-7 commands). | Product R2 key, reference R2 keys (if Director), creative brief, campaign type | Browser confirms "Campaign created successfully". URL becomes `https://admachine.xyz/{teamId}/campaigns/{campaignId}` | Extract `{campaignId}` from the URL. Go to step 3. |
| **3. Monitor Generation Stream** | REST: `am.py stream` | `MANIFEST=$(python3 am.py stream {campaignId})` | `{campaignId}`: from URL in step 2b | Progress to stderr. On completion: JSON to stdout with `"completedCount": N` where N > 0. | If `"completedCount" == 0` after 10 mins: run `python3 am.py tokens`. If balance OK, wait 2 mins and retry. Otherwise go to step 4. |
| **4. Deliver Ads to Chat** | REST: `am.py deliver` | `python3 am.py deliver --manifest-json "$MANIFEST"` | `$MANIFEST`: JSON string from step 3 | JSON: `{"ads": [{"title": "...", "localPath": "/tmp/am_deliver/...", "imageUrl": "..."}], "count": N}` | For each ad: send to chat with `message action=send media={localPath} caption="{title}"`. Then ask: "ZIP export / Meta export / Save to disk?" |
| **5. Regen / Edit / Animate / Upscale** | Browser CDP | Open `references/campaign-management.md` → section for your action. Execute CDP commands in order. | Action type, campaign ID, ad ID | Browser confirms operation complete. | Run `python3 am.py stream {campaignId}` to capture updated manifest. Deliver with step 4. |
| **6a. Export Single Ad** | REST: `am.py download` | `python3 am.py download "{imageUrl}" --out {filename}` | `{imageUrl}`: HTTPS URL from manifest; `{filename}`: e.g. `ad.jpg` | `Downloaded to {filename}` | Share file with user or upload externally. |
| **6b. Export ZIP** | REST: `am.py export-zip` | `python3 am.py export-zip --files-json '[{"url":"{url}","filename":"{name}"}]' --zip-filename {zipname}` | Array of url/filename objects; output ZIP name | `Exported to {zipname}` | Share ZIP with user. |
| **6c. Export for Meta** | REST: `am.py export-meta` | `python3 am.py export-meta --files-json '[{"url":"{url}","filename":"{name}"}]' --campaign-name "{name}"` | Array of url/filename objects; campaign name | `Export pack saved to export/{campaign-name-slug}/` | Share directory or upload ZIP to Meta Ads Manager. |

---

## Core Workflow

### 1. Upload Product Image
```bash
python3 am.py upload product.jpg --type product
# Returns R2 key: teams/{teamId}/uploads/product/{uuid}.jpg
```
Upload types: `product` | `style` | `swipe` | `character` | `inspiration` | `reference` | `misc` | `ugc`

**Next step:** Store the R2 key. If uploading reference assets (style, swipe, character), repeat for each. Once all uploads are done, go to step 2.

### 2. Create Campaign (Browser)
**Before creating:** Run `python3 am.py tokens` to verify sufficient balance for your campaign type.

Campaign types → button text → tokens (2K) → ad count:
- **Full** → "Launch Full Campaign" → **200 tokens** → 20 template ads
- **Bespoke** → "Bespoke" → **40 tokens** → 4 AI concepts
- **Director** → "Director" → **80 tokens** → 8-shot narrative arc
- **Single** → "Single" → **10 tokens** → 1 template ad

**Director mode requires a creative brief + optional style/swipe/character refs:**
1. Upload reference images first: `python3 am.py upload ref.jpg --type style` (repeat per asset)
2. Enhance your brief: `python3 am.py enhance "Your brief text"` — copy the enhanced output
3. Store R2 keys and enhanced brief for the campaign form

**To create the campaign:** Open `references/browser-automation.md`, scroll to "CDP File Injection Flow," and execute each CDP command in order. The flow will:
1. Navigate to the campaign creation form
2. Fill in campaign type, asset keys, and creative brief
3. Click the campaign type button (e.g., "Launch Full Campaign")
4. Wait for the success message

**After creation:** Extract the campaign ID from the browser URL: `https://admachine.xyz/{teamId}/campaigns/{campaignId}`. Use this ID in step 3.

### 3. Monitor Generation
```bash
MANIFEST=$(python3 am.py stream {campaignId})
```
- Progress events (e.g., "Generating ad 5/20") print to stderr as they arrive
- On completion, JSON manifest prints to stdout:

```json
{
  "campaignId": "abc123xyz",
  "completed": [
    {"adId": "ad-1", "title": "Winter Hero", "imageUrl": "https://...", "imageQuality": "2K"},
    {"adId": "ad-2", "title": "Summer Vibes", "imageUrl": "https://...", "imageQuality": "2K"}
  ],
  "errors": [],
  "completedCount": 2
}
```

**Next step:** Once `$MANIFEST` contains JSON with `"completedCount" > 0`, go to step 4. If `completedCount == 0` after 10 minutes, run `python3 am.py tokens` to check balance, wait 2 minutes, then re-run the stream command.

### 4. Deliver Ads to Chat
```bash
DELIVERY=$(python3 am.py deliver --manifest-json "$MANIFEST")
```

`deliver` downloads each ad to `/tmp/am_deliver/` and outputs:
```json
{
  "ads": [
    {"title": "Winter Hero", "localPath": "/tmp/am_deliver/01_Winter_Hero.png", "imageUrl": "..."}
  ],
  "dir": "/tmp/am_deliver",
  "count": 1
}
```

**Then use the `message` tool for each ad:**
```
message action=send media=<localPath> caption="<title>"
```

**After all ads are sent, ask the user:**
> "Your {N} ads are ready! What would you like to do?"
> - 📤 Share in this chat
> - 🗜️ Export as ZIP
> - 📋 Export for Meta Ads Manager
> - 💾 Save to disk

### 5. Manage Ads
Open `references/campaign-management.md` and scroll to the section for your action:
- **Regenerate ad:** "Regenerate Ad Flow" → execute CDP commands in order → monitor with `python3 am.py stream {campaignId}`
- **Edit prompt:** "Edit Prompt Flow"
- **Animate → video:** "Animate (Video) Flow" → monitor with stream command
- **Upscale → 4K:** "Upscale Flow"
- **Delete:** "Delete Ad Flow"

After any management operation, capture updated manifest: `MANIFEST=$(python3 am.py stream {campaignId})` — then deliver with step 4.

### 6. Export
```bash
# Single file
python3 am.py download "https://..." --out ad.jpg

# ZIP of all ads
python3 am.py export-zip \
  --files-json '[{"url":"...","filename":"ad-1.jpg"}]' \
  --zip-filename campaign.zip

# Meta Ads Manager upload pack (manifest + README)
python3 am.py export-meta \
  --files-json '[{"url":"...","filename":"ad.jpg"}]' \
  --campaign-name "My Campaign"
```

---

## Token Costs (from source)

| Operation | 2K | 4K |
|-----------|-----|-----|
| Per image generated | 10 | 18 |
| Full Campaign (20 ads) | 200 | 360 |
| Bespoke (4 concepts) | 40 | 72 |
| Director Mode (8 shots) | 80 | 144 |
| Single Asset | 10 | 18 |
| Regen / Edit | 10 | 18 |
| Upscale (2K → 4K) | 18 | — |
| Video 4s | 40 | — |
| Video 6s | 60 | — |
| Video 8s | 80 | — |

Always check before campaigns:
```bash
python3 am.py tokens
```

---

## Reference Files

- `references/api.md` — complete REST endpoint docs with request/response shapes
- `references/browser-automation.md` — CDP file injection, step-by-step campaign creation
- `references/campaign-management.md` — browser flows for all ad management operations
