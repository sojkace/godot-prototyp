class_name Rail
extends Building
## A rail piece with two openings (see GridUtil directions). Rail cards place one or
## more of these along a path (CardShape); where they may go: PlacementRules.
## A halt card ({"upgrade": "halt"}) on a rail makes a train start exactly here every round,
## without an action (see Main.end_round).

enum Kind { STRAIGHT, CURVE }

const HALT_MODEL := preload("res://assets/models/buildings/observer.glb")

@export var kind := Kind.STRAIGHT

var has_halt := false


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



func can_upgrade(kind_id: String) -> bool:
	return kind_id == "halt" and not has_halt


func apply_upgrade(kind_id: String) -> void:
	if kind_id != "halt" or has_halt:
		return
	has_halt = true
	# Small signal house beside the track (placeholder model), not turned with the rail.
	var model := HALT_MODEL.instantiate() as Node3D
	model.scale = Vector3.ONE * 0.45
	model.position = Vector3(0.32, 0.0, 0.32)
	model.rotation.y = -rotation.y
	add_child(model)
