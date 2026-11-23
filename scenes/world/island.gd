class_name Island
extends Node3D
## The board: generates a random island (like the Unity IslandBuilder), places the start
## setup, tracks what stands on which cell and lets new factories appear as the island
## grows. Game rules for single building types live in the building scripts (see Building
## hooks), not here. Command line: `-- --seed=123` makes the island reproducible.

const DIRT_ID := "dirt"

## Outline generation: walk around ISLAND_CENTER in random angle steps, putting a vertex
## at a random distance each time (radius / angle limits come from GameRules).
const ISLAND_CENTER := Vector2(0.5, 0.5)

const STATION_CELL := Vector2i(0, 0)
## Other start buildings: cell -> building id
const START_BUILDINGS := {
	Vector2i(1, 1): "mine_gold",
	Vector2i(-1, 0): "itemcrafter",
	Vector2i(0, -1): "marketplace",
}

## Grid cell -> Building
var buildings := {}
## Grid cell -> true for every land cell
var land := {}
var island_seed := 0
var factories: Array[Factory] = []
var _start_land := 0
var _rng := RandomNumberGenerator.new()


## Builds a new island. Called by Main after GameState.reset().
func setup() -> void:
	_rng.randomize()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			_rng.seed = int(arg.trim_prefix("--seed="))
	island_seed = _rng.seed
	_generate_land()
	_build_start_island()
	_start_land = land.size()
	GameState.set_stat("land", land.size())
	spawn_factory()


# --- Queries ---

func is_land(c: Vector2i) -> bool:
	return land.has(c)


## True if the cell is land with plain ground (dirt) on it.
func is_free_ground(c: Vector2i) -> bool:
	var building := buildings.get(c) as Building
	return is_land(c) and building != null and building.is_buildable_ground


func all_buildings() -> Array:
	return buildings.values()


func count_type(id: String) -> int:
	var count := 0
	for building: Building in buildings.values():
		if building.type_id() == id:
			count += 1
	return count


func stations() -> Array[Station]:
	var result: Array[Station] = []
	for building: Building in buildings.values():
		if building is Station:
			result.append(building)
	return result


## A station that may put a train on `c` right now (area covers it, trains left), or null.
func station_for(c: Vector2i) -> Station:
	for station in stations():
		if station.can_send() and (station.covers(c) or station.cell == c):
			return station
	return null


# --- Changes ---

## Builds `id` on the cell (replacing the ground) and runs its on_placed() hook.
func place_building(id: String, c: Vector2i, steps: int) -> Building:
	var old := buildings.get(c) as Building
	if old:
		buildings.erase(c)
		old.queue_free()
	var building := _place(id, c)
	building.set_rotation_steps(steps)
	building.on_placed()
	Events.building_placed.emit(building)
	return building


## Builds every cell of a card layout (see CardShape) in order. Tool entries demolish
## (bomb) or add ground (bridge); upgrade entries automate the building there.
func place_layout(layout: Array[Dictionary]) -> void:
	for entry in layout:
		var c: Vector2i = entry["cell"]
		if entry.has("upgrade"):
			(buildings[c] as Building).set_automated()
			continue
		match entry.get("tool", ""):
			"bomb":
				demolish(c)
			"bridge":
				land[c] = true
				place_building("bridge", c, 0)
				_land_changed()
			_:
				place_building(entry["id"], c, entry["steps"])


## Blows up whatever stands on the cell and leaves plain dirt.
func demolish(c: Vector2i) -> void:
	place_building(DIRT_ID, c, 0)
	_explosion(GridUtil.cell_to_world(c))


func _explosion(at: Vector3) -> void:
	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.4
	sphere.height = 0.8
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.6, 0.15, 0.9)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere.material = material
	flash.mesh = sphere
	flash.position = at + Vector3.UP * 0.4
	add_child(flash)
	var tween := flash.create_tween().set_parallel()
	tween.tween_property(flash, "scale", Vector3.ONE * 2.5, 0.35)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.35)
	tween.chain().tween_callback(flash.queue_free)


## Turns water cells around `center` into new ground, rising out of the sea.
func claim_land(center: Vector2i, offsets: Array[Vector2i]) -> void:
	var delay := 0.0
	for offset in offsets:
		var c := center + offset
		if is_land(c):
			continue
		land[c] = true
		var dirt := _place(DIRT_ID, c)
		dirt.position.y = -3.0
		var tween := dirt.create_tween()
		tween.tween_interval(delay)
		tween.tween_property(dirt, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		delay += 0.05
	_land_changed()


## Every GameRules.land_per_factory new land cells a new factory appears.
func _land_changed() -> void:
	GameState.set_stat("land", land.size())
	var due := 1 + floori(float(land.size() - _start_land) / maxi(1, GameState.rules.land_per_factory))
	while factories.size() < due:
		if spawn_factory() == null:
			break


## Puts the next factory of GameRules.factory_sequence on a free spot away from the station.
func spawn_factory() -> Factory:
	var rules := GameState.rules
	var c: Variant = _factory_spot()
	if c == null:
		return null
	var index := factories.size()
	var ore: String = rules.factory_sequence[index % rules.factory_sequence.size()]
	var old := buildings.get(c) as Building
	if old:
		buildings.erase(c)
		old.queue_free()
	var factory := GameData.building_scene("factory").instantiate() as Factory
	factory.setup(ore, index)
	_add(factory, c)
	factories.append(factory)
	GameState.set_stat("factories", factories.size())
	Events.factory_appeared.emit(factory)
	return factory


## Free ground in the right distance from the station with free ground around it
## (relaxed step by step if the island has no such spot).
func _factory_spot() -> Variant:
	var rules := GameState.rules
	for strict in [true, false]:
		var candidates: Array[Vector2i] = []
		for c: Vector2i in land:
			if not is_free_ground(c):
				continue
			var distance := absi(c.x - STATION_CELL.x) + absi(c.y - STATION_CELL.y)
			if strict and (distance < rules.factory_min_distance or distance > rules.factory_max_distance):
				continue
			if not strict and distance < 3:
				continue
			if _free_around(c) >= (6 if strict else 2):
				candidates.append(c)
		if not candidates.is_empty():
			return candidates[_rng.randi() % candidates.size()]
	return null


func _free_around(c: Vector2i) -> int:
	var count := 0
	for x in range(-1, 2):
		for y in range(-1, 2):
			if (x != 0 or y != 0) and is_free_ground(c + Vector2i(x, y)):
				count += 1
	return count


## Hook dispatch: every building reacts to a train step / the end of a round.
func notify_train_step(trains: Array[Train]) -> void:
	for building: Building in buildings.values():
		building.on_train_step(trains)


func notify_round_end() -> void:
	for building: Building in buildings.values():
		building.on_round_end()


# --- Generation ---

func _generate_land() -> void:
	var rules := GameState.rules
	var outline := PackedVector2Array()
	var angle := _rng.randf_range(0.0, rules.island_max_angle_step)
	while angle < 360.0:
		var distance := _rng.randf_range(rules.island_min_radius, rules.island_max_radius)
		outline.append(ISLAND_CENTER + Vector2(distance, 0.0).rotated(deg_to_rad(angle)))
		angle += _rng.randf_range(rules.island_min_angle_step, rules.island_max_angle_step)

	var reach := ceili(rules.island_max_radius) + 1
	for x in range(-reach, reach + 1):
		for y in range(-reach, reach + 1):
			var c := Vector2i(roundi(ISLAND_CENTER.x) + x, roundi(ISLAND_CENTER.y) + y)
			if Geometry2D.is_point_in_polygon(Vector2(c), outline):
				land[c] = true

	# The start setup (and the cells around it) always needs land.
	for x in range(-2, 3):
		for y in range(-2, 3):
			land[STATION_CELL + Vector2i(x, y)] = true


func _build_start_island() -> void:
	_place("station", STATION_CELL)
	for c: Vector2i in START_BUILDINGS:
		_place(START_BUILDINGS[c], c)
	for c: Vector2i in land:
		if not buildings.has(c):
			_place(DIRT_ID, c)


func _place(id: String, c: Vector2i) -> Building:
	return _add(GameData.building_scene(id).instantiate() as Building, c)


func _add(building: Building, c: Vector2i) -> Building:
	building.cell = c
	building.island = self
	building.position = GridUtil.cell_to_world(c)
	add_child(building)
	buildings[c] = building
	return building
