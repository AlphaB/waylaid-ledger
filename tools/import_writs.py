"""Import Forever writ objectives from Wowhead; no runtime game/network dependency.

The current quest index contains both old Argent Dawn and new Forever writs.
Only quests first seen in patch 16001 are considered. The quest's objective table
must explicitly require exactly one named Craftsman's Writ and at least one
other item. Unknown/incomplete objectives are reported rather than guessed.
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
import urllib.error

ROOT = pathlib.Path(__file__).resolve().parents[1]
QUEST_INDEX = "https://www.wowhead.com/forever/quests/name:Craftsman%27s%20Writ"


def parse_index(text):
    for match in re.finditer(r'data:\s*\[', text):
        try:
            rows, _ = json.JSONDecoder().raw_decode(text[match.end() - 1:])
        except ValueError:
            continue
        if rows and isinstance(rows[0], dict) and 'category' in rows[0]:
            return [q for q in rows if q.get('firstseenpatch') == 16001
                    and q.get('name', '').startswith("Craftsman's Writ:")]
    raise ValueError('Wowhead quest list did not contain a parseable quest index')


def parse_objectives(text):
    heading = re.search(r'<h1\b[^>]*>.*?</h1>', text, re.S)
    assert heading, 'Missing quest heading'
    table = re.search(r'<table class="icon-list"[^>]*>(.*?)</table>', text[heading.end():], re.S)
    assert table, 'Missing quest objective table'
    rows = []
    for match in re.finditer(r'<tr\b[^>]*data-icon-list-quantity="(\d+)"[^>]*>(.*?)</tr>', table.group(1), re.S):
        link = re.search(r'<a\b[^>]*href="[^\"]*item=(\d+)[^\"]*"[^>]*>(.*?)</a>', match.group(2), re.S)
        assert link, 'Objective has no item link'
        rows.append({'itemID': int(link.group(1)), 'quantity': int(match.group(1)),
                     'name': html.unescape(re.sub('<[^>]*>', '', link.group(2)))})
    assert rows, 'No item objectives'
    return rows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cache', type=pathlib.Path, default=ROOT / 'research/writs')
    parser.add_argument('--refresh', action='store_true')
    args = parser.parse_args()
    args.cache.mkdir(parents=True, exist_ok=True)

    def fetch(name, url):
        path = args.cache / name
        if args.refresh or not path.exists():
            with urllib.request.urlopen(url, timeout=45) as response:
                raw = response.read()
            assert b'<html' in raw.lower(), f'Unexpected response for {url}'
            path.write_bytes(raw)
        return path.read_bytes()

    index = parse_index(fetch('quests.html', QUEST_INDEX).decode())

    def read_quest(quest):
        quest_id = quest['id']
        url = f'https://www.wowhead.com/forever/quest={quest_id}'
        try:
            raw = fetch(f'quest-{quest_id}.html', url)
            rows = parse_objectives(raw.decode())
            writs = [r for r in rows if r['name'].startswith("Craftsman's Writ:")]
            assert len(writs) == 1 and writs[0]['name'] == quest['name'], 'Writ objective/name mismatch'
            writ = writs[0]
            requirements = [r for r in rows if r['itemID'] != writ['itemID']]
            assert requirements and all(r['quantity'] > 0 for r in requirements)
            return {'itemID': writ['itemID'], 'questID': quest_id, 'name': writ['name'],
                    'requirements': requirements, 'source': url,
                    'sourceSHA256': hashlib.sha256(raw).hexdigest()}, None
        except (AssertionError, ValueError, OSError) as error:
            return None, {'questID': quest_id, 'name': quest['name'], 'reason': str(error), 'source': url}

    records, missing = [], []
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
        for number, (record, problem) in enumerate(executor.map(read_quest, index), 1):
            if record: records.append(record)
            if problem: missing.append(problem)
            if number % 20 == 0: print(f'Processed {number}/{len(index)} quests', flush=True)
    if missing:
        for problem in missing:
            print(f'Unresolved {problem["source"]}: {problem["reason"]}')
        raise SystemExit("Import incomplete; existing catalog was not changed.")
    assert len({r['itemID'] for r in records}) == len(records), 'Duplicate writ items require manual review'
    catalog = {'retrieved': datetime.date.today().isoformat(), 'indexSource': QUEST_INDEX,
               'writs': sorted(records, key=lambda r: r['itemID']), 'unresolved': missing}
    temporary = ROOT / 'data/writs.json.tmp'
    temporary.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + '\n')
    temporary.replace(ROOT / 'data/writs.json')
    required = {r['itemID'] for w in records for r in w['requirements']}
    crates = json.loads((ROOT / 'data/catalog.json').read_text())
    extra = required - {int(i) for i in crates['materials']}
    print(f'{len(records)} writs; {len(required)} delivery items; {len(extra)} new versus crate scans; {len(missing)} unresolved')
    from build_writs import build
    build()

if __name__ == '__main__':
    main()
