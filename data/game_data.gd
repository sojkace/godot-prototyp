class_name GameData
## Balance data for the prototype. Change numbers here to tune the game.

const ITEMS: Array[String] = ["wood", "stone", "metal", "glass"]
const ITEM_NAMES := {"wood": "Holz", "stone": "Stein", "metal": "Metall", "glass": "Glas"}
## Item cards in the shuffled item deck (reshuffled when empty).
const ITEM_DECK := {"wood": 25, "stone": 25, "metal": 20, "glass": 20}
const START_ITEMS := {"wood": 2, "stone": 2, "metal": 2, "glass": 1}
## Items every workshop (item crafter) delivers after each round.
const ITEMS_PER_CRAFTER := 2

const BUILDING_NAMES := {
	"rail_straight": "Schiene",
	"rail_curve": "Kurve",
	"mine_gold": "Goldmine",
	"mine_silver": "Silbermine",
	"itemcrafter": "Werkstatt",
	"flag_normal": "Flagge",
	"flag_pointy": "Langflagge",
	"observer": "Beobachter",
	"marketplace": "Marktplatz",
}

## Card decks. The top card of each deck can be played; it costs one of each item in "cost".
const DECKS := {
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
const DECK_ORDER: Array[String] = ["rails", "buildings", "land"]


## Levels. Every round is a string of trains in spawn order:
## "s" = small train (4 loads, train_1_*), "b" = big train (8 loads, train_2_*).
## Level 1 follows the Unity "Level1" settings (5 rounds each with 1, 2, 3, 4 trains).
const LEVELS: Array[Dictionary] = [
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


static func icon(id: String) -> Texture2D:
	return load("res://assets/ui/icons/%s.png" % id)
