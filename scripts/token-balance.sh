#!/usr/bin/env bash
# token-balance.sh — Fetch team token balance.
# Usage: ./token-balance.sh --cookie TOKEN --team TEAM_ID [--base-url URL] [--json]
set -euo pipefail
BASE_URL="https://admachine.xyz"; COOKIE=""; TEAM_ID=""; JSON_MODE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cookie) COOKIE="$2"; shift 2 ;;
    --team) TEAM_ID="$2"; shift 2 ;;
    --base-url) BASE_URL="$2"; shift 2 ;;
    --json) JSON_MODE=true; shift ;;
    *) echo "Usage: $0 --cookie TOKEN --team TEAM_ID [--base-url URL] [--json]" >&2; exit 1 ;;
  esac
done
[[ -z "$COOKIE" || -z "$TEAM_ID" ]] && {
  echo "Usage: $0 --cookie TOKEN --team TEAM_ID" >&2; exit 1
}
RESP=$(curl -sf \
  -H "Cookie: __Secure-authjs.session-token=${COOKIE}" \
  "${BASE_URL}/api/teams/${TEAM_ID}/subscription")
if $JSON_MODE; then
  echo "$RESP"
else
  echo "$RESP" | python3 -c "
import sys,json
d=json.load(sys.stdin)
tokens=d.get('tokens',d.get('available','?'))
max_t=d.get('maxTokens',d.get('total','?'))
plan=d.get('plan','unknown')
status=d.get('status',d.get('subscriptionStatus','unknown'))
print(f'Plan: {plan} | Tokens: {tokens} / {max_t} | Status: {status}')
"
fi
