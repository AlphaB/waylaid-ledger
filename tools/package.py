"""Build a source-inclusive ZIP with a standard installable addon folder."""
import pathlib
import re
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]

def package():
    toc = (ROOT / 'WaylaidLedger/WaylaidLedger.toc').read_text()
    assert toc == (ROOT / 'WaylaidLedger/WaylaidLedger_Camelot.toc').read_text()
    version = re.search(r'^## Version: ([0-9.]+)$', toc, re.MULTILINE).group(1)
    core = (ROOT / 'WaylaidLedger/Core.lua').read_text()
    assert f'addon.version = "{version}"' in core
    assert '## OptionalDeps: Auctionator, TradeSkillMaster' in toc
    for line in toc.splitlines():
        if line.strip() and not line.startswith('#'):
            assert (ROOT / 'WaylaidLedger' / line).is_file(), line
    output = ROOT / 'dist' / f'WaylaidLedger-{version}.zip'
    output.parent.mkdir(exist_ok=True)
    paths = []
    for directory in ['WaylaidLedger', 'tools', 'tests', 'data', 'docs', '.github']:
        paths += [p for p in (ROOT / directory).rglob('*') if p.is_file() and '__pycache__' not in p.parts]
    paths += [ROOT / name for name in ['README.md', 'LICENSE', 'requirements-dev.txt', '.gitignore']]
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(paths):
            archive.write(path, path.relative_to(ROOT))
    with zipfile.ZipFile(output) as archive:
        assert archive.testzip() is None
        assert 'WaylaidLedger/WaylaidLedger.toc' in archive.namelist()
    print(output)
    print(f'{len(paths)} files, {output.stat().st_size:,} bytes; archive integrity passed')

if __name__ == '__main__':
    package()
