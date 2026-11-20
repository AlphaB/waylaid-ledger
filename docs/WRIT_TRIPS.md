# Writ trips

Open the Craftsman's Writs list in the Auction House or saved-price browser and
select **Writ trips**. The report ranks one-stop trips by effective cost per
reputation point. Each shows its delivery order, shopping list, estimated
upfront cost, and what extra writs would add.

In **Settings**, set **Time value (gold/hour)** and select **Apply**. Reopen
**Writ trips** to see the new ranking. The initial value is 6 gold per hour,
equivalent to 10 silver per minute. Set it to 0 to rank by shopping cost per
reputation. The score adds the value of the estimated travel and hand-in time
to the shopping cost, then divides by the total base reputation. The shopping
total is shown separately.

## Coverage and price estimates

The first catalog has 53 writs at 26 named recipients. The report requires a
mapped recipient and a price for every item you are missing to recommend a
purchase. Optional writs with incomplete price data show **No price**. Writs
already delivered by the current character are skipped. Quantities are combined across
each trip, and only the current character's bags offset purchases. Saved Auction
House prices can change. Flight fares and coin-pouch returns are outside the
shopping total.

The seed locations come from
[WritRoute 1.2.0](https://www.curseforge.com/wow/addons/craftsmans-writroute-for-forever/files/9712722)
and include approximate map positions. WritRoute's license is bundled.
[Forever quest records](https://db.icy-veins.com/wow-forever/quests/94286)
place Spek at Riverglades 76.9, 54.1. The
[Goblin Rocket Fuel quest record](https://www.wowhead.com/forever/quest=94265/craftsmans-writ-goblin-rocket-fuel)
and player report place its turn-in at Alchemist Pestlezugg in Gadgetzan.

## Route model

The player, recipients and the current continent's discovered, faction-compatible
flight stops are projected into the game's world coordinates. Each recipient is
assigned to the closest such stop within three estimated minutes on foot. A plan
starts at the player's position for the nearest stop's local trip. Other trips
include travel to that nearest stop and one taxi ride. The game may take an
indirect taxi route or have no connection between a pair of discovered stops.

For each flight stop the planner considers up to eight nearby recipients,
nearest first. It starts with the best-scoring individual writ. It then adds
the writ with the best resulting score as long as the recommendation improves,
breaking score ties by higher reputation and shorter time. For each candidate
basket, it minimizes the walking time across every order of its recipients and
ends at the last hand-in.
Estimates use straight-line distance, 7 yards per second on foot, 25 on the
taxi, 10 seconds for takeoff and 10 seconds per hand-in. The walking model
ignores terrain, mount speed and obstacles. For a single writ at a recipient,
its added time includes the change in the shortest walk if that recipient were
omitted. Extra writs at a shared recipient only add the hand-in time. A
one-writ trip shows the entire trip time as that writ's addition.

Each optional writ is scored separately against the displayed recommendation.
Its extra purchase cost comes from repricing the entire basket, including
shared goods and bags. Its extra time compares shortest walking orders before
and after adding it. Adding several optional writs can share a detour or change
the quantities you need, so their individual estimates may overlap.

## Live verification

Pending in Forever. Compare mapped destinations and the discovered flight
stops with the native map on each faction and continent. Compare predicted
arrival and hand-in time with a completed trip. Verify shopping quantities,
daily lockouts, empty reports, mouse and native controller activation,
scrolling, Back and focus return in both browsers. Verify the gold-per-hour
field with mouse, keyboard and controller, including decimal input, applying a
change and reopening the report.
