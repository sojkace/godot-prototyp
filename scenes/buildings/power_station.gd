class_name PowerStation
extends Building
## End of the line: a full train pays coins (1 per 4 loads), any other train costs one heart.

@onready var _coin: Node3D = $Coin
@onready var _heart: Node3D = $HeartBroken


func _ready() -> void:
	_coin.hide()
	_heart.hide()


func receive(train: Train) -> void:
	if train.is_full():
		GameState.coins += maxi(1, train.capacity / 4)
		_pop(_coin)
	else:
		GameState.hearts -= 1
		_pop(_heart)


func _pop(part: Node3D) -> void:
	part.show()
	part.position = Vector3(0.0, 0.5, 0.0)
	part.rotation = Vector3(PI / 2.0, 0.0, 0.0)  # models lie flat, stand them up
	var tween := create_tween().set_parallel()
	tween.tween_property(part, "position:y", 1.4, 0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(part, "rotation:y", TAU, 0.9)
	tween.chain().tween_callback(part.hide)
