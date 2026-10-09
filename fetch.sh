#!/usr/bin/env bash
# Fetches competitor status feeds and writes status.json.
# Statuspage sites give JSON; Instatus (Modal, Together) and Better Stack
# (RunPod) block their APIs, so their HTML pages are embedded as text for
# the consumer to parse.
set -u
UA="Mozilla/5.0 (StatusRelay; +https://github.com/alex-remade/status-relay)"
fetch() { curl -sL -m 25 -A "$UA" "$1" || true; }
html_to_text() { python3 -c "
import sys, re
h = sys.stdin.read()
h = re.sub(r'<script.*?</script>', ' ', h, flags=re.S)
h = re.sub(r'<svg.*?</svg>', ' ', h, flags=re.S)
h = re.sub(r'<[^>]+>', '\n', h)
h = re.sub(r'&nbsp;', ' ', h)
lines = [l.strip() for l in h.split('\n') if l.strip()]
print('\n'.join(lines))"; }

python3 - <<'PY'
import json, subprocess, datetime

def sh(cmd):
    return subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=120).stdout

def jget(url):
    out = sh(f'curl -sL -m 25 -A "StatusRelay" "{url}"')
    try:
        return json.loads(out)
    except Exception:
        return {"error": "fetch or parse failed"}

def hget(url):
    out = sh(f'curl -sL -m 25 -A "Mozilla/5.0 (StatusRelay)" "{url}" | ./html2text.py')
    return out[:20000]

data = {
    "fetched_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "baseten": jget("https://status.baseten.co/api/v2/incidents.json"),
    "fireworks": jget("https://status.fireworks.ai/api/v2/incidents.json"),
    "lambda": jget("https://status.lambdalabs.com/api/v2/incidents.json"),
    "modal_incidents_text": hget("https://status.modal.com/incidents"),
    "modal_home_text": hget("https://status.modal.com/"),
    "together_incidents_text": hget("https://status.together.ai/incidents"),
    "runpod_home_text": hget("https://uptime.runpod.io/"),
}
# Trim the Statuspage payloads to the newest 15 incidents each to keep the file small.
for k in ("baseten", "fireworks", "lambda"):
    if isinstance(data[k], dict) and isinstance(data[k].get("incidents"), list):
        data[k]["incidents"] = data[k]["incidents"][:15]
json.dump(data, open("status.json", "w"), indent=1)
print("wrote status.json")
PY
