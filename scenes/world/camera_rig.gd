extends Node3D
## Angled top-down camera. Drag to pan, mouse wheel / pinch / trackpad to zoom.
## Works with mouse (desktop) and touch (mobile). Touch-emulated mouse events are ignored
## so a finger drag is not handled twice.

@export var min_distance := 5.0
@export var max_distance := 22.0
@export var wheel_zoom_factor := 1.1
## Allowed area for the rig's position on the XZ plane.
@export var pan_bounds := Rect2(-10.0, -10.0, 23.0, 22.0)

@onready var _camera: Camera3D = $Pitch/Camera3D

var _touches := {}  # touch index -> Vector2 screen position
var _mouse_dragging := false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touches[touch.index] = touch.position
		else:
			_touches.erase(touch.index)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event as InputEventScreenDrag)
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
		var button := event as InputEventMouseButton
		match button.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_zoom(1.0 / wheel_zoom_factor)
			MOUSE_BUTTON_WHEEL_DOWN:
				_zoom(wheel_zoom_factor)
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
				_mouse_dragging = button.pressed
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		var motion := event as InputEventMouseMotion
		if _mouse_dragging:
			_pan(motion.position - motion.relative, motion.position)
	elif event is InputEventMagnifyGesture:
		_zoom(1.0 / (event as InputEventMagnifyGesture).factor)


func _handle_touch_drag(drag: InputEventScreenDrag) -> void:
	var previous: Vector2 = _touches.get(drag.index, drag.position - drag.relative)
	if _touches.size() == 1:
		_pan(previous, drag.position)
	elif _touches.size() == 2:
		for other_index in _touches:
			if other_index != drag.index:
				var other: Vector2 = _touches[other_index]
				var new_distance := drag.position.distance_to(other)
				if new_distance > 1.0:
					_zoom(previous.distance_to(other) / new_distance)
	_touches[drag.index] = drag.position


func _zoom(factor: float) -> void:
	_camera.position.z = clampf(_camera.position.z * factor, min_distance, max_distance)


## Moves the rig so the ground point under `from` ends up under `to`.
func _pan(from: Vector2, to: Vector2) -> void:
	var a: Variant = _ground_point(from)
	var b: Variant = _ground_point(to)
	if a == null or b == null:
		return
	var delta: Vector3 = a - b
	position.x = clampf(position.x + delta.x, pan_bounds.position.x, pan_bounds.end.x)
	position.z = clampf(position.z + delta.z, pan_bounds.position.y, pan_bounds.end.y)


func _ground_point(screen_pos: Vector2) -> Variant:
	var origin := _camera.project_ray_origin(screen_pos)
	var direction := _camera.project_ray_normal(screen_pos)
	return Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)
