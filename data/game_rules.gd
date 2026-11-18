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
## Items every workshop (itemcrafter) delivers after each round.
@export var items_per_crafter := 2

@export_group("Cards")
## Coins needed to throw away the top card of a deck.
@export var discard_cost := 1
## deck id -> {"name", "cost": [item ids, one of each is paid], "cards": {building id: count}}
@export var decks: Dictionary = {
	"rails": {
		"name": "Schienen",
		"cost": ["wood", "metal"],
		"cards": {"rail_straight": 7, "rail_curve": 5},
	},
	"buildings": {
		"name": "Gebäude",
		"cost": ["stone", "glass"],
		"cards": {"mine_gold": 5, "mine_silver": 4, "itemcrafter": 3, "observer": 2, "marketplace": 1},
	},
	"land": {
		"name": "Land",
		"cost": ["wood", "stone"],
		"cards": {"flag_normal": 5, "flag_pointy": 3},
	},
}
## Left-to-right order of the decks in the HUD.
@export var deck_order: Array[String] = ["rails", "buildings", "land"]

@export_group("Trains")
## Seconds per rail step.
@export var step_duration := 0.6
## Items each mine loads per train step.
@export var loads_per_mine_step := 1
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
