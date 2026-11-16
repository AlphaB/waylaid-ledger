"""Run production-module tests on Lua 5.1, optionally with actual upstream APIs.

Downloaded upstream addon packages remain external inputs and are not bundled.
"""
import argparse
import pathlib
import sys
import zipfile

from lupa.lua51 import LuaRuntime

root = pathlib.Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--auctionator', type=pathlib.Path, help='Path to an Auctionator release ZIP')
parser.add_argument('--tsm', type=pathlib.Path, help='Path to a TradeSkillMaster release ZIP')
args = parser.parse_args()
lua = LuaRuntime(unpack_returned_tuples=True)
lua.globals().PROJECT_ROOT = str(root)
try:
    if args.auctionator:
        with zipfile.ZipFile(args.auctionator) as archive:
            names = ['Source/API/v1/GetAuctionPrice.lua', 'Source/API/v1/GetAuctionAge.lua',
                     'Source/API/v1/MultiSearch.lua', 'Source_ModernAH/API/v1/RegisterForDBUpdate.lua']
            lua.globals().UPSTREAM_AUCTIONATOR = lua.table_from({
                name: archive.read('Auctionator/' + name).decode() for name in names
            })
    if args.tsm:
        with zipfile.ZipFile(args.tsm) as archive:
            lua.globals().UPSTREAM_TSM = archive.read('TradeSkillMaster/App/API.lua').decode()
            lua.globals().UPSTREAM_TSM_GROUP_IMPORT = archive.read('TradeSkillMaster/LibTSMTypes/Source/ImportExport/GroupImport.lua').decode()
    lua.execute((root / 'tests/spec.lua').read_text(), name='tests/spec.lua')
except Exception as error:
    print(error, file=sys.stderr)
    sys.exit(1)
