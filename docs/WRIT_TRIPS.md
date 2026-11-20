# Writ trips

Open the Craftsman's Writs list in the Auction House or saved-price browser and
select **Writ trips**. Choose a flight stop from the dropdown, which ranks the
recommended trips by effective cost per reputation point. Tick or untick any
optional writ to update the delivery order, shopping list, shopping total,
estimated time and reputation together. Selections are kept when switching
flight stops within the planner. Reopening it builds fresh recommendations.

In **Settings**, set **Time value (gold/hour)** and select **Apply**. Reopen
**Writ trips** to see the new ranking. The initial value is 6 gold per hour,
equivalent to 10 silver per minute. Set it to 0 to rank by shopping cost per
reputation. The score adds the value of the estimated travel and hand-in time
to the shopping cost, then divides by the total base reputation. The shopping
total is shown separately.

## Coverage and price estimates

The first catalog has 53 writs at 26 named recipients. A recommendation requires a
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

Each checkbox shows the extra cost, time and reputation for that writ relative
to the rest of the current selection. Toggling a writ reprices the combined
basket after subtracting bags once and recalculates the shortest walking order.
When a selected quantity has no quote, the missing item shows **No price** and
the shopping total and effective cost stay unknown. The route, time and
reputation still update.

At the Auction House, **Send to Auctionator** rereads your bags and opens
Auctionator Shopping with the missing quantities for the currently selected
trip. A compatible Auctionator install is required. Items still missing a
saved estimate are included in the search.

## Live verification

Pending in Forever. Compare mapped destinations and the discovered flight
stops with the native map on each faction and continent. Compare predicted
arrival and hand-in time with a completed trip. Verify shopping quantities,
daily lockouts, empty planner states, the stop selector and optional checkboxes
with mouse and native controller, scrolling, Back and focus return in both
browsers. Verify the gold-per-hour
field with mouse, keyboard and controller, including decimal input, applying a
change and reopening the planner.

Live verification is also pending for the Auctionator handoff, combined
quantities after a bag change, and controller focus on the Shopping tab.
