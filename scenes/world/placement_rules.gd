class_name PlacementRules
## Where a card's piece may go. All building rules of the game are in this file.
##   every cell: free ground (dirt), no cell used twice
##   rails: start at the open rail end (CardShape does that) and must end facing free ground,
##          so the line can always continue
##   other pieces: never on the cell the rails need next, and (GameRules.require_adjacent)
##          at least one cell must touch an existing building
##   bomb:  on any building except ground, the power station and rails - only the last rail
##          of the line may be blown up (the start rails stay)
##   bridge: on a sea cell next to land, or on water standing on land


static func is_valid(island: Island, layout: Array[Dictionary], rail: bool) -> bool:
	if layout.is_empty():
		return false
	if layout[0].has("tool"):
		return can_use_tool(island, layout[0]["tool"], layout[0]["cell"])
	var cells := {}
	for entry in layout:
		var c: Vector2i = entry["cell"]
		if cells.has(c) or not island.is_free_ground(c):
			return false
		cells[c] = true

	if rail:
		var last: Dictionary = layout[-1]
		var exit: Vector2i = last["cell"] + GridUtil.DIR_VECTORS[last["out"]]
		return island.is_free_ground(exit) and not cells.has(exit)

	if cells.has(island.open_end_cell()):
		return false
	if GameState.rules.require_adjacent and not touches_building(island, cells):
		return false
	return true


static func can_use_tool(island: Island, tool: String, c: Vector2i) -> bool:
	var building := island.buildings.get(c) as Building
	match tool:
		"bomb":
			if building == null or building.is_buildable_ground or building is PowerStation:
				return false
			if building is Rail:
				return c == island.rail_path[-1] and island.rail_path.size() > Island.RAIL_CELLS.size() + 1
			return true
		"bridge":
			if island.is_land(c):
				return building != null and building.type_id() == "water"
			for dir_vector in GridUtil.DIR_VECTORS:
				if island.is_land(c + dir_vector):
					return true
	return false


## True if any cell has a direct neighbour (N/W/S/E) with a real building on it.
static func touches_building(island: Island, cells: Dictionary) -> bool:
	for c: Vector2i in cells:
		for dir_vector in GridUtil.DIR_VECTORS:
			var n: Vector2i = c + dir_vector
			if cells.has(n):
				continue
			var building := island.buildings.get(n) as Building
			if building and not building.is_buildable_ground and building.counts_as_neighbor:
				return true
	return false


## Every valid placement of a card: [{"anchor", "steps", "layout"}]. Rails have at most
## one per mirror state; other cards are tried on every land cell in every rotation.
static func options(island: Island, card_id: String) -> Array[Dictionary]:
	var def := CardShape.definition(card_id)
	var rail := CardShape.is_rail(def)
	var anchors: Array = [island.open_end_cell()] if rail else island.land.keys()
	if CardShape.is_tool_card(def):
		anchors = _land_and_coast(island)
	var result: Array[Dictionary] = []
	for anchor: Vector2i in anchors:
		for steps in CardShape.step_count(def):
			var layout := CardShape.layout(def, island, anchor, steps)
			if is_valid(island, layout, rail):
				result.append({"anchor": anchor, "steps": steps, "layout": layout})
	return result


## Land cells plus every sea cell touching land.
static func _land_and_coast(island: Island) -> Array:
	var result := {}
	for c: Vector2i in island.land:
		result[c] = true
		for dir_vector in GridUtil.DIR_VECTORS:
			result[c + dir_vector] = true
	return result.keys()
