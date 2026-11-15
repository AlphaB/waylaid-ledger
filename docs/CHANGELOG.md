# Changelog

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
