class_name PlacementRules
## Where a card's piece may go. All building rules of the game are in this file.
##   every cell: free ground (dirt), no cell used twice
##   rails:  may start anywhere; both ends of the block must face free ground, a factory or
##           a rail opening towards it (so every line can go on or is finished)
##   other pieces: (GameRules.require_adjacent) at least one cell must touch a building
##   upgrade: on a building that takes this upgrade (auto: mines, halt: rails)
##   bomb:   on any building except ground and factories
##   bridge: on a sea cell next to land, or on water standing on land


static func is_valid(island: Island, layout: Array[Dictionary], rail: bool) -> bool:
	if layout.is_empty():
		return false
	if layout[0].has("tool"):
		return can_use_tool(island, layout[0]["tool"], layout[0]["cell"])
	if layout[0].has("upgrade"):
		var target := island.buildings.get(layout[0]["cell"]) as Building
		return target != null and target.can_upgrade(layout[0]["upgrade"])
	var cells := {}
	for entry in layout:
		var c: Vector2i = entry["cell"]
		if cells.has(c) or not island.is_free_ground(c):
			return false
		cells[c] = true

	if rail:
		var first: Dictionary = layout[0]
		var last: Dictionary = layout[-1]
		return _end_ok(island, first["cell"], first["in"], cells) \
			and _end_ok(island, last["cell"], last["out"], cells)

	if GameState.rules.require_adjacent and not touches_building(island, cells):
		return false
	return true


## The cell in direction `dir` from a block end at `c` must let the line go on.
static func _end_ok(island: Island, c: Vector2i, dir: int, cells: Dictionary) -> bool:
	var n: Vector2i = c + GridUtil.DIR_VECTORS[dir]
	if cells.has(n):
		return false
	if island.is_free_ground(n):
		return true
	var building := island.buildings.get(n) as Building
	if building is Factory:
		return true
	return building is Rail and (building as Rail).openings().has(GridUtil.opposite(dir))


static func can_use_tool(island: Island, tool: String, c: Vector2i) -> bool:
	var building := island.buildings.get(c) as Building
	match tool:
		"bomb":
			return building != null and not building.is_buildable_ground \
				and not building is Factory
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


## Every valid placement of a card: [{"anchor", "steps", "layout"}], tried on every
## possible anchor cell in every rotation.
static func options(island: Island, card_id: String) -> Array[Dictionary]:
	var def := CardShape.definition(card_id)
	var rail := CardShape.is_rail(def)
	var anchors: Array = island.land.keys()
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
