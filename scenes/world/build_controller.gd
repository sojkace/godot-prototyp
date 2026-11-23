class_name BuildController
extends Node3D
## Placement mode for one card: shows a ghost of every cell of the card's piece
## (CardShape), tap a cell to move it (rails stay at the open end), "Drehen" turns it
## (rails: the whole block, see CardShape.rail_variants), then Main confirms or cancels.
## Shop tools (bomb, bridge) use the same preview on a single cell. Green/red markers show if the spot is
## valid (PlacementRules). Placing and paying is done by Main, not here.
## Also reports taps on the island while not placing (cell_tapped).

signal placement_changed(active: bool, valid: bool, can_rotate: bool)
## Tap on a cell while not placing (collect items, open the marketplace ...).
signal cell_tapped(cell: Vector2i)

## Max finger/mouse movement (px) that still counts as a tap and not a camera drag.
const TAP_MAX_DISTANCE := 14.0

@export var island: Island
@export var camera: Camera3D

var active := false

var _card_def := {}
var _rail := false
var _anchor := Vector2i.ZERO
var _steps := 0
var _valid := false
var _layout: Array[Dictionary] = []
## One ghost building / marker / optional range overlay per layout entry.
var _ghosts: Array[Building] = []
var _markers: Array[MeshInstance3D] = []
var _overlays: Array[Node3D] = []
var _hidden: Array[Building] = []
var _valid_material: StandardMaterial3D
var _invalid_material: StandardMaterial3D
var _press_position := Vector2.ZERO


func _ready() -> void:
	_valid_material = _make_marker_material(Color(0.2, 0.9, 0.3, 0.5))
	_invalid_material = _make_marker_material(Color(0.95, 0.2, 0.2, 0.5))


func start(card_id: String) -> void:
	cancel()
	_card_def = CardShape.definition(card_id)
	_rail = CardShape.is_rail(_card_def)
	_steps = 0
	_anchor = island.open_end_cell()
	_layout = CardShape.layout(_card_def, island, _anchor, _steps)
	var marker_mesh := BoxMesh.new()
	marker_mesh.size = Vector3(1.0, 0.04, 1.0)
	for entry in _layout:
		_ghosts.append(_make_ghost(entry["id"]))
		var marker := MeshInstance3D.new()
		marker.mesh = marker_mesh
		add_child(marker)
		_markers.append(marker)
		var overlay_scene := GameData.area_overlay(_ghosts[-1].area_shape)
		var overlay: Node3D = overlay_scene.instantiate() if overlay_scene else null
		if overlay:
			add_child(overlay)
		_overlays.append(overlay)
	active = true
	_start_at_best_spot(card_id)


## The current layout if it is valid, otherwise an empty list.
func valid_layout() -> Array[Dictionary]:
	return _layout.duplicate() if active and _valid else ([] as Array[Dictionary])


## Next rotation (rails: mirror). Prefers the next one that fits.
func rotate_preview() -> void:
	if not active or not CardShape.can_turn(_card_def):
		return
	var count := CardShape.step_count(_card_def)
	var next := (_steps + 1) % count
	for i in range(1, count):
		var candidate := (_steps + i) % count
		if _is_valid_at(_anchor, candidate):
			next = candidate
			break
	_steps = next
	_update()


func cancel() -> void:
	_show_hidden()
	var nodes: Array[Node] = []
	nodes.append_array(_ghosts)
	nodes.append_array(_markers)
	nodes.append_array(_overlays)
	for node in nodes:
		if node:
			node.queue_free()
	_ghosts.clear()
	_markers.clear()
	_overlays.clear()
	_layout.clear()
	if active:
		active = false
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
		if hit == null:
			return
		var point: Vector3 = hit
		var c := Vector2i(roundi(point.x), roundi(point.z))
		if not active:
			cell_tapped.emit(c)
		elif not _rail:
			_anchor = c
			_update()


## Starts on the valid spot closest to the screen center (any rotation), if there is one.
func _start_at_best_spot(card_id: String) -> void:
	if not _rail:
		var center := _cell_at_screen_center()
		_anchor = center
		var best_distance := INF
		for option in PlacementRules.options(island, card_id):
			var distance := Vector2(option["anchor"] - center).length()
			if distance < best_distance:
				best_distance = distance
				_anchor = option["anchor"]
				_steps = option["steps"]
	else:
		for steps in CardShape.step_count(_card_def):
			if _is_valid_at(_anchor, steps):
				_steps = steps
				break
	_update()


func _is_valid_at(anchor: Vector2i, steps: int) -> bool:
	return PlacementRules.is_valid(island, CardShape.layout(_card_def, island, anchor, steps), _rail)


func _update() -> void:
	_show_hidden()
	_layout = CardShape.layout(_card_def, island, _anchor, _steps)
	_valid = PlacementRules.is_valid(island, _layout, _rail)
	for i in _layout.size():
		var c: Vector2i = _layout[i]["cell"]
		var pos := GridUtil.cell_to_world(c)
		# Turned rail blocks can swap straight and curve pieces.
		if _ghosts[i].type_id() != _layout[i]["id"]:
			_ghosts[i].queue_free()
			_ghosts[i] = _make_ghost(_layout[i]["id"])
		_ghosts[i].position = pos
		_ghosts[i].set_rotation_steps(_layout[i]["steps"])
		_markers[i].position = pos + Vector3.UP * 0.02
		_markers[i].material_override = _valid_material if _valid else _invalid_material
		if _overlays[i]:
			_overlays[i].position = pos + Vector3.UP * 0.02
		# Hide the ground under the ghost so they don't overlap.
		var under := island.buildings.get(c) as Building
		if under:
			under.visible = false
			_hidden.append(under)
	placement_changed.emit(true, _valid, CardShape.can_turn(_card_def))


func _make_ghost(id: String) -> Building:
	var ghost := GameData.building_scene(id).instantiate() as Building
	ghost.is_preview = true
	add_child(ghost)
	return ghost


func _show_hidden() -> void:
	for building in _hidden:
		if is_instance_valid(building):
			building.visible = true
	_hidden.clear()


func _cell_at_screen_center() -> Vector2i:
	var hit: Variant = _ground_point(get_viewport().get_visible_rect().size / 2.0)
	if hit == null:
		return island.rail_path[0]
	var point: Vector3 = hit
	return Vector2i(roundi(point.x), roundi(point.z))


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
