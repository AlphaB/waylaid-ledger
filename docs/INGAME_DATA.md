# In-game data and fast scanning

The addon ships empty crate/writ tables. Item IDs, names and delivery quantities
are learned from the game; there is no downloaded delivery catalog or web importer.
Existing market snapshots and settings are retained on upgrade. A first in-game
scan is needed to populate the catalog; existing auction-addon prices alone cannot
enumerate every crate/writ through the reviewed public price APIs.

## First use and refresh

At an auctioneer, run `/wll scan all` or click **Full AH scan** in scan controls.
On the ranked-list UI, **Scan prices** uses the same full-scan path. The automatic
list scan can bootstrap an empty catalog. Auctionator and TSM remain optional:
their public price APIs supply prices once an item's ID is known.

The addon observes full-scan requests made by other addons and consumes the
shared `REPLICATE_ITEM_LIST_UPDATE` response. It never invokes Auctionator/TSM
internals or starts their scanners. An already completed scan from before this
addon loaded has no verifiable timestamp and is not presented as a fresh scan.

The client/server full-scan cooldown is 15 minutes. The last observed request time
is retained per character/realm across reloads so Refresh cannot repeatedly request replication.
During cooldown, use saved prices or `/wll scan deep` for an explicit detailed scan
of learned purchase/delivery items. Per-item fallback remains available on clients
without replication support; it retains the readiness and rolling request budget.

## Requirement learning

Names are indexed from AH replication rows, bags, ordinary AH browse results,
and item tooltips. Candidate names currently recognize English `Waylaid Crate:`
and `Craftsman's Writ:` prefixes. Non-English discovery formats need live samples;
unsupported descriptions remain unknown rather than receiving guessed quantities.

`C_TooltipInfo.GetItemByID` supplies descriptions. The parser accepts quantity/item
bullet lists and explicit English Bring/Deliver/Require clauses. Hyperlinked item
IDs are used when present; plain names must match exactly and unambiguously in
the observed localized name index. Requirements are read after the whole AH name
index is built, independently of auction row order. Missing item data retries on
item-load/tooltip events, further observations, provider updates, and later scans.
Retries are coalesced and deferred: each frame reads at most five descriptions,
yielding sooner after two milliseconds. Unrelated tooltip instance updates and
unchanged ordinary item loads do not retry the catalog. Candidate tooltip updates
retry only that item; unresolved descriptions sleep until another relevant signal.
UI updates occur once after a retry wave, and displayed tooltip data is reused
instead of fetched again.

Crate entries are alternatives; writ requirements are cumulative. A missing,
ambiguous, unsupported, duplicate or invalid requirement invalidates the entire
bundle. Unresolved rows cannot be shopped or assigned a zero-cost delivery total.
Build/locale partitions prevent another client's parsed quantities from becoming
an unchecked source. Parsed requirements are rechecked when their item is hovered
or encountered in a later full scan.

Only observed items appear. The client does not provide an API that enumerates
all future crates/writs; an item absent from the AH can still be learned from a
bag or tooltip. Missing plain-name goods need another observation before their IDs
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

Lua 5.1 tests execute production modules, including empty startup, exact name and
hyperlink resolution, large quantities, ambiguity, late data and invalidation.
The bulk test feeds 6,000 auctions in 24 batches using one replication request;
this is a request-count/batching regression, not a measured live-server timing.
Tests also cover passive reuse, minimum prices, fresh-shortage preservation,
cooldown, cancellation and timeout. Event-burst tests cover 180 unresolved
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
