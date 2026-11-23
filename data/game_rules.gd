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
@export var start_items: Dictionary[String, int] = {"wood": 6, "stone": 3, "metal": 2, "glass": 2}

@export_group("Turn")
## Actions per round for manual work (tap a mine / workshop, put a train on a rail).
@export var actions_per_round := 3
## Cards drawn into the hand every round.
@export var hand_size := 3
## Cards that may be kept for the next round (reserve slots).
@export var reserve_slots := 1
## Coins to throw away a hand card and draw a new one.
@export var discard_cost := 1

@export_group("Deck")
## The deck always has exactly this many cards (swap cards in and out, never add).
@export var deck_size := 20
## Card id -> count; must add up to deck_size.
@export var start_deck: Dictionary[String, int] = {
	"rail_f": 3, "rail_l": 3, "rail_ff": 3, "rail_fl": 2, "rail_lf": 1, "rail_ll": 1,
	"mine_gold": 2, "mine_silver": 1, "itemcrafter": 1, "flag_normal": 2, "pond": 1,
}
## Cards that can be swapped into the deck without research.
@export var start_collection: Array[String] = [
	"rail_f", "rail_l", "rail_ff", "rail_fl", "rail_lf", "rail_ll", "rail_lr",
	"mine_gold", "mine_silver", "itemcrafter", "flag_normal", "pond",
]
## Coins to swap one deck card for another card of the collection.
@export var swap_cost := 2
## Coins to swap out a curse card (it replaced a normal card when an order expired).
@export var curse_swap_cost := 4
## Card put into the deck (replacing a random normal card) when an order expires.
@export var curse_card := "curse_flood"

@export_group("Cards")
## Non-rail cards must touch an existing building (not just any free ground).
@export var require_adjacent := true
## Every card. A card places a piece of one or more cells and costs items ("cost"):
##   "cells": [[x, y, "building_id"], ...]  offsets from the tapped cell, turned as a whole
##   "rail": "FLR"  rigid track block: F = straight, L / R = curve; starts anywhere
##   "upgrade": "auto", "targets": [building ids]  automates a building (no more tapping)
##   "tool": "bomb" | "bridge", "coins": n  bought in the shop
##   "curse": true  bad card from expired orders (free to play, costs coins to swap out)
##   "icon" (optional): icon id, default = first building / rail type
@export var cards: Dictionary = {
	"rail_f": {"name": "Gerade", "rail": "F", "cost": {"wood": 1}},
	"rail_l": {"name": "Kurve", "rail": "L", "cost": {"wood": 1}},
	"rail_ff": {"name": "Lange Gerade", "rail": "FF", "cost": {"wood": 1}},
	"rail_fff": {"name": "Sehr lange Gerade", "rail": "FFF", "cost": {"wood": 1, "metal": 1}},
	"rail_lr": {"name": "Doppelkurve", "rail": "LR", "cost": {"wood": 1}},
	"rail_ll": {"name": "Kehre", "rail": "LL", "cost": {"wood": 1}},
	"rail_fl": {"name": "Gerade + Kurve", "rail": "FL", "cost": {"wood": 1}},
	"rail_lf": {"name": "Kurve + Gerade", "rail": "LF", "cost": {"wood": 1}},
	"mine_gold": {"name": "Goldmine", "cells": [[0, 0, "mine_gold"]], "cost": {"stone": 1}},
	"mine_silver": {"name": "Silbermine", "cells": [[0, 0, "mine_silver"]], "cost": {"stone": 1}},
	"mine_gold_pond": {"name": "Goldmine am Teich", "cells": [[0, 0, "mine_gold"], [1, 0, "water"]],
		"cost": {"stone": 1}},
	"mine_silver_twin": {"name": "Silber-Doppelmine",
		"cells": [[0, 0, "mine_silver"], [1, 0, "mine_silver"]], "cost": {"stone": 1, "metal": 1}},
	"itemcrafter": {"name": "Werkstatt", "cells": [[0, 0, "itemcrafter"]], "cost": {"stone": 1, "glass": 1}},
	"marketplace": {"name": "Marktplatz", "cells": [[0, 0, "marketplace"]], "cost": {"stone": 1, "glass": 1}},
	"flag_normal": {"name": "Flagge", "cells": [[0, 0, "flag_normal"]], "cost": {"wood": 1, "stone": 1}},
	"flag_pointy": {"name": "Langflagge", "cells": [[0, 0, "flag_pointy"]], "cost": {"wood": 1, "glass": 1}},
	"pond": {"name": "Teich", "icon": "water", "cells": [[0, 0, "water"], [1, 0, "water"]]},
	"station": {"name": "Bahnhof", "cells": [[0, 0, "station"]], "cost": {"stone": 2, "metal": 1}},
	"halt": {"name": "Haltepunkt", "cells": [[0, 0, "halt"]], "cost": {"metal": 1, "glass": 1}},
	"auto_mine": {"name": "Förderband", "icon": "auto", "upgrade": "auto",
		"targets": ["mine_gold", "mine_silver"], "cost": {"metal": 1}},
	"auto_crafter": {"name": "Meister", "icon": "auto", "upgrade": "auto",
		"targets": ["itemcrafter"], "cost": {"metal": 1, "glass": 1}},
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
## Research: costs points, unlocks cards for the collection and/or gives extra actions.
@export var research: Array[Dictionary] = [
	{"id": "conveyor", "name": "Förderband", "cost": 2, "unlocks": ["auto_mine"],
		"description": "Minen füllen sich jede Runde selbst."},
	{"id": "halt", "name": "Haltepunkt", "cost": 2, "unlocks": ["halt"],
		"description": "Ein Haltepunkt an der Schiene schickt jede Runde selbst einen Zug los."},
	{"id": "master", "name": "Meister", "cost": 3, "unlocks": ["auto_crafter"],
		"description": "Werkstätten liefern ihre Items selbst ab."},
	{"id": "big_mines", "name": "Bergbau", "cost": 1, "unlocks": ["mine_silver_twin", "mine_gold_pond"],
		"description": "Neue Minen-Karten."},
	{"id": "land", "name": "Landgewinnung", "cost": 1, "unlocks": ["flag_pointy", "rail_fff"],
		"description": "Langflagge und sehr lange Gerade."},
	{"id": "station", "name": "Zweiter Bahnhof", "cost": 3, "unlocks": ["station"],
		"description": "Bahnhof-Karte: 4 Züge mehr und neue Reichweite."},
	{"id": "trade", "name": "Handel", "cost": 1, "unlocks": ["marketplace"],
		"description": "Marktplatz-Karte."},
	{"id": "organisation", "name": "Organisation", "cost": 4, "actions": 1,
		"description": "+1 Aktion pro Runde."},
]

@export_group("Orders")
## Factory types in the order they appear (gold / silver = the mine type that serves them).
@export var factory_sequence: Array[String] = ["gold", "silver", "gold", "silver", "gold", "silver"]
## A new factory appears every time the island gained this many land cells.
@export var land_per_factory := 12
## Factories appear between these distances (steps) from the first station.
@export var factory_min_distance := 4
@export var factory_max_distance := 7
## Order size of the first factory; every later factory wants `order_growth` more.
@export var order_base := 5
@export var order_growth := 3
## Rounds until an order expires (then a curse card goes into the deck).
@export var order_deadline := 5
## Rewards: coins per delivered load, plus coins and item cards per finished order.
@export var coins_per_load := 0
@export var coins_per_order := 3
@export var items_per_order := 4

@export_group("Buildings")
## Items a mine gets per tap (or per round when automated), and how much it can store.
@export var mine_tap_amount := 3
@export var mine_capacity := 6
## Items a train takes from a mine per step.
@export var loads_per_mine_step := 2
## Trains per station (each one can be sent once per round).
@export var trains_per_station := 4
## Items of one random kind a workshop has ready after each round.
@export var items_per_crafter := 3
## Item cards in the shuffled item deck (workshops, order rewards, market).
@export var item_deck: Dictionary[String, int] = {"wood": 34, "stone": 26, "metal": 20, "glass": 14}

@export_group("Trains")
## Seconds per rail step.
@export var step_duration := 0.45
## A train needs at least this many rail cells to its factory (no one-rail shortcuts).
@export var min_train_route := 4

@export_group("Marketplace")
@export var market_offer_count := 6
@export var market_refresh_rounds := 3
@export var market_trades_per_round := 1

@export_group("Island")
@export var island_min_radius := 4.5
@export var island_max_radius := 7.0
@export var island_min_angle_step := 25.0
@export var island_max_angle_step := 55.0
