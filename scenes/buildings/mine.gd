class_name Mine
extends Building
## Holds ore (`stock`). Tapping it (one action) digs GameRules.mine_tap_amount more; an
## automated mine (conveyor card) digs by itself every round. Trains heading to a factory of
## the same ore take ore when they pass through the mine's area.

## Ore this mine produces; factories with the same ore want it.
@export var ore := "gold"
## How far the optional "PopPart" child moves up when the mine gives an item.
@export var pop_height := 0.9

@onready var _pop_part: Node3D = get_node_or_null("PopPart")
@onready var _model: Node3D = $Model
var _pop_rest_y := 0.0
var stock := 0


func _ready() -> void:
	if _pop_part:
		_pop_rest_y = _pop_part.position.y
	_update_info()


func capacity() -> int:
	return GameState.rules.mine_capacity


func is_full() -> bool:
	return stock >= capacity()


func tap_costs_action() -> bool:
	return not is_full()


func on_tapped() -> void:
	dig()


func can_automate() -> bool:
	return true


func dig() -> void:
	if is_full():
		return
	stock = mini(stock + GameState.rules.mine_tap_amount, capacity())
	play_give()
	_update_info()


func on_round_end() -> void:
	if automated:
		dig()


func on_train_step(trains: Array[Train]) -> void:
	var gave := false
	for train in trains:
		if stock <= 0:
			break
		if train.cargo != ore or train.is_full() or not covers(train.cell()):
			continue
		var amount := mini(mini(GameState.rules.loads_per_mine_step, stock), train.space())
		train.add_load(amount)
		stock -= amount
		gave = true
	if gave:
		play_give()
		_update_info()


func _update_info() -> void:
	set_info("%d/%d" % [stock, capacity()], Color(1.0, 0.85, 0.3) if ore == "gold" else Color(0.85, 0.9, 1.0))
	if is_inside_tree() and not is_preview:
		var target := -0.12 if stock == 0 else 0.0
		if not is_equal_approx(_model.position.y, target):
			create_tween().tween_property(_model, "position:y", target, 0.3)


func play_give() -> void:
	if not is_inside_tree():
		return
	var tween := create_tween()
	if _pop_part:
		tween.tween_property(_pop_part, "position:y", _pop_rest_y + pop_height, 0.15) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(_pop_part, "position:y", _pop_rest_y, 0.3)
	else:
		tween.tween_property(_model, "scale", Vector3(1.0, 1.08, 1.0), 0.08)
		tween.tween_property(_model, "scale", Vector3.ONE, 0.2)
