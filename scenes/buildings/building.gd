class_name Building
extends Node3D
## Base for everything that occupies one grid cell on the island.
##
## Mechanics are hooks: a building type overrides only what it needs, the island and the
## train controller call the hooks on every building. New mechanic = new script with a hook,
## no changes to the game loop. Where things may be built: PlacementRules.
##   on_placed()          right after the player built it (flags claim land)
##   on_train_step()      after every train step (mines load trains)
##   on_round_end()       after every round (automated mines dig, factories tick ...)
##   tap_costs_action()   true if tapping now does manual work (costs one action)
##   on_tapped()          the player tapped the building (fill a mine ...)
##   can_upgrade(kind)    an upgrade card of this kind may be played on it ("auto" by default
##                        when can_automate(); rails take "halt"), apply_upgrade(kind) does it

## True for plain ground (dirt) that other buildings may be built on.
@export var is_buildable_ground := false
## Area of effect around the building (see GridUtil.area_offsets).
@export_enum("none", "square", "cross", "diamond", "long_cross") var area_shape := "none"
## Non-rail cards must touch a building with this flag (water does not count).
@export var counts_as_neighbor := true

## Grid cell this building stands on (x = world X, y = world Z).
var cell := Vector2i.ZERO
## Current rotation in 90° steps (0..3).
var rotation_steps := 0
## Set by the island when the building is placed (null for placement previews).
var island: Island
## True for the ghost shown while placing; such a building must not change game state.
var is_preview := false
## True once an upgrade card automated it (no more tapping needed).
var automated := false


## Rotate in 90° steps around Y. One step turns the model's north side to the west.
func set_rotation_steps(steps: int) -> void:
	rotation_steps = posmod(steps, 4)
	rotation.y = rotation_steps * PI / 2.0


## Building type, taken from the scene file name (e.g. "mine_gold", "flag_normal").
func type_id() -> String:
	return scene_file_path.get_file().get_basename()


func area_offsets() -> Array[Vector2i]:
	return GridUtil.area_offsets(area_shape)


## True if `target_cell` lies inside this building's area.
func covers(target_cell: Vector2i) -> bool:
	return area_offsets().has(target_cell - cell)


## Marks the building as automated and shows a small golden gear above it.
func set_automated() -> void:
	if automated:
		return
	automated = true
	var gear := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.18
	mesh.bottom_radius = 0.18
	mesh.height = 0.06
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.8, 0.2)
	material.emission_enabled = true
	material.emission = Color(0.6, 0.45, 0.05)
	mesh.material = material
	gear.mesh = mesh
	gear.position = Vector3(0.3, 1.1, 0.3)
	gear.rotation.x = PI / 2.0
	add_child(gear)
	var tween := gear.create_tween().set_loops()
	tween.tween_property(gear, "rotation:y", TAU, 3.0).from(0.0)


## Floating text above the building (stock, order, trains left ...). Created on first use.
func set_info(text: String, color := Color.WHITE) -> void:
	if is_preview:
		return
	var label := get_node_or_null("Info") as Label3D
	if label == null:
		label = Label3D.new()
		label.name = "Info"
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.font_size = 48
		label.outline_size = 12
		label.pixel_size = 0.006
		label.position = Vector3(0, 1.35, 0)
		add_child(label)
	label.text = text
	label.modulate = color
	label.visible = text != ""


# --- Hooks (override in subclasses) ---

func on_placed() -> void:
	pass


func on_train_step(_trains: Array[Train]) -> void:
	pass


func on_round_end() -> void:
	pass


func tap_costs_action() -> bool:
	return false


func on_tapped() -> void:
	pass


func can_automate() -> bool:
	return false


func can_upgrade(kind: String) -> bool:
	return kind == "auto" and can_automate() and not automated


func apply_upgrade(kind: String) -> void:
	if kind == "auto":
		set_automated()
