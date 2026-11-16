# Auction addon integrations

## Current behavior (0.8.1)

Auctionator and TSM supply optional cached price estimates. Auto reuses fresh
own snapshots, then provider estimates. Tab switches, missing prices, and unresolved
descriptions do not schedule queries. Own scans require Refresh/a scan command,
or the separate opt-in AH-open preference. An external full scan cancels pending
automatic work for that AH visit. Forced provider modes retain their source policy.

Auctionator autoscan is observed without reading or retaining its raw snapshot.
The public DB callback carries no progress, so a capability-checked adapter uses
`Auctionator.EventBus:Register` with `FullScan.Events.ScanStart`, `ScanProgress`,
`ScanComplete`, and `ScanFailed`. Only the numeric progress value is retained;
the completion event's auction-data payload is ignored. Discovery and provider
redraws remain paused until completion/failure. Refresh is disabled meanwhile.

This optional event-bus adapter is version-sensitive, unlike the public price API.
Tests execute Auctionator 347's unmodified event bus, event constants and DB callback.
Without these events, an observed external `ReplicateItems` call shows a waiting
status and the public DB callback ends the wait. AH closure or 120 seconds without
progress also releases the wait; neither path restarts automatic scanning.

Row shopping prefers Auctionator advanced shopping; when unavailable, an ID-based
basket opens `AuctionHouseFrame:SelectBrowseResult` and `QueryItem` with the
correct BuyItems/BuyCommodities context. Equipment passes the item-ID variant
query flag. Native quantity-selection events preserve commodity quantities
through asynchronous list/display refreshes. The standard UI owns listing selection and purchase
confirmation. No purchase API is invoked by Waylaid Ledger. The same readiness
and rolling request budget gates opening a basket item.

Native controller support uses Blizzard security-wrapped `RefreshButtonGroups`,
`SetScrollFrameForFrame`, `SetTargetButtonForFrame`, and FrameControlsManager
show/hide/focus entry points. Dynamic directional overrides resolve virtual rows
after synchronous nearest scrolling. No bindings or native internal tables are
modified. Calls wait until out of combat and tolerate late gamepad addon loading.

Contracts checked against the Forever branch on 2026-11-16:

- [Auction frame and purchase navigation](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_AuctionHouseUI/Shared/Blizzard_AuctionHouseFrame.lua)
- [Commodity quantity selection](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_AuctionHouseUI/Shared/Blizzard_AuctionHouseCommoditiesBuyFrame.lua)
- [Native SmartNavigation](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadSmartNavigation/SmartNavigation.lua)
- [Navigation customization](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadSmartNavigation/Utility.lua)
- [Frame focus manager](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadSharedUtility/FrameControlsManager.lua)

The earlier sections below record historical integration behavior. The scoped
scanning section describes the detailed fallback; replication-capable clients
use the full-snapshot refresh documented in [INGAME_DATA.md](INGAME_DATA.md).

Implemented in version 0.2.0. Release sources inspected on 2026-11-15:

| Provider | Reviewed release | Primary distribution |
| --- | --- | --- |
| Auctionator | 347, supports Forever 1.60.1 | [CurseForge file 9620638](https://www.curseforge.com/wow/addons/auctionator/files/9620638) |
| TradeSkillMaster | 4.15.7, supports Forever 1.60.1 | [CurseForge file 9595290](https://www.curseforge.com/wow/addons/tradeskill-master/files/9595290) |

The upstream addon ZIPs are development inputs, not bundled dependencies or
redistributed files. API contracts were read from the actual release packages.

## Auctionator

Price and shopping operations use `Auctionator.API.v1`:

- `GetAuctionPriceByItemID("WaylaidLedger", itemID)`: a cached minimum unit price
  in copper, or nil when unavailable.
- `GetAuctionAgeByItemID("WaylaidLedger", itemID)`: age in whole scan days, or
  unavailable. A zero does not establish minute-level freshness.
- `RegisterForDBUpdate("WaylaidLedger", callback)`: register once per API table;
  invalidate estimates and refresh visible tooltips/UI after scan processing.
- `MultiSearchAdvanced("WaylaidLedger", terms)`: current shopping handoff. Terms
  contain `searchString`, `categoryKey=""`, `isExact=true`, and `quantity`.
- `ConvertToSearchString` and `CreateShoppingList`: capability-detected fallback
  if advanced multi-search is unavailable. This replaces only the reserved
  addon-managed list name for the crate/scope.

Reviewed source paths inside the release:

- `Source/API/v1/{GetAuctionPrice,GetAuctionAge,MultiSearch,ShoppingLists}.lua`
- `Source_ModernAH/API/v1/RegisterForDBUpdate.lua`
- `Source/Database/Mixin.lua` (used only to verify returned price/age semantics;
  our addon never calls its internal functions).

The public data-exactness API is not used as proof of available quantity. It
checks database-key matching, not whether the bundle can be bought for the quote.

## TradeSkillMaster

Uses only `TSM_API.GetCustomPriceValue(key, "i:<item ID>")` for base-item
estimates of crate materials and finished writ goods. Default key: `DBMinBuyout`.
The optional `DBMarket` key is labelled **TSM market**. No automatic fallback
between these two price definitions occurs.

The reviewed release's API is in `TradeSkillMaster/App/API.lua`. It validates
argument types and TSM item strings, returns either a number or nil/error text,
and rejects colon-style calls. Our adapter calls it as a plain function through
`pcall`. No public per-item scan-time or price-change notification was found.
We do not use internal TSM modules, mutate groups/operations, or start its scanner.

[TSM's price-source definitions](https://support.tradeskillmaster.com/custom-strings/which-price-sources-can-i-use-and-what-do-they-mean)
explain why a current minimum-buyout estimate and a weighted historical market
value must remain distinct. TSM's own data installation/sync is managed by TSM;
Waylaid Ledger needs no additional desktop component.

## Resolution and freshness

`Pricing.Resolve` accepts an injected provider lookup and returns one row per
bundle. It preserves fresh own-scan results, including shortages, in Auto. If
it needs estimates it tries Auctionator, then TSM; a known-old Auctionator price
is deferred until after other usable estimates. A forced mode never silently
changes provider.

Own scan prices retain their original timestamps and 30-minute eligibility.
Auctionator ages remain in scan-day buckets; cached prices can still win the
lowest-known comparison.
TSM age remains explicitly unknown. Estimates are never assigned a fabricated
`scannedAt` or available quantity and are never stored as own scan snapshots.

The single lowest known cost across resolved options is highlighted green
for all sources, including imported and cached prices. Ties
are allowed, while failures, shortages and unknown costs remain excluded.
The compact tooltip uses color and plain amounts without estimate prefixes.
Shift reveals source/age inline; source badges and footer legends are removed.

Provider reads, including misses, are cached on demand for 15 seconds, keyed by
market context, provider, item ID, and TSM price definition. Replacing the provider
API table invalidates those reads. Auctionator DB updates, source/profile changes,
and relevant late addon loads invalidate the cache. No provider polling timer
runs while idle. Provider amounts must be positive finite numbers; bundle totals
are rounded up to integer copper. The supported catalog has at most 45 units per
option; the unit-price guard also leaves room for up to 1000 without exceeding
Lua's exact integer range.

Custom market profiles cannot consume provider estimates because the public APIs
do not expose a house identifier to match those profiles. Default-profile reads
use whichever market context the installed provider has initialized for the
current character. Faction/realm/profile changes cannot reuse our adapter cache.

## Shopping and failure handling

Core validates the crate, option, AH-open state, shopping capability and localized
material names before stopping the scanner. It then stops the scanner explicitly
before calling Auctionator, so deferred searches cannot overlap our query queue.
A failed handoff is reported and leaves completed own snapshots intact. The
scanner is not restarted automatically, since Auctionator may have partly started.

Every search is user-triggered. All-alternatives searches are only comparisons;
fulfilling a crate requires one of those bundles. No purchase/post/cancel API is
called. Search names use the client's localized item data. English fallbacks are
used only on English clients; other locales request missing item data and ask the
user to retry instead of searching with the wrong language.

## Validation performed

- The standard Lua 5.1 suite executes production modules, including all official locales.
- Two optional tests execute the **unmodified public API source** from Auctionator
  347 and TSM 4.15.7, with their internal services and UI stubbed.
- Auctionator contract check: returned copper and day age, update registration,
  advanced-search argument validation, exact search terms, quantity handoff.
- TSM contract check: actual API item-string validation and configured source keys.
- Existing scan/pagination/pricing tests remain in the suite.

Actual in-game addon scheduling, UI layout and third-party interactions still
require a live Forever test. `/wll report` includes provider capabilities, source
policy, selected TSM key, per-row provenance and recent API errors.

## Writ policy and AH tabs (v0.3.0)

Writs use the same provider APIs, cache, stale handling, and TSM key as crates,
with a separate Auto/Auctionator/TSM/Off preference. They never start queries.
A writ price is the full delivery quantity times a cached base-item unit price.

LibStub and LibAHTab 1.0 minor 5 are bundled with their own licenses. LibAHTab
shares a single extra-tab row with compatible addons, including Auctionator 347,
without appending to Blizzard's `AuctionHouseFrame.Tabs` array. The actual
unmodified library is executed by the integration tests.

## Complete basket lists (v0.4.0)

Purchase estimates add one writ/crate to the full delivery amount. Writ purchases
use the writ source policy; crate purchases use provider Auto independently of
the crate-delivery policy. No purchase IDs are added to the own scanner.

Row shopping passes exact localized names and quantities for the writ/crate and
its selected delivery goods to `MultiSearchAdvanced`. Its released implementation
clicks `AuctionatorTabs_Shopping` and raises `ListSearchRequested`; our code does
not call internal tab frames itself. Contract tests execute that implementation
and assert a tab click and complete quantities for both a writ and a crate.

Older list-creation APIs do not guarantee tab switching. They remain available
for the legacy commands, but row shopping capability checks require the advanced
API before interrupting any existing scan. Missing localized names also leave
the current scan undisturbed.

## Cached pricing and opening scans

Version 0.5.1 removes the outdated-data notification completely. Provider age
limitations remain: Auctionator only exposes whole scan-day differences, and
TSM exposes no age through the reviewed public API. Neither provider receives
an invented timestamp. Source freshness still drives resolution and refresh;
it no longer suppresses lowest-known highlighting when prices are cached.

The new scan-on-open option runs the own 96-material crate scanner in Auto/Own
modes, independently of the visible tab. It does not start Auctionator internals,
scan writ goods, or populate purchase estimates. Publicly observed competing
queries defer pending opening work until two seconds of quiet, including page
requests. They cancel active scans; manual refresh or the next AH visit is
required after interruption. Existing shopping handoffs still
stop our scanner before calling the provider.

## Native UI (v0.6.0)

Only one `WaylaidLedger` tab is registered with LibAHTab, labelled Waylaid.
Writs and Crates are child pages controlled by native `PanelTopTabButtonTemplate`
buttons. Internal tabs never register with LibAHTab or touch Blizzard's AH tab array.

The lists use the same `WowScrollBoxList` / `WowClassicScrollBar` primitives as
Forever's classic auction item list, plus the native inset and column headers.
The element initializer rebinds recycled buttons; callbacks read current entry
data. Item-tooltip updates do not replace the data provider under the pointer.

The official AddOns page uses `Settings.RegisterCanvasLayoutCategory`,
`Settings.RegisterAddOnCategory`, and `Settings.OpenToCategory(category:GetID())`.
Registration happens once per addon load; all settings entry points open it.
All features continue using the same SavedVariables keys.

## Refresh and scrollbar rail (v0.6.1)

In v0.6.1, Refresh invalidated only the adapter's 15-second memory cache and
rebuilt the active list. This was superseded by the scan paths below. Provider public APIs return their existing saved price data; own
scan snapshots are retained. It recalculates/resorts baskets without starting
a scan or issuing an auction query. A production-button regression check verifies
newly saved provider amounts, changed ordering, retained scroll policy, unchanged
scanner requests and preserved own snapshots.

The native classic scrollbar's `Background.Middle` is explicitly given a neutral
solid color. This avoids the green middle artwork on the reported client while
retaining the native template, mouse-wheel, track, arrows and thumb bindings.
Primary template: [TrimScrollBar.xml](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Shared/Scroll/TrimScrollBar.xml).

## Scoped scanning (v0.7.0)

Refresh runs a fresh own scan for all IDs in the filtered category, including
contract purchases and all delivery alternatives/objectives. A completed job
can hand its frozen ID/quantity scope to `MultiSearchAdvanced` after the own
scanner has stopped. This opens Auctionator Shopping, with no claim of silent
or full-house scanning. Follow-up defaults on when supported and can be
disabled with `/wll auctionatorfollowup off` on the legacy per-item path.
Stops, closure, profile changes or external queries cancel pending work. Names and capability checks precede the provider handoff.

TSM 4.15.7's released `App/API.lua` contains no public scan-start API. Targeted
Shopping scans are manual group operations. We export the supported legacy
`group:Name,i:ID,...` format for the same filtered scope, without mutating TSM
groups or calling its internal services. An optional test executes the released
TSM `GroupImport.lua` parser against the exported format. A Shopping scan need
not change historical DBMarket or app-supplied AuctionDB values.

Own writ deliveries now use quantity-aware snapshots and support an explicit
Own source. Purchase and delivery share their category's source preference,
so Auto/Own can show complete self-scanned totals, including custom profiles.
Forced provider modes still use only their selected databases.

## UI simplification and full-scan status (v0.7.2)

On Forever, replication-based Refresh supersedes the v0.7.0 per-item Refresh
path above: it requests a full AH snapshot, with no Auctionator follow-up. The
settings page no longer exposes that inactive switch or the advanced TSM export
button. Their slash commands remain available. The legacy standalone controls
window is removed; `/wll controls` opens official settings.

Price choices use Forever's native `DropdownButton` / `WowStyle1DropdownTemplate`
and `SetupMenu` radio descriptions. Primary client sources:
[DropdownButton.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_Menu/DropdownButton.lua),
[Classic/MenuTemplates.xml](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_Menu/Classic/MenuTemplates.xml).

List status reads the replication job's waiting state and actual auction count,
including passive shared snapshots in v0.7.2–v0.8.0 (removed in v0.8.1). It does not use
the empty per-item scanner queue. Batches only update status text and the Stop
button; completed scans rebuild prices and list ordering. Stop cancels our
snapshot observer without cancelling the other addon's scan.
