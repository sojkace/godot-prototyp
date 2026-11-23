extends Node
## Global event bus for things that happen during play. Systems emit, anyone may listen
## (HUD, sounds, statistics, tutorials ...) without the emitter knowing about them.
## State changes (coins, items, cards) are signals on GameState instead.

## The player ended the planning phase; trains start rolling.
signal round_started(round_number: int)
## All trains arrived and buildings got on_round_end(); the next round is ready.
signal round_ended(round_number: int)
## Trains moved one step (after mines loaded them).
signal train_step(trains: Array[Train])
## A train reached its factory.
signal train_arrived(train: Train, factory: Factory)
## A factory's order was finished / ran out.
signal order_done(factory: Factory)
signal order_expired(factory: Factory)
## A new factory appeared on the island.
signal factory_appeared(factory: Factory)
## The player built something (not fired for the start setup).
signal building_placed(building: Building)
## The player tapped a marketplace; the HUD opens its trade window.
signal market_requested(market: Marketplace)
## Items were added to the inventory by a building (e.g. a workshop) or an order.
signal items_delivered(items: Array[String], source: Building)
## Short message for the player (e.g. why an action did not work).
signal message(text: String)
