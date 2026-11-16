# In-game data and fast scanning

The addon ships the previous 30-crate / 150-writ catalog as a fallback, with
complete in-game descriptions taking precedence. The lists and known delivery
quantities are available before the first scan. Existing market snapshots,
settings and successfully learned definitions are retained on upgrade. Old
unresolved rows for bundled items recover their fallback. See [CATALOG.md](CATALOG.md)
for the fallback's provenance.

## First use and refresh

At an auctioneer, run `/wll scan all` for an own full snapshot on Forever, which
can discover additional contracts. **Refresh** reloads public provider prices for
Auto with an available provider, Auctionator, or TSM. It requests an own snapshot
for Own, custom market profiles, or when no provider is available. Missing provider
quotes remain unknown; use that provider’s scan controls for newer data.
Tab switches never schedule queries. Auctionator and TSM remain optional:
their public price APIs supply prices once an item's ID is known.

External full scans are observed only for their lifecycle and status. Waylaid
does not consume another addon's replication rows. Auctionator's optional scan
events provide its percentage; discovery stays idle through database processing
and resumes once on completion/failure. The price database callback invalidates
cached provider quotes. See [INTEGRATIONS.md](INTEGRATIONS.md) for the guarded
adapter and fallback behavior. New contract discovery from the entire market
requires an explicit Waylaid scan.

Full snapshots share a 15-minute interval. Ordinary query readiness does not
indicate that replication is available. The addon records response timestamps
without reading another addon’s rows, and checks Auctionator’s guarded saved
last-request timestamp. Both survive reloads; old guessed per-market lockouts are
still discarded. A known cooldown rejects an own full scan immediately with a
remaining-time message. An unanswered request reports the missing response rather
than suggesting that an idle house is sufficient. Unknown server restrictions
can still cause a request to time out. `/wll scan deep` requests detailed purchase/delivery prices
with normal pagination and the rolling request budget. Per-item fallback remains
available on clients without replication support.

## Requirement learning

Names are indexed from AH replication rows, bags, ordinary AH browse results,
and relevant item tooltips. Unrelated item-load events do not grow the index or
retry unresolved descriptions. Candidate names recognize the localized crate and writ prefixes
for every locale listed on the [official Battle.net product page](https://tw.shop.battle.net/en-us/product/world-of-warcraft-forever):
`enUS`, `enGB`, `deDE`, `frFR`, `esES`, `esMX`, `ptBR`, `ruRU`, `koKR`, and `zhTW`.
English fallback names are also accepted on these clients. The bundled English
name index is seeded only on enUS/enGB; other locales request actual client names. Controls, settings,
price tooltips, shopping baskets and scan status messages use the client language
automatically. Both English variants use English wording; Spanish variants share
control translations with their respective localized crate names. Missing
translations and unsupported locales fall back to English. Slash-command keywords,
saved setting values and diagnostic-report field names remain stable.

Button text adapts to available width while retaining the client font, settings
labels can wrap, and the basket reserves room for wrapped instructions. The native
controller actions are unchanged. Localized layout and typography still need a
live-client check; the automated UI tests use frame mocks.

`C_TooltipInfo.GetItemByID` supplies descriptions. The parser accepts quantity/item
bullet lists and explicit delivery/require clauses in these locales. Unicode
spaces, curly apostrophes, full-width colons, multiplication signs, supported
quantity wrappers and Chinese quantity/name adjacency are normalized. Crate Use
descriptions also support named colors, inline bullets and escaped line breaks.
Hyperlinked item IDs are used when present; plain names must match exactly and unambiguously in
the observed localized name index, ignoring letter case with explicit UTF-8
handling. Accents are retained. Requirements are read after the whole AH name
index is built, independently of auction row order. Missing item data retries on
item-load/tooltip events, further observations, provider updates, and later scans.
Shopping can reuse a saved observed name from the current locale/build while
the client's item-name cache is loading.
Retries are coalesced and deferred: each frame reads at most five descriptions,
yielding sooner after two milliseconds. Unrelated tooltip instance updates and
unchanged ordinary item loads do not retry the catalog. Candidate tooltip updates
retry only that item; unresolved descriptions sleep until another relevant signal.
UI updates occur once after a retry wave, and displayed tooltip data is reused
instead of fetched again.

Crate entries are alternatives; writ requirements are cumulative. An explicit
ambiguous, incomplete, duplicate or invalid requirement invalidates the entire
bundle. Generic writ flavor text and loading text do not erase an already known
bundle. Writ tooltips that omit objectives continue using the fallback quantities.
Unknown items with unsupported descriptions remain unresolved. Unresolved rows
cannot be shopped or assigned a zero-cost delivery total.
Build/locale partitions prevent another client's parsed quantities from becoming
an unchecked source. Parsed requirements are rechecked when their item is hovered
or encountered in a later full scan.

Localized prefix samples were checked against Forever item tooltips for
[crate 248682](https://www.wowhead.com/forever/item=248682) and
[writ 264050](https://www.wowhead.com/forever/item=264050) on 2026-11-16.
Format support does not guarantee that every localized description can resolve:
German, Portuguese, Latin American Spanish and Russian samples include plural or
declined names that differ from the item's name. These require an authoritative
item link; the parser does not guess an item ID from a grammatical stem. Writ
descriptions that do not supply quantities retain a bundled fallback when available;
new items remain unresolved. A partial parse never replaces a complete bundle.

All bundled items appear immediately. Additional items need observation: the
client does not provide an API that enumerates all future crates/writs. An item
absent from the AH can still be learned from a bag or tooltip. Missing plain-name goods need another observation before their IDs
can be resolved. The addon does not infer requirements from crafting recipes.

## Prices, speed and cancellation

`C_AuctionHouse.ReplicateItems()` requests the market once. Replicate rows are
zero-indexed; quantity is return 3, total buyout return 10, and item ID return 17.
The scan indexes at most 250 rows per frame, yielding sooner after two milliseconds.
Row processing runs only on the scan frame, rather than also inside response events
and the main scheduler. The 30-second timeout measures lack of progress, so a large
snapshot that continues to advance can finish across more frames. Only
minimum positive unit prices are retained; bid-only and invalid prices are skipped.
No missing/partial row becomes a verified sold-out result.

The full market name index and minimum-price map are temporary. Descriptions
resolve against that complete index before committing prices for contracts and
their delivery goods. Other item names and prices are released when the scan
finishes or is cancelled. Upgrades also remove unrelated full-scan estimates
from saved market profiles, preserving relevant prices and detailed snapshots.
Localized-name collisions remain ambiguous after cleanup.

Item/tooltip retries and Auctionator update redraws wait for 250 ms of quiet.
Auctionator price updates invalidate the price cache immediately but do not
retry delivery parsing. Ending an external full scan retries pending descriptions
once. Unchanged descriptions do not redraw lists or rebuild tooltips, preventing
the tooltip → discovery → redraw feedback loop. Missing tooltip data requests
an item load only once until actual tooltip data arrives. Consumed discovery queue entries are periodically
compacted during long event streams.

Run `python3 tests/scan_performance.py --verify` for a synthetic three-scan
benchmark (100,000 auction rows, 20,000 unique items per scan). It reports CPU
time, peak Lua memory growth and retained growth after garbage collection, and
checks that unrelated market data is released. These figures exclude WoW's
native auction API costs and are not an in-game FPS or memory measurement.

Replication prices are labelled AH full-scan estimates. They do not establish
buyable stock, owner/account filtering, stack outlay, or availability at every
price tier. Fresh detailed snapshots, including observed shortages, take priority.
Both price forms retain their real observation timestamps. Automatic provider
resolution and forced-source policies continue to apply.

A stopped/closed/timed-out scan cannot commit a late response. Processing retains
the originating market object across profile changes. No purchase, posting or
cancellation API is called. Detailed per-item scanning remains serialized and
paginated, with its existing 100-request/60.1-second budget and server readiness.

## Validation

Lua 5.1 tests execute production modules, including fallback upgrades, exact name and
hyperlink resolution, large quantities, ambiguity, late data and invalidation.
The locale matrix checks candidate recognition, complete and partial bundles,
Unicode case collisions, wrappers, hyperlinks and per-locale persistence for all
ten variants. Delivery-clause examples are constructed syntax tests, not captured
live-client descriptions. Localized plurals without links are tested as unresolved.
The bulk test feeds 6,000 auctions in 24 batches using one replication request;
this is a request-count/batching regression, not a measured live-server timing.
Tests also cover passive reuse, minimum prices, fresh-shortage preservation,
immediate repeat refreshes, ignored old lockouts, cancellation and timeout. Event-burst tests cover 180 unresolved
descriptions, targeted tooltip updates, retry coalescing, reentry and elapsed-time
budgets using a simulated clock. These do not measure live client frame times.
Legacy UI/pricing tests use synthetic catalogs
that are injected only by the test runner and excluded from install packages.

Primary contracts checked against the Forever client source and Auctionator 347:

- [Blizzard auction API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/AuctionHouseDocumentation.lua)
- [Blizzard tooltip API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoDocumentation.lua)
- [Auctionator 347 release](https://www.curseforge.com/wow/addons/auctionator/files/9620638), `Source_ModernAH/FullScan/Mixins/Frame.lua`

Live Forever testing is still required for exact tooltip wording, asynchronous
item-data delivery, server cooldown behavior, elapsed scan time, and actual UI
rendering. `/wll inspect <itemID>` provides description text for unsupported cases.
