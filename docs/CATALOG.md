# Catalogs, requirements and prices

The addon bundles two factual catalogs, kept separate from player price data.

| Editable source | Generated runtime file | Meaning |
| --- | --- | --- |
| `data/catalog.json` | `WaylaidLedger/Data.lua` | 30 crate IDs, names, alternative item IDs/counts, 96 unique goods |
| `data/writs.json` | `WaylaidLedger/WritData.lua` | 150 writ IDs, quest IDs, names, required delivery item IDs/counts, 150 unique goods |

Both JSON files record Wowhead Forever source URLs, retrieval dates and response
hashes. `tools/build_catalog.py` and `tools/build_writs.py` validate them and
produce Lua offline. TOC load order makes the tables available when the addon
starts. The game never downloads Wowhead pages. Refreshing the source catalog
is a deliberate developer import/rebuild/release action.

Runtime tables are keyed by numeric item ID, so relationships are independent
of client language. Display/search names prefer native localized item data;
English catalog names provide display fallbacks. Localized Auctionator searches
wait for actual client names instead of using English guesses.

## Alternatives versus objectives

Crate `248683` (Apprentice Ore) has alternatives: 20 Copper Ore (`2770`) **or**
20 Tin Ore (`2771`). We price both bundles and select the lowest known cost.

Writ `264037` (Crafted Solid Shot) requires **200** Crafted Solid Shot (`8069`).
Its `requirements` array is cumulative: every objective is needed. A future
multi-objective writ receives a total only when all objectives are priced.
The writ itself is excluded from the delivery subtotal and added once to the
purchase + delivery acquisition total.

## Scan lists are derived, not separately maintained

`Catalog.ScanItems(contractIDs)` walks the selected crate/writ definitions. It
includes each contract itself plus all its delivery goods, deduplicates by item
ID and sorts the IDs. It also records the maximum required quantity for each ID,
used as the target quantity in an Auctionator limited search. It never sums all
alternative bundles as if the player had to purchase them all.

Full scopes are 300 writ IDs/goods and 126 crate IDs/goods. Two delivery IDs are
shared, leaving 424 combined IDs. A list filter creates a smaller scope. Refresh
freezes that scope before scanning, so later sorting/filter edits cannot change
the active job or its provider follow-up.

## Saved prices are separate

`## SavedVariables: WaylaidLedgerDB` lets WoW persist settings, inventory
snapshots, logs and our completed scan snapshots across reload/logout. Market
keys separate region, realm, faction, project and custom profile. Each item
snapshot contains its timestamp, auction type and buyable offers in copper;
failed attempts are stored separately and do not overwrite successful data.

Commodity prices consume price tiers to meet the required count. Item auctions
use indivisible-stack optimization, including unavoidable excess. Writ/crate
purchase quotes use a required count of one. Equipment uses a base-ID gear-variant
search; ownership/buyout filtering still applies. No purchase is performed.

Auctionator/TSM prices remain in those addons' databases. Our adapter caches
public API reads in memory for 15 seconds, without copying them into own scan
snapshots or inventing their timestamps. Source policies choose between fresh
own quotes and those optional estimates. The lists, scanner queue and catalog
files do not store independent copies of the price data.
