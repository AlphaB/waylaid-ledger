# Changelog

## 0.8.4

- Hand controller focus to Search when opening Waylaid or switching category tabs.
- Explicitly link the outer auction tab, category tabs, page controls and list rows in all four directions.
- Prevent tab-entry navigation from falling through to geometric scroll-frame centering.
- Release tab overrides when Waylaid is hidden, preserving native auction navigation.
- Extend the native-source test through actual tab clicks and page controls before traversing rows.
- 213 default Lua 5.1 tests; 219 with native navigation/auction UI and Auctionator contracts. In-game verification remains outstanding.

## 0.8.3

- Add timestamped, opt-in chat diagnostics with explicit `/wll debug on` and `/wll debug off` commands.
- Explain Auctionator scan detection, progress, completion/failure, closure, watchdog timeouts, and database callbacks.
- Log own-scan requests, stages, row counts, elapsed time, cancellations, and external-scan conflicts.
- Summarize tab selections, UI updates, description retries, and ignored discovery events without per-event chat spam.
- Include active external scan state and suppressed-message counts in `/wll report`; bound retained logs to 100 entries and 1,000 characters per message.
- Test disabled logging, repeated enable/disable, event-storm throttling, and logging during the Auctionator autoscan simulation.

## 0.8.2

- Enable controller list scrolling only while a row in the active list has focus.
- Move down from Search, Refresh/Stop or Settings directly into a visible row without scrolling first.
- Exclude scrollbar arrow/thumb controls from gamepad focus; mouse scrolling remains available.
- Preserve D-pad row selection across virtual-row boundaries, filtering, price updates and category changes.
- Add focus/viewport/boundary regressions and an optional test using unmodified Forever navigation code.
- 209 default Lua 5.1 regression tests; live in-game controller verification remains required.

## 0.8.1

- Stop processing Auctionator’s full snapshot alongside its autoscan; pause discovery until completion/failure.
- Remove scans triggered by tab switches, missing list prices, and unresolved descriptions. Explicit Refresh and opt-in AH-open scans remain available.
- Cancel pending automatic own scans when another addon starts a full scan.
- Show Auctionator’s reported percentage and disable Refresh while its scan runs. Show description-resolution progress during own scans.
- Break tooltip/discovery redraw feedback when delivery requirements have not changed; avoid repeated item-load requests for missing tooltip data.
- Cover 60,000 interleaved item-load events, tab switching, scan failures, compatibility fallback, and the released Auctionator event-bus contract.
- 206 default Lua regression tests; 208 with Auctionator’s released source. Live-client verification remains required.

## 0.8.0

- Ignore unrelated item-load events and wait for 250 ms of quiet before retrying delivery descriptions.
- Coalesce Auctionator price-update redraws; price changes no longer reparse delivery descriptions.
- Remove per-auction tuple/closure allocations and reuse normalized contract-prefix patterns.
- Resolve new deliveries before committing scan prices, then retain only contracts and delivery goods.
- Release the temporary market name index and prune unrelated estimates from older saved databases.
- Preserve fresh detailed snapshots, localized-name ambiguity, cancellation and progress timeouts.
- Add a repeated 100,000-auction CPU/memory benchmark and regressions for events spread across frames.
- 202 Lua 5.1 regression tests; Lua/Python lint and formatting checks pass.

## 0.7.2

- Remove the legacy standalone scan/shopping popup; use auction lists and official settings.
- Minimap left-click opens the auction list at the AH and settings elsewhere; right-click opens settings.
- Group settings by purpose, with matching native price-source dropdowns and explanatory tooltips.
- Dim dependent controls without discarding saved preferences.
- Remove inactive Auctionator follow-up and advanced TSM export buttons from the settings page.
- Show full/shared snapshot waiting states and auction-count progress instead of `1/0` from an empty item queue.
- Keep Stop available for shared snapshot processing; refresh status without rebuilding list rows.
- Correct Refresh's tooltip to describe the full-house snapshot; retain advanced slash commands.
- Preserve all ten supported client locales and native shopping/controller navigation.
- Remove duplicate Scan/Stop buttons and the superseded tracked-refresh checkbox.
- Record the standing PR → green CI → merge → GitHub release workflow in AGENTS.md.
- 195 Lua 5.1 regression tests.

## 0.7.1

- Restore the complete 30-crate / 150-writ fallback catalog after discovery migration.
- Preserve cached prices and learned bundles when descriptions contain only loading or flavor text.
- Parse crate Use lists with named colors, inline bullets and escaped line breaks.
- Remove the addon full-scan cooldown and ignore old saved lockout timestamps.
- Keep server readiness, single-flight scanning, cancellation and timeout checks.
- 146 Lua 5.1 regression tests.

- Preserve equipment variant queries, complete contract/inventory scopes, scoped refresh and TSM export.
- Cover native equipment handoff with the unmodified Forever query contract.

- Translate controls, settings, tooltips, baskets and scan status into every official client language.
- Automatically select the client locale, with English fallback and stable command/settings values.
- Fit longer button labels, wrap settings text and reflow basket instructions.
- Validate translation coverage/format arguments and bootstrap all ten locales through the install manifest.

- Recognize localized crate/writ prefixes for all ten official Forever locale variants.
- Parse localized delivery clauses, Unicode spacing/case and quantity wrappers.
- Preserve ambiguity checks and invalidate incomplete bundles in every locale.
- Keep unsupported plurals/declensions unresolved unless item hyperlinks supply IDs.
- Add a ten-locale regression matrix; live localized-client verification remains required.
- Defer and coalesce delivery parsing during full scans; ignore unrelated tooltip updates.
- Bound description retries and replication reads per frame, with elapsed-time budgets.
- Reuse displayed tooltip descriptions and refresh the UI once per retry wave.
- Let progressing large snapshots finish without hitting a total-duration timeout.

## 0.7.0

- Built-in fallback scanning for all writ/crate purchases and delivery goods.
- Auto uses optional provider data and scans missing/stale data in the active list.
- Own scans is available independently for writs; custom profiles can show complete totals.
- Built-in shopping basket opens Blizzard buying screens when Auctionator is absent.
- Scan prices and Stop controls in each list; Refresh schedules missing fallback data.
- Native Forever gamepad focus, virtual-row D-pad traversal, right-stick scrolling, and focus preservation.
- 122 default Lua 5.1 regression checks; 124 including unmodified Forever commodity UI contracts.
- Independent Astra High review and follow-up corrections; live controller/client verification remains required.

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
