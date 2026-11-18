class_name PowerStation
extends Building
## End of the line: a full train pays coins (capacity / loads_per_coin),
## any other train costs hearts (see GameRules).

@onready var _coin: Node3D = $Coin
@onready var _heart: Node3D = $HeartBroken


func _ready() -> void:
	_coin.hide()
	_heart.hide()


func receive(train: Train) -> void:
	var rules := GameState.rules
	var full := train.is_full()
	if full:
		GameState.coins += maxi(1, train.capacity / maxi(1, rules.loads_per_coin))
		_pop(_coin)
	else:
		GameState.hearts -= rules.hearts_per_missed_train
		_pop(_heart)
	Events.train_arrived.emit(train, full)


func _pop(part: Node3D) -> void:
	part.show()
	part.position = Vector3(0.0, 0.5, 0.0)
	part.rotation = Vector3(PI / 2.0, 0.0, 0.0)  # models lie flat, stand them up
	var tween := create_tween().set_parallel()
	tween.tween_property(part, "position:y", 1.4, 0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(part, "rotation:y", TAU, 0.9)
	tween.chain().tween_callback(part.hide)
