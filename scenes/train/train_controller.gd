class_name TrainController
extends Node
## Runs one round: spawns the round's trains at the open rail end and moves them
## step by step to the power station. After every step the island's buildings get
## on_train_step() (mines load trains there).

signal round_finished

## Train code (see GameRules.levels) -> scene
const TRAIN_SCENES := {
	"s": preload("res://scenes/train/train.tscn"),
	"b": preload("res://scenes/train/train_big.tscn"),
}

@export var island: Island

var running := false


## `train_codes`: one character per train in spawn order, e.g. "ssb".
func run_round(train_codes: String) -> void:
	if running:
		return
	running = true
	Events.round_started.emit(GameState.round_index + 1, train_codes)
	var step := GameState.rules.step_duration
	var path := island.rail_path
	var trains: Array[Train] = []
	var to_spawn: Array[String] = []
	for code in train_codes:
		to_spawn.append(code)

	while not to_spawn.is_empty() or not trains.is_empty():
		for train in trains:
			train.path_index -= 1
			train.move_to(path[train.path_index], step * 0.9)
		if not to_spawn.is_empty():
			trains.append(_spawn(to_spawn.pop_front(), path))
		await get_tree().create_timer(step, false).timeout

		for arrived in trains.duplicate():
			if arrived.path_index == 0:
				island.power_station.receive(arrived)
				trains.erase(arrived)
				arrived.queue_free()
		island.notify_train_step(trains)
		Events.train_step.emit(trains)
		await get_tree().create_timer(step * 0.3, false).timeout

	running = false
	round_finished.emit()


func _spawn(code: String, path: Array[Vector2i]) -> Train:
	var scene: PackedScene = TRAIN_SCENES.get(code, TRAIN_SCENES["s"])
	var train := scene.instantiate() as Train
	train.path_index = path.size() - 1
	train.place_at(path[train.path_index])
	island.add_child(train)
	return train
