# Waylaid Ledger

Compare the cost of buying and filling **Waylaid Crates** and **Craftsman's
Writs** in World of Warcraft: Forever. Find the best value per reputation or
Merchant's Favor, compare crate options in tooltips, and shop for the goods you need.

**[Download the latest release](https://github.com/AlphaB/waylaid-ledger/releases/latest)**

Version **1.4.0** · For **WoW Forever** · No other addons required.

## Install

1. Open the **[latest release](https://github.com/AlphaB/waylaid-ledger/releases/latest)**.
   Under **Assets**, download **`WaylaidLedger-1.4.0.zip`** (or the newer version
   shown there). Choose the WaylaidLedger ZIP, **not “Source code”**.
2. **Close WoW** and extract the ZIP. Inside is a folder named **`WaylaidLedger`**.
3. Find your **Forever game folder**. In Battle.net, select Forever and use
   **Show in Explorer** (Windows) or **Show in Finder** (Mac). Open the folder
   for the client you play, then **Interface → AddOns**.
4. Copy **`WaylaidLedger`** into **`AddOns`**. A typical finished path is:

   ```text
   World of Warcraft/_forever_/Interface/AddOns/WaylaidLedger/WaylaidLedger.toc
   ```

   Some older installations use `_classic_beta_` instead of `_forever_`.
   The important part: `WaylaidLedger.toc` must be directly inside
   `AddOns/WaylaidLedger`, without an extra folder in between.
5. Start Forever. At character selection, open **AddOns**, enable
   **Waylaid Ledger**, and log in.

**Updating?** Close the game and replace the old `Interface/AddOns/WaylaidLedger`
folder with the new one. Your saved prices and settings are stored separately;
leave the game's `WTF` folder alone.

## Your first scan

1. Visit an **auctioneer** and open the **Waylaid** tab.
2. Choose **Craftsman's Writs** or **Waylaid Crates**. The item lists are included;
   a scan supplies prices.
3. **Without Auctionator or TSM:** click **Refresh** to scan the auction house.
   **With either addon:** scan/update prices in that addon, then click **Refresh**
   in Waylaid to load them. You can always type **`/wll scan all`** at the
   auction house to request Waylaid's own full scan.
4. Compare the results and click a row to shop for **one crate or writ plus its
   delivery goods**. Auctionator opens its Shopping tab when available;
   otherwise, Waylaid opens a basket leading to the game's buying screens.
   **You confirm every purchase yourself.**

Full auction-house scans share a **15-minute cooldown**. If a scan is unavailable,
use saved prices and try again later. Prices remain available after leaving the
auction house or restarting the game.

Writ tooltips show estimated coin-pouch rewards. The writ list hides orders
your character delivered today. Select **Show delivered** to include them.
Prices at least 10% below usual are flagged after you collect scans on three earlier days.

Select **Writ trips** in either writ browser to compare one-stop trips on your
current continent. Plans group deliveries by recipient and show the walking
order, estimated travel and added time per writ, reputation, and a priced
shopping list that accounts for items in your bags. Trips use discovered flight
stops and the [mapped writ destinations](docs/WRIT_TRIPS.md). Set **Time value
(gold/hour)** in **Settings** to change how much travel time counts toward the
trip ranking. Choose a flight stop and tick optional writs to update the
delivery order, shopping list, total time, reputation and effective cost.

## Everyday use

- **Browse anywhere:** left-click the minimap button or type **`/wll`**. Away from
  an auctioneer, you can search, sort and view saved prices; return to the auction
  house to scan or buy.
- **Compare value:** lists start with the lowest cost per reputation (writs) or
  Merchant's Favor (crates), including both purchase and delivery. Click a column
  heading to change the sort order; click it again to reverse it.
- **Check a crate:** hover it to see filling costs. **Green** marks the cheapest
  known option. Hold **Shift** for price sources and age.
- **Change settings:** right-click the minimap button or type **`/wll settings`**.
  Choose price sources, inventory tracking, automatic scans and tooltip details.
  **Auto** is the default; Auctionator and TSM are optional.
- **Use a controller:** Forever's native controller UI supports the lists,
  settings and shopping basket. Up/down moves through rows; the right stick
  scrolls while the list has focus. Mouse and keyboard also work.

The interface follows your game language, with English as a fallback.

### Understanding prices

List totals include buying the crate or writ **and** its delivery goods.
Item tooltips show **delivery costs only**. Items you already own are not
subtracted. A crate basket uses one filling option; a writ basket includes all
its requirements.

Prices are saved estimates, so the final auction price or available quantity may
change. Green means **lowest known**, including older saved prices; an unpriced
option could be cheaper. **No price / Not scanned** means price data is missing.
**Only N / None listed** means a detailed scan found too little stock.
Unidentified crates and sealed writs must be identified before their requirements
can be priced.

## Need help?

- **Addon missing from the AddOns menu?** Check that you used the Forever client
  folder, extracted the ZIP, and placed the `.toc` file at the path shown above.
  Restart the game after correcting it.
- **Prices missing or old?** Clear the list's search box, check the selected
  price source in settings, and scan at an auctioneer. With Auctionator or TSM
  selected, Refresh reads that addon's saved data; it does not start its scan.
- **A scan is running?** Waylaid's **Stop** button stops its own scan. Wait for
  another addon's scan to finish before refreshing.
- **Something else wrong?** [Report an issue](https://github.com/AlphaB/waylaid-ledger/issues)
  with the addon version, what happened and any exact error. **`/wll report`**
  opens a diagnostic report you can copy; nothing is sent automatically.

Type **`/wll help`** for all commands. Advanced users can run **`/wll scan deep`**
at an auctioneer for detailed stock and whole-stack pricing checks.

## Technical reference

For contributors: Python 3.10+ and the packages in `requirements-dev.txt` are
needed to run `python3 tests/run.py`. Build an install ZIP with
`python3 tools/package.py`. Release and controller checks are documented below.

- [Development and verification](docs/DEVELOPMENT.md) · [Controller checklist](docs/CONTROLLER.md)
- [Catalog and discovery](docs/INGAME_DATA.md) · [Price providers and shopping](docs/INTEGRATIONS.md)
- [Reward calculations](docs/REWARDS.md) · [Changelog](docs/CHANGELOG.md) · [Third-party licenses](docs/THIRD_PARTY.md)

## Thanks

Thanks to **[Aelris](https://www.twitch.tv/aelris_)** for the idea behind Waylaid Ledger!
