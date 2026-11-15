# Implementation notes

## Runtime structure

- `Data.lua`: generated ID-based catalog and English fallback names. In-game item
  names are used when cached, so identifiers work independently of client locale.
  Controls and explanatory strings are currently English.
- `Catalog.lua`: crate/material selection and localized-name lookup.
- `Pricing.lua`: depth-aware commodity quotes and 0/1 subset optimization for
  indivisible auctions. State counts are capped at the required bundle size.
- `Providers.lua`: optional public API adapters, on-demand estimates, update
  callbacks, and Auctionator shopping handoff. See [INTEGRATIONS.md](INTEGRATIONS.md).
- `Scanner.lua`: single-flight, event-driven state machine. Query courtesy spacing is 0.05s;
  throttle readiness also gates every request. Each unanswered item gets one retry
  after 15s. The total per-item deadline is 90s, including throttle/page waits.
- `Tooltip.lua`: modern item-tooltip post-processing, duplicate suppression,
  refreshes after scan completion, and a legacy hook fallback.
- `UI.lua`: scan controls and a selectable diagnostic-report window.
- `Core.lua`: startup, persisted market caches, commands, API hooks, event routing.

The scanner only commits a material after its full result set arrives. Partial
pages are not treated as sold out. The latest successfully completed snapshot is
preserved on failure and marked unusable for cheapest selection. A stopped scan
keeps completed materials. Late events with another item ID/key are ignored.
The client events expose no request nonce; events for a repeated request for the
same item must be interpreted against the client's current result cache.

Hooks on `SendSearchQuery`, `SendSellSearchQuery`, `SendBrowseQuery`,
`SearchForItemKeys`, and `ReplicateItems` stop our scanner if another caller starts
an auction operation. Calls made inside our own guarded send operation are
recognized. There is no universal cross-addon lock: finish other scan operations
before starting this one. Internal page-request activity from another addon is
not independently attributed.

No timers run while idle. While scanning or waiting for a scheduled refresh, a frame checks state on update. One
material's completed snapshot is persisted immediately in SavedVariables memory;
WoW writes SavedVariables to disk on logout/reload, as usual. Logs are capped at
100 entries.

## Upstream facts and API checks

Retrieved 2026-11-15:

- [Wowhead crate entry / crate family](https://www.wowhead.com/forever/item=248549/waylaid-crate).
- [Example requirement data: Apprentice Herbs](https://www.wowhead.com/forever/item=248682&xml).
- [Example requirement data: Journeyman Parts](https://www.wowhead.com/forever/item=248707&xml).
- Every crate's exact source URL and SHA-256 are recorded in `data/catalog.json`.
- Item IDs were initially resolved by exact names from
  [nexus-devs/wow-classic-items](https://github.com/nexus-devs/wow-classic-items),
  then **all 96 names/IDs were verified against Wowhead Forever XML**. The Classic
  index is not required by the finished importer or addon.
- [Blizzard-generated auction API, Forever branch](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/AuctionHouseDocumentation.lua).
- [Blizzard tooltip handler, Forever branch](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua).
- [Blizzard commodity UI, Forever branch](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_AuctionHouseUI/Shared/Blizzard_AuctionHouseCommoditiesBuyFrame.lua).

The relevant auction contract is `C_AuctionHouse.MakeItemKey`,
`SendSearchQuery(itemKey, sorts, separateOwnerItems)`,
`HasFullCommoditySearchResults`, `HasFullItemSearchResults`, both `RequestMore*`
methods, both `GetNum*SearchResults` methods, and both `Get*SearchResultInfo`
methods. `IsThrottledMessageSystemReady` gates requests. The API documents a
100 search/minute limit; a rolling 100-request / 60.1s budget includes page
requests and observed external queries and survives scanner restarts. Server
readiness is always required, regardless of the courtesy interval.

`COMMODITY_SEARCH_RESULTS_UPDATED/ADDED` carry an item ID;
`ITEM_SEARCH_RESULTS_UPDATED/ADDED` carry an item key. The no-payload
`COMMODITY_SEARCH_RESULTS_RECEIVED` is deliberately not used to identify a job.
Commodity rows expose `unitPrice`, `quantity`, `numOwnerItems`, and account-owner
flags. Item rows expose total `buyoutAmount`, `quantity`, and auction IDs.
No legacy `QueryAuctionItems` or `GetAuctionItemInfo` offsets are used.

The Wowhead Journeyman Parts tooltip currently says **45 Gold Power Core**;
that value is imported literally. Older beta descriptions or underlying spell
effect values may disagree. If the live crate says something else, capture it
with `/wll inspect 248707` and update the source catalog with evidence.

The source/API review and simulated tests cannot establish live-client behavior.
In particular, actual query scheduling, addon restrictions, and compatibility
with installed auction addons need an in-game check.

## Manual verification

Use an identified Apprentice Herbs or Apprentice Ore crate for the first test.
Compare the whole required quantity against the current AH tier breakdown. Then
try an unsold material, stop mid-scan, close the AH mid-scan, start a default UI
search mid-scan, and reload to check persistence. Scan all only after the small
scan works. Send `/wll report` and exact Lua errors to diagnose differences.

## Conventions

Lua 5.1 syntax, four-space indentation, local module namespaces, integer copper,
no mutable global namespace beyond the SavedVariables table and registered slash
commands/UI frame names. Runtime modules take `addonName, addon` from WoW's addon
loader. Tests execute the actual production modules without transformed code.

Catalog refresh is an explicit developer action. The addon has no HTTP capability
and never attempts network calls outside WoW's built-in AH query API.

## v0.3 modules and data

`Inventory.lua` stores recognized bag/bank contents in account SavedVariables.
Character identity uses GUID; snapshots are partitioned by market identity.
`C_Bank.FetchPurchasedBankTabIDs` supplies actual containers for Character and
Account banks. A bank tab without loaded slots cannot erase a prior snapshot.
Shared-bank snapshots are included once. No remote-character API is assumed.

`UI.lua` reparents the same controls between a standalone shell and a LibAHTab
panel. `Minimap.lua` uses native frames, with an update callback only during drag.

`WritData.lua` is generated offline from `data/writs.json`: 150 Forever quests,
150 distinct required goods, 148 additional IDs relative to crate materials.
`WritPricing.lua` reuses provider resolution without using persisted own scans;
requirements are cumulative, so it clears alternative-winner highlights and only
returns a total when every required item has a price. Nothing adds writ goods to
`Catalog.Materials` or the scanner. Main and writ source settings are independent.

Primary sources: [writ overview](https://www.wowhead.com/forever/guide/professions/craftsmans-writs-overview-recipes-rewards),
[Forever quest index](https://www.wowhead.com/forever/quests/name:Craftsman%27s%20Writ),
[bank API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/BankDocumentation.lua),
and [LibAHTab upstream](https://github.com/TheMouseNest/LibAHTab).

Importer review checks: all 150 objective writ item IDs/names matched the guide's
150 item links. Quest IDs are parsed rather than inferred from item-ID offsets.
Delivery objectives exclude the writ itself; Crafted Solid Shot requires 200
units. Network/parse failures abort replacement of the existing checked-in data.
