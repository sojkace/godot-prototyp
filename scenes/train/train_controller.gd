class_name TrainController
extends Node
## Drives all trains sent this round at the same time, one cell per step, until each one
## reached its factory. After every step the island's buildings get on_train_step()
## (mines load trains there); trains at the end of their route deliver.

signal round_finished

const TRAIN_SCENE := preload("res://scenes/train/train.tscn")

@export var island: Island

var running := false


## A new train on `route` towards `factory`, standing still until the round starts.
func make_train(route: Array[Vector2i], factory: Factory) -> Train:
	var train := TRAIN_SCENE.instantiate() as Train
	island.add_child(train)
	train.setup(route, factory)
	return train


func run_round(trains: Array[Train]) -> void:
	if running:
		return
	running = true
	Events.round_started.emit(GameState.round_index + 1)
	var step := GameState.rules.step_duration
	var moving := trains.duplicate()
	_after_step(moving)
	while not moving.is_empty():
		for train: Train in moving:
			train.advance(step * 0.9)
		await get_tree().create_timer(step, false).timeout
		_after_step(moving)
	await get_tree().create_timer(step * 0.5, false).timeout
	running = false
	round_finished.emit()


func _after_step(moving: Array) -> void:
	var typed: Array[Train] = []
	typed.assign(moving)
	island.notify_train_step(typed)
	Events.train_step.emit(typed)
	for train: Train in moving.duplicate():
		if train.at_end():
			if is_instance_valid(train.factory):
				train.factory.receive(train)
				Events.train_arrived.emit(train, train.factory)
			moving.erase(train)
			train.queue_free()
