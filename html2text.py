#!/usr/bin/env python3
import sys, re
h = sys.stdin.read()
h = re.sub(r'<script.*?</script>', ' ', h, flags=re.S)
h = re.sub(r'<svg.*?</svg>', ' ', h, flags=re.S)
h = re.sub(r'<[^>]+>', '\n', h)
h = h.replace('&nbsp;', ' ').replace('&amp;', '&').replace('&#39;', "'")
lines = [l.strip() for l in h.split('\n') if l.strip()]
print('\n'.join(lines))
