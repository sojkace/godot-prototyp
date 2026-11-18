class_name BuildController
extends Node3D
## Placement mode: shows a preview of the chosen building, tap a cell to move it,
## rotate (if the building allows it), then confirm or cancel. Green/red marker shows if
## the spot is valid. Placement rules come from the building itself (Building.can_place),
## so this controller works for any building type.

signal placement_changed(active: bool, valid: bool, can_rotate: bool)
signal building_placed
## Tap on a cell while not placing (e.g. to open the marketplace).
signal cell_tapped(cell: Vector2i)

## Max finger/mouse movement (px) that still counts as a tap and not a camera drag.
const TAP_MAX_DISTANCE := 14.0

@export var island: Island
@export var camera: Camera3D

var active := false

var _building_id := ""
var _preview: Building
var _overlay: Node3D
var _hidden_building: Building
var _marker: MeshInstance3D
var _valid_material: StandardMaterial3D
var _invalid_material: StandardMaterial3D
var _cell := Vector2i.ZERO
var _steps := 0
var _valid := false
var _press_position := Vector2.ZERO


func _ready() -> void:
	var box := BoxMesh.new()
	box.size = Vector3(1.0, 0.1, 1.0)
	_marker = MeshInstance3D.new()
	_marker.mesh = box
	_marker.visible = false
	add_child(_marker)
	_valid_material = _make_marker_material(Color(0.2, 0.9, 0.3, 0.5))
	_invalid_material = _make_marker_material(Color(0.95, 0.2, 0.2, 0.5))


func start(building_id: String) -> void:
	cancel()
	_building_id = building_id
	_preview = GameData.building_scene(building_id).instantiate() as Building
	add_child(_preview)
	var overlay_scene := GameData.area_overlay(_preview.area_shape)
	if overlay_scene:
		_overlay = overlay_scene.instantiate() as Node3D
		add_child(_overlay)
	active = true
	_marker.visible = true
	var preferred: Variant = _preview.preferred_cell(island)
	_move_to(preferred if preferred != null else _cell_at_screen_center())


## Switch to the next rotation that fits (e.g. curve left <-> right).
func rotate_preview() -> void:
	if not active or not _preview.rotatable:
		return
	_steps = _preview.best_rotation(island, _cell, (_steps + 1) % 4)
	_update()


func confirm() -> bool:
	if not active or not _valid:
		return false
	var id := _building_id
	var cell := _cell
	var steps := _steps
	cancel()
	island.place_building(id, cell, steps)
	building_placed.emit()
	return true


func cancel() -> void:
	_show_hidden_building()
	if _preview:
		_preview.queue_free()
		_preview = null
	if _overlay:
		_overlay.queue_free()
		_overlay = null
	if active:
		active = false
		_marker.visible = false
		placement_changed.emit(false, false, false)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.index == 0:
			_handle_press(touch.pressed, touch.position)
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT:
			_handle_press(button.pressed, button.position)


func _handle_press(pressed: bool, screen_pos: Vector2) -> void:
	if pressed:
		_press_position = screen_pos
	elif screen_pos.distance_to(_press_position) <= TAP_MAX_DISTANCE:
		var hit: Variant = _ground_point(screen_pos)
		if hit != null:
			var point: Vector3 = hit
			var c := Vector2i(roundi(point.x), roundi(point.z))
			if active:
				_move_to(c)
			else:
				cell_tapped.emit(c)


func _move_to(c: Vector2i) -> void:
	_show_hidden_building()
	_cell = c
	_steps = _preview.best_rotation(island, c, _steps)
	# Hide the ground under the preview so they don't overlap.
	_hidden_building = island.buildings.get(c) as Building
	if _hidden_building:
		_hidden_building.visible = false
	_update()


func _update() -> void:
	_valid = _preview.can_place(island, _cell, _steps)
	var pos := GridUtil.cell_to_world(_cell)
	_preview.position = pos
	_preview.set_rotation_steps(_steps)
	_marker.position = pos + Vector3.UP * 0.05
	_marker.material_override = _valid_material if _valid else _invalid_material
	if _overlay:
		_overlay.position = pos + Vector3.UP * 0.02
	placement_changed.emit(true, _valid, _preview.rotatable)


func _show_hidden_building() -> void:
	if is_instance_valid(_hidden_building):
		_hidden_building.visible = true
	_hidden_building = null


func _cell_at_screen_center() -> Vector2i:
	var hit: Variant = _ground_point(get_viewport().get_visible_rect().size / 2.0)
	if hit == null:
		return island.rail_path[0]
	var point: Vector3 = hit
	return _nearest_buildable(Vector2i(roundi(point.x), roundi(point.z)))


## Closest cell (by distance) where the preview building could go; falls back to `origin`.
func _nearest_buildable(origin: Vector2i) -> Vector2i:
	var best := origin
	var best_distance := INF
	for x in range(-4, 5):
		for y in range(-4, 5):
			var c := origin + Vector2i(x, y)
			var distance := Vector2(x, y).length()
			if distance < best_distance and _preview.can_place(island, c, _steps):
				best = c
				best_distance = distance
	return best


func _ground_point(screen_pos: Vector2) -> Variant:
	var origin := camera.project_ray_origin(screen_pos)
	var direction := camera.project_ray_normal(screen_pos)
	return Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)


func _make_marker_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material
