# Changelog

## 0.6.1

- Replace the classic scrollbar middle artwork with a dark rail to remove the green strip.
- Keep native scrolling, arrows and thumb behavior unchanged.
- Rename the internal Writs tab to Craftsman's Writs.
- Clarify Refresh behavior in its button tooltip and documentation.
- Test that Refresh bypasses cached provider reads and resorts saved prices without scanning.
- 108 default Lua 5.1 tests; 110 with upstream API contracts.

## 0.6.0

- One outer Waylaid auction tab, with internal Writs and Waylaid Crates tabs.
- Native auction-style ScrollBox and scrollbar, framed headers and compact striped rows.
- Recycle visible row buttons instead of creating one for every catalog item.
- Preserve category search and scroll state; avoid rebuilding rows during item hover.
- Move all preferences to Settings → AddOns → Waylaid Ledger.
- Settings buttons, minimap right-click and `/wll settings` open the same official page.
- Remove `~` price prefixes and list footer/age markers.
- Highlight every cheapest known tooltip option in green, including provider/cached prices.
- 107 default Lua 5.1 tests; 109 with upstream API contracts.

## 0.5.1

- Remove the outdated-data notification from all item and basket tooltips.
- Restore lowest-known highlighting even when every available price is cached.
- Use one lowest-cost selection across tooltips, controls and crate shopping.
- Explicit winner text color survives native money strings with embedded white formatting.
- Unknown, insufficient and failed results still cannot win; ties highlight together.
- 103 default Lua 5.1 tests; 105 with upstream public API contracts.

## 0.5.0

- Opt-in automatic own scanning on AH open, independent of visible panels and inventory tracking.
- Scan only missing, stale or failed crate materials; reuse fresh snapshots.
- Two-second quiet period on opening; active scans yield to competing searches.
- Persisted settings checkbox and `/wll scanopen on|off`.
- Remove tooltip source badges and gray explanatory footers.
- One gray outdated-data notice after 12 hours for timestamped own data.
- Cautious notice for Auctionator previous-day prices; no invented provider timestamps.
- 102 default Lua 5.1 tests; 104 including upstream API contracts.

## 0.4.0

- Separate Writs and Waylaid Crates auction tabs with scrollable ranked lists.
- Purchase, delivery, and total columns; unknown totals sort last.
- Search by item or delivery goods; hover for the full price breakdown.
- Crate rows select the cheapest known usable filling option.
- Row clicks open Auctionator Shopping with one writ/crate and its delivery goods.
- Baskets are repriced and localized names validated before handing off scans.
- Purchase quotes read Auctionator/TSM caches; own scanning stays at 96 materials.
- Original scan controls remain under settings and `/wll controls`.
- 87 default Lua 5.1 tests; 89 with upstream API contracts including tab switching.

## 0.3.0

- AH-integrated Waylaid tab using the shared LibAHTab row.
- Optional, draggable minimap button and settings window.
- Server-ready scanning with a rolling request budget instead of a fixed 0.8s delay.
- Compact, consistent scan/provider tooltips; hold Shift for details.
- Configurable bag, visited-bank, shared-bank and alt inventory snapshots.
- Automatic refresh of missing/stale tracked crate prices in the AH panel.
- Provider-only hover estimates for 150 Forever Craftsman's Writs.
- Exact Wowhead objectives; 148 new goods kept out of the own-scan queue.
- Clean install ZIP and downloadable CI artifact.
- 74 default Lua 5.1 tests; 76 with upstream public API contracts.

## 0.2.0

- Optional Auctionator and TSM price providers, defaulting to Auto.
- Configurable provider and TSM price definition, preserved across reloads.
- Source-labelled unit-price estimates and honest data-age labels.
- Separate green verified and amber estimated cheapest-option highlighting.
- Auctionator update notifications and capability-based shopping handoff.
- UI controls to search all alternatives, cycle bundles, and shop one option.
- Own scanner stops before handing queries to Auctionator.
- Localized material names for shopping; missing names are loaded before retry.
- Expanded diagnostics and migration without clearing 0.1.0 scan snapshots.
- 53 default tests; 55 including release-source API contract checks.

## 0.1.0

- Initial 30-crate / 96-material catalog from Wowhead Forever.
- Standalone quantity-aware auction scanning, cached prices, and crate tooltips.
