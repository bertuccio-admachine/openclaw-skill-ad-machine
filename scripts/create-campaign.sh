#!/usr/bin/env bash
# create-campaign.sh
# Browser automation wrapper for creating Ad Machine campaigns.
# Uses OpenClaw browser + CDP for reliable file injection.
#
# This script calls the OpenClaw `browser` tool via the CLI.
# It is a GUIDE for agents — agents should use the browser tool directly
# following the exact sequence documented in references/browser-automation.md
#
# Usage reference (for agents reading this):
#   1. navigate to https://admachine.xyz/<teamId>
#   2. Upload product image via CDP DOM.setFileInputFiles (see browser-automation.md)
#   3. Select format button by text (e.g. "Instagram Portrait 4:5")
#   4. Select quality (2K/4K)
#   5. Click campaign type button
#   6. For Director: fill brief textarea + upload optional refs
#   7. Wait for redirect to /<teamId>/campaigns/<id>
#   8. Connect to SSE stream to monitor progress
#
# Campaign types → button text → token cost:
#   full       → "Launch Full Campaign"   → 200 tokens → 8 ads
#   bespoke    → "Bespoke"                → 40 tokens  → 5 ads
#   director   → "Director"               → 80 tokens  → 8 ads
#   single     → "Single"                 → 10 tokens  → 1 ad
#
# File input index mapping (0-based):
#   0        = product image (required for all types)
#   1        = second product angle (optional, multi-view)
#   N-3      = Style Dropper reference (Director only)
#   N-2      = Swipe reference (Director only)
#   N-1      = Character reference (Director only)
#   where N = total number of file inputs on the page
#
# CDP file injection (Node.js example):
# ─────────────────────────────────────
# const ws = new WebSocket(targetWsUrl);
# ws.onopen = () => {
#   // Enable DOM domain
#   ws.send(JSON.stringify({id:1, method:'DOM.enable', params:{}}));
# };
# // After DOM.enable ack:
# ws.send(JSON.stringify({
#   id: 2,
#   method: 'DOM.getDocument',
#   params: {depth: 0}
# }));
# // Use rootNodeId to querySelector
# ws.send(JSON.stringify({
#   id: 3,
#   method: 'DOM.querySelector',
#   params: { nodeId: rootNodeId, selector: 'input[type=file]' }
# }));
# // Use returned nodeId to inject file
# ws.send(JSON.stringify({
#   id: 4,
#   method: 'DOM.setFileInputFiles',
#   params: {
#     nodeId: fileInputNodeId,
#     files: ['/absolute/path/to/image.png']
#   }
# }));

echo "This script is a reference guide. Agents should follow browser-automation.md directly." >&2
echo "See: skills/ad-machine/references/browser-automation.md" >&2
exit 0
