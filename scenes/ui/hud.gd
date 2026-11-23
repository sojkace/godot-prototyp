class_name Hud
extends CanvasLayer
## Landscape screen layout (built in code) and coordinator of the UI components:
##   top bar (coins, actions, research points, round, Deck / Forschung / pause),
##   OrdersPanel (left), HandBar + ShopBar + "Runde beenden" (bottom), placement row,
##   toast, DeckPanel, ResearchPanel, PauseMenu.
## The HUD never changes game state itself; it only emits signals that main.gd handles.

signal end_round_pressed
signal restart_pressed
signal menu_pressed
signal card_pressed(slot: int)
signal discard_pressed(slot: int)
signal tool_pressed(card_id: String)
signal rotate_pressed
signal confirm_pressed
signal cancel_pressed
signal research_pressed(index: int)
signal swap_pressed(out_card: String, in_card: String)

var _running := false
var _placing := false
var _toast_tween: Tween
var _coins_label: Label
var _actions_label: Label
var _research_button: Button
var _round_label: Label
var _bottom: Control
var _hand_bar: HandBar
var _shop_bar: ShopBar
var _end_button: Button
var _place_row: HBoxContainer
var _rotate_button: Button
var _confirm_button: Button
var _orders: OrdersPanel
var _toast: Label
var _deck_panel: DeckPanel
var _research_panel: ResearchPanel
var _pause_menu: PauseMenu


func _ready() -> void:
	# The HUD keeps working while the game is paused (pause menu).
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_top_bar(root)
	_build_bottom(root)

	_orders = OrdersPanel.new()
	_orders.position = Vector2(10, 66)
	root.add_child(_orders)

	_toast = UiKit.label(26)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.position.y = 90
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.add_theme_constant_override("outline_size", 8)
	_toast.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1))
	_toast.modulate.a = 0.0
	root.add_child(_toast)

	_deck_panel = DeckPanel.new()
	add_child(_deck_panel)
	_deck_panel.swap_requested.connect(swap_pressed.emit)
	_deck_panel.visibility_changed.connect(_on_dialog_closed)
	_research_panel = ResearchPanel.new()
	add_child(_research_panel)
	_research_panel.research_requested.connect(research_pressed.emit)
	_research_panel.visibility_changed.connect(_on_dialog_closed)
	_pause_menu = PauseMenu.new()
	add_child(_pause_menu)
	_pause_menu.restart_pressed.connect(restart_pressed.emit)
	_pause_menu.menu_pressed.connect(menu_pressed.emit)

	GameState.coins_changed.connect(_refresh.unbind(1))
	GameState.actions_changed.connect(_refresh.unbind(1))
	GameState.round_changed.connect(_refresh.unbind(1))
	GameState.research_changed.connect(_refresh)
	GameState.milestone_reached.connect(func(m: Dictionary) -> void:
		show_toast("Meilenstein: %s\n+%d Forschungspunkte" % [m["name"], int(m["points"])]))
	Events.message.connect(show_toast)
	Events.order_done.connect(func(f: Factory) -> void:
		show_toast("Auftrag erfüllt: %s" % GameData.item_name(f.ore)))
	Events.order_expired.connect(func(f: Factory) -> void:
		show_toast("Auftrag verpasst (%s)\nEine Fluchkarte kommt ins Deck" % GameData.item_name(f.ore)))
	Events.factory_appeared.connect(func(f: Factory) -> void:
		if f.factory_index > 0:
			show_toast("Neue Fabrik: %s" % GameData.item_name(f.ore)))
	_refresh()


func _build_top_bar(root: Control) -> void:
	var bar := PanelContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 56
	root.add_child(bar)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	bar.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	margin.add_child(row)
	_coins_label = UiKit.label(22)
	row.add_child(_coins_label)
	_actions_label = UiKit.label(22)
	row.add_child(_actions_label)
	_round_label = UiKit.label(22)
	_round_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_round_label)
	row.add_child(UiKit.button("Deck", open_panel.bind("deck"), 20, 44.0))
	_research_button = UiKit.button("Forschung", open_panel.bind("research"), 20, 44.0)
	row.add_child(_research_button)
	row.add_child(UiKit.button(" II ", func() -> void: _pause_menu.set_paused(true), 20, 44.0))


func _build_bottom(root: Control) -> void:
	_bottom = MarginContainer.new()
	_bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom.offset_top = -232
	_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "bottom"]:
		_bottom.add_theme_constant_override("margin_" + side, 12)
	root.add_child(_bottom)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 16)
	_bottom.add_child(row)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)
	_hand_bar = HandBar.new()
	_hand_bar.size_flags_vertical = Control.SIZE_SHRINK_END
	_hand_bar.card_pressed.connect(card_pressed.emit)
	_hand_bar.discard_pressed.connect(discard_pressed.emit)
	row.add_child(_hand_bar)

	_place_row = HBoxContainer.new()
	_place_row.size_flags_vertical = Control.SIZE_SHRINK_END
	_place_row.add_theme_constant_override("separation", 10)
	_rotate_button = UiKit.button("Drehen", rotate_pressed.emit, 24, 64.0)
	_confirm_button = UiKit.button("Bauen", confirm_pressed.emit, 24, 64.0)
	for button in [_rotate_button, _confirm_button, UiKit.button("Abbrechen", cancel_pressed.emit, 24, 64.0)]:
		button.custom_minimum_size.x = 170
		_place_row.add_child(button)
	row.add_child(_place_row)

	var side := VBoxContainer.new()
	side.size_flags_vertical = Control.SIZE_SHRINK_END
	side.add_theme_constant_override("separation", 10)
	_shop_bar = ShopBar.new()
	_shop_bar.tool_pressed.connect(tool_pressed.emit)
	side.add_child(_shop_bar)
	_end_button = UiKit.button("Runde beenden", end_round_pressed.emit, 26, 80.0)
	side.add_child(_end_button)
	row.add_child(side)


func set_running(running: bool) -> void:
	_running = running
	_hand_bar.locked = running
	_shop_bar.locked = running
	_refresh()


func set_placement(active: bool, valid: bool, can_rotate: bool) -> void:
	_placing = active
	_confirm_button.disabled = not valid
	_rotate_button.disabled = not can_rotate
	_refresh()


## Short message in the upper middle of the screen.
func show_toast(text: String) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


## "deck" or "research".
func open_panel(panel_name: String) -> void:
	if _running:
		return
	cancel_pressed.emit()
	_bottom.hide()
	match panel_name:
		"deck":
			_deck_panel.open()
		"research":
			_research_panel.open()


func _on_dialog_closed() -> void:
	if not _deck_panel.visible and not _research_panel.visible:
		_bottom.show()


func _refresh() -> void:
	if _coins_label == null:
		return
	_coins_label.text = "Münzen %d" % GameState.coins
	_actions_label.text = "Aktionen %d/%d" % [GameState.actions, GameState.max_actions()]
	_actions_label.modulate = Color(1, 0.6, 0.5) if GameState.actions == 0 else Color.WHITE
	_research_button.text = "Forschung (%d)" % GameState.research_points
	_round_label.text = "Runde %d" % (GameState.round_index + 1)
	_place_row.visible = _placing
	_hand_bar.visible = not _placing
	_shop_bar.visible = not _placing
	_end_button.visible = not _placing
	_end_button.disabled = _running
	_end_button.text = "Züge fahren …" if _running else "Runde beenden"
