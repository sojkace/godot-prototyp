class_name HandBar
extends HBoxContainer
## The hand. Each card shows icon, shape sketch and name; playing it costs one action.
## Below it "Neu" throws it away for coins and draws another one.

signal card_pressed(slot: int)
signal discard_pressed(slot: int)

const CARD_SIZE := Vector2(150, 170)

## While true (trains running) every button is disabled.
var locked := false:
	set(value):
		locked = value
		_queue_rebuild()

var _rebuild_queued := false


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameState.cards_changed.connect(_queue_rebuild)
	GameState.actions_changed.connect(_queue_rebuild.unbind(1))
	GameState.coins_changed.connect(_queue_rebuild.unbind(1))
	_rebuild()


## Rebuilds once at the end of the frame (several changes often come together, and a
## button must not be freed while its own pressed signal runs).
func _queue_rebuild() -> void:
	if not _rebuild_queued:
		_rebuild_queued = true
		_rebuild.call_deferred()


func _rebuild() -> void:
	_rebuild_queued = false
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var cards := GameState.hand
	for slot in cards.size():
		add_child(_make_card(slot, cards[slot]))
	if cards.is_empty():
		add_child(UiKit.label(18, "Keine Karten auf der Hand"))


func _make_card(slot: int, card_id: String) -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)

	var button := Button.new()
	button.custom_minimum_size = CARD_SIZE
	button.disabled = locked or GameState.actions <= 0
	button.pressed.connect(card_pressed.emit.bind(slot))
	button.tooltip_text = _tooltip(card_id)
	var inner := VBoxContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	button.add_child(inner)

	var visuals := HBoxContainer.new()
	visuals.alignment = BoxContainer.ALIGNMENT_CENTER
	visuals.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visuals.add_child(UiKit.icon(GameData.icon(CardShape.icon_id(card_id)), Vector2(56, 64)))
	var shape := ShapePreview.new()
	shape.custom_minimum_size = Vector2(56, 64)
	shape.card_id = card_id
	visuals.add_child(shape)
	inner.add_child(visuals)
	var name_label := UiKit.label(17, CardShape.card_name(card_id))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(name_label)
	column.add_child(button)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var redraw := UiKit.button("Neu (%d)" % GameState.rules.discard_cost, discard_pressed.emit.bind(slot), 14, 32.0)
	redraw.disabled = locked or not GameState.can_discard(slot)
	redraw.tooltip_text = "Wegwerfen und neu ziehen, kostet %d Münze" % GameState.rules.discard_cost
	redraw.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(redraw)
	column.add_child(row)
	return column


static func _tooltip(card_id: String) -> String:
	var def := CardShape.definition(card_id)
	if def.get("upgrade", "") == "halt":
		return "Auf eine Schiene legen: dort fährt jede Runde ein Zug los (ohne Aktion)"
	if CardShape.is_upgrade(def):
		var names: Array[String] = []
		for id in def.get("targets", []):
			names.append(GameData.building_name(id))
		return "Automatisiert: %s" % ", ".join(names)
	if def.get("curse", false):
		return "Fluchkarte aus einem verpassten Auftrag (verstopft Hand und Deck)"
	return CardShape.card_name(card_id)
