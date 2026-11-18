class_name Rail
extends Building
## A rail piece with two openings (see GridUtil directions).
## Rails only go at the open end of the line, connected to the last rail, and the new
## end must again face free ground (otherwise the line would be blocked).

enum Kind { STRAIGHT, CURVE }

@export var kind := Kind.STRAIGHT


## Openings of the unrotated model.
func base_openings() -> Array[int]:
	if kind == Kind.STRAIGHT:
		return [GridUtil.NORTH, GridUtil.SOUTH]
	return [GridUtil.NORTH, GridUtil.WEST]


func openings_for_steps(steps: int) -> Array[int]:
	var result: Array[int] = []
	for d in base_openings():
		result.append((d + steps) % 4)
	return result


func openings() -> Array[int]:
	return openings_for_steps(rotation_steps)


func connect_dirs(dir_a: int, dir_b: int) -> void:
	set_rotation_steps(GridUtil.steps_for(base_openings(), [dir_a, dir_b]))


func can_place(on_island: Island, at: Vector2i, steps: int) -> bool:
	if at != on_island.open_end_cell() or not on_island.is_free_ground(at):
		return false
	var dirs := openings_for_steps(steps)
	var to_prev := GridUtil.dir_between(at, on_island.rail_path[-1])
	if not dirs.has(to_prev):
		return false
	for d in dirs:
		if d != to_prev:
			return on_island.is_free_ground(at + GridUtil.DIR_VECTORS[d])
	return false


func preferred_cell(on_island: Island) -> Variant:
	return on_island.open_end_cell()


## First rotation (starting after `current` when cycling) that fits, else `current`.
func best_rotation(on_island: Island, at: Vector2i, current: int) -> int:
	for i in 4:
		var candidate := (current + i) % 4
		if can_place(on_island, at, candidate):
			return candidate
	return current


func on_placed() -> void:
	island.rail_path.append(cell)
