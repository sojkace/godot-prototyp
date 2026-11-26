class_name GameRules
extends Resource
## One complete rule variant: every tunable number plus cards, start deck, research and
## milestones. Variants live in `res://data/rules/*.tres` and only store the values that
## differ from the defaults below. Pick one in the main menu or with `-- --rules=<file name>`.
## Game idea: see docs/konzept.md (turn-based deckbuilding incremental).

@export var title := "Standard"
@export_multiline var description := ""

@export_group("Start")
@export var start_coins := 2

@export_group("Turn")
## Actions per round: playing a card, tapping a mine and putting a train on a rail each cost one.
@export var actions_per_round := 3
## The hand is filled up to this many cards every round (unplayed cards stay).
@export var hand_size := 3
## Coins to throw away a hand card and draw a new one.
@export var discard_cost := 1

@export_group("Deck")
## The deck always has exactly this many cards (swap cards in and out, never add).
@export var deck_size := 20
## Card id -> count; must add up to deck_size.
@export var start_deck: Dictionary[String, int] = {
	"rail_f": 3, "rail_l": 3, "rail_ff": 3, "rail_fl": 2, "rail_lf": 1, "rail_ll": 1,
	"mine_gold": 2, "mine_silver": 2, "flag_normal": 2, "pond": 1,
}
## Cards that can show up in the card choice without research.
@export var start_collection: Array[String] = [
	"rail_f", "rail_l", "rail_ff", "rail_fl", "rail_lf", "rail_ll", "rail_lr",
	"mine_gold", "mine_silver", "flag_normal", "pond",
]
## After every finished order the player picks one of this many collection cards and
## chooses a deck card it replaces (the deck size stays the same) ...
@export var reward_choices := 3
## ... or takes this many coins instead.
@export var reward_coins := 2
## Collection cards that never show up in the card choice (they only hinder).
@export var reward_excluded: Array[String] = ["pond"]
## Card put into the deck (replacing a random normal card) when an order expires.
@export var curse_card := "curse_flood"

@export_group("Cards")
## Non-rail cards must touch an existing building (not just any free ground).
@export var require_adjacent := true
## Every card. Playing one costs an action; it places a piece of one or more cells:
##   "cells": [[x, y, "building_id"], ...]  offsets from the tapped cell, turned as a whole
##   "rail": "FLR"  rigid track block: F = straight, L / R = curve; starts anywhere
##   "upgrade": "auto", "targets": [building ids]  automates a building (no more tapping)
##   "upgrade": "halt"  on a rail: a train starts there every round without an action
##   "tool": "bomb" | "bridge", "coins": n  bought in the shop
##   "curse": true  bad card from expired orders (costs coins to swap out)
##   "icon" (optional): icon id, default = first building / rail type
@export var cards: Dictionary = {
	"rail_f": {"name": "Gerade", "rail": "F"},
	"rail_l": {"name": "Kurve", "rail": "L"},
	"rail_ff": {"name": "Lange Gerade", "rail": "FF"},
	"rail_fff": {"name": "Sehr lange Gerade", "rail": "FFF"},
	"rail_lr": {"name": "Doppelkurve", "rail": "LR"},
	"rail_ll": {"name": "Kehre", "rail": "LL"},
	"rail_fl": {"name": "Gerade + Kurve", "rail": "FL"},
	"rail_lf": {"name": "Kurve + Gerade", "rail": "LF"},
	"mine_gold": {"name": "Goldmine", "cells": [[0, 0, "mine_gold"]]},
	"mine_silver": {"name": "Silbermine", "cells": [[0, 0, "mine_silver"]]},
	"mine_gold_pond": {"name": "Goldmine am Teich", "cells": [[0, 0, "mine_gold"], [1, 0, "water"]]},
	"mine_silver_twin": {"name": "Silber-Doppelmine",
		"cells": [[0, 0, "mine_silver"], [1, 0, "mine_silver"]]},
	"flag_normal": {"name": "Flagge", "cells": [[0, 0, "flag_normal"]]},
	"flag_pointy": {"name": "Langflagge", "cells": [[0, 0, "flag_pointy"]]},
	"pond": {"name": "Teich", "icon": "water", "cells": [[0, 0, "water"], [1, 0, "water"]]},
	"halt": {"name": "Haltepunkt", "icon": "halt", "upgrade": "halt",
		"targets": ["rail_straight", "rail_curve"]},
	"auto_mine": {"name": "Förderband", "icon": "auto", "upgrade": "auto",
		"targets": ["mine_gold", "mine_silver"]},
	"curse_flood": {"name": "Überflutung", "icon": "water", "curse": true,
		"cells": [[0, 0, "water"], [1, 0, "water"], [0, 1, "water"]]},
	# Shop tools (bought with coins, not in the deck).
	"bomb": {"name": "Bombe", "tool": "bomb", "coins": 2},
	"bridge": {"name": "Brücke", "tool": "bridge", "coins": 2},
}
## Tool cards offered in the shop (always available, paid with coins).
@export var shop: Array[String] = ["bomb", "bridge"]

@export_group("Research")
## Research points come from milestones. stat: see GameState.stats.
@export var milestones: Array[Dictionary] = [
	{"name": "Erster Auftrag", "stat": "orders_done", "target": 1, "points": 1},
	{"name": "5 Aufträge", "stat": "orders_done", "target": 5, "points": 1},
	{"name": "12 Aufträge", "stat": "orders_done", "target": 12, "points": 2},
	{"name": "25 Aufträge", "stat": "orders_done", "target": 25, "points": 2},
	{"name": "45 Aufträge", "stat": "orders_done", "target": 45, "points": 3},
	{"name": "70 Aufträge", "stat": "orders_done", "target": 70, "points": 3},
	{"name": "15 Züge geschickt", "stat": "trains_sent", "target": 15, "points": 1},
	{"name": "50 Züge geschickt", "stat": "trains_sent", "target": 50, "points": 2},
	{"name": "120 Züge geschickt", "stat": "trains_sent", "target": 120, "points": 2},
	{"name": "Insel mit 125 Feldern", "stat": "land", "target": 125, "points": 1},
	{"name": "Insel mit 150 Feldern", "stat": "land", "target": 150, "points": 2},
	{"name": "Insel mit 180 Feldern", "stat": "land", "target": 180, "points": 2},
	{"name": "2 Fabriken", "stat": "factories", "target": 2, "points": 1},
	{"name": "3 Fabriken", "stat": "factories", "target": 3, "points": 1},
	{"name": "5 Fabriken", "stat": "factories", "target": 5, "points": 2},
]
## Research: costs points, unlocks cards for the collection (they show up first in the next
## card choice) and/or gives extra actions.
@export var research: Array[Dictionary] = [
	{"id": "conveyor", "name": "Förderband", "cost": 2, "unlocks": ["auto_mine"],
		"description": "Minen füllen sich jede Runde selbst."},
	{"id": "halt", "name": "Haltepunkt", "cost": 2, "unlocks": ["halt"],
		"description": "Haltepunkt auf eine Schiene: dort fährt jede Runde selbst ein Zug los (ohne Aktion)."},
	{"id": "big_mines", "name": "Bergbau", "cost": 1, "unlocks": ["mine_silver_twin", "mine_gold_pond"],
		"description": "Neue Minen-Karten."},
	{"id": "land", "name": "Landgewinnung", "cost": 1, "unlocks": ["flag_pointy", "rail_fff"],
		"description": "Langflagge und sehr lange Gerade."},
	{"id": "organisation", "name": "Organisation", "cost": 4, "actions": 1,
		"description": "+1 Aktion pro Runde."},
]

@export_group("Orders")
## Factory types in the order they appear (gold / silver = the mine type that serves them).
@export var factory_sequence: Array[String] = ["gold", "silver", "gold", "silver", "gold", "silver"]
## A new factory appears every time the island gained this many land cells ...
@export var land_per_factory := 12
## ... and at the latest every this many rounds, even if the island does not grow
## (whichever brings more factories counts). 0 = only through land.
@export var rounds_per_factory := 8
## Factories appear between these distances (steps) from the middle of the start setup.
@export var factory_min_distance := 4
@export var factory_max_distance := 7
## First order size of a factory; every later factory starts `order_growth` higher.
@export var order_base := 4
@export var order_growth := 0
## Every finished order makes the next order of the same factory this much bigger.
@export var order_growth_per_order := 1
## Rounds until an order expires (then a curse card goes into the deck).
@export var order_deadline := 5
## Rounds for the very first order of a new factory (time to build its line).
@export var first_order_deadline := 8
## A new factory is announced this many rounds before it opens (its cell is reserved).
@export var factory_warning_rounds := 2
## Rewards: coins per delivered load and per finished order.
@export var coins_per_load := 0
@export var coins_per_order := 3

@export_group("Buildings")
## Ore a mine gets per tap (or per round when automated), and how much it can store.
@export var mine_tap_amount := 3
@export var mine_capacity := 6
## Ore a train takes from a mine for every rail cell of its route inside the mine's area:
## long lines through many mine areas fill trains, shortcuts next to the factory do not.
@export var loads_per_mine_step := 1

@export_group("Trains")
## Seconds per rail step.
@export var step_duration := 0.45

@export_group("Island")
@export var island_min_radius := 4.5
@export var island_max_radius := 7.0
@export var island_min_angle_step := 25.0
@export var island_max_angle_step := 55.0
