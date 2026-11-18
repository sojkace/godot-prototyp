class_name Building
extends Node3D
## Base for everything that occupies one grid cell on the island.
##
## Mechanics are hooks: a building type overrides only what it needs, the island and the
## train controller call the hooks on every building. New mechanic = new script with a hook,
## no changes to the game loop.
##   can_place()       where the building may be built (default: free ground)
##   preferred_cell()  where the placement preview starts
##   on_placed()       right after the player built it (flags claim land)
##   on_train_step()   after every train step (mines load trains)
##   choose_train()    let a building pick which train another building serves (observer)
##   on_round_end()    after every round (workshops deliver, marketplaces refresh)

## True for plain ground (dirt) that other buildings may be built on.
@export var is_buildable_ground := false
## Area of effect around the building (see GridUtil.area_offsets).
@export_enum("none", "square", "cross", "diamond", "long_cross") var area_shape := "none"
## True if the player may turn it while placing (rails).
@export var rotatable := false

## Grid cell this building stands on (x = world X, y = world Z).
var cell := Vector2i.ZERO
## Current rotation in 90° steps (0..3).
var rotation_steps := 0
## Set by the island when the building is placed (null for placement previews).
var island: Island


## Rotate in 90° steps around Y. One step turns the model's north side to the west.
func set_rotation_steps(steps: int) -> void:
	rotation_steps = posmod(steps, 4)
	rotation.y = rotation_steps * PI / 2.0


## Building type, taken from the scene file name (e.g. "mine_gold", "itemcrafter").
func type_id() -> String:
	return scene_file_path.get_file().get_basename()


func area_offsets() -> Array[Vector2i]:
	return GridUtil.area_offsets(area_shape)


## True if `target_cell` lies inside this building's area.
func covers(target_cell: Vector2i) -> bool:
	return area_offsets().has(target_cell - cell)


# --- Hooks (override in subclasses) ---

func can_place(on_island: Island, at: Vector2i, _steps: int) -> bool:
	return on_island.is_free_ground(at) and at != on_island.open_end_cell()


## Start cell for the placement preview, or null to start at the screen center.
func preferred_cell(_on_island: Island) -> Variant:
	return null


## Rotation (0..3) the preview should use at `at`; default keeps the current one.
func best_rotation(_on_island: Island, _at: Vector2i, current: int) -> int:
	return current


func on_placed() -> void:
	pass


func on_train_step(_trains: Array[Train]) -> void:
	pass


## Return a train from `candidates` if this building decides which train `source` serves,
## otherwise null.
func choose_train(_source: Building, _candidates: Array[Train]) -> Train:
	return null


func on_round_end() -> void:
	pass
