extends Node
## Global event bus for things that happen during play. Systems emit, anyone may listen
## (HUD, sounds, statistics, tutorials ...) without the emitter knowing about them.
## State changes (coins, items, decks) are signals on GameState instead.

## A round's trains start rolling.
signal round_started(round_number: int, train_codes: String)
## All trains of the round arrived; buildings already got on_round_end().
signal round_ended(round_number: int)
## Trains moved one step (after mines loaded them).
signal train_step(trains: Array[Train])
## A train reached the power station.
signal train_arrived(train: Train, was_full: bool)
## The player built something (not fired for the start setup).
signal building_placed(building: Building)
## The player tapped a marketplace; the HUD opens its trade window.
signal market_requested(market: Marketplace)
## Items were added to the inventory by a building (e.g. a workshop).
signal items_delivered(items: Array[String], source: Building)
