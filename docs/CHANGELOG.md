# Changelog

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
