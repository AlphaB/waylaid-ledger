"""Build a clean install ZIP with exactly one addon folder."""

import argparse
import pathlib
import re
import subprocess
import sys
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]


def package(navigation_ui=None):
    command = [sys.executable, str(ROOT / "tests/run.py")]
    if navigation_ui:
        command.extend(["--navigation-ui", str(navigation_ui), "--forever-navigation", str(navigation_ui)])
    subprocess.run(command, cwd=ROOT, check=True)
    addon = ROOT / "WaylaidLedger"
    toc = (addon / "WaylaidLedger.toc").read_text()
    assert toc == (addon / "WaylaidLedger_Camelot.toc").read_text()
    version = re.search(r"^## Version: ([0-9.]+)$", toc, re.MULTILINE).group(1)
    assert f'addon.version = "{version}"' in (addon / "Core.lua").read_text()
    assert "## OptionalDeps: Auctionator, TradeSkillMaster" in toc
    for line in toc.splitlines():
        if line.strip() and not line.startswith("#"):
            assert (addon / line).is_file(), line
    output = ROOT / "dist" / f"WaylaidLedger-{version}.zip"
    output.parent.mkdir(exist_ok=True)
    paths = sorted(p for p in addon.rglob("*") if p.is_file())
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as archive:
        for path in paths:
            archive.write(path, path.relative_to(ROOT))
        archive.write(ROOT / "LICENSE", "WaylaidLedger/LICENSE")
    with zipfile.ZipFile(output) as archive:
        assert archive.testzip() is None
        assert "WaylaidLedger/WaylaidLedger.toc" in archive.namelist()
        assert all(name.startswith("WaylaidLedger/") for name in archive.namelist())
    print(output)
    print(f"{len(paths) + 1} files, {output.stat().st_size:,} bytes; archive integrity passed")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--navigation-ui", type=pathlib.Path)
    args = parser.parse_args()
    package(args.navigation_ui)
