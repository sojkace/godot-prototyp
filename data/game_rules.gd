class_name GameRules
extends Resource
## One complete rule variant: every tunable number plus decks and levels.
## Variants live in `res://data/rules/*.tres`. A variant only stores the values that differ
## from the defaults below, so a new experiment = duplicate a .tres and change a few fields
## in the Inspector. Pick it in the main menu or with `-- --rules=<file name>`.

@export var title := "Standard"
@export_multiline var description := ""

@export_group("Start")
@export var start_hearts := 3
@export var start_coins := 0
@export var start_items: Dictionary[String, int] = {"wood": 2, "stone": 2, "metal": 2, "glass": 1}

@export_group("Items")
## Item cards in the shuffled item deck (reshuffled when empty).
@export var item_deck: Dictionary[String, int] = {"wood": 25, "stone": 25, "metal": 20, "glass": 20}
## Items of one random kind a workshop (itemcrafter) has ready after each round.
@export var items_per_crafter := 2
## False: the player has to tap the workshop to collect (uncollected items do not pile up).
@export var crafter_auto_collect := false

@export_group("Cards")
## Coins needed to throw away the top card of a deck.
@export var discard_cost := 1
## Non-rail cards must touch an existing building (not just any free ground).
@export var require_adjacent := true
## Every card the decks can contain. A card places a piece of one or more cells:
##   "cells": [[x, y, "building_id"], ...]  offsets from the tapped cell, turned as a whole
##   "rail": "FLR"  track from the open rail end: F = straight, L / R = curve (mirror = turn)
##   "icon" (optional): icon id for the card, default = first building / rail type
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
	"mine_silver_twin": {"name": "Silber-Doppelmine", "cells": [[0, 0, "mine_silver"], [1, 0, "mine_silver"]]},
	"mine_silver_lake": {"name": "Silbermine am See",
		"cells": [[0, 0, "mine_silver"], [1, 0, "water"], [1, 1, "water"]]},
	"itemcrafter": {"name": "Werkstatt", "cells": [[0, 0, "itemcrafter"]]},
	"itemcrafter_pond": {"name": "Werkstatt am Teich", "cells": [[0, 0, "itemcrafter"], [0, 1, "water"]]},
	"observer": {"name": "Beobachter", "cells": [[0, 0, "observer"]]},
	"marketplace": {"name": "Marktplatz", "cells": [[0, 0, "marketplace"]]},
	"flag_normal": {"name": "Flagge", "cells": [[0, 0, "flag_normal"]]},
	"flag_pointy": {"name": "Langflagge", "cells": [[0, 0, "flag_pointy"]]},
	"flag_swamp": {"name": "Flagge im Sumpf",
		"cells": [[0, 0, "flag_normal"], [-1, 0, "water"], [1, 0, "water"]]},
	"pond": {"name": "Teich", "icon": "water", "cells": [[0, 0, "water"], [1, 0, "water"]]},
	"lake": {"name": "See", "icon": "water", "cells": [[0, 0, "water"], [1, 0, "water"], [0, 1, "water"]]},
	# Tools, bought with coins in the shop (not in decks):
	# bomb = turn a building (or the last rail) back into dirt, bridge = new ground on water.
	"bomb": {"name": "Bombe", "tool": "bomb", "coins": 2},
	"bridge": {"name": "Brücke", "tool": "bridge", "coins": 2},
}
## Tool cards offered in the shop (always available, paid with coins).
@export var shop: Array[String] = ["bomb", "bridge"]
## deck id -> {"name", "cost": [item ids, one of each is paid], "cards": {card id: count}}
@export var decks: Dictionary = {
	"rails": {
		"name": "Schienen",
		"cost": ["wood", "metal"],
		"cards": {"rail_f": 4, "rail_l": 4, "rail_ff": 3, "rail_fff": 1, "rail_lr": 2, "rail_ll": 2,
			"rail_fl": 2, "rail_lf": 2},
	},
	"buildings": {
		"name": "Gebäude",
		"cost": ["stone", "glass"],
		"cards": {"mine_gold": 2, "mine_silver": 3, "mine_gold_pond": 3, "mine_silver_twin": 2,
			"mine_silver_lake": 2, "itemcrafter": 2, "itemcrafter_pond": 2, "observer": 2,
			"marketplace": 1, "pond": 2},
	},
	"land": {
		"name": "Land",
		"cost": ["wood", "stone"],
		"cards": {"flag_normal": 4, "flag_pointy": 2, "flag_swamp": 3, "lake": 2},
	},
}
## Left-to-right order of the decks in the HUD.
@export var deck_order: Array[String] = ["rails", "buildings", "land"]

@export_group("Trains")
## Seconds per rail step.
@export var step_duration := 0.6
## Items each mine loads per train step.
@export var loads_per_mine_step := 1
## Items a mine can give per round in total (0 = unlimited). Then it is empty until the next round.
@export var mine_loads_per_round := 3
## A full train pays capacity / loads_per_coin coins (at least 1).
@export var loads_per_coin := 4
## Hearts lost when a train arrives at the power station without being full.
@export var hearts_per_missed_train := 1

@export_group("Marketplace")
@export var market_offer_count := 6
@export var market_refresh_rounds := 3
@export var market_trades_per_round := 1

@export_group("Island")
@export var island_min_radius := 4.0
@export var island_max_radius := 7.0
@export var island_min_angle_step := 25.0
@export var island_max_angle_step := 55.0

@export_group("Levels")
## Every round is a string of trains in spawn order: "s" = small (4 loads), "b" = big (8 loads).
## Level 1 follows the Unity "Level1" settings (5 rounds each with 1, 2, 3, 4 trains).
@export var levels: Array[Dictionary] = [
	{
		"name": "Level 1",
		"description": "20 Runden, kleine Züge",
		"rounds": [
			"s", "s", "s", "s", "s",
			"ss", "ss", "ss", "ss", "ss",
			"sss", "sss", "sss", "sss", "sss",
			"ssss", "ssss", "ssss", "ssss", "ssss",
		],
	},
	{
		"name": "Level 2",
		"description": "15 Runden, schwere Züge mit 8 Plätzen",
		"rounds": [
			"s", "s", "b", "s", "b",
			"sb", "bs", "bb", "sb", "bb",
			"sbb", "bbs", "bbb", "bbb", "bbbb",
		],
	},
]
