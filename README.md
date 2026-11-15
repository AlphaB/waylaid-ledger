# Waylaid Ledger

A standalone World of Warcraft: Forever addon that scans the auction house for
Waylaid Crate materials and adds the cost of every filling option to crate
item tooltips. The cheapest freshly scanned option is highlighted in green; the lowest imported
estimate is highlighted in amber. Auctionator and TSM are optional price providers.

Version **0.2.0** · Forever **1.60.1 / interface 16001** · No addon dependencies.

## Install

1. Extract the download. Copy the **WaylaidLedger** folder into the Forever
   client's **Interface/AddOns** directory. Select Forever in Battle.net and use
   **Show in Explorer / Show in Finder** to locate the correct installation.
   Common path: `World of Warcraft/_forever_/Interface/AddOns/WaylaidLedger/`.
   An older beta installation may use `_classic_beta_`; use the directory that
   actually contains the client you play.
2. Check that `WaylaidLedger.toc` sits directly inside that folder, rather than
   inside another nested `WaylaidLedger` folder. The top-level `tools`, `tests`,
   `docs`, and `data` directories are developer sources; do not copy those into
   AddOns.
3. Restart the game, enable **Waylaid Ledger** in the AddOns menu, and log in.
4. Hover an identified crate. If Auctionator or TSM already has pricing data,
   estimates appear immediately, including away from the auction house.
5. For quantity-aware prices, visit an auctioneer, type **`/wll`**, and choose
   **Scan bags** or **Scan all**. Keep other auction searches idle until it finishes.
6. Hover a recognized Waylaid Crate in your bags, chat, or the auction house to
   compare its options. Open `/wll` to choose a price provider or shop a bundle.

**Scan all** searches 96 materials. A quiet server can complete the initial
requests in roughly 80 seconds; pagination or throttling takes longer. Prices
remain available after leaving the auction house and across reloads/logins.
The addon does not require Auctionator or TradeSkillMaster.

## What the tooltip means

Each line is the cost to buy one complete bundle for **one crate**. The crate's
own purchase price is not included. Existing inventory is not deducted.

- **Cheapest**: all alternatives have fresh known results; all tied minima turn
  green.
- **Lowest verified** (green): the lowest usable quantity-aware scan cost, but
  some other alternatives are unverified.
- **Lowest estimate** (amber): the lowest usable imported unit-price estimate.
  Estimates have a `~` prefix and identify Auctionator or the selected TSM source.
  Green and amber compare separate categories; an estimated alternative may
  prove cheaper than the lowest verified one when you scan it.
- **Not scanned**: no completed scan exists for that material in this market.
- **Only N available / None for sale**: a completed scan found too little buyable
  stock. These options receive no fill-cost estimate and cannot win.
- **Stale**: an own scan is older than 30 minutes, or Auctionator reports data
  from an earlier scan day. It remains visible in gray and cannot win.
- **Today / Nd old**: Auctionator reports age in whole days. `Today` cannot
  establish that the price is younger than 30 minutes.
- **Age unknown**: the provider exposes no usable age, including the reviewed
  TSM price API. The amount remains an estimate, never a verified scan.
- **Scan failed**: the most recent attempt failed. An older amount may remain
  visible, but it cannot win until a successful rescan. In Auto mode an imported
  estimate may be displayed instead, with the failed own scan identified.
- **Buy N**: an item auction requires purchasing a whole stack, leaving excess
  units. The displayed amount includes that entire purchase.

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

At an auctioneer, hover a crate and open `/wll`:

- **Search all alternatives** opens Auctionator searches for every possible
  filling material, with required quantities. You still need only one bundle.
- **Shop selected option** opens the chosen material and its bundle quantity.
- Click **Option N/M** to cycle choices. A newly hovered crate initially selects
  the lowest verified option, or the lowest estimate if there is no verified one.

Shopping stops our scanner before starting Auctionator's queue. It never buys
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
| `/wll` | Open or close the scan window |
| `/wll scan bags` | Scan materials for recognized crates in equipped bags |
| `/wll scan hovered` | Scan the last recognized crate you hovered |
| `/wll scan all` | Scan all 96 catalogued materials |
| `/wll source auto` | Fresh own scans, then Auctionator, then TSM estimates |
| `/wll source auctionator` | Use only Auctionator estimates |
| `/wll source tsm` | Use only TSM estimates |
| `/wll source own` | Use only our scan snapshots |
| `/wll tsmkey DBMinBuyout` | TSM minimum buyout estimates (default) |
| `/wll tsmkey DBMarket` | TSM historical market-value estimates |
| `/wll search` | Search every alternative for the last hovered crate in Auctionator |
| `/wll shop` | Shop the selected filling option in Auctionator |
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

This release has been tested in a simulated Lua 5.1 client, **not inside WoW**.
Please start with a small test:

1. Enable Lua errors with `/console scriptErrors 1`, then `/reload`.
2. Have an identified crate in your bags and open the auction house.
3. Type `/wll debug`, then `/wll scan bags`.
4. After completion, hover the crate. Check one listed material manually in the
   auction house, including enough units to fill the crate.
5. Close the auction house and hover again. `/reload` and verify cached prices
   remain visible.
6. If using Auctionator, check `/wll source auctionator`, its update after a scan,
   and both shopping buttons. Verify that the selected material and quantity are
   correct. With TSM data available, check `/wll source tsm` against its tooltip.
   Return to `/wll source auto` afterward.
7. If something fails, send the exact error and **`/wll report`** output. Include
   the crate item ID and **`/wll inspect <ID>`** output if its requirements differ.
   The report contains your realm/faction/profile and scan logs; it is only shown
   locally and is never sent automatically.

The game build and live server behavior still need this check. No purchases,
posts, cancellations, trade actions, or communication are performed by the addon.

## Development

Runtime modules are small Lua files loaded in TOC order. `Pricing.lua` is pure;
`Scanner.lua` has injected API/clock/callback dependencies. UI and SavedVariables
integration are separate. No external runtime libraries are bundled.

Requirements for the developer tests: Python 3.10+ and `lupa==2.8`.

```sh
python3 -m pip install -r requirements-dev.txt
python3 tools/build_catalog.py
python3 tests/run.py
python3 tools/package.py
```

The test suite uses a real Lua **5.1** interpreter through Lupa. It covers price
depth, indivisible auctions, randomized exhaustive cross-checks, stale/unknown
results, pagination, throttling, retry timeouts, interruptions, owned-stock
filtering, profile isolation, full bootstrap, tooltip text, provider priorities,
source settings, API errors, price-age semantics, callbacks, and shopping handoff.
The default suite has 53 tests. Two additional contract tests run the actual
unmodified public API Lua from separately downloaded release ZIPs (55 total):

```sh
python3 tests/run.py --auctionator /path/to/Auctionator-347.zip --tsm /path/to/TradeSkillMaster.zip
```

These exercise the public functions with internal services stubbed. They do not
claim to run either entire addon or the live WoW client. Third-party source is
not redistributed in our archive.

`data/catalog.json` is the checked-in factual data source. It contains 30 crate
IDs, each alternative bundle's material ID and quantity, source URLs, retrieval
date, and hashes of the original XML responses. All 96 material IDs/names were
individually verified against Wowhead's Forever XML on 2026-11-15.

To refresh the existing catalog from Wowhead:

```sh
python3 tools/refresh_catalog.py --fresh
python3 tests/run.py
```

Refreshing runs on the developer's computer, never inside the addon. Unknown
material names stop the importer for review. Newly introduced crate IDs need to
be added deliberately; the importer does not silently guess or claim to discover
all future content. See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for the API
contract and source notes.
