class_name Main
extends Node3D
## Game loop: play a card -> place the building -> start trains -> round ends ->
## buildings react (on_round_end) -> next round.
## The public functions below are the player's actions; the HUD and the AutoplayBot both
## use them, so a rule change only has to be made here once.
## Screenshot helpers: `-- --demo-build` (placement mode), `-- --demo-market` (trade window).

## The player may act (start of the game and after every round).
signal turn_ready

@onready var island: Island = $Island
@onready var trains: TrainController = $TrainController
@onready var build: BuildController = $BuildController
@onready var hud: Hud = $Hud

## Deck whose card is currently being placed ("" = none).
var _pending_deck := ""


func _ready() -> void:
	GameState.reset()
	GameState.game_over.connect(_on_game_over)
	hud.start_pressed.connect(start_round)
	hud.restart_pressed.connect(restart)
	hud.menu_pressed.connect(back_to_menu)
	hud.card_pressed.connect(start_placing)
	hud.discard_pressed.connect(discard)
	hud.rotate_pressed.connect(build.rotate_preview)
	hud.confirm_pressed.connect(confirm_placing)
	hud.cancel_pressed.connect(cancel_placing)
	build.placement_changed.connect(hud.set_placement)
	build.cell_tapped.connect(_on_cell_tapped)
	trains.round_finished.connect(_on_round_finished)
	hud.set_running(false)

	var bot := AutoplayBot.from_args(self)
	if bot:
		add_child(bot)
	elif OS.get_cmdline_user_args().has("--demo-market"):
		_on_cell_tapped.call_deferred(Vector2i(2, -1))
	elif OS.get_cmdline_user_args().has("--demo-build"):
		start_placing.call_deferred("buildings")
	turn_ready.emit.call_deferred()


# --- Player actions ---

func is_round_running() -> bool:
	return trains.running


## Shows the placement preview for the top card of a deck (nothing is paid yet).
func start_placing(deck_id: String) -> void:
	if trains.running or not GameState.can_afford(deck_id):
		return
	_pending_deck = deck_id
	build.start(GameState.top_card(deck_id))


## Builds the previewed card at the chosen cell and pays for it. False if not possible.
func confirm_placing() -> bool:
	var deck_id := _pending_deck
	if deck_id == "" or not GameState.can_afford(deck_id):
		return false
	if not build.confirm():
		return false
	_pending_deck = ""
	GameState.play_card(deck_id)
	return true


func cancel_placing() -> void:
	build.cancel()
	_pending_deck = ""


func discard(deck_id: String) -> void:
	if not trains.running and not build.active:
		GameState.discard_top(deck_id)


func start_round() -> void:
	if trains.running:
		return
	cancel_placing()
	hud.set_running(true)
	trains.run_round(GameState.trains_this_round())


func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func back_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")


# --- Flow ---

## Tapping a marketplace opens its trade window.
func _on_cell_tapped(c: Vector2i) -> void:
	var market := island.buildings.get(c) as Marketplace
	if market:
		hud.open_market(market)


func _on_round_finished() -> void:
	var finished_round := GameState.round_index + 1
	if not GameState.finish_round():
		return
	island.notify_round_end()
	Events.round_ended.emit(finished_round)
	hud.set_running(false)
	turn_ready.emit()


func _on_game_over(won: bool) -> void:
	hud.show_game_over(won)
