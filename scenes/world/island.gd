class_name Island
extends Node3D
## The board: generates a random island (like the Unity IslandBuilder), places the start
## setup and tracks what stands on which cell. Game rules for single building types live
## in the building scripts (see Building hooks), not here.
## Command line: `-- --seed=123` makes the island reproducible.

const DIRT_ID := "dirt"

## Outline generation: walk around ISLAND_CENTER in random angle steps, putting a vertex
## at a random distance each time (radius / angle limits come from GameRules).
const ISLAND_CENTER := Vector2(1.5, 0.5)

const POWER_STATION_CELL := Vector2i(0, 0)
## Rails from the power station to the open end.
const RAIL_CELLS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2),
]
## Other start buildings: cell -> building id
const START_BUILDINGS := {
	Vector2i(2, 1): "mine_gold",
	Vector2i(4, 1): "mine_silver",
	Vector2i(1, -1): "itemcrafter",
	Vector2i(2, -1): "marketplace",
}

## Grid cell -> Building
var buildings := {}
## Grid cell -> true for every land cell
var land := {}
## Power station first, then the rails up to the open end.
var rail_path: Array[Vector2i] = []
var power_station: PowerStation
var island_seed := 0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			rng.seed = int(arg.trim_prefix("--seed="))
	island_seed = rng.seed
	_generate_land(rng)
	_build_start_island()


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


## Direction in which the rail line continues after its last rail.
func open_end_dir() -> int:
	var last := rail_path[-1]
	var to_prev := GridUtil.dir_between(last, rail_path[-2])
	for d in (buildings[last] as Rail).openings():
		if d != to_prev:
			return d
	return GridUtil.opposite(to_prev)


## The cell in front of the last rail, where the next rail has to go.
func open_end_cell() -> Vector2i:
	return rail_path[-1] + GridUtil.DIR_VECTORS[open_end_dir()]


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


## Hook dispatch: every building reacts to a train step / the end of a round.
func notify_train_step(trains: Array[Train]) -> void:
	for building: Building in buildings.values():
		building.on_train_step(trains)


func notify_round_end() -> void:
	for building: Building in buildings.values():
		building.on_round_end()


# --- Generation ---

func _generate_land(rng: RandomNumberGenerator) -> void:
	var rules := GameState.rules
	var outline := PackedVector2Array()
	var angle := rng.randf_range(0.0, rules.island_max_angle_step)
	while angle < 360.0:
		var distance := rng.randf_range(rules.island_min_radius, rules.island_max_radius)
		outline.append(ISLAND_CENTER + Vector2(distance, 0.0).rotated(deg_to_rad(angle)))
		angle += rng.randf_range(rules.island_min_angle_step, rules.island_max_angle_step)

	var reach := ceili(rules.island_max_radius) + 1
	for x in range(-reach, reach + 1):
		for y in range(-reach, reach + 1):
			var c := Vector2i(roundi(ISLAND_CENTER.x) + x, roundi(ISLAND_CENTER.y) + y)
			if Geometry2D.is_point_in_polygon(Vector2(c), outline):
				land[c] = true

	# The start setup (and the cells right next to it) always needs land.
	var needed: Array[Vector2i] = [POWER_STATION_CELL]
	needed.append_array(RAIL_CELLS)
	needed.append_array(START_BUILDINGS.keys())
	needed.append(RAIL_CELLS[-1] + Vector2i(0, 1))
	for c in needed:
		for x in range(-1, 2):
			for y in range(-1, 2):
				land[c + Vector2i(x, y)] = true


func _build_start_island() -> void:
	power_station = _place("power_station", POWER_STATION_CELL) as PowerStation
	var exit_dir := GridUtil.dir_between(POWER_STATION_CELL, RAIL_CELLS[0])
	power_station.set_rotation_steps(GridUtil.steps_for([GridUtil.SOUTH], [exit_dir]))

	rail_path = [POWER_STATION_CELL]
	rail_path.append_array(RAIL_CELLS)
	for i in range(1, rail_path.size()):
		var c := rail_path[i]
		var to_prev := GridUtil.dir_between(c, rail_path[i - 1])
		var to_next := GridUtil.opposite(to_prev)
		if i < rail_path.size() - 1:
			to_next = GridUtil.dir_between(c, rail_path[i + 1])
		var is_straight := to_next == GridUtil.opposite(to_prev)
		var rail := _place("rail_straight" if is_straight else "rail_curve", c) as Rail
		rail.connect_dirs(to_prev, to_next)

	for c: Vector2i in START_BUILDINGS:
		_place(START_BUILDINGS[c], c)

	for c: Vector2i in land:
		if not buildings.has(c):
			_place(DIRT_ID, c)


func _place(id: String, c: Vector2i) -> Building:
	var building := GameData.building_scene(id).instantiate() as Building
	building.cell = c
	building.island = self
	building.position = GridUtil.cell_to_world(c)
	add_child(building)
	buildings[c] = building
	return building
