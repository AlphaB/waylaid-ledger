# Auction addon integrations

Implemented in version 0.2.0. Release sources inspected on 2026-11-15:

| Provider | Reviewed release | Primary distribution |
| --- | --- | --- |
| Auctionator | 347, supports Forever 1.60.1 | [CurseForge file 9620638](https://www.curseforge.com/wow/addons/auctionator/files/9620638) |
| TradeSkillMaster | 4.15.7, supports Forever 1.60.1 | [CurseForge file 9595290](https://www.curseforge.com/wow/addons/tradeskill-master/files/9595290) |

The upstream addon ZIPs are development inputs, not bundled dependencies or
redistributed files. API contracts were read from the actual release packages.

## Auctionator

Uses only `Auctionator.API.v1`:

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
Auctionator prices from earlier scan days display in gray and cannot win.
TSM age remains explicitly unknown. Estimates are never assigned a fabricated
`scannedAt` or available quantity and are never stored as own scan snapshots.

The smallest usable own-scan cost is highlighted green. The smallest usable
estimate is highlighted amber. These are separate comparisons, with ties allowed.
The compact tooltip uses color and short source badges; Shift reveals the
comparison legend and price age.

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

- 74 standard Lua 5.1 tests execute the production modules.
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
