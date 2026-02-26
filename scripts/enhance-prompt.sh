#!/usr/bin/env bash
# enhance-prompt.sh — AI-enhance a creative brief via Ad Machine.
# Usage: ./enhance-prompt.sh --cookie TOKEN --prompt "raw brief" [--base-url URL]
#        echo "raw brief" | ./enhance-prompt.sh --cookie TOKEN
set -euo pipefail
BASE_URL="https://admachine.xyz"; COOKIE=""; PROMPT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cookie) COOKIE="$2"; shift 2 ;;
    --prompt) PROMPT="$2"; shift 2 ;;
    --base-url) BASE_URL="$2"; shift 2 ;;
    *) echo "Usage: $0 --cookie TOKEN --prompt TEXT [--base-url URL]" >&2; exit 1 ;;
  esac
done
[[ -z "$PROMPT" ]] && ! [ -t 0 ] && PROMPT=$(cat)
[[ -z "$COOKIE" ]] && { echo "[enhance-prompt] --cookie required" >&2; exit 1; }
[[ -z "$PROMPT" ]] && { echo "[enhance-prompt] --prompt required" >&2; exit 1; }
PAYLOAD=$(python3 -c "import json,sys;print(json.dumps({'prompt':sys.argv[1]}))" "$PROMPT")
RESP=$(curl -sf -X POST \
  -H "Content-Type: application/json" \
  -H "Cookie: __Secure-authjs.session-token=${COOKIE}" \
  -d "$PAYLOAD" "${BASE_URL}/api/enhance-prompt")
echo "$RESP" | python3 -c "
import sys,json
d=json.load(sys.stdin)
if 'enhancedPrompt' in d:
    print(d['enhancedPrompt'])
else:
    print(json.dumps(d),file=sys.stderr); sys.exit(1)
"
