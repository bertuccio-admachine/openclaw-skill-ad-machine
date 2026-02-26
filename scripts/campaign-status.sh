#!/usr/bin/env bash
# campaign-status.sh — Stream SSE events for a campaign, report ad generation status.
# Usage: ./campaign-status.sh --cookie TOKEN --campaign ID [--base-url URL] [--timeout 120] [--json]
set -euo pipefail
BASE_URL="https://admachine.xyz"; COOKIE=""; CAMPAIGN_ID=""; TIMEOUT=120; JSON_MODE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cookie) COOKIE="$2"; shift 2 ;;
    --campaign) CAMPAIGN_ID="$2"; shift 2 ;;
    --base-url) BASE_URL="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --json) JSON_MODE=true; shift ;;
    *) echo "Usage: $0 --cookie TOKEN --campaign ID [--timeout SECS] [--json]" >&2; exit 1 ;;
  esac
done
[[ -z "$COOKIE" || -z "$CAMPAIGN_ID" ]] && {
  echo "Usage: $0 --cookie TOKEN --campaign ID" >&2; exit 1
}
echo "[campaign-status] Connecting to SSE: ${BASE_URL}/api/campaigns/${CAMPAIGN_ID}/stream" >&2
timeout "$TIMEOUT" curl -sN \
  -H "Accept: text/event-stream" \
  -H "Cookie: __Secure-authjs.session-token=${COOKIE}" \
  "${BASE_URL}/api/campaigns/${CAMPAIGN_ID}/stream" | \
python3 -c "
import sys, json
event = None; data_lines = []
for line in sys.stdin:
    line = line.rstrip('\n')
    if line.startswith('event:'): event = line[6:].strip()
    elif line.startswith('data:'): data_lines.append(line[5:].strip())
    elif line == '':
        if event and data_lines:
            raw = ' '.join(data_lines)
            try: payload = json.loads(raw)
            except: payload = {'raw': raw}
            print(json.dumps({'event': event, **payload}), flush=True)
            if event == 'ad_generating':
                print(f\"  ⏳ {payload.get('title','?')} (#{payload.get('index',0)+1})\", file=sys.stderr)
            elif event == 'ad_completed':
                print(f\"  ✅ {payload.get('title','?')} → {payload.get('imageUrl','')}\", file=sys.stderr)
            elif event == 'ad_error':
                print(f\"  ❌ {payload.get('title','?')}: {payload.get('error','')}\", file=sys.stderr)
            elif event == 'insufficient_tokens':
                print(f\"  ⚠️  Insufficient tokens: {payload.get('title','?')}\", file=sys.stderr)
            elif event == 'campaign_done':
                print(f\"\n✅ Campaign done. {payload.get('completedCount','?')} ads.\", file=sys.stderr)
        event = None; data_lines = []
"
echo "[campaign-status] Stream ended." >&2
