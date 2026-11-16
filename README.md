# Waylaid Ledger

A standalone World of Warcraft: Forever addon that scans the auction house for
Waylaid Crate materials and adds the cost of every filling option to crate
item tooltips. The lowest known filling cost is highlighted in green for all price sources,
including cached prices. Auctionator and TSM are optional price providers. Own scans support both crate and writ costs.

Version **0.7.1** · Forever **1.60.1 / interface 16001** · No addon dependencies.

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
4. The complete fallback crate/writ lists are available immediately. Refresh at the AH
   for current prices; saved prices or optional Auctionator/TSM estimates work away from the AH.
5. Visit an auctioneer and select **Waylaid**, then its internal **Craftsman's Writs** or
   **Waylaid Crates** tab. Each list shows
   its catalog in order of **purchase + delivery** cost. Click a row to open
   Auctionator Shopping with one writ/crate and its complete delivery bundle.
   The minimap button opens your last used list; right-click it for the official
   **Settings → AddOns → Waylaid Ledger** page.
6. Hover a recognized Waylaid Crate in your bags, chat, or the auction house to
   compare its options. `/wll settings` changes price preferences.
   `/wll controls` opens the original scan and diagnostic controls.

**Full AH scan** uses one bulk request. Saved prices remain available after
leaving the auction house and across reloads/logins. Auctionator and
TradeSkillMaster are optional.

## Catalog and in-game discovery

The addon includes the previous **30 crate / 150 writ** catalog as a fallback,
so the complete lists and delivery quantities appear immediately after upgrading.
Existing market prices and settings are retained. Complete in-game descriptions
update those quantities and can add new items. Generic writ flavor text or
loading text does not erase known bundles. See [in-game data](docs/INGAME_DATA.md).

Use **Refresh** or `/wll scan all` at the auction house to update prices with one
full AH snapshot. The addon has no fixed full-scan cooldown; Refresh can request
another snapshot after the current scan finishes or is stopped. Client readiness
and server restrictions still apply. `/wll scan deep` requests detailed prices
for known purchases and delivery goods with the normal per-item request budget.
Bulk prices are unit-price estimates; detailed scans retain stock and stack checks.

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
read their changing inventories live. Only known crate/writ and delivery-item counts are stored.
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

This is Waylaid Ledger's own crate-material scan, not an Auctionator full scan.
Writ goods and writ/crate purchase prices continue to use Auctionator/TSM caches.
It does not run in forced Auctionator or TSM mode, and performs no queries away
from the auction house.

## Ranked auction lists

Inside the Waylaid auction tab, **Craftsman's Writs** lists known identified writs,
and **Waylaid Crates** lists
known identified crates. Columns show the purchase price of one writ/crate, the
full delivery cost, and their sum. Rows with known totals sort from cheapest to
most expensive; unknown totals follow alphabetically. Missing data is never counted as zero. Prices have no estimate prefixes or
age markers; detailed provenance remains available on hover.

Each crate row chooses its cheapest usable filling option across scans and
provider estimates. Older cached prices remain eligible for this comparison. This is the **lowest known** cost; unpriced alternatives might be cheaper.
A completed scan showing insufficient stock excludes that alternative. A crate
with no priced filling option cannot launch a basket until prices are available.
Writ objectives are cumulative and always use their full delivery quantities.

Purchase quotes and delivery costs now use the same selected source policy,
including quantity-aware own scans. Writs have their own Auto/Own/Auctionator/TSM/
Off preference. Auto uses fresh own snapshots first, then optional providers.
Custom market profiles can use complete own-scan totals; external estimates stay
disabled there. Buying a whole item stack can cost more than one unit, and own
quotes include that actual outlay.

The list uses Blizzard's native auction-style ScrollBox and scrollbar, framed
column headers, compact striped rows, and recycled visible item buttons.
Search filters item names and required goods. **Refresh** starts a fresh own scan
for the **current filtered list**: each writ/crate itself and every corresponding
delivery item. Crates scan all alternatives so the cheapest can be chosen. IDs
are deduplicated; shared goods are queried once. Even fresh items are rescanned
on explicit Refresh. The button becomes **Stop**, with progress shown beside it.
No matching rows means no queries. Old snapshots remain until replaced by a
completed result; failures do not turn into invented zero prices.

By default, if Auctionator's supported API is available, a completed Refresh then
opens **Auctionator Shopping** and searches the **same frozen item scope** using
exact localized names. This updates prices through Auctionator's normal shopping
searches, not a full-house scan. In official settings, **Refresh: Own + Auctionator**
can be switched to **Refresh: Own scan**. Queries are sequential, never parallel.
Stop, AH closure, market changes or competing queries cancel pending handoffs.
Use Auto or Own to display the own scan; forced providers retain their own data.

TSM's released public API exposes prices/groups but no scan-start function. The
**TSM group export** settings button or `/wll tsmexport [writs|crates|all]` copies
an item-list import for the current filtered scope. Import it in TSM and manually
run that group's Shopping scan. TSM controls import/group membership choices and
its own pricing databases; a group scan does not guarantee a DBMarket update.
We do not call internal TSM modules or alter TSM SavedVariables.

Clicking a row opens Auctionator's **Shopping** tab with exact-name searches for
**one writ/crate plus the required delivery goods**. A crate includes exactly
one alternative, selected again using current prices at click time. This uses
Auctionator's public advanced shopping API; update Auctionator if it is missing.
TSM can supply prices, but Auctionator is required for this shopping handoff.
The existing legacy shopping commands remain available on older compatible APIs.

## Craftsman's Writ estimates

Hover a learned **Forever Craftsman's Writ** to see the estimated
price of its required finished goods. Delivery quantities are learned from the
client's descriptions; unresolved requirements never receive a fabricated total. These are delivery costs, excluding the writ's own purchase
price, crafting reagents, quest rewards, and owned inventory deductions.

The writ catalog has **150 distinct delivery items**. Complete writ scans add
150 writ tokens for **300 IDs**. Crates add 30 crate tokens to 96 goods for
**126 IDs**. Two delivery items overlap, so the combined queue is **424**, not
426. The shared 100-request rolling limit still applies; full scans can take
several minutes. Filtering is the fastest way to refresh only relevant entries.

The separate **Writ prices** settings button cycles **Auto / Own / Auctionator / TSM /
Off**. Auto prefers usable Auctionator data, then TSM, then known-old Auctionator
data in gray. Writ settings are independent of the crate source. Custom market profiles disable
external writ estimates just as they do for crates. Hold Shift for details.
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
| `/wll` | At AH: last used list tab; elsewhere: scan window |
| `/wll controls` | Open the standalone scan and diagnostic controls |
| `/wll scan bags` | Scan purchases and goods for recognized crates/writs in equipped bags |
| `/wll scan hovered` | Scan the last recognized crate you hovered |
| `/wll scan tracked` | Scan purchases and goods for remembered bag/bank/alt crates and writs |
| `/wll settings` | Configure inventory, refresh, minimap, details, and writs |
| `/wll inventory` | Show last-seen inventory snapshot timestamps |
| `/wll minimap on` | Show button (`off` hides it) |
| `/wll tracking on` | Capture bag inventory (`off` disables it) |
| `/wll banks on` | Include visited banks (`off` excludes them) |
| `/wll alts on` | Include remembered alts (`off` excludes them) |
| `/wll scanopen on` | Auto-scan missing/stale crate prices on AH open (`off` disables it) |
| `/wll autoscan on` | Refresh tracked prices in the AH panel (`off` disables it) |
| `/wll details on` | Always show tooltip details (`off` uses Shift) |
| `/wll writsource auto` | Writ prices: auto, own, auctionator, tsm, or off |
| `/wll scan all` | Scan all 424 unique catalogued items |
| `/wll scan writs` | Scan 300 writ purchase/delivery IDs |
| `/wll scan crates` | Scan 126 crate purchase/delivery IDs |
| `/wll refresh writs` | Scan the filtered writ list, optionally followed by Auctionator |
| `/wll auctionscan writs` | Start only the scoped Auctionator Shopping search |
| `/wll tsmexport writs` | Copy a scoped TSM group import; scan it manually in TSM |
| `/wll auctionatorfollowup off` | Disable the Auctionator follow-up (`on` enables it) |
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

The earlier versions were tested in the user's live client. The unified tab, native lists and official settings page are tested in a
simulated Lua 5.1 client and need a live check.
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
8. If something fails, send the exact error and **`/wll report`** output. Include
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

Requirements: Python 3.10+, Lua 5.1/LuaRocks, Luacheck 1.2.0, and
[StyLua 2.6.0](https://github.com/JohnnyMorganz/StyLua/releases/tag/v2.6.0).
The Python dependencies include Lupa (Lua 5.1 tests) and Ruff (Python lint/format).

```sh
python3 -m pip install -r requirements-dev.txt
luarocks --lua-version=5.1 install luacheck 1.2.0-1
luacheck WaylaidLedger tests
stylua --check WaylaidLedger tests
python3 -m ruff check .
python3 -m ruff format --check .
python3 tests/run.py
python3 tools/package.py
```

To apply formatting locally:

```sh
stylua --verify WaylaidLedger tests
python3 -m ruff check --fix .
python3 -m ruff format .
```

Luacheck checks Lua 5.1 globals, unused variables, and suspicious code; `.luacheckrc`
lists the WoW APIs and test mocks explicitly. StyLua uses four-space indentation
and a 120-column target. Vendored `WaylaidLedger/Libs` files are excluded from Lua
linting and formatting.

The test suite uses a real Lua **5.1** interpreter through Lupa. It covers price
depth, indivisible auctions, randomized exhaustive cross-checks, stale/unknown
results, pagination, throttling, retry timeouts, interruptions, owned-stock
filtering, profile isolation, full bootstrap, tooltip text, provider priorities,
source settings, API errors, price-age semantics, callbacks, and shopping handoff.
The default suite has 146 tests. Three additional contract tests run the actual
unmodified public API Lua from separately downloaded release ZIPs (149 total):

```sh
python3 tests/run.py --auctionator /path/to/Auctionator-347.zip --tsm /path/to/TradeSkillMaster.zip
```

These exercise the public functions with internal services stubbed. They do not
claim to run either entire addon or the live WoW client. The full upstream Auctionator/TSM packages are not redistributed; only the
separately licensed shared tab libraries are bundled.

Complete runtime descriptions update the bundled fallback requirements.
CI requires Lua/Python lint and formatting checks before running the Lua suite
and uploading the clean install ZIP as the
**WaylaidLedger-install** artifact. `python3 tools/package.py` builds the same
single-folder archive locally. See [docs/INGAME_DATA.md](docs/INGAME_DATA.md).
