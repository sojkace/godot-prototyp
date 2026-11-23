class_name Hud
extends CanvasLayer
## Screen layout and coordinator of the UI components:
##   top bar (coins, hearts, round, pause button), InventoryBar, CardBar, ShopBar, placement row,
##   start button, toast, MarketPanel, PauseMenu and game-over panel.
## The HUD never changes game state itself; it only emits signals that main.gd handles.

signal start_pressed
signal restart_pressed
signal card_pressed(deck_id: String)
signal discard_pressed(deck_id: String)
signal tool_pressed(card_id: String)
signal rotate_pressed
signal confirm_pressed
signal cancel_pressed
signal menu_pressed

@onready var _coins_label: Label = %CoinsLabel
@onready var _hearts_label: Label = %HeartsLabel
@onready var _round_label: Label = %RoundLabel
@onready var _bottom: Control = %Bottom
@onready var _card_bar: CardBar = %CardRow
@onready var _place_row: Control = %PlaceRow
@onready var _rotate_button: Button = %RotateButton
@onready var _confirm_button: Button = %ConfirmButton
@onready var _start_button: Button = %StartButton
@onready var _toast: Label = %Toast
@onready var _game_over_panel: Control = %GameOverPanel
@onready var _game_over_label: Label = %GameOverLabel

var _running := false
var _placing := false
var _toast_tween: Tween
var _shop_bar: ShopBar
var _market_panel: MarketPanel
var _pause_menu: PauseMenu
## Items delivered this frame, collected so several workshops give one toast.
var _pending_delivery: Array[String] = []


func _ready() -> void:
	# The HUD keeps working while the game is paused (pause menu).
	process_mode = Node.PROCESS_MODE_ALWAYS

	_market_panel = MarketPanel.new()
	add_child(_market_panel)
	_market_panel.closed.connect(_on_market_closed)
	_market_panel.traded.connect(show_toast)

	_pause_menu = PauseMenu.new()
	add_child(_pause_menu)
	_pause_menu.restart_pressed.connect(restart_pressed.emit)
	_pause_menu.menu_pressed.connect(menu_pressed.emit)
	var pause_button := UiKit.button(" II ", _pause_menu.set_paused.bind(true), 22, 0.0)
	_round_label.get_parent().add_child(pause_button)
	%RestartButton.get_parent().add_child(UiKit.button("Hauptmenü", menu_pressed.emit))

	_shop_bar = ShopBar.new()
	_card_bar.add_sibling(_shop_bar)
	_shop_bar.tool_pressed.connect(tool_pressed.emit)
	_card_bar.card_pressed.connect(card_pressed.emit)
	_card_bar.discard_pressed.connect(discard_pressed.emit)
	_start_button.pressed.connect(start_pressed.emit)
	%RestartButton.pressed.connect(restart_pressed.emit)
	_rotate_button.pressed.connect(rotate_pressed.emit)
	_confirm_button.pressed.connect(confirm_pressed.emit)
	%CancelButton.pressed.connect(cancel_pressed.emit)

	GameState.coins_changed.connect(func(_v: int) -> void: _refresh())
	GameState.hearts_changed.connect(func(_v: int) -> void: _refresh())
	GameState.round_changed.connect(func(_v: int) -> void: _refresh())
	Events.items_delivered.connect(_on_items_delivered)

	_game_over_panel.hide()
	_toast.modulate.a = 0.0
	_refresh()


func set_running(running: bool) -> void:
	_running = running
	_card_bar.locked = running
	_shop_bar.locked = running
	_refresh()


func set_placement(active: bool, valid: bool, can_rotate: bool) -> void:
	_placing = active
	_confirm_button.disabled = not valid
	_rotate_button.disabled = not can_rotate
	_refresh()


## Short message in the middle of the screen.
func show_toast(text: String) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.6)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


func show_game_over(won: bool) -> void:
	_market_panel.hide()
	_bottom.hide()
	_game_over_label.text = "Gewonnen! %d Münzen" % GameState.coins if won \
		else "Keine Herzen mehr.\n%d Münzen" % GameState.coins
	_game_over_panel.show()


func open_market(market: Marketplace) -> void:
	_bottom.hide()
	_market_panel.open(market)


func _on_market_closed() -> void:
	if not _game_over_panel.visible:
		_bottom.show()


func _on_items_delivered(items: Array[String], _source: Building) -> void:
	if _pending_delivery.is_empty():
		_flush_delivery.call_deferred()
	_pending_delivery.append_array(items)


func _flush_delivery() -> void:
	var names: Array[String] = []
	for item in _pending_delivery:
		names.append("+1 " + GameData.item_name(item))
	_pending_delivery.clear()
	show_toast("Abgeholt:\n" + ", ".join(names))


func _refresh() -> void:
	_coins_label.text = "Münzen: %d" % GameState.coins
	_hearts_label.text = "Herzen: %d" % GameState.hearts
	_round_label.text = "Runde %d/%d · Züge: %d" % [
		GameState.round_index + 1, GameState.round_count(), GameState.trains_this_round().length()]
	_place_row.visible = _placing
	_card_bar.visible = not _placing
	_shop_bar.visible = not _placing
	_start_button.visible = not _placing
	_start_button.disabled = _running
	_start_button.text = "Zug fährt …" if _running else "Zug starten"
