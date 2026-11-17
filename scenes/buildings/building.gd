class_name Building
extends Node3D
## Base for everything that occupies one grid cell on the island.

## True for plain ground (dirt) that other buildings may be built on.
@export var is_buildable_ground := false

## Grid cell this building stands on (x = world X, y = world Z).
var cell := Vector2i.ZERO
## Current rotation in 90° steps (0..3).
var rotation_steps := 0


## Rotate in 90° steps around Y. One step turns the model's north side to the west.
func set_rotation_steps(steps: int) -> void:
	rotation_steps = posmod(steps, 4)
	rotation.y = rotation_steps * PI / 2.0


## Building type, taken from the scene file name (e.g. "mine_gold", "itemcrafter").
func type_id() -> String:
	return scene_file_path.get_file().get_basename()


## Called after every round (Unity: NextRound). Override in subclasses.
func on_round_end() -> void:
	pass
