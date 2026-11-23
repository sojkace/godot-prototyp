class_name Mine
extends Building
## After every train step the mine loads items into a non-full train standing in its area.
## Which train: a building that watches the mine (observer) may choose, otherwise random.
## GameRules.mine_loads_per_round limits the total per round (the mine looks empty then).

## How far the optional "PopPart" child moves up when the mine gives an item.
@export var pop_height := 0.9

@onready var _pop_part: Node3D = get_node_or_null("PopPart")
@onready var _model: Node3D = $Model
var _pop_rest_y := 0.0
## Items left this round (-1 = unlimited).
var loads_left := -1


func _ready() -> void:
	if _pop_part:
		_pop_rest_y = _pop_part.position.y
	_refill()


func on_round_end() -> void:
	_refill()


func is_empty() -> bool:
	return loads_left == 0


func on_train_step(trains: Array[Train]) -> void:
	var gave := false
	for i in GameState.rules.loads_per_mine_step:
		if is_empty():
			break
		var candidates: Array[Train] = []
		for train in trains:
			if not train.is_full() and covers(train.cell()):
				candidates.append(train)
		if candidates.is_empty():
			break
		_pick_train(candidates).add_load()
		gave = true
		if loads_left > 0:
			loads_left -= 1
	if gave:
		play_give()
	if is_empty():
		_set_dim(true)


func _refill() -> void:
	var limit := GameState.rules.mine_loads_per_round
	loads_left = limit if limit > 0 else -1
	_set_dim(false)


## Empty mines sink a little into the ground so the player sees they are used up.
func _set_dim(dim: bool) -> void:
	var target := -0.12 if dim else 0.0
	if is_inside_tree() and not is_equal_approx(_model.position.y, target):
		create_tween().tween_property(_model, "position:y", target, 0.3)


func _pick_train(candidates: Array[Train]) -> Train:
	for building: Building in island.buildings.values():
		var chosen := building.choose_train(self, candidates)
		if chosen:
			return chosen
	return candidates.pick_random()


func play_give() -> void:
	var tween := create_tween()
	if _pop_part:
		tween.tween_property(_pop_part, "position:y", _pop_rest_y + pop_height, 0.15) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(_pop_part, "position:y", _pop_rest_y, 0.3)
	else:
		tween.tween_property(_model, "scale", Vector3(1.0, 1.08, 1.0), 0.08)
		tween.tween_property(_model, "scale", Vector3.ONE, 0.2)
