#!/usr/bin/env bash
# export-campaign.sh — Download ads as single files, ZIP, or Meta export pack.
#
# Modes:
#   single  POST /api/download         → one file
#   zip     POST /api/download/zip     → ZIP archive
#   meta    POST /api/export/meta      → Meta Ads Manager pack (manifest + README)
#
# Usage (single):
#   ./export-campaign.sh --cookie TOKEN --mode single \
#     --url "https://..." --filename "ad.png" --out ./dl/
#
# Usage (zip):
#   ./export-campaign.sh --cookie TOKEN --mode zip \
#     --files '[{"url":"...","filename":"ad1.png"}]' \
#     --zip-name "export.zip" --out ./dl/
#
# Usage (meta):
#   ./export-campaign.sh --cookie TOKEN --mode meta \
#     --files '[{"url":"...","filename":"01_feed_img.png"}]' \
#     --manifest '[{"adId":"...","adTitle":"...","mediaType":"image","aspectRatio":"4:5","placementCode":"feed","recommendedPlacement":"Instagram Feed","source":"bespoke"}]' \
#     --campaign-name "Winter Sale" --zip-name "Meta_Export.zip" --out ./dl/
set -euo pipefail
BASE_URL="https://admachine.xyz"; COOKIE=""; MODE=""; OUT_DIR="."
SINGLE_URL=""; SINGLE_FILENAME=""; FILES_JSON=""; MANIFEST_JSON="[]"
ZIP_NAME="AdMachine_Export.zip"; CAMPAIGN_NAME="Campaign"; INCLUDE_README="true"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cookie) COOKIE="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --base-url) BASE_URL="$2"; shift 2 ;;
    --out) OUT_DIR="$2"; shift 2 ;;
    --url) SINGLE_URL="$2"; shift 2 ;;
    --filename) SINGLE_FILENAME="$2"; shift 2 ;;
    --files) FILES_JSON="$2"; shift 2 ;;
    --manifest) MANIFEST_JSON="$2"; shift 2 ;;
    --zip-name) ZIP_NAME="$2"; shift 2 ;;
    --campaign-name) CAMPAIGN_NAME="$2"; shift 2 ;;
    --no-readme) INCLUDE_README="false"; shift ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done
[[ -z "$COOKIE" || -z "$MODE" ]] && { echo "Usage: $0 --cookie TOKEN --mode (single|zip|meta) ..." >&2; exit 1; }
mkdir -p "$OUT_DIR"
case "$MODE" in
  single)
    [[ -z "$SINGLE_URL" || -z "$SINGLE_FILENAME" ]] && { echo "--url and --filename required" >&2; exit 1; }
    OUT_FILE="${OUT_DIR}/${SINGLE_FILENAME}"
    PAYLOAD=$(python3 -c "import json,sys;print(json.dumps({'url':sys.argv[1],'filename':sys.argv[2]}))" "$SINGLE_URL" "$SINGLE_FILENAME")
    HTTP=$(curl -sf -o "$OUT_FILE" -w "%{http_code}" -X POST \
      -H "Content-Type: application/json" \
      -H "Cookie: __Secure-authjs.session-token=${COOKIE}" \
      -d "$PAYLOAD" "${BASE_URL}/api/download")
    [[ "$HTTP" == "200" ]] || { echo "[export] HTTP $HTTP" >&2; exit 1; }
    echo "[export] Saved: $OUT_FILE" >&2; echo "$OUT_FILE" ;;
  zip)
    [[ -z "$FILES_JSON" ]] && { echo "--files required" >&2; exit 1; }
    OUT_FILE="${OUT_DIR}/${ZIP_NAME}"
    PAYLOAD=$(python3 -c "import json,sys;files=json.loads(sys.argv[1]);print(json.dumps({'files':files,'zipFilename':sys.argv[2]}))" "$FILES_JSON" "$ZIP_NAME")
    HTTP=$(curl -sf -o "$OUT_FILE" -w "%{http_code}" -X POST \
      -H "Content-Type: application/json" \
      -H "Cookie: __Secure-authjs.session-token=${COOKIE}" \
      -d "$PAYLOAD" "${BASE_URL}/api/download/zip")
    [[ "$HTTP" == "200" ]] || { echo "[export] HTTP $HTTP" >&2; exit 1; }
    echo "[export] ZIP saved: $OUT_FILE" >&2; echo "$OUT_FILE" ;;
  meta)
    [[ -z "$FILES_JSON" ]] && { echo "--files required" >&2; exit 1; }
    OUT_FILE="${OUT_DIR}/${ZIP_NAME}"
    PAYLOAD=$(python3 -c "
import json,sys
files=json.loads(sys.argv[1]); manifest=json.loads(sys.argv[2])
print(json.dumps({'files':files,'manifest':manifest,'zipFilename':sys.argv[3],'campaignName':sys.argv[4],'includeREADME':sys.argv[5]=='true'}))
" "$FILES_JSON" "$MANIFEST_JSON" "$ZIP_NAME" "$CAMPAIGN_NAME" "$INCLUDE_README")
    HTTP=$(curl -sf -o "$OUT_FILE" -w "%{http_code}" -X POST \
      -H "Content-Type: application/json" \
      -H "Cookie: __Secure-authjs.session-token=${COOKIE}" \
      -d "$PAYLOAD" "${BASE_URL}/api/export/meta")
    [[ "$HTTP" == "200" ]] || { echo "[export] HTTP $HTTP" >&2; exit 1; }
    echo "[export] Meta pack saved: $OUT_FILE" >&2; echo "$OUT_FILE" ;;
  *)
    echo "Unknown mode: $MODE (use single, zip, meta)" >&2; exit 1 ;;
esac
