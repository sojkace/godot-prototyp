class_name GameData
## Static catalog: ore and building names, icons, scenes and range overlays.
## Balance numbers are NOT here - they live in GameRules (`res://data/rules/*.tres`).
##
## Adding a new building type:
##   1. scene `res://scenes/buildings/<id>.tscn` (Model child + script extending Building)
##   2. name in BUILDING_NAMES, icon `res://assets/ui/icons/<id>.png` (tools/blender/render_icons.py)
##   3. add a card using it to GameRules.cards and put the card into a deck

const ITEM_NAMES := {"gold": "Gold", "silver": "Silber"}
## Icon ids without an own picture that reuse another one.
const ICON_ALIASES := {"gold": "mine_gold", "silver": "mine_silver",
	"halt": "observer", "factory": "fabric"}

const BUILDING_NAMES := {
	"rail_straight": "Schiene",
	"rail_curve": "Kurve",
	"mine_gold": "Goldmine",
	"mine_silver": "Silbermine",
	"flag_normal": "Flagge",
	"flag_pointy": "Langflagge",
	"observer": "Beobachter",
	"halt": "Haltepunkt",
	"factory": "Fabrik",
	"water": "Wasser",
	"bridge": "Brücke",
	"dirt": "Erde",
}

## Range overlay model per area shape (see GridUtil.area_offsets), shown while placing.
const AREA_OVERLAYS := {
	"square": "res://assets/models/grids/grid_mine_gold.glb",
	"cross": "res://assets/models/grids/grid_mine_silver.glb",
	"diamond": "res://assets/models/grids/grid_flag_normal.glb",
	"long_cross": "res://assets/models/grids/grid_flag_pointy.glb",
}


## Icon for an ore / building / card icon id, or null if none was rendered.
static func icon(id: String) -> Texture2D:
	var path := "res://assets/ui/icons/%s.png" % ICON_ALIASES.get(id, id)
	return load(path) if ResourceLoader.exists(path) else null


static func building_scene(id: String) -> PackedScene:
	return load("res://scenes/buildings/%s.tscn" % id)


static func building_name(id: String) -> String:
	return BUILDING_NAMES.get(id, id)


static func item_name(id: String) -> String:
	return ITEM_NAMES.get(id, id)


static func area_overlay(shape: String) -> PackedScene:
	return load(AREA_OVERLAYS[shape]) if AREA_OVERLAYS.has(shape) else null
