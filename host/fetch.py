#!/usr/bin/env python3
"""Download the pinned runtime archives. No account data is accessed."""
import hashlib
import json
import pathlib
import urllib.request

repo = pathlib.Path(__file__).resolve().parent.parent
cache = repo / '.cache'
cache.mkdir(exist_ok=True)
assets = json.loads((repo / 'host/downloads.json').read_text())
for name, asset in assets.items():
    target = cache / name
    if target.exists():
        with target.open('rb') as stream:
            if hashlib.file_digest(stream, 'sha256').hexdigest() == asset['sha256']:
                print(f'{name}: verified')
                continue
    temporary = target.with_suffix(target.suffix + '.part')
    urllib.request.urlretrieve(asset['url'], temporary)
    with temporary.open('rb') as stream:
        actual = hashlib.file_digest(stream, 'sha256').hexdigest()
    if actual != asset['sha256']:
        raise SystemExit(f'Checksum mismatch for {name}; download not used.')
    temporary.replace(target)
    print(f'{name}: downloaded and verified')
