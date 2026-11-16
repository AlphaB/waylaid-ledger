# Implementation notes

## Runtime structure

- `Localization.lua` and `Locales.lua`: client-selected control translations for
  all official locales. Keep `%d`/`%s` argument order intact. `tests/run.py` extracts
  UI translation keys; the Lua suite checks coverage and formatting and boots each
  locale through the installed TOC. Diagnostic-report fields remain English.

- `Data.lua` / `WritData.lua`: bundled fallback catalog tables. `Discovery.lua` updates
  requirements and names from complete client descriptions; see [INGAME_DATA.md](INGAME_DATA.md).
  Controls and explanatory strings use the client locale with English fallback.
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
- `UI.lua`: registered settings and the auction tab host; legacy controls redirect to settings.
- `NativeShopping.lua`: ID-based basket and Blizzard buy-screen navigation.
- `Navigation.lua`: native Forever SmartNavigation/focus integration.
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

Catalog discovery happens in game. The addon has no HTTP capability and uses only
WoW APIs. There are no web import/build scripts.

## Historical implementation notes

Version 0.7.0 expands the scanner scopes through `Shopping.ScanItems`; writ
requirements and purchase prices now share persisted depth snapshots. Ranked
lists schedule fallback work independently of inventory tracking. The older
96-material opening and tracked-crate scans remain available. See
[INTEGRATIONS.md](INTEGRATIONS.md#current-behavior-070) for current controller and
shopping contracts; provider-only statements below describe older versions.

## v0.3 modules and data

`Inventory.lua` stores recognized bag/bank contents in account SavedVariables.
Character identity uses GUID; snapshots are partitioned by market identity.
`C_Bank.FetchPurchasedBankTabIDs` supplies actual containers for Character and
Account banks. A bank tab without loaded slots cannot erase a prior snapshot.
Shared-bank snapshots are included once. No remote-character API is assumed.

`UI.lua` retains standalone scan controls, registers one LibAHTab panel, and
switches internal category pages. `BrowseUI.lua` supplies a native ScrollBox
with purchase, delivery and total columns. Only visible lists are rebuilt on
price updates; filtering reuses current entries, and item hover updates only
the standalone controls. There is no background polling. `Minimap.lua` uses native frames, with an update callback only during drag.

`Data.lua` and `WritData.lua` initialize the 30-crate / 150-writ fallback.
Complete client descriptions take precedence and are persisted by `Discovery.lua`.
`BulkScan.lua` uses one public replication request to index item names and
minimum unit prices. See [INGAME_DATA.md](INGAME_DATA.md) for the current data,
state, refresh, and verification contracts. Older scan scopes below are historical.

## Complete acquisition baskets (v0.4.0)

`Shopping.lua` builds ranked entries and exact-name shopping terms independently
of frame rendering. Each total combines a provider purchase estimate for one
identified writ/crate with the full delivery quote. Missing components produce a
nil total; comparator ordering is numeric total, then name and item ID, with
unknown totals last. Stale totals retain their values and carry a visible marker.

Crates select the lowest known nonfailed cost across resolved scan/provider
quotes, including older cached amounts. Observed shortages
are excluded. This does not claim that an unpriced alternative is more expensive.
Writ requirements are cumulative; every objective must be priced for a total.

`Core.ShopEntry` reprices on click, constructs the full basket, and validates
localized names and the tab-switching API before stopping the scanner. One
crate/writ and only the selected delivery goods are handed off. Legacy
delivery-only commands retain their older API fallback; list row shopping
requires `MultiSearchAdvanced`, whose upstream implementation switches tabs.

All 180 purchase IDs are read only from optional price databases. Neither list
construction nor Refresh creates auction queries or expands the scanner catalog.
Automatic tracked-crate refresh runs in the internal Crates page/scan controls, not Writs.
Tests execute actual Auctionator 347 public source to check Shopping tab clicks
and both complete baskets, including the 200-unit ammo requirement.

## Opening scan and compact tooltips (v0.5.0)

`db.scanOnOpen` is an opt-in boolean independent of `db.tracking.autoScan`.
`autoReason` distinguishes queued opening scans from queued panel refreshes;
`scanOnOpen` distinguishes active opening scans from panel-driven runs. Both
use the same scheduler and scanner. Opening work covers all crate materials,
reuses fresh snapshots, and waits two seconds to yield to other addon startup
queries. Panel refresh cannot replace queued opening work. Panel visibility
changes only cancel panel work. Explicit stops, AH closure and provider changes cancel pending/active work.
Competing queries defer pending opening work until two seconds of quiet and
stop an active scan without restarting it. Pagination methods are observed too,
and initial Blizzard browse queries cannot suppress the pending scan forever.

Tooltip default amounts carry no source badges or explanatory footers.
Version 0.5.1 removes the outdated-data notice and its helpers entirely.
`Pricing.LowestKnown` supplies one cost comparison for tooltips, controls,
resolved winner flags and shopping, including cached prices. Failed, unknown
and insufficient results remain ineligible. All lowest-known winners are green, regardless of source or cache age. Native money-string
color codes are stripped only for the winning amount and an explicit tint is
applied without removing coin textures. Source freshness still drives Auto
resolution and refresh. Shift/detailed mode retains inline source/age.

## Native lists and settings (v0.6.0)

Primary client sources inspected from the Forever branch:

- [Auction item-list template](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_AuctionHouseUI/Classic/Blizzard_AuctionHouseItemList.xml)
- [ScrollBox](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Shared/Scroll/ScrollBox.lua)
- [List view initializer contract](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Shared/Scroll/ScrollBoxListView.lua)
- [Native templates](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml)
- [Settings registration/opening API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_Settings.lua)

Native list frames initialize with `CreateScrollBoxListLinearView`, a 34px
element extent, and a Button initializer. `CreateDataProvider` supplies filtered
entries, retaining scroll position on refresh; filtering explicitly returns to
the beginning. The initializer creates row parts once and rebinds entry data
on every reuse. Headers and numbers share calculated column boundaries.

`UI.SelectBrowserTab` owns internal visibility, selection and tracked-refresh
gating. The outer LibAHTab container preserves the last category. AH-opening
scans retain their independent lifecycle across internal switches.

Settings are a registered canvas category with native checkboxes and source
controls. No custom settings dialog or extra slash-command state is created.
Tests simulate a recycled visible-row pool, confirm post-filter click quantities,
check header bounds and hover stability, and validate official-category routing.
Actual client template rendering still requires the user's live check.

## Expanded scan engine (v0.7.0)

`Catalog.ScanItems` derives IDs and maximum target quantities from the learned
catalogs. Manual/Refresh scopes include contracts and goods; the existing
AH-opening/tracked automatic refresh remains the 96-material crate refresh to
avoid silently increasing background queries. Explicit all/writ/crate scans
cover 424/300/126 IDs. Bag/tracked/hovered manual scopes include writs too.

`ResolveRows` centralizes market isolation and source policy. Writ objectives
are cumulative and purchases are one-unit quotes from the same persisted own
snapshots/provider resolution as deliveries. Fresh own shortages are not
replaced with provider unit estimates in Auto.

`Scanner.Tick` classifies items with `GetItemKeyInfo`; equipment uses
`SendSellSearchQuery` with the base item key to include gear variants. Local item-class data provides a fallback before AH metadata is available. Missing
classification waits for item data (within the existing job timeout), and a
missing required API records failure instead of a false empty snapshot.

Refresh freezes filtered IDs/quantities and runs one own queue. On natural
completion, an optional provider job is deferred to the scheduler so it cannot
run inside an own-query callback. It validates the market/open state before
opening Auctionator Shopping. Every explicit stop/context interruption clears
active and pending provider jobs. TSM export is copy-only; its import parser is
validated in an optional release-source contract test.
