"""Refresh crate quantities and verify material IDs using Wowhead Forever XML.

Runs only on a developer's computer. Uses six concurrent HTTP reads with cached
raw responses under research/. No runtime addon network requests are involved.
Unknown crate types/material names fail explicitly for review instead of guessing
item IDs. Use --fresh to bypass the local cache. Requires Python 3.10+.
"""
import argparse
import concurrent.futures
import datetime
import hashlib
import html
import json
import pathlib
import re
import urllib.request
import xml.etree.ElementTree as ET
from build_catalog import ROOT, build


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--fresh', action='store_true')
    args = parser.parse_args()
    path = ROOT / 'data/catalog.json'
    catalog = json.loads(path.read_text())
    cache = ROOT / 'research'
    cache.mkdir(exist_ok=True)
    names = {name: int(i) for i, name in catalog['materials'].items()}

    def fetch(job):
        kind, item_id = job
        target = cache / f'{kind}-{item_id}.xml'
        if args.fresh or not target.exists():
            url = f'https://www.wowhead.com/forever/item={item_id}&xml'
            with urllib.request.urlopen(url, timeout=45) as response:
                raw = response.read()
            # Do not cache challenge pages/errors as valid XML.
            item = ET.fromstring(raw).find('item')
            assert item is not None and int(item.attrib['id']) == item_id, url
            target.write_bytes(raw)
        raw = target.read_bytes()
        item = ET.fromstring(raw).find('item')
        assert item is not None and int(item.attrib['id']) == item_id
        return kind, item_id, raw, item

    jobs = [('crate', c['itemID']) for c in catalog['crates']]
    jobs += [('material', int(i)) for i in catalog['materials']]
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as executor:
        results = list(executor.map(fetch, jobs))
    new_crates = []
    for kind, item_id, raw, item in results:
        if kind == 'material':
            assert item.findtext('name') == catalog['materials'][str(item_id)], item_id
            continue
        tooltip = html.unescape(re.sub('<[^>]+>', '\n', item.findtext('htmlTooltip')))
        options = []
        for quantity, name in re.findall(r'- (\d+) ([^\n]+)', tooltip):
            name = name.strip()
            if name not in names:
                raise ValueError(f'Unknown material {name!r}: verify its Forever item ID and add it before refreshing.')
            options.append({'itemID': names[name], 'quantity': int(quantity)})
        assert 2 <= len(options) <= 5, f'Incomplete requirements for {item_id}'
        new_crates.append({'itemID': item_id, 'name': item.findtext('name'), 'options': options,
                           'source': f'https://www.wowhead.com/forever/item={item_id}&xml',
                           'sourceSHA256': hashlib.sha256(raw).hexdigest()})
    catalog['crates'] = sorted(new_crates, key=lambda c: c['itemID'])
    if args.fresh:
        catalog['retrieved'] = datetime.date.today().isoformat()
    # The existing catalog is not touched until every download and validation passes.
    temporary = path.with_suffix('.json.tmp')
    temporary.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + '\n')
    temporary.replace(path)
    build()
    print(f"Verified all {len(names)} material names and IDs against Wowhead Forever.")

if __name__ == '__main__':
    main()
