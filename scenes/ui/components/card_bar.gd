class_name CardBar
extends HBoxContainer
## One big button per deck showing its top card, name and cost, plus a discard button.
## Decks come from the active GameRules, so new decks show up automatically.

signal card_pressed(deck_id: String)
signal discard_pressed(deck_id: String)

const CARD_SIZE := Vector2(0, 230)
const COST_ICON_SIZE := Vector2(34, 34)

## While true (trains running) every button is disabled.
var locked := false:
	set(value):
		locked = value
		_refresh()

var _cards := {}  # deck id -> {button, discard, icon, name, count}


func _ready() -> void:
	for deck_id in GameState.deck_ids():
		_add_deck(deck_id)
	GameState.items_changed.connect(_refresh)
	GameState.decks_changed.connect(_refresh)
	GameState.coins_changed.connect(func(_v: int) -> void: _refresh())
	_refresh()


func _add_deck(deck_id: String) -> void:
	var deck_column := VBoxContainer.new()
	deck_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_column.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var button := Button.new()
	button.custom_minimum_size = CARD_SIZE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(card_pressed.emit.bind(deck_id))

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	button.add_child(column)

	var count_label := UiKit.label(18)
	var card_icon := UiKit.icon(null, Vector2(0, 110))
	var name_label := UiKit.label(26)
	var cost_row := HBoxContainer.new()
	cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for item in GameState.deck_cost(deck_id):
		cost_row.add_child(UiKit.icon(GameData.icon(item), COST_ICON_SIZE))
	column.add_child(count_label)
	column.add_child(card_icon)
	column.add_child(name_label)
	column.add_child(cost_row)

	var discard := UiKit.button("Ablegen (%d Münze)" % GameState.rules.discard_cost,
		discard_pressed.emit.bind(deck_id), 18, 0.0)

	deck_column.add_child(button)
	deck_column.add_child(discard)
	add_child(deck_column)
	_cards[deck_id] = {
		"button": button, "discard": discard, "icon": card_icon, "name": name_label, "count": count_label,
	}


func _refresh() -> void:
	for deck_id in _cards:
		var card: Dictionary = _cards[deck_id]
		var top := GameState.top_card(deck_id)
		(card["icon"] as TextureRect).texture = GameData.icon(top) if top != "" else null
		(card["name"] as Label).text = GameData.building_name(top) if top != "" else "–"
		(card["count"] as Label).text = "%s (%d)" % [GameState.deck_name(deck_id), GameState.cards_left(deck_id)]
		(card["button"] as Button).disabled = locked or not GameState.can_afford(deck_id)
		(card["discard"] as Button).disabled = locked or not GameState.can_discard(deck_id)
