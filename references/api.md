# Ad Machine API Reference

Base URL: `https://admachine.xyz`
Auth: Cookie header `__Secure-authjs.session-token=<token>`

---

## Table of Contents
1. [Auth / Session](#1-auth--session)
2. [Upload](#2-upload)
3. [Campaign Creation (Server Actions)](#3-campaign-creation-server-actions)
4. [Campaign Management (Server Actions)](#4-campaign-management-server-actions)
5. [SSE Generation Stream](#5-sse-generation-stream)
6. [Export & Download](#6-export--download)
7. [Tokens / Dashboard](#7-tokens--dashboard)
8. [Prompt Enhancement](#8-prompt-enhancement)
9. [Token Costs Reference](#9-token-costs-reference)

---

## 0. Onboarding Demo (Free — No Subscription Required)

New users get **7 free studio-quality assets** just by signing up and uploading a product photo. No credit card, no subscription.

### Flow
1. Sign up at [admachine.xyz](https://admachine.xyz)
2. Upload a product photo on the onboarding page
3. 7 ads generate automatically across these styles:
   - Cinematic Master
   - Influencer Lifestyle
   - Vintage Retro
   - Professional Studio
   - Octane Render
   - Poster Art
   - Editorial Fashion
4. All generated at 4:5 (Instagram Portrait), 2K quality
5. After demo, subscribe to unlock full access

### Skill Flow (Onboarding)
```bash
# 1. Upload product image (no team token needed for demo)
python3 am.py upload product.jpg --type product

# 2. Use browser tool to navigate to admachine.xyz/onboarding
#    and inject the image key — the demo generates automatically

# 3. Stream and download just like any campaign
```

---

## 1. Auth / Session

### Extract session token via CDP (browser tool)
```
CDP: Storage.getCookies
Filter: name === "__Secure-authjs.session-token"
```
Store as `AM_SESSION_TOKEN` env var.

### Get team ID
After login, the URL is: `https://admachine.xyz/{teamId}/campaigns`
The `teamId` is a MongoDB ObjectId string. Store as `AM_TEAM_ID`.

---

## 2. Upload

### POST /api/upload/presign
Get a presigned S3/R2 URL for direct upload.

**Request:**
```json
{
  "teamId": "string",
  "type": "product | style | swipe | character | misc | ugc | inspiration | reference",
  "contentType": "image/png | image/jpeg | image/webp | image/gif",
  "fileSize": 12345
}
```

**Response:**
```json
{
  "presignedUrl": "https://...",
  "key": "teams/{teamId}/uploads/{type}/{uuid}.{ext}"
}
```

**Step 2 — PUT to presigned URL:**
```
PUT {presignedUrl}
Content-Type: {contentType}
Body: raw file bytes
```
Returns 200/204 on success. The `key` is what you pass to campaign creation.

---

## 3. Campaign Creation (Server Actions)

> Campaign creation uses **Next.js Server Actions** invoked from the browser UI.
> Use the browser tool to interact with the app UI, or call actions via Next-Action headers.

### Calling Server Actions via fetch

All server actions live at: `POST https://admachine.xyz/{teamId}/campaigns`

Headers required:
```
Next-Action: {actionHash}
Content-Type: application/json
Cookie: __Secure-authjs.session-token={token}
```

Body: JSON array of function arguments, e.g.:
```json
[{"teamId":"...","imageKeys":["..."],"settings":{"aspectRatio":"16:9","imageSize":"2K"},"name":"My Campaign"}]
```

### Discovering Action Hashes

Action hashes are embedded in the Next.js client bundle. To find them:
1. Load `https://admachine.xyz/{teamId}/campaigns` with the browser tool
2. Evaluate: `document.querySelectorAll('[data-action]')` to find action references
3. Or search the page source for `"Next-Action"` references

### Campaign Types

| Type | Function | Token Cost | Ad Count |
|------|----------|-----------|----------|
| Full | `createCampaign` | 200 (2K) / 400 (4K) | 8 templates |
| Bespoke | `createBespokeCampaign` | 50 (2K) / 100 (4K) | 5 AI concepts |
| Director | `createDirectorCampaign` | 80 (2K) / 160 (4K) | 8-shot arc |
| Single | `createSingleAsset` | 10 (2K) / 20 (4K) | 1 template |

### Full Campaign
```json
{
  "teamId": "string",
  "imageKeys": ["teams/.../.../product/uuid.jpg"],
  "settings": { "aspectRatio": "16:9", "imageSize": "2K" },
  "name": "Campaign Name"
}
```

### Bespoke Campaign
Same shape as Full Campaign. Uses AI to generate creative concepts instead of templates.

### Director Campaign
```json
{
  "teamId": "string",
  "imageKeys": ["teams/.../product/uuid.jpg"],
  "creativeBrief": "A premium skincare product that...",
  "styleImageKey": "teams/.../style/uuid.jpg",
  "swipeImageKey": "teams/.../swipe/uuid.jpg",
  "characterImageKey": "teams/.../character/uuid.jpg",
  "settings": { "aspectRatio": "16:9", "imageSize": "2K" },
  "name": "Director Campaign"
}
```
- `styleImageKey` — palette/lighting/vibe reference
- `swipeImageKey` — composition/layout reference
- `characterImageKey` — identity/face lock reference
- All reference keys are optional (pass only what you have)

### Single Asset
```json
{
  "teamId": "string",
  "templateId": "string",
  "imageKeys": ["teams/.../product/uuid.jpg"],
  "settings": { "aspectRatio": "16:9", "imageSize": "2K" },
  "name": "Campaign Name"
}
```

### Adding to Existing Campaign
Pass `campaignId` instead of `imageKeys` + `name` to add ads to an existing campaign.

### Settings
- `aspectRatio`: `"16:9"` | `"9:16"` | `"1:1"` | `"4:5"`
- `imageSize`: `"2K"` | `"4K"`

---

## 4. Campaign Management (Server Actions)

Same endpoint: `POST https://admachine.xyz/{teamId}/campaigns`
Different `Next-Action` hash per function.

### regenerateAd(adId, campaignId)
Args: `["{adId}", "{campaignId}"]`

### editAd(adId, campaignId, prompt, action, maskDataUrl?)
Args: `["{adId}", "{campaignId}", "new prompt", "REGENERATE"|"EDIT_MASK", "data:image/png;base64,..."]`

### animateAd(adId, campaignId, duration)
Args: `["{adId}", "{campaignId}", "5s"|"10s"]`
Token costs: 5s = 40 tokens, 10s = 75 tokens

### upscaleAd(adId, campaignId)
Args: `["{adId}", "{campaignId}"]`
Token cost: 20 tokens (upgrades 2K → 4K)

### updateCampaignName(campaignId, newName)
Args: `["{campaignId}", "New Name"]`

### deleteAds(campaignId, deleteTargets)
Args: `["{campaignId}", [{"adId": "...", "imageKey": "..."}]]`
- If all ads deleted, campaign is auto-deleted too

### deleteCampaign(campaignId)
Args: `["{campaignId}"]`
- Deletes all ads, R2 assets, and the campaign document

---

## 5. SSE Generation Stream

### GET /api/campaigns/{campaignId}/stream

Triggers image generation for all pending ads in the campaign.
Returns Server-Sent Events.

```
Accept: text/event-stream
Cookie: __Secure-authjs.session-token={token}
```

**Events:**

| Event | Data |
|-------|------|
| `ad_generating` | `{adId, index, title}` |
| `ad_completed` | `{adId, imageUrl, imageQuality, title}` |
| `ad_error` | `{adId, error}` |
| `insufficient_tokens` | `{adId, title, required, remaining}` |
| `campaign_done` | `{completedCount}` |
| `error` | `{message}` |

**Workflow:** Create campaign (get campaignId) → connect to stream → wait for `campaign_done`.

---

## 6. Export & Download

### POST /api/download
Download a single ad via proxy.

**Request:**
```json
{ "url": "https://r2.admachine.xyz/...", "filename": "ad.jpg" }
```
**Response:** Binary file with `Content-Disposition` attachment header.

---

### POST /api/download/zip
Download multiple ads as a zip.

**Request:**
```json
{
  "files": [
    { "url": "https://r2.admachine.xyz/...", "filename": "ad-1.jpg" },
    { "url": "https://r2.admachine.xyz/...", "filename": "ad-2.jpg" }
  ],
  "zipFilename": "campaign-export.zip"
}
```
Max 50 files. **Response:** Binary zip.

---

### POST /api/export/meta
Export Meta-ready zip with manifest.csv and README.txt.

**Request:**
```json
{
  "files": [{ "url": "...", "filename": "ad-1.jpg" }],
  "campaignName": "My Campaign",
  "manifest": [
    {
      "adId": "abc123",
      "adTitle": "Product Hero",
      "mediaType": "image",
      "aspectRatio": "16:9",
      "placementCode": "facebook_feed",
      "recommendedPlacement": "Facebook Feed",
      "source": "template"
    }
  ]
}
```
**Response:** Binary zip with images + `manifest.csv` + `README.txt`.

---

## 7. Tokens / Dashboard

### GET /api/teams/{teamId}/subscription
Returns token balance + subscription details.

**Response:**
```json
{
  "tokens": 850,
  "tokensUsed": 150,
  "tokensTotal": 1000,
  "plan": "starter",
  "renewsAt": "2026-03-01T00:00:00Z"
}
```

---

## 8. Prompt Enhancement

### POST /api/enhance-prompt
AI-enhance a creative brief before passing to Director Mode.

**Request:**
```json
{ "prompt": "A skincare product for glowing skin" }
```

**Response:**
```json
{
  "enhancedPrompt": "A premium anti-aging skincare serum that..."
}
```

---

## 9. Token Costs Reference
_(Source: constants/tokens.ts — STANDARD_IMAGE=10, IMAGE_4K=18, VIDEO_PER_SECOND=10)_

| Operation | 2K | 4K |
|-----------|----|----|
| Single image | 10 | 18 |
| Full campaign (20 ads) | 200 | 360 |
| Bespoke campaign (4 ads) | 40 | 72 |
| Director campaign (8 ads) | 80 | 144 |
| Single Asset | 10 | 18 |
| Regenerate ad | 10 | 18 |
| Edit ad | 10 | 18 |
| Upscale to 4K | 18 | — |
| Animate 4s | 40 | — |
| Animate 6s | 60 | — |
| Animate 8s | 80 | — |
