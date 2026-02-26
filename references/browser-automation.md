# Browser Automation Guide — Ad Machine

## Overview
Campaign creation requires browser interaction. The critical constraint is **file upload**: React's file input does not respond to standard browser `upload` tool calls. CDP `DOM.setFileInputFiles` is the only reliable method.

---

## Prerequisites
- OpenClaw browser running (`browser action=start`)
- Ad Machine session active at admachine.xyz (logged in)
- Session cookie extracted via `scripts/extract-cookie.js` for any API calls

---

## Session Cookie Extraction

```
browser action=snapshot → find CDP WebSocket URL
node --experimental-websocket scripts/extract-cookie.js [--port 9222]
```

Or use the browser `snapshot` to confirm you're on an authenticated page before proceeding.

---

## Campaign Creation Flow

### Step 1: Navigate to Dashboard
```
browser action=navigate targetUrl=https://admachine.xyz/<teamId>
```
Wait for the hero upload section to be visible.

### Step 2: Inject Product Image via CDP
**Critical: Use CDP `DOM.setFileInputFiles`, NOT browser upload tool.**

```javascript
// 1. Get CDP target list
const targets = await fetch('http://localhost:9222/json').then(r => r.json());
const target = targets.find(t => t.type === 'page' && t.webSocketDebuggerUrl);
const ws = new WebSocket(target.webSocketDebuggerUrl);

// 2. Enable DOM domain
ws.send(JSON.stringify({id:1, method:'DOM.enable', params:{}}));

// 3. Get root document node
ws.send(JSON.stringify({id:2, method:'DOM.getDocument', params:{depth:0}}));
// → response.result.root.nodeId = rootNodeId

// 4. Find all file inputs
ws.send(JSON.stringify({
  id: 3,
  method: 'DOM.querySelectorAll',
  params: { nodeId: rootNodeId, selector: 'input[type=file]' }
}));
// → response.result.nodeIds = [id0, id1, ...]

// 5. Inject file into product input (index 0)
ws.send(JSON.stringify({
  id: 4,
  method: 'DOM.setFileInputFiles',
  params: {
    nodeId: nodeIds[0],
    files: ['/absolute/path/to/product.png']
  }
}));
```

React fires its onChange handler automatically after `setFileInputFiles`. Wait ~500ms for state to update.

### Step 3: Select Format
Take a snapshot to see format buttons. Click by text:
```
browser action=act request={kind:click, ref:<format-button-ref>}
```
Format options: "Square 1:1", "Landscape 16:9", "Portrait 9:16", "Instagram Portrait 4:5", "Instagram Landscape 5:4"

### Step 4: Select Quality
```
browser action=act request={kind:click, ref:<2K-or-4K-button-ref>}
```

### Step 5: (Director Only) Fill Creative Brief
```
browser action=act request={kind:fill, ref:<textarea-ref>, text:"Your creative brief here"}
```

### Step 6: (Director Only) Upload Reference Images
Determine file input indices from the snapshot:
- Total inputs = N
- Style Dropper = inputs[N-3]
- Swipe reference = inputs[N-2]  
- Character reference = inputs[N-1]

Inject each via CDP `DOM.setFileInputFiles` with the appropriate index.

### Step 7: Click Generate Button
| Campaign Type | Button Text |
|---------------|-------------|
| Full Campaign | "Launch Full Campaign" |
| Bespoke | "Bespoke" |
| Director | "Director" |
| Single Asset | "Single" |

```
browser action=act request={kind:click, ref:<generate-button-ref>}
```

### Step 8: Wait for Redirect
After clicking, the app redirects to `/<teamId>/campaigns/<campaignId>`.
Poll browser snapshot or wait for URL change.

### Step 9: Monitor Generation
```bash
./scripts/campaign-status.sh --cookie "$COOKIE" --campaign "$CAMPAIGN_ID" --timeout 300
```
Or connect to SSE stream directly:
```
GET /api/campaigns/<id>/stream
Accept: text/event-stream
Cookie: __Secure-authjs.session-token=<value>
```

---

## Aspect Ratio → Placement Mapping
| Aspect Ratio | Common Placements |
|---|---|
| 1:1 (Square) | Facebook Feed, Instagram Feed |
| 9:16 (Portrait) | Instagram Stories, TikTok, Reels |
| 16:9 (Landscape) | YouTube, Facebook Video |
| 4:5 (Instagram Portrait) | Instagram Feed (optimal) |
| 5:4 (Instagram Landscape) | Instagram Feed wide |

---

## Troubleshooting

**File not registering after upload:**
- Confirm you used CDP `DOM.setFileInputFiles`, not browser upload tool
- Wait at least 500ms after injection before clicking next element
- Take a snapshot to confirm the file preview appears

**Generate button is disabled:**
- Product image not registered → re-inject via CDP
- No format selected → click a format button
- Insufficient tokens → check `/api/teams/[teamId]/subscription`

**SSE stream disconnects:**
- Reconnect: GET /api/campaigns/[id]/stream again
- Generation resumes; already-completed ads send `ad_completed` immediately
- Refreshing the campaign page also reconnects the stream

**Redirect not happening:**
- Take a snapshot and check for validation errors on the form
- Check for insufficient token alert dialog
