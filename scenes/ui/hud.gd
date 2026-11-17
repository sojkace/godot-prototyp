class_name Hud
extends CanvasLayer
## Top bar (coins, hearts, round), inventory, card decks, placement controls,
## start button, delivery toast and game-over panel.

signal start_pressed
signal restart_pressed
signal card_pressed(deck_id: String)
signal discard_pressed(deck_id: String)
signal rotate_pressed
signal confirm_pressed
signal cancel_pressed
signal menu_pressed

const CARD_SIZE := Vector2(0, 230)
const COST_ICON_SIZE := Vector2(40, 40)

@onready var _coins_label: Label = %CoinsLabel
@onready var _hearts_label: Label = %HeartsLabel
@onready var _round_label: Label = %RoundLabel
@onready var _inventory_row: HBoxContainer = %InventoryRow
@onready var _card_row: HBoxContainer = %CardRow
@onready var _place_row: Control = %PlaceRow
@onready var _rotate_button: Button = %RotateButton
@onready var _confirm_button: Button = %ConfirmButton
@onready var _start_button: Button = %StartButton
@onready var _toast: Label = %Toast
@onready var _game_over_panel: Control = %GameOverPanel
@onready var _game_over_label: Label = %GameOverLabel

var _running := false
var _placing := false
var _item_labels := {}  # item id -> Label
var _cards := {}  # deck id -> {button, icon, name, count}
var _toast_tween: Tween

var _pause_panel: PanelContainer

# Marketplace window
var _market: Marketplace
var _selected_offer := -1
var _market_panel: PanelContainer
var _market_status: Label
var _offer_grid: GridContainer
var _give_row: HBoxContainer


func _ready() -> void:
	_build_inventory()
	_build_cards()
	_build_market_panel()
	_build_pause()
	# The HUD keeps working while the game is paused (pause menu).
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.coins_changed.connect(func(_v: int) -> void: _refresh())
	GameState.hearts_changed.connect(func(_v: int) -> void: _refresh())
	GameState.round_changed.connect(func(_v: int) -> void: _refresh())
	GameState.items_changed.connect(_refresh)
	GameState.items_changed.connect(_refresh_market)
	GameState.decks_changed.connect(_refresh)
	_start_button.pressed.connect(start_pressed.emit)
	%RestartButton.pressed.connect(restart_pressed.emit)
	_rotate_button.pressed.connect(rotate_pressed.emit)
	_confirm_button.pressed.connect(confirm_pressed.emit)
	%CancelButton.pressed.connect(cancel_pressed.emit)
	_game_over_panel.hide()
	_toast.modulate.a = 0.0
	_refresh()


func set_running(running: bool) -> void:
	_running = running
	_refresh()


func set_placement(active: bool, valid: bool, can_rotate: bool) -> void:
	_placing = active
	_confirm_button.disabled = not valid
	_rotate_button.disabled = not can_rotate
	_refresh()


## Short message in the middle of the screen, e.g. what the workshops delivered.
func show_toast(text: String) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.6)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


func show_delivery(items: Array[String]) -> void:
	if items.is_empty():
		return
	var names: Array[String] = []
	for item in items:
		names.append("+1 " + GameData.ITEM_NAMES[item])
	show_toast("Werkstatt liefert:\n" + ", ".join(names))


func show_game_over(won: bool) -> void:
	%Bottom.hide()
	_game_over_label.text = "Gewonnen! %d Münzen" % GameState.coins if won \
		else "Keine Herzen mehr.\n%d Münzen" % GameState.coins
	_game_over_panel.show()


func _refresh() -> void:
	_coins_label.text = "Münzen: %d" % GameState.coins
	_hearts_label.text = "Herzen: %d" % GameState.hearts
	_round_label.text = "Runde %d/%d · Züge: %d" % [
		GameState.round_index + 1, GameState.round_count(), GameState.trains_this_round().length()]
	for item in _item_labels:
		(_item_labels[item] as Label).text = str(GameState.item_count(item))
	for deck_id in _cards:
		_refresh_card(deck_id)

	_place_row.visible = _placing
	_card_row.visible = not _placing
	_start_button.visible = not _placing
	_start_button.disabled = _running
	_start_button.text = "Zug fährt …" if _running else "Zug starten"


func _refresh_card(deck_id: String) -> void:
	var card: Dictionary = _cards[deck_id]
	var top := GameState.top_card(deck_id)
	(card["icon"] as TextureRect).texture = GameData.icon(top) if top != "" else null
	(card["name"] as Label).text = GameData.BUILDING_NAMES.get(top, "–")
	(card["count"] as Label).text = "%s (%d)" % [GameData.DECKS[deck_id]["name"], GameState.cards_left(deck_id)]
	(card["button"] as Button).disabled = _running or not GameState.can_afford(deck_id)
	(card["discard"] as Button).disabled = _running or not GameState.can_discard(deck_id)


func _build_inventory() -> void:
	for item in GameData.ITEMS:
		var icon := TextureRect.new()
		icon.texture = GameData.icon(item)
		icon.custom_minimum_size = COST_ICON_SIZE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.tooltip_text = GameData.ITEM_NAMES[item]
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 26)
		label.custom_minimum_size = Vector2(36, 0)
		_inventory_row.add_child(icon)
		_inventory_row.add_child(label)
		_item_labels[item] = label


## One big button per deck showing its top card, name and cost, plus a discard button.
func _build_cards() -> void:
	for deck_id in GameData.DECK_ORDER:
		var deck_column := VBoxContainer.new()
		deck_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		deck_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var discard := Button.new()
		discard.text = "Ablegen (%d Münze)" % GameState.DISCARD_COST
		discard.add_theme_font_size_override("font_size", 18)
		discard.pressed.connect(discard_pressed.emit.bind(deck_id))

		var button := Button.new()
		button.custom_minimum_size = CARD_SIZE
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(card_pressed.emit.bind(deck_id))

		var column := VBoxContainer.new()
		column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		button.add_child(column)

		var deck_label := _make_label(18)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(0, 110)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var name_label := _make_label(26)

		var cost_row := HBoxContainer.new()
		cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
		cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for item in GameState.deck_cost(deck_id):
			var cost_icon := TextureRect.new()
			cost_icon.texture = GameData.icon(item)
			cost_icon.custom_minimum_size = Vector2(34, 34)
			cost_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			cost_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			cost_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cost_row.add_child(cost_icon)

		column.add_child(deck_label)
		column.add_child(icon)
		column.add_child(name_label)
		column.add_child(cost_row)
		deck_column.add_child(button)
		deck_column.add_child(discard)
		_card_row.add_child(deck_column)
		_cards[deck_id] = {
			"button": button, "discard": discard, "icon": icon, "name": name_label, "count": deck_label,
		}


func _make_label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


# --- Marketplace window ---

func open_market(market: Marketplace) -> void:
	if _market and _market.changed.is_connected(_refresh_market):
		_market.changed.disconnect(_refresh_market)
	_market = market
	_market.changed.connect(_refresh_market)
	_selected_offer = -1
	%Bottom.hide()
	_market_panel.show()
	_refresh_market()


func close_market() -> void:
	if _market and _market.changed.is_connected(_refresh_market):
		_market.changed.disconnect(_refresh_market)
	_market = null
	_market_panel.hide()
	if not _game_over_panel.visible:
		%Bottom.show()


func is_market_open() -> bool:
	return _market_panel.visible


func _build_market_panel() -> void:
	_market_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.15, 0.21, 0.97)
	style.set_corner_radius_all(14)
	_market_panel.add_theme_stylebox_override("panel", style)
	_market_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_market_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_market_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_market_panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	_market_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	var title := _make_label(28)
	title.text = "Marktplatz"
	column.add_child(title)

	var hint := _make_label(18)
	hint.text = "1. Ware wählen   2. tippen, was du dafür gibst"
	column.add_child(hint)

	_offer_grid = GridContainer.new()
	_offer_grid.columns = 3
	_offer_grid.add_theme_constant_override("h_separation", 10)
	_offer_grid.add_theme_constant_override("v_separation", 10)
	column.add_child(_offer_grid)

	var give_label := _make_label(20)
	give_label.text = "Du gibst:"
	column.add_child(give_label)
	_give_row = HBoxContainer.new()
	_give_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_give_row.add_theme_constant_override("separation", 10)
	column.add_child(_give_row)
	for item in GameData.ITEMS:
		var give_button := Button.new()
		give_button.icon = GameData.icon(item)
		give_button.expand_icon = true
		give_button.custom_minimum_size = Vector2(110, 80)
		give_button.add_theme_font_size_override("font_size", 22)
		give_button.set_meta("item", item)
		give_button.pressed.connect(_on_give_pressed.bind(item))
		_give_row.add_child(give_button)

	_market_status = _make_label(18)
	_market_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_market_status.custom_minimum_size = Vector2(420, 0)
	column.add_child(_market_status)

	var close := Button.new()
	close.text = "Schließen"
	close.custom_minimum_size = Vector2(0, 64)
	close.add_theme_font_size_override("font_size", 24)
	close.pressed.connect(close_market)
	column.add_child(close)
	_market_panel.hide()


func _refresh_market() -> void:
	if _market == null or not is_instance_valid(_market):
		return
	for child in _offer_grid.get_children():
		child.queue_free()
	for i in _market.offers.size():
		var item := _market.offers[i]
		var offer := Button.new()
		offer.toggle_mode = true
		offer.button_pressed = i == _selected_offer
		offer.icon = GameData.icon(item)
		offer.expand_icon = true
		offer.text = GameData.ITEM_NAMES[item]
		offer.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		offer.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		offer.custom_minimum_size = Vector2(140, 110)
		offer.add_theme_font_size_override("font_size", 20)
		offer.disabled = _market.used_this_round
		offer.pressed.connect(_on_offer_pressed.bind(i))
		_offer_grid.add_child(offer)
	for give_button: Button in _give_row.get_children():
		var item: String = give_button.get_meta("item")
		give_button.text = str(GameState.item_count(item))
		give_button.disabled = _selected_offer < 0 or not _market.can_trade(_selected_offer, item)
	if _market.used_this_round:
		_market_status.text = "Heute schon getauscht. Neue Waren in %d Runde(n)." % _market.rounds_until_refresh
	else:
		_market_status.text = "1 Tausch pro Runde. Neue Waren in %d Runde(n)." % _market.rounds_until_refresh


func _on_offer_pressed(index: int) -> void:
	_selected_offer = index if _selected_offer != index else -1
	_refresh_market()


func _on_give_pressed(item: String) -> void:
	if _market and _market.can_trade(_selected_offer, item):
		var got := GameData.ITEM_NAMES[_market.offers[_selected_offer]] as String
		_market.trade(_selected_offer, item)
		_selected_offer = -1
		show_toast("Getauscht: -1 %s, +1 %s" % [GameData.ITEM_NAMES[item], got])


# --- Pause menu ---

func _build_pause() -> void:
	var pause_button := Button.new()
	pause_button.text = " II "
	pause_button.add_theme_font_size_override("font_size", 22)
	pause_button.pressed.connect(set_paused.bind(true))
	%RoundLabel.get_parent().add_child(pause_button)

	_pause_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.15, 0.21, 0.97)
	style.set_corner_radius_all(14)
	_pause_panel.add_theme_stylebox_override("panel", style)
	_pause_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_pause_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_pause_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_pause_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	_pause_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(360, 0)
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	var title := _make_label(32)
	title.text = "Pause"
	column.add_child(title)
	column.add_child(_make_menu_button("Weiter", set_paused.bind(false)))
	column.add_child(_make_menu_button("Neu starten", restart_pressed.emit))
	column.add_child(_make_menu_button("Hauptmenü", menu_pressed.emit))
	_pause_panel.hide()

	# Game-over panel also gets a way back to the menu.
	%RestartButton.get_parent().add_child(_make_menu_button("Hauptmenü", menu_pressed.emit))


func set_paused(paused: bool) -> void:
	get_tree().paused = paused
	_pause_panel.visible = paused


func _make_menu_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 64)
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(callback)
	return button
