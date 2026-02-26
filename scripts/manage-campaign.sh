#!/usr/bin/env bash
# manage-campaign.sh
# Campaign management operations via REST/server-action patterns.
# All management actions (regenerate, edit, animate, upscale, delete, rename)
# are Next.js Server Actions. They must be called via browser form submission
# or the internal action endpoint.
#
# IMPORTANT: Server Actions cannot be called directly as REST APIs.
# They require a valid Next.js action ID and session cookie.
# Agents must use the OpenClaw browser tool to trigger these actions.
#
# ─── HOW TO CALL A SERVER ACTION VIA BROWSER ──────────────────────────────
#
# Option A: Browser interaction (recommended)
#   - Navigate to the campaign page: /<teamId>/campaigns/<campaignId>
#   - Locate the ad card
#   - Click the appropriate button (Regenerate / Edit / Animate / Upscale / Delete)
#   - Confirm any dialogs
#   - Wait for the operation to complete (image updates, video appears, etc.)
#
# Option B: Evaluate action via browser tool (advanced)
#   Use browser act with evaluate kind to call Next.js hydrated button functions
#   or use CDP Runtime.evaluate to trigger React synthetic events.
#
# ─── AVAILABLE OPERATIONS ─────────────────────────────────────────────────
#
# REGENERATE AD
#   Button: "Regenerate" on ad card context menu
#   Cost: same as original ad's token cost (2K or 4K rate)
#   Result: new image replaces current, visible in gallery
#
# EDIT AD (prompt-based)
#   Button: "Edit" → opens Edit modal
#   Fields: new prompt text
#   Action: "REGENERATE" mode (re-generates entire image with new prompt)
#   Cost: standard token cost
#
# EDIT AD (inpaint/mask)
#   Button: "Edit" → draw mask → submit
#   Action: "EDIT_MASK" mode (inpaints only the masked area)
#   Cost: standard token cost
#   Note: mask is drawn on canvas and passed as data URI
#
# ANIMATE AD → VIDEO
#   Button: "Animate" on ad card
#   Options: 5s or 10s video
#   Cost: VIDEO_5S or VIDEO_10S tokens (check /api/teams/[teamId]/subscription for rates)
#   Result: MP4 video attached to the ad, downloadable
#
# UPSCALE AD → 4K
#   Button: "Upscale" on ad card
#   Cost: upscale token rate
#   Result: high-res version replaces or joins the ad's image versions
#
# ADD MORE CONCEPTS
#   Button: "Add 5 more concepts" (Bespoke campaigns only)
#   Cost: BESPOKE_ADD token cost
#   Result: 5 additional concepts appended to campaign
#
# ADD TEMPLATE SET
#   Button: "Add template set" (Full campaigns only)
#   Cost: FULL_ADD token cost
#   Result: 8 more template ads appended
#
# DELETE ADS
#   Button: Select ads → "Delete selected"
#   No token cost. Irreversible.
#
# DELETE CAMPAIGN
#   Button: Campaign settings → "Delete campaign"
#   No token cost. Deletes all ads. Irreversible.
#
# RENAME CAMPAIGN
#   UI: Campaign title → click to edit (inline rename)
#   Or: Campaign settings → Rename field

echo "This script is a reference guide." >&2
echo "Use browser tool interactions per references/campaign-management.md" >&2
exit 0
