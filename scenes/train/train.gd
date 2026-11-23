class_name Train
extends Node3D
## A wagon sent from a station: it drives its `route` (rail cells) to `factory`, takes ore
## of the factory's kind from mines it passes and delivers it there. Then it is gone
## (back at its station for the next round).

@export var capacity := 4

var load_count := 0
## Rail cells from the start to the last cell before the factory.
var route: Array[Vector2i] = []
var path_index := 0
var factory: Factory
## Ore this train collects (= factory.ore).
var cargo := ""

@onready var _stages: Array[Node] = $Stages.get_children()


func _ready() -> void:
	_update_model()


func setup(new_route: Array[Vector2i], target: Factory) -> void:
	route = new_route
	factory = target
	cargo = target.ore
	path_index = 0
	place_at(route[0])
	_face(_next_dir())


## Grid cell the train stands on (logically, even while its tween still runs).
func cell() -> Vector2i:
	return route[path_index]


func is_full() -> bool:
	return load_count >= capacity


func space() -> int:
	return capacity - load_count


func at_end() -> bool:
	return path_index >= route.size() - 1


func add_load(amount := 1) -> void:
	load_count = mini(load_count + amount, capacity)
	_update_model()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.2, 0.8, 1.2), 0.08)
	tween.tween_property(self, "scale", Vector3.ONE, 0.15)


## Moves one cell along the route.
func advance(duration: float) -> void:
	if at_end():
		return
	_face(_next_dir())
	path_index += 1
	var tween := create_tween()
	tween.tween_property(self, "position", GridUtil.cell_to_world(cell()), duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func place_at(target: Vector2i) -> void:
	position = GridUtil.cell_to_world(target)


func _next_dir() -> int:
	if at_end():
		return GridUtil.dir_between(cell(), factory.cell) if factory else 0
	return GridUtil.dir_between(cell(), route[path_index + 1])


## Turns the model towards a grid direction (models face north = -Z).
func _face(dir: int) -> void:
	if dir >= 0:
		rotation.y = dir * PI / 2.0


## Shows the model stage that matches the current load (train_1_0 ... train_1_4).
func _update_model() -> void:
	var visible_stage := mini(load_count, _stages.size() - 1)
	for i in _stages.size():
		(_stages[i] as Node3D).visible = i == visible_stage
