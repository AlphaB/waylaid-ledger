"""Benchmark real scan modules on repeated synthetic auction-house snapshots."""

import argparse
import pathlib

from lupa.lua51 import LuaRuntime

root = pathlib.Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument(
    "--source", type=pathlib.Path, default=root, help="Addon source root; permits before/after comparisons"
)
parser.add_argument("--verify", action="store_true", help="Assert bounded retained scan data")
args = parser.parse_args()
lua = LuaRuntime()
lua.globals().PROJECT_ROOT = str(args.source.resolve())
lua.globals().VERIFY_BOUNDS = args.verify
lua.execute((root / "tests/scan_performance.lua").read_text())
