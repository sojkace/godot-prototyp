class_name TrainController
extends Node
## Runs one round: spawns the round's trains at the open rail end and moves them
## step by step to the power station. After every step each mine loads one train.

signal round_finished

## Train code (see GameData.LEVELS) -> scene
const TRAIN_SCENES := {
	"s": preload("res://scenes/train/train.tscn"),
	"b": preload("res://scenes/train/train_big.tscn"),
}

@export var island: Island
## Seconds per rail step.
@export var step_duration := 0.6

var running := false


## `train_codes`: one character per train in spawn order, e.g. "ssb".
func run_round(train_codes: String) -> void:
	if running:
		return
	running = true
	var path := island.rail_path
	var trains: Array[Train] = []
	var to_spawn: Array[String] = []
	for code in train_codes:
		to_spawn.append(code)

	while not to_spawn.is_empty() or not trains.is_empty():
		for train in trains:
			train.path_index -= 1
			train.move_to(GridUtil.cell_to_world(path[train.path_index]), step_duration * 0.9)
		if not to_spawn.is_empty():
			var scene: PackedScene = TRAIN_SCENES.get(to_spawn.pop_front(), TRAIN_SCENES["s"])
			var new_train := scene.instantiate() as Train
			new_train.path_index = path.size() - 1
			new_train.position = GridUtil.cell_to_world(path[new_train.path_index])
			island.add_child(new_train)
			trains.append(new_train)
		await get_tree().create_timer(step_duration, false).timeout

		for arrived in trains.duplicate():
			if arrived.path_index == 0:
				island.power_station.receive(arrived)
				trains.erase(arrived)
				arrived.queue_free()
		_distribute(trains)
		await get_tree().create_timer(step_duration * 0.3, false).timeout

	running = false
	round_finished.emit()


## Every mine gives one item to a non-full train inside its area: a random one,
## or - if an observer watches the mine - the train closest to being full.
func _distribute(trains: Array[Train]) -> void:
	var path := island.rail_path
	for mine in island.mines:
		var candidates: Array[Train] = []
		for train in trains:
			if not train.is_full() and mine.covers(path[train.path_index]):
				candidates.append(train)
		if not candidates.is_empty():
			var chosen: Train = candidates.pick_random()
			if island.is_observed(mine.cell):
				candidates.sort_custom(func(a: Train, b: Train) -> bool: return a.load_count > b.load_count)
				chosen = candidates[0]
			chosen.add_load()
			mine.play_give()
