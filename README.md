# Waylaid Ledger

A standalone World of Warcraft: Forever addon that scans the auction house for
Waylaid Crate materials and adds the cost of every filling option to crate
item tooltips. The lowest known filling cost is highlighted in green for all price sources,
including cached prices. Auctionator and TSM are optional price providers.

Version **0.7.0** · Forever **1.60.1 / interface 16001** · No addon dependencies.

## Install

1. Extract the download. Copy the **WaylaidLedger** folder into the Forever
   client's **Interface/AddOns** directory. Select Forever in Battle.net and use
   **Show in Explorer / Show in Finder** to locate the correct installation.
   Common path: `World of Warcraft/_forever_/Interface/AddOns/WaylaidLedger/`.
   An older beta installation may use `_classic_beta_`; use the directory that
   actually contains the client you play.
2. Check that `WaylaidLedger.toc` sits directly inside that folder, rather than
   inside another nested `WaylaidLedger` folder. The install ZIP contains only
   the addon and its licenses; developer sources live in this repository.
3. Restart the game, enable **Waylaid Ledger** in the AddOns menu, and log in.
4. Discover requirements with a first AH scan (see below). After discovery,
   saved scan prices or optional Auctionator/TSM estimates also work away from the AH.
5. Visit an auctioneer and select **Waylaid**, then its internal **Craftsman's Writs** or
   **Waylaid Crates** tab. Each list shows
   its catalog in order of **purchase + delivery** cost. Click a row to open
   Auctionator Shopping when available, or a built-in basket with one writ/crate
   and its complete delivery bundle.
   The minimap button opens your last used list; right-click it for the official
   **Settings → AddOns → Waylaid Ledger** page.
6. Hover a recognized Waylaid Crate in your bags, chat, or the auction house to
   compare its options. `/wll settings` changes price preferences.
   `/wll controls` opens the original scan and diagnostic controls.

**Full AH scan** uses one bulk request. Saved prices remain available after
leaving the auction house and across reloads/logins. Auctionator and
TradeSkillMaster are optional.

## In-game discovery and fast scans

Requirements now come from the game's item descriptions. No delivery catalog or
web importer is bundled. See [in-game data and scanning](docs/INGAME_DATA.md).
Discovery formats cover all ten official client locale variants: US/EU English,
German, French, European/Latin American Spanish, Brazilian Portuguese, Russian,
Korean and Traditional Chinese. Controls, settings, price tooltips, shopping baskets,
and scan status messages automatically follow the client language, with English
fallback for missing translations. Plain plural or
declined names that cannot be mapped exactly to an item remain unresolved;
see the discovery notes for current limits.
On first use, visit an auctioneer and run `/wll scan all` (or **Full AH scan** in
scan controls). The lists fill as items and descriptions are discovered. A bulk
scan started by another addon is reused automatically while Waylaid Ledger is loaded.

The full scan uses one replication request, rather than hundreds of item searches.
The server's full-scan cooldown is 15 minutes; saved prices remain usable between
scans. `/wll scan deep` explicitly requests detailed prices for learned items.
Bulk prices are unit-price estimates; detailed scans retain stock and stack checks.

The fixed catalog sizes and per-item scan timings in older release notes below
are historical. Only items encountered in game can appear in the learned lists.

## What the tooltip means

Each line is the cost to buy one complete bundle for **one crate**. The crate's
own purchase price is not included. Existing inventory is not deducted.

- Each option uses one compact row: quantity/item on the left, amount on the
  right. Prices have no `~` prefix. Source badges and the gray explanatory
  footer remain removed.
- The **lowest displayed known filling cost** is highlighted **green** for
  every source, including estimates and older cached scans. All tied
  minima highlight, even if every available price is cached. Unknown prices,
  failed scans, and observed shortages never win.
- **Not scanned / No price** means no usable data exists for the selected source.
- **Only N / None listed** means a complete scan found insufficient buyable stock.
- Failed prices stay gray and cannot win. Cache freshness still guides Auto's
  source selection and automatic refresh; older cached prices remain eligible
  for lowest-known comparison. There is **no outdated-data notification**.
- **Buy N** includes unavoidable excess from purchasing a whole auction stack.
- Hold **Shift** for ages and detailed explanations, or enable detailed tooltips
  in settings. Source and age appear inline only in this detailed view; the
  footer legends stay removed. Auctionator age is in days; TSM age is unknown.

Commodity costs consume the cheapest price tiers until the required count is
reached. Item-auction costs use an exact minimum-cost subset calculation; a cheap
unit price on a large stack does not necessarily mean the lowest cash outlay.
Bids without a buyout and your own auctions are excluded. For commodities, a
bucket flagged as containing another character's account-owned stock is excluded
entirely because the API exposes no separate account-owned quantity. This can
make the estimate conservative when other sellers share that price bucket.
All prices are **snapshots**, not reserved purchase quotes. External estimates
are `required quantity × cached unit price`: they do not establish available
quantity, account-owned stock filtering, price-tier depth, or whole-stack outlay.

The unidentified crate (item 248549) must be opened/identified before its
requirements are known. Its tooltip explains this instead of inventing prices.

## Tracking and controls

`/wll settings` opens **Settings → AddOns → Waylaid Ledger**. This page configures
crate/writ price sources, the TSM price definition, minimap visibility, bag/bank/alt
tracking, automatic AH refresh, and tooltip details. Drag the
minimap button to reposition it. Away from the AH, `/wll` opens a standalone window.
At the AH, only **one Waylaid tab** occupies the addon tab row. Writs and
Waylaid Crates use internal top tabs, leaving more room for Auctionator and
other auction addons. Each category keeps its own search and scroll position.
The original scan controls remain under `/wll controls` or the official settings
page's **Scan controls** button; there is no separate settings popup.

Bag snapshots update on login and inventory changes. Character/shared bank
snapshots update while the bank is open. Log into each alt and visit its bank
once to seed the data. Offline characters show **last-seen** counts; WoW cannot
read their changing inventories live. Only crate/material counts are stored.
Snapshots are restricted to the same region/realm/faction/project; shared-bank
items are counted once. `/wll inventory` shows snapshot timestamps. Settings can
clear remembered inventory without clearing prices.

Automatic refresh runs only at the AH while the Waylaid Crates tab or scan controls are visible, for
missing, stale, or failed requirements of tracked crates. It never queries in a
forced Auctionator/TSM mode. **Stop** pauses automatic refresh for that AH visit;
manual scan or reopening the AH enables it again. Starting another auction search
stops our queue. There are no idle polling timers or auction queries away from AH.

### Scan when opening the auction house

Enable **Auto-scan crate prices on auction open (Auto/Own)** in `/wll settings`,
or type **`/wll scanopen on`** (`off` disables it). This option is **off by default**
and survives reloads. It is separate from tracked-inventory refresh.

With crate price source Auto or Own, it waits two seconds after the AH opens,
then scans missing, failed, or stale materials across the full **96-item crate
catalog**, without needing our tab or inventory tracking. Fresh snapshots are
reused. Closing or switching away from our panels does not cancel this opening
scan; **Stop**, AH closure, disabling the option, or a competing query during an
active scan cancels it. Pending opening work waits until observed searches and
page requests have been quiet for two seconds, so the initial Blizzard browse
query does not suppress it. An interrupted active scan stays paused until a
manual scan or the next AH visit.

This opening option scans crate materials. Opening a ranked list also queues
its missing prices, including writ goods and writ/crate purchase prices.
It does not run in forced Auctionator or TSM mode, and performs no queries away
from the auction house.

## Ranked auction lists

Inside the Waylaid auction tab, **Craftsman's Writs** lists discovered identified writs,
and **Waylaid Crates** lists
discovered identified crates. Columns show the purchase price of one writ/crate, the
full delivery cost, and their sum. Rows with known totals sort from cheapest to
most expensive; unknown totals follow alphabetically. Missing data is never counted as zero. Prices have no estimate prefixes or
age markers; detailed provenance remains available on hover.

Each crate row chooses its cheapest usable filling option across scans and
provider estimates. Older cached prices remain eligible for this comparison. This is the **lowest known** cost; unpriced alternatives might be cheaper.
A completed scan showing insufficient stock excludes that alternative. A crate
with no priced filling option cannot launch a basket until prices are available.
Writ objectives are cumulative and always use their full delivery quantities.

Purchase and delivery prices follow that category's source preference. In Auto,
existing Auctionator/TSM prices are used automatically. Opening a category queues
our own scans for missing, failed, or stale prices without a current provider
estimate. Fresh own snapshots, including observed shortages, are reused. This
works with neither addon installed and with custom market profiles.

**Refresh** rereads saved provider prices and schedules missing fallback data.
**Scan prices** deliberately refreshes the full current category with our scanner
(in Auto/Own mode). **Stop** pauses automatic work until Refresh, a manual scan,
or the next AH visit. A full category scan covers **126 items for Crates** or
**300 for Writs**, including their purchase prices. The shared rolling throttle
means a large scan can take several minutes. Switching categories cancels an
active automatic list scan; leaving the Waylaid tab also stops it. Opening scans
and explicit manual scans keep their separate lifecycle.

The lists use native ScrollBox rows, filtering, and scrollbars. Hover a row for
its complete price breakdown. Totals are acquisition costs: rewards, owned stock,
AH fees, and travel are not deducted. Unknown or failed components never count as
zero. Completed scans persist after leaving the AH and across reloads.

Clicking a row uses Auctionator's advanced Shopping API when available. Otherwise,
a built-in basket lists **one writ/crate plus its delivery goods**. Open each item
from that basket to use Blizzard's buy screen. Commodity quantities are filled
in; whole item auctions are selected and confirmed in the native UI. The basket
remains available alongside the AH until closed. Crates include exactly one
alternative, repriced when clicked. TSM supplies optional prices; it is not
required for shopping. All purchases require the normal user confirmation.

## Built-in controller support

WoW Forever's native gamepad UI can navigate the category tabs, controls, basket,
and virtual list rows. D-pad up/down traverses rows beyond the visible pool;
the right stick scrolls the active list. Price updates preserve the focused item
when the list resorts. Decorative headers are excluded from navigation. The
standalone scan and diagnostic windows participate in native frame focus and
Back/close handling. No controller addon is required.

## Craftsman's Writ estimates

Hover a learned **Forever Craftsman's Writ** to see the estimated
price of its required finished goods. Delivery quantities are learned from the
client's descriptions; unresolved requirements never receive a fabricated total. These are delivery costs, excluding the writ's own purchase
price, crafting reagents, quest rewards, and owned inventory deductions.

Writ delivery and purchase prices use the same provider and own-scan resolver as
crates. The separate **Writ prices** preference cycles **Auto / Auctionator / TSM /
Own scans / Off**. Auto uses fresh own depth scans, then optional provider data,
and scans missing data while the Writs list is open. This preference is independent
of the crate source. Custom market profiles use only our own snapshots. Hold
Shift for source and age details.
Unidentified sealed writ containers have no known requirements and are not priced.

## Optional price providers and shopping

The **Prices** button cycles **Auto / Auctionator / TSM / Own scans**. The TSM
button switches **minimum buyout / market value**. Settings survive reloads.

In **Auto**, each material uses:

1. A fresh own scan, including an observed shortage or no listings.
2. An Auctionator estimate not known to be from an earlier day.
3. A TSM estimate using `DBMinBuyout` by default.
4. An older Auctionator estimate in gray, if no usable alternative exists.
5. The old own snapshot or an unknown result if neither addon has data.

A forced source uses only that provider. For example, selecting TSM does not
silently replace a missing TSM price with Auctionator or our scan. `DBMarket`
is a selectable historical market-value estimate; it is never chosen silently
when `DBMinBuyout` is missing. The addon needs no external service, API key, or
account connection. Existing TSM users maintain their pricing through TSM's
normal data setup.

For the original delivery-only shopping controls, hover a crate and use `/wll controls`:

- **Search all alternatives** opens searches for every possible
  filling material, with required quantities. You still need only one bundle.
- **Shop selected option** opens the chosen material and its bundle quantity.
- Click **Option N/M** to cycle choices. A newly hovered crate initially selects
  the lowest verified option, or the lowest estimate if there is no verified one.

Shopping uses the built-in basket if Auctionator is absent. It stops our scanner
before opening buying screens or starting Auctionator's queue. It never buys
anything. The current API uses a temporary Auctionator shopping search. For
older compatible releases, a fallback creates/replaces only an addon-managed
`Waylaid Ledger - <crate ID> - ...` list. Localized clients use actual in-game
material names; a missing name is requested, and the user can retry after it loads.

Auctionator's public price-update callback refreshes estimates and tooltips.
TSM estimates are read on demand and briefly cached in memory for 15 seconds;
that cache duration does not indicate the underlying price data's freshness.
Imported estimates are not written into our persisted scan snapshots.

Both integrations use capability checks, optional dependencies, and protected
public-API calls. Missing addons and missing data do not prevent own scans.
See [docs/INTEGRATIONS.md](docs/INTEGRATIONS.md) for the reviewed API contracts.

## Commands

| Command | Action |
| --- | --- |
| `/wll` | At AH: last used list tab; elsewhere: scan window |
| `/wll controls` | Open the standalone scan and diagnostic controls |
| `/wll scan bags` | Scan materials for recognized crates in equipped bags |
| `/wll scan hovered` | Scan the last recognized crate you hovered |
| `/wll scan tracked` | Scan materials for remembered bag/bank/alt crates |
| `/wll settings` | Configure inventory, refresh, minimap, details, and writs |
| `/wll inventory` | Show last-seen inventory snapshot timestamps |
| `/wll minimap on` | Show button (`off` hides it) |
| `/wll tracking on` | Capture bag inventory (`off` disables it) |
| `/wll banks on` | Include visited banks (`off` excludes them) |
| `/wll alts on` | Include remembered alts (`off` excludes them) |
| `/wll scanopen on` | Auto-scan missing/stale crate prices on AH open (`off` disables it) |
| `/wll autoscan on` | Refresh tracked prices in the AH panel (`off` disables it) |
| `/wll details on` | Always show tooltip details (`off` uses Shift) |
| `/wll writsource auto` | Writ prices: auto, auctionator, tsm, own, or off |
| `/wll scan all` | Scan all 96 crate materials |
| `/wll scan crates` | Scan all 126 crate purchase and delivery items |
| `/wll scan writs` | Scan all 300 writ purchase and delivery items |
| `/wll source auto` | Fresh own scans, then Auctionator, then TSM estimates |
| `/wll source auctionator` | Use only Auctionator estimates |
| `/wll source tsm` | Use only TSM estimates |
| `/wll source own` | Use only our scan snapshots |
| `/wll tsmkey DBMinBuyout` | TSM minimum buyout estimates (default) |
| `/wll tsmkey DBMarket` | TSM historical market-value estimates |
| `/wll search` | Search every alternative for the last hovered crate |
| `/wll shop` | Shop the selected filling option |
| `/wll shop 2` | Shop option 2 for the last hovered crate |
| `/wll stop` | Stop; keep completed material snapshots |
| `/wll report` | Open a selectable, copyable diagnostic report |
| `/wll debug` | Toggle detailed scan messages |
| `/wll inspect 248707` | Copy the client's own tooltip text for that item |
| `/wll market neutral` | Switch to a separate market cache profile |
| `/wll market default` | Return to the default profile |
| `/wll clear` | Clear prices in the current realm/faction/profile |

`/waylaidledger` is an alias for `/wll`. Escape closes the windows.

Caches are isolated by region, realm, faction, project, and market profile. If you
use a neutral auction house or another house with a different inventory, switch
to a separate profile before scanning; the API surface used here does not expose
a reliable auction-house identity. **Imported prices are disabled for custom
profiles**, since the reviewed providers do not expose a matching house identity.
Use own scans there. Return to `default` for normal provider estimates.

## First live test

The fallback scans, built-in basket and native controller integration are tested
in a simulated Lua 5.1 client and still need a live Forever check.
Please start with a small test:

1. Enable Lua errors with `/console scriptErrors 1`, then `/reload`.
2. Have an identified crate in your bags and open the auction house.
3. Check the single Waylaid tab alongside Auctionator and the two internal tabs.
   Check filtering, mouse-wheel/scrollbar scrolling, and row hovers.
   Check one purchase + delivery total and click it: Auctionator should open
   Shopping with one writ/crate and the full delivery quantity.
   Check the minimap button and settings.
   Type `/wll debug`, then `/wll scan bags`. Check that Stop pauses auto refresh.
4. After completion, hover the crate. Check one listed material manually in the
   auction house, including enough units to fill the crate.
5. Close the auction house and hover again. `/reload` and verify cached prices
   remain visible.
6. If using Auctionator, check `/wll source auctionator`, its update after a scan,
   and the legacy shopping buttons in `/wll controls`. Verify that the selected material and quantity are
   correct. With TSM data available, check `/wll source tsm` against its tooltip.
   Return to `/wll source auto` afterward.
7. Log into an alt, visit its bank, and check remembered crate counts after
   returning. Toggle bank/alt tracking to check inclusion. Hover a writ with
   Auctionator/TSM prices; compare its quantity and estimated cost.
8. Disable Auctionator and TSM, leave both sources on Auto, and open each list.
   Verify that totals populate from our scan, then open a basket and check its
   native buying screen and quantity (including the 200-unit ammo writ).
9. Enable Forever's built-in controller UI. Navigate tabs, move past ten rows
   with the D-pad, scroll with the right stick, filter, and refresh prices while
   focused on a row. Check basket and standalone-window Back/close behavior.
10. If something fails, send the exact error and **`/wll report`** output. Include
   the crate item ID and **`/wll inspect <ID>`** output if its requirements differ.
   The report contains your realm/faction/profile and scan logs; it is only shown
   locally and is never sent automatically.

The game build and live server behavior still need this check. No purchases,
posts, cancellations, trade actions, or communication are performed by the addon.

## Development

Runtime modules are small Lua files loaded in TOC order. `Pricing.lua` is pure;
`Scanner.lua` has injected API/clock/callback dependencies. UI and SavedVariables
integration are separate. LibStub (public domain) and LibAHTab 1.0 minor 5
(MIT, plusmouse) are vendored unchanged, with licenses, to share the AH tab row.
See [third-party notices](docs/THIRD_PARTY.md).

Requirements for the developer tests: Python 3.10+ and `lupa==2.8`.

```sh
python3 -m pip install -r requirements-dev.txt
python3 tests/run.py
python3 tools/package.py
```

The test suite uses a real Lua **5.1** interpreter through Lupa. It covers price
depth, indivisible auctions, randomized exhaustive cross-checks, stale/unknown
results, pagination, throttling, retry timeouts, interruptions, owned-stock
filtering, profile isolation, full bootstrap, tooltip text, provider priorities,
source settings, API errors, price-age semantics, callbacks, and shopping handoff.
The default suite also covers complete fallback scans and native controller
navigation (122 checks). Two additional contract tests run the actual unmodified
public API Lua from separately downloaded release ZIPs:

```sh
python3 tests/run.py --auctionator /path/to/Auctionator-347.zip --tsm /path/to/TradeSkillMaster.zip
```

Two further contracts execute unmodified Forever commodity list and buy-display
source, including asynchronous quantity synchronization and cached-zero results.
Place `Blizzard_AuctionHouseCommoditiesList.lua` and
`Blizzard_AuctionHouseCommoditiesBuyFrame.lua` from the Forever UI's
`Interface/AddOns/Blizzard_AuctionHouseUI/Shared` directory in a local folder:

```sh
python3 tests/run.py --forever-ui /path/to/forever-ui-sources
```

These exercise the public functions with internal services stubbed. They do not
claim to run either entire addon or the live WoW client. The full upstream Auctionator/TSM packages are not redistributed; only the
separately licensed shared tab libraries are bundled.

Requirements are learned at runtime, with no developer refresh/import step.
CI runs the Lua suite and uploads the clean install ZIP as the
**WaylaidLedger-install** artifact. `python3 tools/package.py` builds the same
single-folder archive locally. See [docs/INGAME_DATA.md](docs/INGAME_DATA.md).
