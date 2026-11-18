class_name AutoplayBot
extends Node
## Test player for balancing. Uses the same actions as the HUD (Main's public functions).
##   `-- --autoplay`      plays one game fast and prints every round.
##   `-- --simulate=N`    plays N games quietly and prints a summary (win rate, coins ...).
## Combine with `--rules=<variant>` and `--level=N` to compare rule variants.
## Strategy: trade the most plentiful item for the scarcest one, play every affordable
## card (rails at the open end, buildings near the screen center), discard a card that
## cannot be placed (once per deck per turn), then start the trains.

## Results of finished games; static, so it survives the scene reload between games.
static var _results: Array[Dictionary] = []
static var _games_total := 0

var game: Main
var verbose := true


## Creates a bot if the command line asks for one, otherwise returns null.
static func from_args(main: Main) -> AutoplayBot:
	var args := OS.get_cmdline_user_args()
	var bot: AutoplayBot = null
	for arg in args:
		if arg.begins_with("--simulate="):
			bot = AutoplayBot.new()
			bot.verbose = false
			_games_total = maxi(1, int(arg.trim_prefix("--simulate=")))
	if bot == null and args.has("--autoplay"):
		bot = AutoplayBot.new()
		_games_total = 1
	if bot:
		bot.game = main
	return bot


func _ready() -> void:
	Engine.time_scale = 20.0 if verbose else 60.0
	game.turn_ready.connect(_play_turn, CONNECT_DEFERRED)
	GameState.game_over.connect(_on_game_over)
	if verbose:
		Events.round_ended.connect(_log_round)
		print("%s, rules=%s, island seed=%d land=%d" % [
			GameState.level()["name"], GameState.rules_id, game.island.island_seed, game.island.land.size()])


func _play_turn() -> void:
	_trade()
	var discarded := {}
	var acted := true
	while acted:
		acted = false
		for deck_id in GameState.deck_ids():
			if not GameState.can_afford(deck_id):
				continue
			var card := GameState.top_card(deck_id)
			game.start_placing(deck_id)
			if game.confirm_placing():
				_log("  played %s" % card)
				acted = true
				continue
			game.cancel_placing()
			if GameState.can_discard(deck_id) and not discarded.has(deck_id):
				discarded[deck_id] = true
				_log("  discarded %s" % card)
				game.discard(deck_id)
				acted = true
			else:
				_log("  could not place %s" % card)
	game.start_round()


## At every marketplace with trades left, swap the most plentiful item for the scarcest offer.
func _trade() -> void:
	for building: Building in game.island.all_buildings():
		var market := building as Marketplace
		if market == null or market.is_used_up():
			continue
		var most := GameData.ITEMS[0]
		for item in GameData.ITEMS:
			if GameState.item_count(item) > GameState.item_count(most):
				most = item
		var best := -1
		for i in market.offers.size():
			if market.can_trade(i, most) and (best < 0 \
					or GameState.item_count(market.offers[i]) < GameState.item_count(market.offers[best])):
				best = i
		if best >= 0 and GameState.item_count(market.offers[best]) + 1 < GameState.item_count(most):
			_log("  traded %s -> %s" % [most, market.offers[best]])
			market.trade(best, most)


func _log_round(round_number: int) -> void:
	print("round %d: coins=%d hearts=%d items=%s rail=%d buildings=%s land=%d" % [
		round_number, GameState.coins, GameState.hearts, GameState.items,
		game.island.rail_path.size() - 1, _building_counts(), game.island.land.size()])


func _on_game_over(won: bool) -> void:
	_results.append({
		"won": won,
		"round": GameState.round_index + 1,
		"coins": GameState.coins,
		"hearts": GameState.hearts,
		"rail": game.island.rail_path.size() - 1,
	})
	if verbose:
		print("game over, won=%s" % won)
	else:
		print("game %d/%d: won=%s round=%d coins=%d" % [
			_results.size(), _games_total, won, GameState.round_index + 1, GameState.coins])
	if _results.size() < _games_total:
		game.get_tree().reload_current_scene.call_deferred()
		return
	if _games_total > 1:
		_print_summary()
	get_tree().quit()


func _print_summary() -> void:
	var wins := 0
	var rounds := 0.0
	var coins := 0.0
	var rail := 0.0
	for r in _results:
		wins += 1 if r["won"] else 0
		rounds += r["round"]
		coins += r["coins"]
		rail += r["rail"]
	var n := float(_results.size())
	print("=== %s, rules=%s, %d games ===" % [GameState.level()["name"], GameState.rules_id, _results.size()])
	print("win rate %d%%, avg round reached %.1f/%d, avg coins %.1f, avg rail length %.1f" % [
		roundi(100.0 * wins / n), rounds / n, GameState.round_count(), coins / n, rail / n])


func _building_counts() -> Dictionary:
	var counts := {}
	for building: Building in game.island.all_buildings():
		var id := building.type_id()
		if id != Island.DIRT_ID and not building is Rail:
			counts[id] = counts.get(id, 0) + 1
	return counts


func _log(text: String) -> void:
	if verbose:
		print(text)
