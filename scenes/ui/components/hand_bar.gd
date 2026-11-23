class_name HandBar
extends HBoxContainer
## The playable cards: the hand plus the reserve. Each card shows icon, shape sketch, name
## and item cost; below it "Behalten" (move to the reserve) and "Neu" (swap for coins).

signal card_pressed(slot: int)
signal reserve_pressed(slot: int)
signal discard_pressed(slot: int)

const CARD_SIZE := Vector2(150, 170)
const COST_ICON_SIZE := Vector2(26, 26)

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
	GameState.items_changed.connect(_queue_rebuild)
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
	var cards := GameState.playable_cards()
	for slot in cards.size():
		add_child(_make_card(slot, cards[slot]))
	if cards.is_empty():
		add_child(UiKit.label(18, "Keine Karten auf der Hand"))


func _make_card(slot: int, card_id: String) -> Control:
	var reserved := GameState.is_reserved_slot(slot)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)

	var button := Button.new()
	button.custom_minimum_size = CARD_SIZE
	button.disabled = locked or not GameState.can_pay(card_id)
	button.pressed.connect(card_pressed.emit.bind(slot))
	button.tooltip_text = _tooltip(card_id)
	if reserved:
		button.modulate = Color(1.0, 0.92, 0.7)
	var inner := VBoxContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	button.add_child(inner)

	if reserved:
		inner.add_child(UiKit.label(14, "Reserviert"))
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
	inner.add_child(cost_row(GameState.card_cost(card_id), COST_ICON_SIZE))
	column.add_child(button)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	if not reserved:
		var keep := UiKit.button("Behalten", reserve_pressed.emit.bind(slot), 14, 32.0)
		keep.disabled = locked or not GameState.can_reserve(slot)
		keep.tooltip_text = "In die Reserve legen: bleibt für die nächste Runde"
		keep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(keep)
	var redraw := UiKit.button("Neu (%d)" % GameState.rules.discard_cost, discard_pressed.emit.bind(slot), 14, 32.0)
	redraw.disabled = locked or not GameState.can_discard(slot)
	redraw.tooltip_text = "Wegwerfen und neu ziehen, kostet %d Münze" % GameState.rules.discard_cost
	redraw.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(redraw)
	column.add_child(row)
	return column


## Icons with counts for an item cost, "gratis" if empty.
static func cost_row(cost: Dictionary, icon_size: Vector2) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if cost.is_empty():
		row.add_child(UiKit.label(15, "gratis"))
	for item in cost:
		if int(cost[item]) > 1:
			row.add_child(UiKit.label(16, "%d×" % int(cost[item])))
		var item_icon := UiKit.icon(GameData.icon(item), icon_size)
		row.add_child(item_icon)
	return row


static func _tooltip(card_id: String) -> String:
	var def := CardShape.definition(card_id)
	if CardShape.is_upgrade(def):
		var names: Array[String] = []
		for id in def.get("targets", []):
			names.append(GameData.building_name(id))
		return "Automatisiert: %s" % ", ".join(names)
	if def.get("curse", false):
		return "Fluchkarte aus einem verpassten Auftrag (gratis, aber sie verstopft das Deck)"
	return CardShape.card_name(card_id)
