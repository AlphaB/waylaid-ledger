# Reward efficiency in 0.9.0

The auction lists rank complete acquisition cost (one identified writ/crate plus
all delivery goods) divided by its base repeatable reward. Writs use reputation;
crates use Merchant's Favor. The cheapest known filling option still supplies
each crate's delivery cost. Ratios retain fractional copper when sorting; the
display rounds up to the next copper so a positive cost never looks free.

Since 0.9.1 this is the default sort; clickable headers also offer item name,
purchase, delivery and total cost, with ascending/descending directions. Each
table keeps its session selection across Refresh and filtering. Missing numeric
values stay last in either direction. Equal selected values fall back to the
default efficiency order described below.

Known ratios appear first. Unranked entries follow, ordered by known total,
then name and item ID; missing totals follow known totals. Equal ratios use those
same tie breakers. Missing rewards or price components never become zero.
Acquisition totals do not subtract cash rewards, owned goods, travel or AH fees.
Reputation bonuses, random Favor bonuses, the one-time Shipping Label bonus and
Forged Delivery Receipts are outside this base-reward comparison.

## Wowhead research — 2026-11-16

| Writ tier | Base reputation | Identified item IDs |
| --- | ---: | --- |
| Journeyman | 75 | 264011–264055 (45 items) |
| Expert | 125 | 264056–264115 (60 items) |
| Artisan | 200 | 264116–264160 (45 items) |

The tiers of all 150 items were matched individually against
[Wowhead's writ guide](https://www.wowhead.com/forever/guide/professions/craftsmans-writs-overview-recipes-rewards),
updated November 15. Their IDs happen to form these contiguous groups; no IDs
outside them are assigned a reward. Item pages also show their tier, for example
[Small Silk Pack](https://www.wowhead.com/forever/item=264050),
[Truesilver Rod](https://www.wowhead.com/forever/item=264077) and
[Runecloth Bag](https://www.wowhead.com/forever/item=264153).
[Truesilver Rod's quest](https://www.wowhead.com/forever/quest=94277)
independently reports 125 reputation for the player's supply faction. The two
faction entries are alternatives, not a combined reward of 250. Writ Coin Pouches
have variable cash contents, so their reported averages are not deducted.

| Crate tier / variants | Herbs, Ore, Textiles, Curiosities | Fabrics, Ingots, Parts |
| --- | ---: | ---: |
| Apprentice | 5 Favor | 10 Favor |
| Journeyman | 10 Favor | 20 Favor |
| Expert (including Earthly and Flowering herbs) | 15 Favor | 30 Favor |
| Artisan (including Earthly and Flowering herbs) | 30 Favor (user-selected) | 30 Favor (user-selected) |

Earthly and Flowering are herb variants within Expert and Artisan, rather than
independent tiers. For example, Wowhead identifies
[Earthly Expert Herbs](https://www.wowhead.com/forever/item=248690) and
[Flowering Artisan Herbs](https://www.wowhead.com/forever/item=248696).

[Wowhead's supply guide](https://www.wowhead.com/forever/guide/azeroth-commerce-authority-reputation-professions)
documents common/uncommon Apprentice and Journeyman sealed rewards.
[Merchant's Favor comments](https://www.wowhead.com/forever/currency=3402/merchants-favor)
report common/uncommon Expert rewards as 15/30. Item reports confirm the contents
distinction: [Apprentice Ore](https://www.wowhead.com/forever/item=248683) pays 5,
[Apprentice Fabrics](https://www.wowhead.com/forever/item=248702) and
[Apprentice Ingots](https://www.wowhead.com/forever/item=248703) pay 10,
[Journeyman Ingots](https://www.wowhead.com/forever/item=248706) pays 20, and
[Earthly Expert Herbs](https://www.wowhead.com/forever/item=248690) pays 15.
Some of these values rely on player comments from beta; live verification remains
desirable. The reward table uses these reported base rewards.

Wowhead currently shows neither Favor nor cash rewards for the Artisan crate
turn-ins [91902](https://www.wowhead.com/forever/quest=91902) and
[91907](https://www.wowhead.com/forever/quest=91907). The user selected **30 Favor
for every Artisan crate** on 2026-11-16. All eight Artisan crate IDs
(248695–248699, 248711–248713) therefore use 30 and participate in efficiency
ranking, including Earthly/Flowering herbs and Fabrics/Ingots/Parts. This is a
user-selected assumption, not a Wowhead-verified payout.

## Data boundaries and validation

`Rewards.lua` contains only numeric reward metadata keyed by item ID. It does not
populate the discovered crate/writ catalog, change delivery requirements or
depend on localized names. Discovery remains responsible for which items appear.
Unknown future items remain unranked until verified reward metadata is added.

Lua 5.1 regressions cover cross-tier ordering where a more expensive basket is
better value, processed/raw crates, all eight Artisan rewards at 30 Favor,
unknown future rewards, missing prices,
fractional-copper order, ties, displayed rewards and localized control coverage.
Live-client reward and layout verification remains outstanding.

## Writ coin pouches, daily deliveries and prices

The writ tooltip shows a tier estimate for the variable Coin Pouch reward.
[Wowhead's loot observations](https://www.wowhead.com/forever/guide/professions/craftsmans-writs-overview-recipes-rewards)
and the [writ reward table](https://conquestcapped.com/guides/wow-forever/wow-forever-craftsmans-writs/#craftsman-s-writ-rewards-and-the-daily-limit)
report tier-level figures. Journeyman estimates are 22–45 silver, Expert
50–90 silver and Artisan about 75 silver. Per-order payouts are unverified.

Each named writ quest can be delivered once per character per daily reset.
The browser and tooltip read the current character's quest completion flag.

A deal is a fresh writ purchase quote at least 10% below the median of earlier
scan days in the past 14 days. Comparison requires at least three earlier days
with prices for that item, market and scan type. The addon keeps the latest
positive observation per UTC day. Full-scan unit estimates and targeted
buyable-lot prices have independent histories.
