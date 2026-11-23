class_name ShopBar
extends HBoxContainer
## One button per shop tool (GameRules.shop, e.g. bomb and bridge), paid with coins.

signal tool_pressed(card_id: String)

## While true (trains running) every button is disabled.
var locked := false:
	set(value):
		locked = value
		_refresh()

var _buttons := {}  # card id -> Button


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	for card_id in GameState.rules.shop:
		var def := CardShape.definition(card_id)
		var button := UiKit.button("%s · %d Münzen" % [def.get("name", card_id), int(def.get("coins", 0))],
			tool_pressed.emit.bind(card_id), 20, 52.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.icon = GameData.icon(CardShape.icon_id(card_id))
		button.expand_icon = true
		add_child(button)
		_buttons[card_id] = button
	GameState.coins_changed.connect(func(_v: int) -> void: _refresh())
	_refresh()


func _refresh() -> void:
	for card_id in _buttons:
		var cost := int(CardShape.definition(card_id).get("coins", 0))
		(_buttons[card_id] as Button).disabled = locked or GameState.coins < cost
