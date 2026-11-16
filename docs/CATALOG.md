# Discovered requirements and prices

`Data.lua` and `WritData.lua` initialize empty tables. `Discovery.lua` learns
crate alternatives and cumulative writ objectives from item descriptions supplied
by the client. There is no bundled delivery database or web import/build step.
See [INGAME_DATA.md](INGAME_DATA.md) for discovery formats and limitations.

The learned catalog is saved under `WaylaidLedgerDB.discovery`, partitioned by
locale and client build. Localized item-name indexes map observed AH/bag items to
IDs. Hyperlinks provide IDs directly; ambiguous names stay unresolved. A parsed
crate supplies alternatives, while every writ objective is required. Unresolved
bundles cannot receive a complete total or shopping action.

`Catalog.ScanItems(contractIDs)` derives deduplicated purchase and delivery item
IDs from learned definitions. There is no fixed number of supported crates,
writs or scan items. The game's market and items encountered by the player decide
which definitions can be discovered.

Routine refreshes request one bulk AH replication snapshot. They do not follow
that request with another per-item Auctionator scan. The server's 15-minute full
scan cooldown applies; use saved prices between scans. `/wll scan deep` requests
detailed prices for learned IDs with normal pagination and search throttling.
Existing explicit Auctionator scans and TSM exports remain available.

Prices remain separate from requirements. Market keys partition region, realm,
faction, project and custom profile. Replication snapshots contain observed
minimum unit-price estimates and real timestamps. Detailed snapshots contain
buyable offers and support stock checks, commodity price tiers and whole-stack
optimization. Fresh detailed shortages take priority over bulk estimates.
Auctionator/TSM public API values retain their provider identity and freshness
limitations; they are not presented as verified inventory.
