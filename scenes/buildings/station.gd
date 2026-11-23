class_name Station
extends Building
## Train depot. It is not connected to the rails: the player puts one of its trains on any
## rail cell inside its area (one action each). Trains come back after delivering, so every
## train can be sent once per round.

var trains_left := 0
var _range_marks: Node3D


func _ready() -> void:
	trains_left = GameState.rules.trains_per_station
	_update_info()


func can_send() -> bool:
	return trains_left > 0


func take_train() -> void:
	trains_left -= 1
	_update_info()


func on_round_end() -> void:
	trains_left = GameState.rules.trains_per_station
	_update_info()


## Tapping shows / hides the cells where this station may put trains (free, no action).
func on_tapped() -> void:
	if _range_marks:
		_range_marks.queue_free()
		_range_marks = null
		return
	_range_marks = Node3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.9, 0.03, 0.9)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.7, 1.0, 0.35)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = material
	for offset in area_offsets():
		if not island.is_land(cell + offset):
			continue
		var mark := MeshInstance3D.new()
		mark.mesh = mesh
		mark.position = GridUtil.cell_to_world(cell + offset) + Vector3.UP * 0.06
		_range_marks.add_child(mark)
	island.add_child(_range_marks)


func _update_info() -> void:
	set_info("Züge %d/%d" % [trains_left, GameState.rules.trains_per_station])
