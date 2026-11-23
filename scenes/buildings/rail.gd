class_name Rail
extends Building
## A rail piece with two openings (see GridUtil directions). Rail cards place one or
## more of these along a path (CardShape); where they may go: PlacementRules.

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


func on_placed() -> void:
	island.rail_path.append(cell)
