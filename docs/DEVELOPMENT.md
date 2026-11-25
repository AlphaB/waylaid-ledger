# Implementation notes

## README cleanup (1.6.1)

Reduced the README to main features, installation/update instructions and the
existing Aelris credit. Runtime changes are limited to release version metadata.

Validation: 255 default Lua checks and 257 checks against each freshly fetched
pinned/latest Forever navigation source passed. Python lint/formatting and
install ZIP integrity passed.

Manual verification not performed: fresh installation in a live Forever client
and the hardware-controller, focus/Back, localized-layout and combat/taint checks
in [CONTROLLER.md](CONTROLLER.md).

## README installation guide (1.0.2)

Reorganized the README around downloading the install asset, locating the Forever
AddOns folder, enabling the addon, updating and obtaining first prices. Condensed
everyday use and troubleshooting, linked the existing technical documentation,
and credited Aelris. Runtime changes are limited to release version metadata.

Validation: 246 default Lua checks and 248 checks against each freshly fetched
pinned/latest Forever navigation source passed. Python lint/formatting, README
local-link checks and install ZIP integrity passed.

Manual verification not performed: a fresh installation in a live Forever client
and the hardware-controller, focus/Back, localized-layout and combat/taint checks
in CONTROLLER.md. Automated validation cannot establish these results.

## Player text audit (1.0.1)

Reviewed active player-facing text in minimap, settings, list headers/status and
tooltips, item tooltips, shopping baskets, scan results, startup/help messages,
install metadata and README against the current handlers and price-source policy.
Historical changelog entries remain historical; developer diagnostics keep their
technical vocabulary. Updated affected translations for all supported locales.

Corrected stale settings routing, an empty-search prompt that suggested discovery
scans, material-only scan wording, a full-scan message that implied every delivery
was resolved, settings explanations of opening scans and inventory freshness,
and Refresh hints that offered Stop during another addon's scan. README now
matches default reward-cost sorting, controller header navigation, full-snapshot
versus detailed scans, provider-aware Refresh and standalone browser filtering.
Command help includes `scan deep` and no longer advertises the inactive legacy
`autoscan` preference as a current setting.

Regression coverage checks minimap hints inside and outside the AH in every
locale, cached-list empty guidance and the disabled Refresh tooltip during an
external scan. Release validation passed: 246 default checks, 248 checks with
each pinned/latest Forever source, Lua/Python lint and formatting, all five
performance scenarios and install ZIP integrity.

Not performed: live-client layout of the revised translated hints, actual mouse
and hardware-controller hover/focus/Back behavior, and combat/taint verification.
The live checklist in CONTROLLER.md remains outstanding; text review and source
simulation do not establish those results.

## Cached browser (1.0.0)

`UI.CreateBrowser` builds both containers with the same tabs, `BrowseUI` rows,
filtering, sorting, pricing and tooltips. The standalone instance is created on
first use without loading Blizzard's auction UI. Its views use separate registry
keys and a window owner; auction views retain their existing keys and owner.
The remembered category is shared, while each container retains its own searches
and scroll positions. Only visible views refresh on data/settings changes.

Outside the AH, Refresh invalidates provider estimates and rebuilds from saved
prices without queuing scans. Row activation uses the existing closed-AH guard
and explains that shopping requires an auctioneer. Opening the AH closes the
standalone window and keeps the normal auction-tab flow.

Validation: regression checks cover cached totals, both categories, search,
reopening, no auction requests, virtual rows, sorting, empty results, focus,
late gamepad initialization and combat recovery. Native discovery includes both
pages of the lazily created browser. All 246 default checks and 248 checks with
each pinned/latest Forever source passed, along with Lua/Python lint and
formatting, all five performance scenarios and install ZIP integrity checks.

Manual verification not performed: live Forever rendering before the first AH
visit, native controller hardware input and right-stick scrolling, Back/return
focus from Settings, mouse dragging, Escape, real combat/taint behavior, and
localized layouts. Follow `CONTROLLER.md` with the cached browser and again after
entering/leaving the AH. Automated checks do not establish those client results.

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
- `UI.lua`: registered settings, the auction tab host and the standalone saved-price browser.
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

## Controller regression checks (v0.8.4)

`python tests/run.py --forever-navigation /path/to/native/sources` also runs the
unmodified Forever `SmartNavigation.lua` and `Utility.lua` navigation/selection
methods against the addon. The directory must contain those two source files;
upstream code is an external test input and is never bundled in the install ZIP.
This exercises the real LibAHTab/UI tab handlers and native Click, selection and
Navigate methods, then checks row entry without native centering, traversal in both directions
past the virtual pool, and focus-scoped scrolling. Rendering, input dispatch and
secure execution still require the live-client checklist in README.

## Settings version (0.9.6)

The settings heading displays `Waylaid Ledger  v` followed by `addon.version`,
using the same installed version as diagnostics. It remains a noninteractive
font string in the existing heading space; the initial controller target stays
on Crate prices. Controller settings open/reopen checks and all ten localized
startup checks cover the version display. Release validation passed: 236 default
Lua checks, 238 each with freshly fetched pinned/latest Forever navigation
sources, Lua formatting, Python lint/format checks, and install ZIP integrity.

Live verification remains unperformed for 0.9.6: check the heading at supported
UI scales and complete [CONTROLLER.md](CONTROLLER.md)'s live-client checklist,
including mouse/keyboard, hardware controller input and secure/taint behavior.

## AddOns list icon (0.9.5)

Both install manifests declare `IconTexture: Interface\Icons\INV_Crate_05`,
matching the existing minimap icon. Forever's native
[AddonList_InitAddon](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_AddOnList/AddonList.lua)
reads this metadata before falling back to the question-mark icon. No runtime UI
or controller navigation behavior changes.

Release checks passed: 236 default Lua regressions, 238 checks each with pinned
and latest Forever navigation sources, and clean ZIP packaging/integrity. In-game icon rendering at character
selection and in the game menu remains unverified. The full live controller
checklist in [CONTROLLER.md](CONTROLLER.md) also remains unperformed for 0.9.5;
automated checks cannot establish hardware input or secure/taint behavior.

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

CI enforces Luacheck 1.2.0, StyLua 2.6.0, and the Ruff version pinned in
`requirements-dev.txt`. Run the lint/format commands in the README before sending
a change. Add newly used WoW globals to `.luacheckrc`; keep production APIs
read-only and allow writable mocks only in tests. Unused positional callback
arguments use `_` placeholders. Vendored `Libs` stay unchanged.

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

Native controller support is required for every UI change and release. Follow
[CONTROLLER.md](CONTROLLER.md) for registration, automated release gates and the
live-client checklist. Preserve sortable-header and virtual-row navigation.


## Auction-house freeze investigation (0.9.7)

The live 0.9.4 report exposed paths excluded by the prior synthetic benchmark:
Ledger requested its own 240,290-auction snapshot with scan-on-open enabled in
Auto, and ordinary SendBrowseQuery traffic produced repeated discovery waves
(up to 1,168 attempts) while external scan state was false. The old benchmark
explicitly fired Auctionator ScanStart, used a tiny synthetic catalog, stubbed
list refresh, and stopped before ScanComplete. It established suspension behavior
but could not exclude opening, ordinary browsing or completion stalls.

The revised regressions cover those paths without requiring Auctionator lifecycle
events. Auto now applies the provider-cache policy on open; Own/custom-profile
opt-in scans and explicit requests remain unchanged. Browse callbacks schedule
work, coalesce to the latest snapshot and budget name processing. Revisiting
a known browse item no longer invalidates its resolved description. Item-load and
tooltip-instance updates still refresh changed requirements.

Two before/after scenarios run the same harness against v0.9.4 and the new source:

- Twenty 6,000-row browse snapshots: native reads inside event handlers fall from
  120,020 to zero; total name lookups from 120,000 to 6,000; description reads from
  3,000 to 150. New name processing is capped at 50 rows or 2 ms per frame.
- Completion with the shipped 180-contract catalog and large stale detailed
  histories: 246 discarded order-book quotes become zero. Local Lua CPU time fell
  from about 1.9 seconds to about 0.002 seconds. This fixture intentionally uses
  larger histories than the user's report to test scaling; it does not measure
  their game frame time. Fresh own shortages and unavailable-provider fallbacks
  retain the same results.

Validation: Lua regressions and both performance scenarios are required in CI,
alongside the existing scan/full-scan/Shopping benchmarks. Release validation also
uses pinned and latest Forever controller sources and the released Auctionator
347 public adapter sources. See the PR for exact results.

Outstanding manual verification: repeat the AH-opening comparison with 0.9.7
and the user's existing SavedVariables, keep Auto and scan-on-open enabled, and
verify no own scan request is logged when a provider is available. Check browse
updates, refreshed prices, manual Own scans, AH closure and reopening. Run every
live-client/controller step in CONTROLLER.md, including focus during price
refresh, virtual rows, empty lists, combat recovery and hardware Back/navigation.
No live WoW, controller hardware or security/taint execution was available here.

### Writ rewards, lockouts and price history (1.1.0)

Live Forever checks are pending. Verify coin-pouch estimates against opened
rewards, completion on a specific writ before and after the server's daily
reset and on another character, and a discount against recorded market scans.
Check the changed row and tooltip text in the Auction House and saved browser
with mouse and native controller, including recycled rows, search, activation,
Back and returned focus. Follow the checklist in CONTROLLER.md.

### Delivered writ filter (1.1.1)

Live Forever checks are pending for toggling the filter with mouse and native
controller in both browsers, including a search that only matches delivered
writs, list scrolling, Back and return focus.

### Writ trips (1.2.0)

The route scope, model and pending live Forever checks are recorded in
[WRIT_TRIPS.md](WRIT_TRIPS.md). Lua tests cover shortest walking order, shared
inventory, missed quotes, the current continent and faction, daily lockouts,
and report navigation with Back returning to the trip button.

### Writ trip value (1.3.0)

Lua checks cover applying a gold-per-hour value, ranking changes, and optional
writ estimates at a shared or new recipient. See [WRIT_TRIPS.md](WRIT_TRIPS.md)
for the score, selection method and pending live verification.

### Interactive writ planner (1.4.0)

Lua checks cover toggling multiple writs, sharing purchase quantities, switching
stops, restoring selections and handling missing quotes. The native navigation
contract covers the planner's selector, optional controls, scrolling, empty
state, Back and return focus. Live Forever verification remains pending in
[WRIT_TRIPS.md](WRIT_TRIPS.md).

### Saved writ trips (1.5.0)

Lua checks cover saved selections surviving the shopping handoff, real event
dispatch through QUEST_TURNED_IN, backfill from quest flags, next-stop
progress and isolation by character. The planner's Save trip and Saved trip
controls are covered by native discovery. See [WRIT_TRIPS.md](WRIT_TRIPS.md)
for pending live checks.

### Standalone window controls (1.5.1)

Verify title-bar dragging, keeping windows on screen, clicking and scrolling
the content, Escape, and native controller focus and Back in the saved-price
browser, trip planner, shopping basket, and report window. Check return focus
from both trip views. This remains unverified in the live Forever client.

### Writ trips tab and coin returns (1.6.0)

Verify switching among all three tabs in both browsers, retaining selected
writs, controller entry and scrolling in both trip modes, the Auctionator
handoff, and selecting the saved view via /wll trip. Check the displayed
return estimates against opened coin pouches. In-game checks remain pending.
