#!/usr/bin/env bash
# upload-asset.sh — Presign + upload a file to Ad Machine R2 storage.
# Prints the R2 key to stdout on success.
#
# Usage:
#   ./upload-asset.sh --cookie TOKEN --team TEAM_ID --file PATH --type TYPE [--base-url URL]
# Types: product | style | swipe | character | inspiration | reference | ugc | misc
set -euo pipefail
BASE_URL="https://admachine.xyz"; COOKIE=""; TEAM_ID=""; FILE_PATH=""; ASSET_TYPE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cookie) COOKIE="$2"; shift 2 ;;
    --team) TEAM_ID="$2"; shift 2 ;;
    --file) FILE_PATH="$2"; shift 2 ;;
    --type) ASSET_TYPE="$2"; shift 2 ;;
    --base-url) BASE_URL="$2"; shift 2 ;;
    *) echo "Usage: $0 --cookie TOKEN --team TEAM_ID --file FILE --type TYPE" >&2; exit 1 ;;
  esac
done
[[ -z "$COOKIE" || -z "$TEAM_ID" || -z "$FILE_PATH" || -z "$ASSET_TYPE" ]] && {
  echo "Usage: $0 --cookie TOKEN --team TEAM_ID --file FILE --type TYPE" >&2; exit 1
}
[[ ! -f "$FILE_PATH" ]] && { echo "[upload-asset] File not found: $FILE_PATH" >&2; exit 1; }
MIME=$(file --brief --mime-type "$FILE_PATH" 2>/dev/null || echo "image/png")
case "$MIME" in image/png|image/jpeg|image/webp|image/gif) ;;
  *) MIME="image/png" ;; esac
FILE_SIZE=$(stat -f%z "$FILE_PATH" 2>/dev/null || stat -c%s "$FILE_PATH")
echo "[upload-asset] Presigning type=$ASSET_TYPE mime=$MIME size=${FILE_SIZE}b" >&2
PRESIGN_RESP=$(curl -sf -X POST \
  -H "Content-Type: application/json" \
  -H "Cookie: __Secure-authjs.session-token=${COOKIE}" \
  -d "{\"teamId\":\"${TEAM_ID}\",\"type\":\"${ASSET_TYPE}\",\"contentType\":\"${MIME}\",\"fileSize\":${FILE_SIZE}}" \
  "${BASE_URL}/api/upload/presign")
[[ -z "$PRESIGN_RESP" ]] && { echo "[upload-asset] Empty presign response" >&2; exit 1; }
PRESIGNED_URL=$(echo "$PRESIGN_RESP" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['presignedUrl'])")
R2_KEY=$(echo "$PRESIGN_RESP" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['key'])")
[[ -z "$PRESIGNED_URL" || -z "$R2_KEY" ]] && { echo "[upload-asset] Bad presign response: $PRESIGN_RESP" >&2; exit 1; }
echo "[upload-asset] Uploading to R2..." >&2
HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" -X PUT \
  -H "Content-Type: ${MIME}" --data-binary "@${FILE_PATH}" "$PRESIGNED_URL")
[[ "$HTTP_CODE" == "200" ]] || { echo "[upload-asset] R2 upload failed: HTTP $HTTP_CODE" >&2; exit 1; }
echo "[upload-asset] OK. Key:" >&2
echo "$R2_KEY"
