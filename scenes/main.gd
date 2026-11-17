extends Node3D
## Wires the game loop: play a card -> place the building -> start trains -> round ends ->
## workshops deliver items -> next round.
## Test mode: `-- --autoplay` plays automatically (greedy card use) and prints the state.
## Screenshot helper: `-- --demo-build` opens placement mode for the top building card.

@onready var _trains: TrainController = $TrainController
@onready var _build: BuildController = $BuildController
@onready var _hud: Hud = $Hud
@onready var _island: Island = $Island

var _autoplay := false
## Deck whose card is currently being placed ("" = none).
var _pending_deck := ""


func _ready() -> void:
	GameState.reset()
	GameState.game_over.connect(_on_game_over)
	_hud.start_pressed.connect(_on_start_pressed)
	_hud.restart_pressed.connect(_on_restart_pressed)
	_hud.menu_pressed.connect(_on_menu_pressed)
	_hud.card_pressed.connect(_on_card_pressed)
	_hud.discard_pressed.connect(_on_discard_pressed)
	_hud.rotate_pressed.connect(_build.rotate_preview)
	_hud.confirm_pressed.connect(_on_confirm_pressed)
	_hud.cancel_pressed.connect(_build.cancel)
	_build.placement_changed.connect(_hud.set_placement)
	_build.cell_tapped.connect(_on_cell_tapped)
	_trains.round_finished.connect(_on_round_finished)
	_hud.set_running(false)

	var args := OS.get_cmdline_user_args()
	_autoplay = args.has("--autoplay")
	if _autoplay:
		Engine.time_scale = 20.0
		print("%s, island seed=%d land=%d" % [GameState.level()["name"], _island.island_seed, _island.land.size()])
		_autoplay_turn.call_deferred()
	elif args.has("--demo-market"):
		_on_cell_tapped.call_deferred(Vector2i(2, -1))
	elif args.has("--demo-build"):
		_on_card_pressed.call_deferred("buildings")


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")


func _on_card_pressed(deck_id: String) -> void:
	if _trains.running or not GameState.can_afford(deck_id):
		return
	_pending_deck = deck_id
	_build.start(GameState.top_card(deck_id))


## Tapping a marketplace opens its trade window.
func _on_cell_tapped(c: Vector2i) -> void:
	var market := _island.buildings.get(c) as Marketplace
	if market:
		_hud.open_market(market)


func _on_discard_pressed(deck_id: String) -> void:
	if not _trains.running and not _build.active:
		GameState.discard_top(deck_id)


func _on_confirm_pressed() -> void:
	var deck_id := _pending_deck
	if deck_id == "" or not GameState.can_afford(deck_id):
		return
	if _build.confirm():
		_pending_deck = ""
		GameState.play_card(deck_id)


func _on_start_pressed() -> void:
	_build.cancel()
	_pending_deck = ""
	_hud.set_running(true)
	_trains.run_round(GameState.trains_this_round())


func _on_round_finished() -> void:
	if _autoplay:
		print("round %d: coins=%d hearts=%d items=%s rail=%d mines=%d crafters=%d land=%d" % [
			GameState.round_index + 1, GameState.coins, GameState.hearts, GameState.items,
			_island.rail_path.size() - 1, _island.mines.size(), _island.count_type("itemcrafter"),
			_island.land.size()])
	if not GameState.finish_round():
		return
	_island.on_round_end()
	var crafters := _island.count_type("itemcrafter")
	_hud.show_delivery(GameState.deliver_items(crafters * GameData.ITEMS_PER_CRAFTER))
	_hud.set_running(false)
	if _autoplay:
		_autoplay_turn.call_deferred()


func _on_game_over(won: bool) -> void:
	_hud.show_game_over(won)
	if _autoplay:
		print("game over, won=%s" % won)
		get_tree().quit()


## Test mode: play every affordable card (rails at the open end, buildings near
## the screen center), then start the trains.
func _autoplay_turn() -> void:
	_autoplay_trade()
	var played := true
	var discarded := {}
	while played:
		played = false
		for deck_id in GameData.DECK_ORDER:
			if GameState.can_afford(deck_id):
				var card := GameState.top_card(deck_id)
				_on_card_pressed(deck_id)
				var before := GameState.cards_left(deck_id)
				_on_confirm_pressed()
				if GameState.cards_left(deck_id) != before or _pending_deck == "":
					print("  played %s" % card)
					played = true
				else:
					_build.cancel()
					_pending_deck = ""
					if GameState.can_discard(deck_id) and not discarded.has(deck_id):
						discarded[deck_id] = true
						print("  discarded %s" % card)
						GameState.discard_top(deck_id)
						played = true
					else:
						print("  could not place %s" % card)
	_on_start_pressed()



## Test mode: at every unused marketplace, swap the most plentiful item for the scarcest offered one.
func _autoplay_trade() -> void:
	for building: Building in _island.buildings.values():
		var market := building as Marketplace
		if market == null or market.used_this_round:
			continue
		var most := GameData.ITEMS[0]
		for item in GameData.ITEMS:
			if GameState.item_count(item) > GameState.item_count(most):
				most = item
		var best := -1
		for i in market.offers.size():
			if market.can_trade(i, most) and (best < 0 or GameState.item_count(market.offers[i]) < GameState.item_count(market.offers[best])):
				best = i
		if best >= 0 and GameState.item_count(market.offers[best]) + 1 < GameState.item_count(most):
			print("  traded %s -> %s" % [most, market.offers[best]])
			market.trade(best, most)
