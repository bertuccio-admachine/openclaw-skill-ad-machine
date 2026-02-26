#!/usr/bin/env python3
"""
am.py — Ad Machine CLI for agent automation
Usage: python3 am.py <command> [options]

Requires: AM_SESSION_TOKEN env var (or --token flag)
          AM_TEAM_ID env var (or --team-id flag)
          AM_BASE_URL env var (default: https://admachine.xyz)
"""

import argparse
import json
import mimetypes
import os
import sys
import urllib.request
import urllib.error
from pathlib import Path

# ── Config ────────────────────────────────────────────────────────────────────

DEFAULT_BASE = "https://admachine.xyz"


def get_config(args):
    token = getattr(args, "token", None) or os.environ.get("AM_SESSION_TOKEN", "")
    team_id = getattr(args, "team_id", None) or os.environ.get("AM_TEAM_ID", "")
    base = os.environ.get("AM_BASE_URL", DEFAULT_BASE).rstrip("/")
    return token, team_id, base


def make_headers(token: str, content_type: str = "application/json") -> dict:
    return {
        "Cookie": f"__Secure-authjs.session-token={token}",
        "Content-Type": content_type,
        "Accept": "application/json",
    }


def api_post(base: str, token: str, path: str, payload: dict) -> dict:
    url = f"{base}{path}"
    data = json.dumps(payload).encode()
    req = urllib.request.Request(url, data=data, headers=make_headers(token), method="POST")
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"[ERROR] HTTP {e.code}: {body}", file=sys.stderr)
        sys.exit(1)


def api_get(base: str, token: str, path: str) -> dict:
    url = f"{base}{path}"
    req = urllib.request.Request(url, headers=make_headers(token), method="GET")
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"[ERROR] HTTP {e.code}: {body}", file=sys.stderr)
        sys.exit(1)


# ── Commands ──────────────────────────────────────────────────────────────────

def cmd_auth(args):
    """Test that the session token is valid and print team info."""
    token, team_id, base = get_config(args)
    if not token:
        print("[ERROR] No session token. Set AM_SESSION_TOKEN or pass --token", file=sys.stderr)
        sys.exit(1)
    if not team_id:
        print("[ERROR] No team ID. Set AM_TEAM_ID or pass --team-id", file=sys.stderr)
        sys.exit(1)

    result = api_get(base, token, f"/api/teams/{team_id}/subscription")
    print(json.dumps(result, indent=2))
    print("\n[OK] Auth valid.")


def cmd_tokens(args):
    """Get token balance and subscription info for a team."""
    token, team_id, base = get_config(args)
    if not team_id:
        print("[ERROR] --team-id required", file=sys.stderr)
        sys.exit(1)
    result = api_get(base, token, f"/api/teams/{team_id}/subscription")
    print(json.dumps(result, indent=2))


def cmd_upload(args):
    """Upload a file to R2 via presigned URL. Returns R2 key."""
    token, team_id, base = get_config(args)
    if not team_id:
        print("[ERROR] --team-id required", file=sys.stderr)
        sys.exit(1)

    filepath = Path(args.file)
    if not filepath.exists():
        print(f"[ERROR] File not found: {filepath}", file=sys.stderr)
        sys.exit(1)

    file_size = filepath.stat().st_size
    content_type, _ = mimetypes.guess_type(str(filepath))
    if not content_type or content_type not in ("image/png", "image/jpeg", "image/webp", "image/gif"):
        # Default to jpeg for unknown types
        content_type = "image/jpeg"

    upload_type = args.type  # product | style | swipe | character | misc | ugc | inspiration | reference

    # Step 1: Get presigned URL
    print(f"[1/2] Requesting presigned URL for {filepath.name} ({content_type}, {file_size} bytes)...")
    presign_result = api_post(base, token, "/api/upload/presign", {
        "teamId": team_id,
        "type": upload_type,
        "contentType": content_type,
        "fileSize": file_size,
    })

    presigned_url = presign_result["presignedUrl"]
    r2_key = presign_result["key"]
    print(f"    R2 key: {r2_key}")

    # Step 2: PUT file to presigned URL
    print(f"[2/2] Uploading to R2...")
    with open(filepath, "rb") as f:
        file_data = f.read()

    put_req = urllib.request.Request(
        presigned_url,
        data=file_data,
        headers={"Content-Type": content_type, "Content-Length": str(file_size)},
        method="PUT",
    )
    try:
        with urllib.request.urlopen(put_req) as resp:
            if resp.status not in (200, 204):
                print(f"[ERROR] Upload failed with status {resp.status}", file=sys.stderr)
                sys.exit(1)
    except urllib.error.HTTPError as e:
        print(f"[ERROR] Upload failed: HTTP {e.code} {e.read().decode()}", file=sys.stderr)
        sys.exit(1)

    print(f"\n[OK] Uploaded. R2 key: {r2_key}")
    # Output just the key for scripting
    if args.json:
        print(json.dumps({"key": r2_key, "contentType": content_type}))
    else:
        print(r2_key)


def cmd_enhance(args):
    """Enhance a creative brief / prompt using AI."""
    token, _, base = get_config(args)
    prompt = args.prompt
    result = api_post(base, token, "/api/enhance-prompt", {"prompt": prompt})
    enhanced = result.get("enhancedPrompt", "")
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print(enhanced)


def cmd_stream(args):
    """Monitor SSE generation stream for a campaign. Prints events as they arrive."""
    token, _, base = get_config(args)
    campaign_id = args.campaign_id

    url = f"{base}/api/campaigns/{campaign_id}/stream"
    headers = {
        "Cookie": f"__Secure-authjs.session-token={token}",
        "Accept": "text/event-stream",
        "Cache-Control": "no-cache",
    }

    print(f"[→] Connecting to SSE stream for campaign {campaign_id}...")
    req = urllib.request.Request(url, headers=headers, method="GET")

    try:
        with urllib.request.urlopen(req) as resp:
            event_type = None
            for raw_line in resp:
                line = raw_line.decode("utf-8").rstrip("\n")
                if line.startswith("event:"):
                    event_type = line[6:].strip()
                elif line.startswith("data:"):
                    data_str = line[5:].strip()
                    try:
                        data = json.loads(data_str)
                    except json.JSONDecodeError:
                        data = data_str

                    # Pretty-print events
                    if event_type == "ad_generating":
                        print(f"  [⏳] Generating: {data.get('title', data.get('adId', '?'))}")
                    elif event_type == "ad_completed":
                        print(f"  [✓] Done: {data.get('title', '?')} → {data.get('imageUrl', '')[:60]}...")
                    elif event_type == "ad_error":
                        print(f"  [✗] Error on {data.get('adId', '?')}: {data.get('error', '')}")
                    elif event_type == "insufficient_tokens":
                        print(f"  [!] Insufficient tokens: need {data.get('required')}, have {data.get('remaining')}")
                    elif event_type == "campaign_done":
                        print(f"\n[✓] Campaign complete. {data.get('completedCount', '?')} ads generated.")
                    elif event_type == "error":
                        print(f"[✗] Stream error: {data.get('message', data)}")
                    else:
                        print(f"  [{event_type}] {json.dumps(data)}")

                    if event_type in ("campaign_done", "error"):
                        break
                    event_type = None

    except urllib.error.HTTPError as e:
        print(f"[ERROR] HTTP {e.code}: {e.read().decode()}", file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        print("\n[→] Stream cancelled by user.")


def cmd_download(args):
    """Download a single ad file via the proxy endpoint."""
    token, _, base = get_config(args)

    url = args.url
    filename = args.filename or url.split("/")[-1].split("?")[0] or "download"
    out_path = args.out or filename

    print(f"[→] Downloading {url[:60]}...")
    data = json.dumps({"url": url, "filename": filename}).encode()
    req = urllib.request.Request(
        f"{base}/api/download",
        data=data,
        headers=make_headers(token),
        method="POST",
    )
    try:
        with urllib.request.urlopen(req) as resp:
            content = resp.read()
            with open(out_path, "wb") as f:
                f.write(content)
            print(f"[OK] Saved to {out_path} ({len(content)} bytes)")
    except urllib.error.HTTPError as e:
        print(f"[ERROR] HTTP {e.code}: {e.read().decode()}", file=sys.stderr)
        sys.exit(1)


def cmd_download_raw(base: str, token: str, url: str, filename: str, out_path: str):
    """Internal helper: download binary file via proxy."""
    data = json.dumps({"url": url, "filename": filename}).encode()
    req = urllib.request.Request(
        f"{base}/api/download",
        data=data,
        headers=make_headers(token),
        method="POST",
    )
    with urllib.request.urlopen(req) as resp:
        content = resp.read()
        with open(out_path, "wb") as f:
            f.write(content)
    return out_path


def cmd_export_zip(args):
    """Export multiple ads as a zip file."""
    token, _, base = get_config(args)

    # Parse files: expect JSON array string or individual --url flags
    if args.files_json:
        files = json.loads(args.files_json)
    else:
        print("[ERROR] --files-json required (JSON array of {url, filename} objects)", file=sys.stderr)
        sys.exit(1)

    zip_filename = args.zip_filename or "ad-machine-export.zip"
    out_path = args.out or zip_filename

    print(f"[→] Requesting zip export ({len(files)} files)...")
    data = json.dumps({"files": files, "zipFilename": zip_filename}).encode()
    req = urllib.request.Request(
        f"{base}/api/download/zip",
        data=data,
        headers=make_headers(token),
        method="POST",
    )
    try:
        with urllib.request.urlopen(req) as resp:
            content = resp.read()
            with open(out_path, "wb") as f:
                f.write(content)
            print(f"[OK] Zip saved to {out_path} ({len(content)} bytes)")
    except urllib.error.HTTPError as e:
        print(f"[ERROR] HTTP {e.code}: {e.read().decode()}", file=sys.stderr)
        sys.exit(1)


def cmd_export_meta(args):
    """Export ads as Meta-ready zip with manifest and README."""
    token, _, base = get_config(args)

    if args.files_json:
        files = json.loads(args.files_json)
    else:
        print("[ERROR] --files-json required", file=sys.stderr)
        sys.exit(1)

    campaign_name = args.campaign_name or "Campaign"
    manifest = json.loads(args.manifest_json) if args.manifest_json else []
    out_path = args.out or f"{campaign_name.replace(' ', '_')}_meta.zip"

    print(f"[→] Building Meta export for '{campaign_name}' ({len(files)} files)...")
    data = json.dumps({
        "files": files,
        "campaignName": campaign_name,
        "manifest": manifest,
    }).encode()
    req = urllib.request.Request(
        f"{base}/api/export/meta",
        data=data,
        headers=make_headers(token),
        method="POST",
    )
    try:
        with urllib.request.urlopen(req) as resp:
            content = resp.read()
            with open(out_path, "wb") as f:
                f.write(content)
            print(f"[OK] Meta export saved to {out_path} ({len(content)} bytes)")
    except urllib.error.HTTPError as e:
        print(f"[ERROR] HTTP {e.code}: {e.read().decode()}", file=sys.stderr)
        sys.exit(1)


# ── CLI Setup ─────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        prog="am.py",
        description="Ad Machine CLI — agent automation for admachine.xyz",
    )
    parser.add_argument("--token", help="Session token (overrides AM_SESSION_TOKEN)")
    parser.add_argument("--team-id", dest="team_id", help="Team ID (overrides AM_TEAM_ID)")

    sub = parser.add_subparsers(dest="command", required=True)

    # auth
    p_auth = sub.add_parser("auth", help="Test auth and print team info")

    # tokens
    p_tokens = sub.add_parser("tokens", help="Get token balance and subscription info")

    # upload
    p_upload = sub.add_parser("upload", help="Upload a file to R2")
    p_upload.add_argument("file", help="Path to image file")
    p_upload.add_argument("--type", default="product",
        choices=["product", "style", "swipe", "character", "misc", "ugc", "inspiration", "reference"],
        help="Upload type (default: product)")
    p_upload.add_argument("--json", action="store_true", help="Output JSON with key + contentType")

    # enhance
    p_enhance = sub.add_parser("enhance", help="AI-enhance a creative brief")
    p_enhance.add_argument("prompt", help="Prompt to enhance")
    p_enhance.add_argument("--json", action="store_true", help="Output raw JSON response")

    # stream
    p_stream = sub.add_parser("stream", help="Monitor campaign generation SSE stream")
    p_stream.add_argument("campaign_id", help="Campaign ID")

    # download
    p_dl = sub.add_parser("download", help="Download a single ad via proxy")
    p_dl.add_argument("url", help="Ad asset URL (must be Ad Machine storage URL)")
    p_dl.add_argument("--filename", help="Filename for download")
    p_dl.add_argument("--out", help="Output path (default: filename)")

    # export-zip
    p_zip = sub.add_parser("export-zip", help="Export multiple ads as zip")
    p_zip.add_argument("--files-json", dest="files_json",
        help='JSON array: \'[{"url":"...","filename":"..."}]\'')
    p_zip.add_argument("--zip-filename", dest="zip_filename", help="Zip filename")
    p_zip.add_argument("--out", help="Output path")

    # export-meta
    p_meta = sub.add_parser("export-meta", help="Export ads as Meta-ready zip")
    p_meta.add_argument("--files-json", dest="files_json",
        help='JSON array of {url, filename}')
    p_meta.add_argument("--campaign-name", dest="campaign_name", help="Campaign name")
    p_meta.add_argument("--manifest-json", dest="manifest_json",
        help="JSON manifest array (optional, for full Meta format)")
    p_meta.add_argument("--out", help="Output path")

    args = parser.parse_args()

    commands = {
        "auth": cmd_auth,
        "tokens": cmd_tokens,
        "upload": cmd_upload,
        "enhance": cmd_enhance,
        "stream": cmd_stream,
        "download": cmd_download,
        "export-zip": cmd_export_zip,
        "export-meta": cmd_export_meta,
    }

    commands[args.command](args)


if __name__ == "__main__":
    main()
