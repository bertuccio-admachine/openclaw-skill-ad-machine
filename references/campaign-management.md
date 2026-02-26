# Campaign Management Reference

## Overview
All campaign management operations (regenerate, edit, animate, upscale, add concepts, delete, rename) are implemented as **Next.js Server Actions** in `app/[teamId]/campaigns/actions.ts`.

Server Actions are not standard REST endpoints — they are invoked through browser interaction or React form submission. Agents must use the **browser tool** to trigger these operations.

---

## Table of Contents
1. [Regenerate Ad](#regenerate-ad)
2. [Edit Ad](#edit-ad)
3. [Animate Ad](#animate-ad)
4. [Upscale Ad](#upscale-ad)
5. [Add More Concepts](#add-more-concepts)
6. [Delete Operations](#delete-operations)
7. [Rename Campaign](#rename-campaign)
8. [Navigation Pattern](#navigation-pattern)

---

## Regenerate Ad
Re-generate a single ad with a new random seed (same prompt, new image).

**Browser flow:**
1. Navigate to `/<teamId>/campaigns/<campaignId>`
2. Hover over the target ad card → context menu appears
3. Click "Regenerate" (or the ↻ icon)
4. Confirm if a dialog appears
5. Watch for the image to update (spinner → new image)

**Token cost:** Same as the original generation cost for that ad's quality setting.

**Server Action:** `regenerateAd(adId, campaignId)`

---

## Edit Ad

### Prompt Edit (full re-generation)
**Browser flow:**
1. On campaign page → hover ad → click "Edit"
2. Edit modal opens
3. Type new prompt in the text field
4. Click "Regenerate" / "Apply" (confirm mode = REGENERATE)
5. Wait for new image

**Server Action:** `editAd(adId, campaignId, prompt, "REGENERATE")`

### Inpaint Edit (masked area only)
**Browser flow:**
1. On campaign page → hover ad → click "Edit"
2. Edit modal opens
3. Draw mask over area to change using the canvas brush
4. Enter a prompt describing what should fill the masked area
5. Click "Apply" (mode = EDIT_MASK)
6. Wait for inpainted result

**Server Action:** `editAd(adId, campaignId, prompt, "EDIT_MASK", maskDataUrl)`
- `maskDataUrl` is a `data:image/png;base64,...` URI encoding the mask canvas

---

## Animate Ad
Convert a static image ad into an MP4 video.

**Browser flow:**
1. On campaign page → hover ad → click "Animate"
2. Duration picker appears: "5s" or "10s"
3. Select duration → click confirm
4. Watch for video player to appear on the ad card

**Options:** `5s` | `10s`

**Server Action:** `animateAd(adId, campaignId, duration)` where duration is `"5s"` or `"10s"`

**Token cost:** Higher than static generation. Check current rates via `GET /api/teams/[teamId]/subscription`.

**Note:** Generated videos are MP4 and downloadable via `/api/download`.

---

## Upscale Ad
Upscale a 2K ad to 4K resolution.

**Browser flow:**
1. On campaign page → hover ad → click "Upscale" (or upscale icon)
2. Confirm dialog
3. Wait for 4K version to appear

**Server Action:** `upscaleAd(adId, campaignId)`

**Token cost:** Additional tokens deducted for the upscale operation.

---

## Add More Concepts

### Bespoke: Add 5 More Concepts
**Browser flow:**
1. On a Bespoke campaign page
2. Scroll to bottom of ads grid → "Add 5 more concepts" button
3. Click → wait for 5 new ads to generate

**Server Action:** `addBespokeConcepts(campaignId)`

### Full: Add Another Template Set
**Browser flow:**
1. On a Full campaign page
2. "Add template set" button (bottom of grid)
3. Click → wait for 8 new ads to generate

**Server Action:** `addTemplateSet(campaignId)`

---

## Delete Operations

### Delete Specific Ads
**Browser flow:**
1. On campaign page → select ads (checkbox or long-press)
2. "Delete selected" appears in toolbar
3. Click → confirm dialog → ads removed

**Server Action:** `deleteAds(adIds: string[], campaignId)`

**Note:** Irreversible. Tokens are NOT refunded.

### Delete Entire Campaign
**Browser flow:**
1. Campaign page → settings/kebab menu → "Delete campaign"
2. Confirm dialog (type campaign name or click confirm)
3. Redirects back to dashboard

**Server Action:** `deleteCampaign(campaignId)`

**Note:** Deletes all ads and associated assets. Irreversible.

---

## Rename Campaign
**Browser flow:**
1. Campaign page → click the campaign name (inline edit) OR
2. Campaign settings → Rename field
3. Type new name → press Enter or click confirm

**Server Action:** `updateCampaignName(campaignId, name)`

---

## Navigation Pattern
For all browser-based management operations:

```
1. browser action=navigate targetUrl=https://admachine.xyz/<teamId>/campaigns/<campaignId>
2. browser action=snapshot  → identify target ad and buttons
3. browser action=act request={kind:hover, ref:<ad-card-ref>}  → reveal context menu
4. browser action=act request={kind:click, ref:<action-button-ref>}
5. browser action=snapshot  → confirm operation completed or dialog appeared
6. [handle dialogs if any]
7. browser action=snapshot  → verify result
```

---

## Checking Campaign Data
To get campaign and ad data (image URLs, statuses, etc.) without browser automation:

1. **SSE stream** (if generation in progress):
   `GET /api/campaigns/<id>/stream` — returns `ad_completed` events with `imageUrl`

2. **Browser snapshot** of campaign page:
   Image URLs are in `<img>` src attributes on ad cards.

3. **MongoDB directly** (if you have DB access):
   See `models/Campaign.ts` and `models/Ad.ts` for schemas.
   - `ad.primaryImage.imageKey` → R2 key
   - Use `getImageUrl(key)` from `lib/services/r2` to get signed URL
