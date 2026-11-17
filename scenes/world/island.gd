class_name Island
extends Node3D
## Generates a random island (like the Unity IslandBuilder), places the start setup
## and tracks what stands on which cell. Flags can add new land later.
## Command line: `-- --seed=123` makes the island reproducible.

const DIRT := preload("res://scenes/buildings/dirt.tscn")
const POWER_STATION := preload("res://scenes/buildings/power_station.tscn")
const RAIL_STRAIGHT := preload("res://scenes/buildings/rail_straight.tscn")
const RAIL_CURVE := preload("res://scenes/buildings/rail_curve.tscn")
const MINE_GOLD := preload("res://scenes/buildings/mine_gold.tscn")
const MINE_SILVER := preload("res://scenes/buildings/mine_silver.tscn")
const ITEMCRAFTER := preload("res://scenes/buildings/itemcrafter.tscn")
const MARKETPLACE := preload("res://scenes/buildings/marketplace.tscn")

## Outline generation: walk around ISLAND_CENTER in random angle steps,
## putting a vertex at a random distance each time.
const ISLAND_CENTER := Vector2(1.5, 0.5)
@export var min_radius := 4.0
@export var max_radius := 7.0
@export var min_angle_step := 25.0
@export var max_angle_step := 55.0

const POWER_STATION_CELL := Vector2i(0, 0)
## Rails from the power station to the open end.
const RAIL_CELLS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2),
]
## Other start buildings: cell -> scene
var _start_buildings := {
	Vector2i(2, 1): MINE_GOLD,
	Vector2i(4, 1): MINE_SILVER,
	Vector2i(1, -1): ITEMCRAFTER,
	Vector2i(2, -1): MARKETPLACE,
}

## Grid cell -> Building
var buildings := {}
## Grid cell -> true for every land cell
var land := {}
## Power station first, then the rails up to the open end.
var rail_path: Array[Vector2i] = []
var mines: Array[Mine] = []
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


func is_land(cell: Vector2i) -> bool:
	return land.has(cell)


func count_type(id: String) -> int:
	var count := 0
	for building: Building in buildings.values():
		if building.type_id() == id:
			count += 1
	return count


## True if an observer watches this cell (mines there load trains on purpose).
func is_observed(c: Vector2i) -> bool:
	for building: Building in buildings.values():
		if building is Observer and (building as Observer).observes(c):
			return true
	return false


## Notifies every building that a round ended (marketplaces refresh etc.).
func on_round_end() -> void:
	for building: Building in buildings.values():
		building.on_round_end()


## True if the cell is land with plain ground (dirt) on it.
func is_free_ground(c: Vector2i) -> bool:
	var building := buildings.get(c) as Building
	return is_land(c) and building != null and building.is_buildable_ground


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


## Non-rail buildings: on free ground, but never on the cell the rails need next.
func can_place_building(c: Vector2i) -> bool:
	return is_free_ground(c) and c != open_end_cell()


## Rails: only at the open end, connected to the last rail, and the new end
## must again face free ground (otherwise the line would be blocked).
func can_place_rail(rail: Rail, c: Vector2i, steps: int) -> bool:
	if c != open_end_cell() or not is_free_ground(c):
		return false
	var openings := rail.openings_for_steps(steps)
	var to_prev := GridUtil.dir_between(c, rail_path[-1])
	if not openings.has(to_prev):
		return false
	for d in openings:
		if d != to_prev:
			return is_free_ground(c + GridUtil.DIR_VECTORS[d])
	return false


## Replaces whatever stands on the cell. Rails extend rail_path, flags add land.
func place_building(scene: PackedScene, c: Vector2i, steps: int) -> Building:
	var old := buildings.get(c) as Building
	if old:
		buildings.erase(c)
		old.queue_free()
	var building := _place(scene, c)
	building.set_rotation_steps(steps)
	if building is Rail:
		rail_path.append(c)
	elif building is Flag:
		_claim_land(c, (building as Flag).area_offsets())
	return building


## Turns water cells around `center` into new ground, rising out of the sea.
func _claim_land(center: Vector2i, offsets: Array[Vector2i]) -> void:
	var delay := 0.0
	for offset in offsets:
		var c := center + offset
		if is_land(c):
			continue
		land[c] = true
		var dirt := _place(DIRT, c)
		dirt.position.y = -3.0
		var tween := dirt.create_tween()
		tween.tween_interval(delay)
		tween.tween_property(dirt, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		delay += 0.05


func _generate_land(rng: RandomNumberGenerator) -> void:
	var outline := PackedVector2Array()
	var angle := rng.randf_range(0.0, max_angle_step)
	while angle < 360.0:
		var distance := rng.randf_range(min_radius, max_radius)
		outline.append(ISLAND_CENTER + Vector2(distance, 0.0).rotated(deg_to_rad(angle)))
		angle += rng.randf_range(min_angle_step, max_angle_step)

	var reach := ceili(max_radius) + 1
	for x in range(-reach, reach + 1):
		for y in range(-reach, reach + 1):
			var c := Vector2i(roundi(ISLAND_CENTER.x) + x, roundi(ISLAND_CENTER.y) + y)
			if Geometry2D.is_point_in_polygon(Vector2(c), outline):
				land[c] = true

	# The start setup (and the cells right next to it) always needs land.
	var needed: Array[Vector2i] = [POWER_STATION_CELL]
	needed.append_array(RAIL_CELLS)
	needed.append_array(_start_buildings.keys())
	needed.append(RAIL_CELLS[-1] + Vector2i(0, 1))
	for c in needed:
		for x in range(-1, 2):
			for y in range(-1, 2):
				land[c + Vector2i(x, y)] = true


func _build_start_island() -> void:
	power_station = _place(POWER_STATION, POWER_STATION_CELL) as PowerStation
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
		var rail := _place(RAIL_STRAIGHT if is_straight else RAIL_CURVE, c) as Rail
		rail.connect_dirs(to_prev, to_next)

	for c: Vector2i in _start_buildings:
		_place(_start_buildings[c], c)

	for c: Vector2i in land:
		if not buildings.has(c):
			_place(DIRT, c)


func _place(scene: PackedScene, c: Vector2i) -> Building:
	var building := scene.instantiate() as Building
	building.cell = c
	building.position = GridUtil.cell_to_world(c)
	add_child(building)
	buildings[c] = building
	if building is Mine:
		mines.append(building)
	return building
