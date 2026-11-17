class_name Mine
extends Building
## Each train step, a mine loads one item into one train standing in its area.

enum AreaShape { SQUARE, CROSS }

## SQUARE = all 8 neighbours (gold mine), CROSS = the 4 direct neighbours (silver mine).
@export var area_shape := AreaShape.SQUARE
## How far the optional "PopPart" child moves up when the mine gives an item.
@export var pop_height := 0.9

@onready var _pop_part: Node3D = get_node_or_null("PopPart")
@onready var _model: Node3D = $Model
var _pop_rest_y := 0.0


func _ready() -> void:
	if _pop_part:
		_pop_rest_y = _pop_part.position.y


func area_offsets() -> Array[Vector2i]:
	return GridUtil.area_offsets("square" if area_shape == AreaShape.SQUARE else "cross")


func covers(target_cell: Vector2i) -> bool:
	return area_offsets().has(target_cell - cell)


func play_give() -> void:
	var tween := create_tween()
	if _pop_part:
		tween.tween_property(_pop_part, "position:y", _pop_rest_y + pop_height, 0.15) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(_pop_part, "position:y", _pop_rest_y, 0.3)
	else:
		tween.tween_property(_model, "scale", Vector3(1.0, 1.08, 1.0), 0.08)
		tween.tween_property(_model, "scale", Vector3.ONE, 0.2)
