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
parser.add_argument(
    "--scenario",
    choices=["snapshot", "auctionator", "auctionator-shopping", "auctionator-completion", "browse"],
    default="snapshot",
)
args = parser.parse_args()
lua = LuaRuntime()
lua.globals().PROJECT_ROOT = str(args.source.resolve())
lua.globals().VERIFY_BOUNDS = args.verify
lua.globals().SHOPPING_SCAN = args.scenario == "auctionator-shopping"
scenario = "auctionator_performance.lua" if args.scenario.startswith("auctionator") else "scan_performance.lua"
if args.scenario == "auctionator-completion":
    scenario = "auctionator_completion.lua"
elif args.scenario == "browse":
    scenario = "browse_performance.lua"
lua.execute((root / "tests" / scenario).read_text())
