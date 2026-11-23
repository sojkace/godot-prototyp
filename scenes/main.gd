class_name Main
extends Node3D
## Game loop (endless, turn-based, see docs/konzept.md):
##   planning: play hand cards (paid with items), spend actions (tap mines / workshops,
##             put trains on rails), research, swap deck cards
##   end_round: halts send their trains, all trains drive and deliver
##   round end: buildings react (on_round_end), next hand, actions refill
## The public functions below are the player's actions; the HUD and the AutoplayBot both
## use them, so a rule change only has to be made here once.
## Screenshot helpers: `-- --demo-build` (placement mode), `-- --demo-market` (trade window),
## `-- --demo-card=<card id>` (preview a card), `-- --demo-panel=deck|research`.

## The player may act (start of the game and after every round).
signal turn_ready

@onready var island: Island = $Island
@onready var trains: TrainController = $TrainController
@onready var build: BuildController = $BuildController
@onready var hud: Hud = $Hud

## Hand slot whose card is being placed (-1 = none).
var _pending_slot := -1
## Shop tool currently being placed ("" = none), paid with coins on confirm.
var _pending_tool := ""
## Trains put on rails this round, waiting for end_round().
var _waiting_trains: Array[Train] = []


func _ready() -> void:
	GameState.reset()
	island.setup()
	GameState.draw_hand()
	hud.end_round_pressed.connect(end_round)
	hud.restart_pressed.connect(restart)
	hud.menu_pressed.connect(back_to_menu)
	hud.card_pressed.connect(start_placing)
	hud.reserve_pressed.connect(reserve)
	hud.discard_pressed.connect(discard)
	hud.tool_pressed.connect(start_tool)
	hud.rotate_pressed.connect(build.rotate_preview)
	hud.confirm_pressed.connect(confirm_placing)
	hud.cancel_pressed.connect(cancel_placing)
	hud.research_pressed.connect(research)
	hud.swap_pressed.connect(swap_card)
	build.placement_changed.connect(hud.set_placement)
	build.cell_tapped.connect(tap_cell)
	Events.market_requested.connect(hud.open_market)
	trains.round_finished.connect(_on_round_finished)
	hud.set_running(false)

	var bot := AutoplayBot.from_args(self)
	if bot:
		add_child(bot)
	for arg in OS.get_cmdline_user_args():
		if arg == "--demo-market":
			tap_cell.call_deferred(Vector2i(0, -1))
		elif arg == "--demo-build":
			start_placing.call_deferred(0)
		elif arg.begins_with("--demo-card="):
			build.start.call_deferred(arg.trim_prefix("--demo-card="))
		elif arg.begins_with("--demo-panel="):
			hud.open_panel.call_deferred(arg.trim_prefix("--demo-panel="))
	turn_ready.emit.call_deferred()


# --- Player actions ---

func is_round_running() -> bool:
	return trains.running


func can_play(slot: int) -> bool:
	var card_id := GameState.card_in_slot(slot)
	return card_id != "" and not trains.running and GameState.can_pay(card_id)


## Shows the placement preview for a hand card (nothing is paid yet).
func start_placing(slot: int) -> void:
	if not can_play(slot):
		return
	cancel_placing()
	_pending_slot = slot
	build.start(GameState.card_in_slot(slot))


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
	var slot := _pending_slot
	var tool_id := _pending_tool
	cancel_placing()
	if tool_id != "":
		return _use_tool(tool_id, layout)
	return slot >= 0 and _build(slot, layout)


## Uses a shop tool directly (no preview), e.g. for the bot.
func use_tool(card_id: String, c: Vector2i) -> bool:
	if trains.running or build.active:
		return false
	var layout := CardShape.layout(CardShape.definition(card_id), island, c, 0)
	if not PlacementRules.is_valid(island, layout, false):
		return false
	return _use_tool(card_id, layout)


## Builds a hand card directly (no preview), e.g. for the bot. See PlacementRules.options.
func place_card(slot: int, anchor: Vector2i, steps: int) -> bool:
	if not can_play(slot) or build.active:
		return false
	var def := CardShape.definition(GameState.card_in_slot(slot))
	var layout := CardShape.layout(def, island, anchor, steps)
	if not PlacementRules.is_valid(island, layout, CardShape.is_rail(def)):
		return false
	return _build(slot, layout)


## Taps a cell: a rail gets a train, other buildings do their tap action
## (fill a mine, collect a workshop, open the market). Manual work costs one action.
func tap_cell(c: Vector2i) -> void:
	if trains.running:
		return
	var building := island.buildings.get(c) as Building
	if building is Rail:
		send_train(c)
	elif building:
		if building.tap_costs_action():
			if not GameState.spend_action():
				Events.message.emit("Keine Aktionen mehr in dieser Runde")
				return
		building.on_tapped()


## Why a train can not start on `c` ("" = it can).
func train_problem(c: Vector2i) -> String:
	if not island.buildings.get(c) is Rail:
		return "Hier ist keine Schiene"
	if island.station_for(c) == null:
		return "Kein Bahnhof mit freiem Zug in Reichweite"
	var route := RailNetwork.route(island, c)
	if route.is_empty():
		return "Diese Strecke führt zu keiner Fabrik"
	if (route["path"] as Array).size() < GameState.rules.min_train_route:
		return "Zu nah an der Fabrik: mindestens %d Felder Strecke" % GameState.rules.min_train_route
	return ""


## Puts a train from a station in range on the rail at `c` (one action).
func send_train(c: Vector2i) -> bool:
	var problem := train_problem(c)
	if problem == "" and GameState.actions <= 0:
		problem = "Keine Aktionen mehr in dieser Runde"
	if problem != "":
		Events.message.emit(problem)
		return false
	GameState.spend_action()
	_dispatch(island.station_for(c), c)
	return true


func cancel_placing() -> void:
	build.cancel()
	_pending_slot = -1
	_pending_tool = ""


func reserve(slot: int) -> void:
	if not trains.running and not build.active:
		GameState.reserve_slot(slot)


func discard(slot: int) -> void:
	if not trains.running and not build.active:
		GameState.discard_slot(slot)


func research(index: int) -> void:
	if index >= 0 and index < GameState.rules.research.size():
		GameState.do_research(GameState.rules.research[index])


func swap_card(out_card: String, in_card: String) -> void:
	if not trains.running:
		GameState.swap_card(out_card, in_card)


## Ends the planning phase: halts send their trains, then all trains drive.
func end_round() -> void:
	if trains.running:
		return
	cancel_placing()
	_send_from_halts()
	hud.set_running(true)
	var sent := _waiting_trains.duplicate()
	_waiting_trains.clear()
	trains.run_round(sent)


func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func back_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")


# --- Flow ---

func _dispatch(station: Station, c: Vector2i) -> void:
	var route := RailNetwork.route(island, c)
	station.take_train()
	_waiting_trains.append(trains.make_train(route["path"], route["factory"]))
	GameState.add_stat("trains_sent")


## Every halt sends one train for free from the first rail next to it that leads to a factory.
func _send_from_halts() -> void:
	for building: Building in island.all_buildings():
		var halt := building as Halt
		if halt == null:
			continue
		for c in halt.rail_neighbours():
			if train_problem(c) == "":
				_dispatch(island.station_for(c), c)
				break


func _use_tool(card_id: String, layout: Array[Dictionary]) -> bool:
	if not can_buy(card_id):
		return false
	GameState.coins -= tool_cost(card_id)
	island.place_layout(layout)
	return true


func _build(slot: int, layout: Array[Dictionary]) -> bool:
	if not can_play(slot):
		return false
	GameState.play_slot(slot)
	island.place_layout(layout)
	return true


func _on_round_finished() -> void:
	var finished_round := GameState.round_index + 1
	island.notify_round_end()
	GameState.next_round()
	Events.round_ended.emit(finished_round)
	hud.set_running(false)
	turn_ready.emit()
