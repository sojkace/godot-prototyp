class_name OrdersPanel
extends PanelContainer
## Left side list: every factory's order (ore, delivered / wanted, rounds left), the
## stations' free trains and a short how-to.

var _column: VBoxContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	add_child(margin)
	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", 6)
	_column.custom_minimum_size = Vector2(250, 0)
	margin.add_child(_column)
	for signal_ref: Signal in [Events.round_ended, Events.order_done, Events.order_expired,
			Events.factory_appeared, GameState.actions_changed]:
		signal_ref.connect(_queue_refresh.unbind(1))
	Events.train_arrived.connect(_queue_refresh.unbind(2))
	refresh.call_deferred()


func _queue_refresh() -> void:
	refresh.call_deferred()


func refresh() -> void:
	var island := (get_tree().current_scene as Main).island if get_tree().current_scene is Main else null
	for child in _column.get_children():
		_column.remove_child(child)
		child.queue_free()
	_column.add_child(_title("Aufträge"))
	if island:
		for factory in island.factories:
			var row := HBoxContainer.new()
			row.add_child(UiKit.icon(GameData.icon(factory.ore), Vector2(28, 28)))
			var text := UiKit.label(17, "%s  %d/%d  ·  noch %d R" % [GameData.item_name(factory.ore),
				factory.delivered, factory.order_amount, factory.rounds_left])
			text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			if factory.rounds_left <= 1:
				text.modulate = Color(1, 0.55, 0.45)
			row.add_child(text)
			_column.add_child(row)
		_column.add_child(_title("Bahnhöfe"))
		for station in island.stations():
			_column.add_child(_line("Züge frei: %d/%d" % [station.trains_left, GameState.rules.trains_per_station]))
	_column.add_child(_title("So geht's"))
	for hint in ["Mine antippen: +%d Erz (1 Aktion)" % GameState.rules.mine_tap_amount,
			"Werkstatt antippen: Items holen (1 Aktion)",
			"Schiene antippen: Zug losschicken (1 Aktion)",
			"Bahnhof antippen: Reichweite zeigen",
			"Züge laden an Minen entlang der Strecke",
			"Karten kosten Items, Aufträge geben Münzen"]:
		var label := _line(hint)
		label.add_theme_font_size_override("font_size", 14)
		label.modulate = Color(0.85, 0.88, 0.95)
		_column.add_child(label)


func _title(text: String) -> Label:
	var label := UiKit.label(19, text)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.modulate = Color(1.0, 0.86, 0.35)
	return label


func _line(text: String) -> Label:
	var label := UiKit.label(16, text)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
