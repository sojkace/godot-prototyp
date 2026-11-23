class_name RailNetwork
## Reads the rail graph from the placed Rail buildings: two neighbouring rail cells are
## connected if both have an opening towards each other. A rail opening that points into a
## factory cell ends the line at that factory.


static func rail_at(island: Island, c: Vector2i) -> Rail:
	return island.buildings.get(c) as Rail


## Rail cells connected to the rail at `c`.
static func neighbours(island: Island, c: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var rail := rail_at(island, c)
	if rail == null:
		return result
	for d in rail.openings():
		var n: Vector2i = c + GridUtil.DIR_VECTORS[d]
		var other := rail_at(island, n)
		if other and other.openings().has(GridUtil.opposite(d)):
			result.append(n)
	return result


## Factories the rail at `c` opens into.
static func factories_at(island: Island, c: Vector2i) -> Array[Factory]:
	var result: Array[Factory] = []
	var rail := rail_at(island, c)
	if rail == null:
		return result
	for d in rail.openings():
		var factory := island.buildings.get(c + GridUtil.DIR_VECTORS[d]) as Factory
		if factory:
			result.append(factory)
	return result


## Shortest drive from the rail cell `start` to a factory:
## {"path": [start, ..., last rail cell], "factory": Factory}, or {} if none is reachable.
static func route(island: Island, start: Vector2i) -> Dictionary:
	if rail_at(island, start) == null:
		return {}
	var came_from := {start: start}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		var factories := factories_at(island, c)
		if not factories.is_empty():
			var path: Array[Vector2i] = [c]
			while path[0] != start:
				path.push_front(came_from[path[0]])
			return {"path": path, "factory": factories[0]}
		for n in neighbours(island, c):
			if not came_from.has(n):
				came_from[n] = c
				queue.append(n)
	return {}


## Every rail cell connected (directly or not) to `start`, including it.
static func line_cells(island: Island, start: Vector2i) -> Dictionary:
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		for n in neighbours(island, queue.pop_front()):
			if not seen.has(n):
				seen[n] = true
				queue.append(n)
	return seen


## Open ends: [{"cell": the free cell in front of an unconnected opening, "dir": heading}].
static func open_ends(island: Island) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for c: Vector2i in island.buildings:
		var rail := rail_at(island, c)
		if rail == null:
			continue
		for d in rail.openings():
			var n: Vector2i = c + GridUtil.DIR_VECTORS[d]
			var other := island.buildings.get(n) as Building
			if other is Factory or (other is Rail and (other as Rail).openings().has(GridUtil.opposite(d))):
				continue
			result.append({"cell": n, "dir": d, "from": c})
	return result
