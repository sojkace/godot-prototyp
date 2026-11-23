class_name Main
extends Node3D
## Game loop: play a card -> place its piece -> start trains -> round ends ->
## buildings react (on_round_end) -> collect items -> next round.
## The public functions below are the player's actions; the HUD and the AutoplayBot both
## use them, so a rule change only has to be made here once.
## Screenshot helpers: `-- --demo-build` (placement mode), `-- --demo-market` (trade window),
## `-- --demo-collect` (workshops show items to collect), `-- --demo-card=<card id>` (preview a card).

## The player may act (start of the game and after every round).
signal turn_ready

@onready var island: Island = $Island
@onready var trains: TrainController = $TrainController
@onready var build: BuildController = $BuildController
@onready var hud: Hud = $Hud

## Deck whose card is currently being placed ("" = none).
var _pending_deck := ""
## Shop tool currently being placed ("" = none), paid with coins on confirm.
var _pending_tool := ""


func _ready() -> void:
	GameState.reset()
	GameState.game_over.connect(_on_game_over)
	hud.start_pressed.connect(start_round)
	hud.restart_pressed.connect(restart)
	hud.menu_pressed.connect(back_to_menu)
	hud.card_pressed.connect(start_placing)
	hud.tool_pressed.connect(start_tool)
	hud.discard_pressed.connect(discard)
	hud.rotate_pressed.connect(build.rotate_preview)
	hud.confirm_pressed.connect(confirm_placing)
	hud.cancel_pressed.connect(cancel_placing)
	build.placement_changed.connect(hud.set_placement)
	build.cell_tapped.connect(tap_cell)
	Events.market_requested.connect(hud.open_market)
	trains.round_finished.connect(_on_round_finished)
	hud.set_running(false)

	var bot := AutoplayBot.from_args(self)
	if bot:
		add_child(bot)
	elif OS.get_cmdline_user_args().has("--demo-market"):
		tap_cell.call_deferred(Vector2i(2, -1))
	elif OS.get_cmdline_user_args().has("--demo-build"):
		start_placing.call_deferred("buildings")
	elif OS.get_cmdline_user_args().has("--demo-collect"):
		island.notify_round_end.call_deferred()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--demo-card="):
			build.start.call_deferred(arg.trim_prefix("--demo-card="))
	turn_ready.emit.call_deferred()


# --- Player actions ---

func is_round_running() -> bool:
	return trains.running


## Shows the placement preview for the top card of a deck (nothing is paid yet).
func start_placing(deck_id: String) -> void:
	if trains.running or not GameState.can_afford(deck_id):
		return
	cancel_placing()
	_pending_deck = deck_id
	build.start(GameState.top_card(deck_id))


## Shows the preview for a shop tool (bomb, bridge); coins are paid on confirm.
func start_tool(card_id: String) -> void:
	if trains.running or not can_buy(card_id):
		return
	cancel_placing()
	_pending_tool = card_id
	build.start(card_id)


func tool_cost(card_id: String) -> int:
	return int(CardShape.definition(card_id).get("coins", 0))


func can_buy(card_id: String) -> bool:
	return GameState.coins >= tool_cost(card_id)


## Builds the previewed card / uses the tool where it is shown and pays for it.
## False if not possible.
func confirm_placing() -> bool:
	var layout := build.valid_layout()
	if layout.is_empty():
		return false
	var deck_id := _pending_deck
	var tool_id := _pending_tool
	cancel_placing()
	if tool_id != "":
		return _use_tool(tool_id, layout)
	return deck_id != "" and _build(deck_id, layout)


## Uses a shop tool directly (no preview), e.g. for the bot.
func use_tool(card_id: String, c: Vector2i) -> bool:
	if trains.running or build.active:
		return false
	var layout := CardShape.layout(CardShape.definition(card_id), island, c, 0)
	if not PlacementRules.is_valid(island, layout, false):
		return false
	return _use_tool(card_id, layout)


## Builds the top card of a deck directly (no preview), e.g. for the bot. See PlacementRules.options.
func place_card(deck_id: String, anchor: Vector2i, steps: int) -> bool:
	if trains.running or build.active:
		return false
	var def := CardShape.definition(GameState.top_card(deck_id))
	var layout := CardShape.layout(def, island, anchor, steps)
	if not PlacementRules.is_valid(island, layout, CardShape.is_rail(def)):
		return false
	return _build(deck_id, layout)


## Taps a building on the island (collect items, open a marketplace ...).
func tap_cell(c: Vector2i) -> void:
	var building := island.buildings.get(c) as Building
	if building and not trains.running:
		building.on_tapped()


func cancel_placing() -> void:
	build.cancel()
	_pending_deck = ""
	_pending_tool = ""


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

func _use_tool(card_id: String, layout: Array[Dictionary]) -> bool:
	if not can_buy(card_id):
		return false
	GameState.coins -= tool_cost(card_id)
	island.place_layout(layout)
	return true


func _build(deck_id: String, layout: Array[Dictionary]) -> bool:
	if not GameState.can_afford(deck_id):
		return false
	island.place_layout(layout)
	GameState.play_card(deck_id)
	return true


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
