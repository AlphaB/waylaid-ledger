"""Run production-module tests on Lua 5.1, optionally with actual upstream APIs.

Downloaded upstream addon packages remain external inputs and are not bundled.
"""

import argparse
import json
import pathlib
import re
import sys
import zipfile

from lupa.lua51 import LuaRuntime

root = pathlib.Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--auctionator", type=pathlib.Path, help="Path to an Auctionator release ZIP")
parser.add_argument("--tsm", type=pathlib.Path, help="Path to a TradeSkillMaster release ZIP")
parser.add_argument(
    "--forever-navigation", type=pathlib.Path, help="Directory containing native SmartNavigation.lua and Utility.lua"
)
parser.add_argument(
    "--forever-ui",
    type=pathlib.Path,
    help="Directory containing unmodified Forever commodity list and buy-frame Lua sources",
)
args = parser.parse_args()
lua = LuaRuntime(unpack_returned_tuples=True)
lua.globals().PROJECT_ROOT = str(root)
localization_keys = set()
for path in (root / "WaylaidLedger").glob("*.lua"):
    for literal in re.findall(r'\bL\[\s*("(?:[^"\\]|\\.)*")\s*\]', path.read_text()):
        localization_keys.add(json.loads(literal))
for literal in re.findall(r'\[("(?:[^"\\]|\\.)*")\]\s*=', (root / "WaylaidLedger/Locales.lua").read_text()):
    localization_keys.add(json.loads(literal))
lua.globals().LOCALIZATION_KEYS = lua.table_from(sorted(localization_keys))
try:
    if args.forever_navigation:
        lua.globals().UPSTREAM_FOREVER_NAVIGATION = lua.table_from(
            {name: (args.forever_navigation / name).read_text() for name in ["SmartNavigation.lua", "Utility.lua"]}
        )
    if args.auctionator:
        with zipfile.ZipFile(args.auctionator) as archive:
            names = [
                "Source/API/v1/GetAuctionPrice.lua",
                "Source/API/v1/GetAuctionAge.lua",
                "Source/API/v1/MultiSearch.lua",
                "Source_ModernAH/API/v1/RegisterForDBUpdate.lua",
                "Source/Utilities/EventBusMixin.lua",
                "Source_ModernAH/FullScan/Events.lua",
                "Source/Shopping/Events.lua",
            ]
            lua.globals().UPSTREAM_AUCTIONATOR = lua.table_from(
                {name: archive.read("Auctionator/" + name).decode() for name in names}
            )
    if args.tsm:
        with zipfile.ZipFile(args.tsm) as archive:
            lua.globals().UPSTREAM_TSM = archive.read("TradeSkillMaster/App/API.lua").decode()
            lua.globals().UPSTREAM_TSM_GROUP_IMPORT = archive.read(
                "TradeSkillMaster/LibTSMTypes/Source/ImportExport/GroupImport.lua"
            ).decode()
    if args.forever_ui:
        names = ["Blizzard_AuctionHouseCommoditiesList.lua", "Blizzard_AuctionHouseCommoditiesBuyFrame.lua"]
        if (args.forever_ui / "Blizzard_AuctionHouseFrame.lua").exists():
            names.append("Blizzard_AuctionHouseFrame.lua")
        lua.globals().UPSTREAM_FOREVER_UI = lua.table_from(
            {name: (args.forever_ui / name).read_text() for name in names}
        )
    lua.execute((root / "tests/spec.lua").read_text(), name="tests/spec.lua")
except Exception as error:
    print(error, file=sys.stderr)
    sys.exit(1)
