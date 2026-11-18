class_name Train
extends Node3D
## A wagon that drives along the rail path towards the power station and collects items.

@export var capacity := 4

var load_count := 0
## Index into Island.rail_path (0 = power station).
var path_index := 0
var _cell := Vector2i.ZERO

@onready var _stages: Array[Node] = $Stages.get_children()


func _ready() -> void:
	_update_model()


## Grid cell the train stands on (logically, even while its tween still runs).
func cell() -> Vector2i:
	return _cell


func is_full() -> bool:
	return load_count >= capacity


func add_load() -> void:
	if is_full():
		return
	load_count += 1
	_update_model()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.2, 0.8, 1.2), 0.08)
	tween.tween_property(self, "scale", Vector3.ONE, 0.15)


func place_at(target: Vector2i) -> void:
	_cell = target
	position = GridUtil.cell_to_world(target)


func move_to(target: Vector2i, duration: float) -> void:
	_cell = target
	var tween := create_tween()
	tween.tween_property(self, "position", GridUtil.cell_to_world(target), duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Shows the model stage that matches the current load (train_1_0 ... train_1_4).
func _update_model() -> void:
	var visible_stage := mini(load_count, _stages.size() - 1)
	for i in _stages.size():
		(_stages[i] as Node3D).visible = i == visible_stage
