#!/usr/bin/env python3
"""Pulls funding-news RSS feeds into funding.json for the Serverless funding
signals routine, which cannot reach these hosts from its cloud environment."""
import json, re, subprocess, datetime
from xml.etree import ElementTree as ET

FEEDS = {
    "techcrunch_venture": "https://techcrunch.com/category/venture/feed/",
    "techcrunch_ai": "https://techcrunch.com/category/artificial-intelligence/feed/",
    "crunchbase_news": "https://news.crunchbase.com/feed/",
}

def fetch(url):
    r = subprocess.run(["curl", "-sL", "-m", "25", "-A", "Mozilla/5.0 (StatusRelay)", url],
                       capture_output=True, text=True, timeout=60)
    return r.stdout

def strip_html(s):
    s = re.sub(r"<[^>]+>", " ", s or "")
    return re.sub(r"\s+", " ", s).strip()

items = []
for name, url in FEEDS.items():
    try:
        root = ET.fromstring(fetch(url).encode("utf-8", "ignore"))
    except Exception:
        continue
    for it in root.iter("item"):
        g = lambda tag: (it.findtext(tag) or "").strip()
        items.append({
            "feed": name,
            "title": strip_html(g("title")),
            "link": g("link"),
            "published": g("pubDate"),
            "summary": strip_html(g("description"))[:600],
        })

out = {
    "fetched_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "feeds": list(FEEDS),
    "items": items,
}
json.dump(out, open("funding.json", "w"), indent=1)
print(f"wrote funding.json with {len(items)} items")
