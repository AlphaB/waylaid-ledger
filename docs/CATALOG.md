# Delivery catalog and prices

`Data.lua` and `WritData.lua` include the 0.7.0 fallback: 30 identified crates,
150 identified writs, and their delivery quantities. This restores the complete
lists after the discovery-only migration. Purchase/delivery prices remain in the
existing market caches or come from optional Auctionator/TSM providers.

The fallback is the factual catalog from commit `ce4f643`, checked against
Wowhead Forever on 2026-11-15. Its original source URLs and response hashes remain
in that revision's `data/catalog.json` and `data/writs.json`. Crate quantities
came from item tooltips; writ quantities came from quest objectives, since writ
item tooltips can contain only generic flavor text. The original import tools
are not required or distributed. No web requests run in the addon.

`Discovery.lua` uses complete client descriptions to update fallback bundles and
learn additional items. Learned definitions take precedence on reload. Old
unresolved rows for known fallback IDs recover their bundled quantities on
upgrade. Loading/flavor text preserves known bundles; explicit incomplete or
invalid objectives invalidate them until resolved. Locale/build partitions apply
to learned definitions. See [INGAME_DATA.md](INGAME_DATA.md).

The baseline full detailed scope is 300 writ purchase/delivery IDs, 126 crate
purchase/delivery IDs, or 424 combined after deduplication. Runtime discoveries
can enlarge it. Normal Refresh uses one bulk AH snapshot and has no addon timer
lockout. Client readiness and server restrictions still apply. `/wll scan deep`
uses detailed per-item pagination and the rolling search budget.

Prices remain separate from requirements. Market keys partition region, realm,
faction, project and custom profile. Replication snapshots contain observed
minimum unit-price estimates and real timestamps. Detailed snapshots contain
buyable offers and support stock checks, commodity price tiers and whole-stack
optimization. Fresh detailed shortages take priority over bulk estimates.
Auctionator/TSM public API values retain their provider identity and freshness
limitations; they are not presented as verified inventory.
