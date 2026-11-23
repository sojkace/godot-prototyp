class_name AutoplayBot
extends Node
## Test player for balancing. Uses the same actions as the HUD (Main's public functions).
##   `-- --autoplay`      plays one game fast and prints every round.
##   `-- --simulate=N`    plays N games quietly and prints a summary.
##   `-- --rounds=N`      rounds per game (default 40; the game itself is endless).
##   `-- --bot-speed=N`   time scale (default 20 / 60), e.g. 1 to record a video.
## Combine with `--rules=<variant>` and `--seed=N` to compare rule variants.
## Strategy per round:
##   1. research whatever is affordable, swap new cards into the deck (curses out first)
##   2. play affordable hand cards at their best-scored spot (rails towards factories,
##      mines next to lines of the matching factory, flags for land, upgrades on mines)
##   3. spend actions: dig mines that serve a line, send trains, collect workshops
##   4. end the round

## Results of finished games; static, so it survives the scene reload between games.
static var _results: Array[Dictionary] = []
static var _games_total := 0
static var _rounds_per_game := 40

var game: Main
var verbose := true
## building id -> area_shape (read once from the scene)
var _area_cache := {}
## Round in which the first automation (conveyor / halt / master) was built (-1 = never).
var _first_auto_round := -1


## Creates a bot if the command line asks for one, otherwise returns null.
static func from_args(main: Main) -> AutoplayBot:
	var args := OS.get_cmdline_user_args()
	var bot: AutoplayBot = null
	for arg in args:
		if arg.begins_with("--simulate="):
			bot = AutoplayBot.new()
			bot.verbose = false
			_games_total = maxi(1, int(arg.trim_prefix("--simulate=")))
		elif arg.begins_with("--rounds="):
			_rounds_per_game = maxi(1, int(arg.trim_prefix("--rounds=")))
	if bot == null and args.has("--autoplay"):
		bot = AutoplayBot.new()
		_games_total = 1
	if bot:
		bot.game = main
	return bot


func _ready() -> void:
	Engine.time_scale = 20.0 if verbose else 60.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--bot-speed="):
			Engine.time_scale = float(arg.trim_prefix("--bot-speed="))
	game.turn_ready.connect(_play_turn, CONNECT_DEFERRED)
	Events.building_placed.connect(_on_building_placed)
	if verbose:
		Events.round_ended.connect(_log_round)
		print("rules=%s, island seed=%d land=%d" % [GameState.rules_id, game.island.island_seed, game.island.land.size()])


func _play_turn() -> void:
	if GameState.round_index >= _rounds_per_game:
		_finish()
		return
	_research_and_swap()
	_trade()
	_play_cards()
	_spend_actions()
	game.end_round()


# --- 1. Research & deck ---

const RESEARCH_ORDER: Array[String] = ["conveyor", "halt", "land", "organisation", "master",
	"station", "big_mines", "trade"]


func _research_and_swap() -> void:
	var research := GameState.rules.research
	for id in RESEARCH_ORDER:
		for i in research.size():
			if research[i]["id"] != id or GameState.researched.has(id):
				continue
			if not GameState.can_research(research[i]):
				break  # save points for this one
			_log("  research %s" % id)
			game.research(i)
		if not GameState.researched.has(id):
			break
	# Curses out, then the newest useful cards in for the weakest normal ones.
	var counts := GameState.deck_counts()
	for card_id: String in counts.keys():
		if GameState.is_curse(card_id):
			for i in int(counts[card_id]):
				if GameState.coins >= GameState.swap_price(card_id):
					game.swap_card(card_id, "rail_f")
					_log("  swapped out curse")
	var wanted := {"auto_mine": 3, "halt": 2, "auto_crafter": 1, "station": 1, "mine_silver_twin": 2}
	for card_id: String in wanted:
		if not GameState.collection.has(card_id):
			continue
		while int(GameState.deck_counts().get(card_id, 0)) < int(wanted[card_id]) \
				and GameState.coins >= GameState.rules.swap_cost + 2:
			var out := _weakest_card()
			if out == "":
				break
			game.swap_card(out, card_id)
			_log("  swapped %s -> %s" % [out, card_id])


func _weakest_card() -> String:
	var counts := GameState.deck_counts()
	for card_id in ["pond", "rail_ll", "rail_lr", "rail_lf", "rail_l", "rail_f"]:
		if int(counts.get(card_id, 0)) > 1 or (card_id == "pond" and counts.has(card_id)):
			return card_id
	return ""


# --- 2. Cards ---

func _play_cards() -> void:
	var tries := 0
	var slot := 0
	while slot < GameState.playable_cards().size() and tries < 20:
		tries += 1
		var card := GameState.card_in_slot(slot)
		if not game.can_play(slot):
			slot += 1
			continue
		var best := _best_option(card)
		if best.is_empty() or best["score"] < 0.0:
			if GameState.coins >= 6 and GameState.can_discard(slot):
				game.discard(slot)
				_log("  redrew %s" % card)
			elif GameState.can_reserve(slot):
				game.reserve(slot)
				_log("  kept %s" % card)
			else:
				slot += 1
			continue
		if game.place_card(slot, best["anchor"], best["steps"]):
			_log("  played %s (score %.1f)" % [card, best["score"]])
		else:
			slot += 1


func _best_option(card_id: String) -> Dictionary:
	var best := {}
	var best_score := -INF
	for option in PlacementRules.options(game.island, card_id):
		var score := _score(card_id, option["layout"]) + randf() * 0.1
		if score > best_score:
			best_score = score
			best = option
			best["score"] = score
	return best


func _score(card_id: String, layout: Array[Dictionary]) -> float:
	var def := CardShape.definition(card_id)
	if CardShape.is_rail(def):
		return _score_rail(layout)
	if CardShape.is_upgrade(def):
		var target := game.island.buildings.get(layout[0]["cell"]) as Building
		if target is Mine:
			return 5.0 + (5.0 if _mine_serves_line(target as Mine) else 0.0)
		return 4.0
	var score := 0.0
	for entry in layout:
		var id: String = entry["id"]
		var c: Vector2i = entry["cell"]
		for dir_vector in GridUtil.DIR_VECTORS:
			if game.island.buildings.get(c + dir_vector) is Factory:
				score -= 8.0  # keep the factory's sides free for rails
		if id.begins_with("mine"):
			score += _score_mine(id, c)
		elif id.begins_with("flag"):
			for offset in GridUtil.area_offsets(_area_shape(id)):
				if not game.island.is_land(c + offset):
					score += 1.0
			# Growing the island brings new factories once the current ones are served.
			score += 2.0 if _all_connected() else -2.0
		elif id == "halt":
			score += 8.0 if _halt_useful(c) else -5.0
		elif id == "station":
			score += 3.0
		elif id == "water":
			score += minf(_distance_to_rails(c), 4.0) - (6.0 if GameState.is_curse(card_id) else 3.0)
		else:
			score += 1.0
	return score


## Rails: build a line from the station area to the target factory, then extend finished
## lines backwards (past mines, into station range) until trains can use them.
func _score_rail(layout: Array[Dictionary]) -> float:
	var island := game.island
	var last: Dictionary = layout[-1]
	var first: Dictionary = layout[0]
	var front: Vector2i = last["cell"] + GridUtil.DIR_VECTORS[last["out"]]
	var back: Vector2i = first["cell"] + GridUtil.DIR_VECTORS[first["in"]]
	var target := _target_factory()
	if target == null:
		return -1.0
	# PlacementRules guarantees that a rail at either end is connected to the block.
	var joined := Vector2i(9999, 9999)
	var free_end := front
	var free_cell: Vector2i = last["cell"]
	if island.buildings.get(back) is Rail:
		joined = back
	elif island.buildings.get(front) is Rail:
		joined = front
		free_end = back
		free_cell = first["cell"]
	var joins := joined.x != 9999
	if joins and island.buildings.get(back) is Rail and island.buildings.get(front) is Rail:
		return -2.0  # closing a loop helps nobody
	var score := 0.0
	var line_route := RailNetwork.route(island, joined) if joins else {}
	if not line_route.is_empty():
		# Extending a finished line away from its factory.
		var factory: Factory = line_route["factory"]
		if island.buildings.get(free_end) is Factory:
			return -5.0
		score += layout.size() * 0.5
		score += _mine_bonus(layout, factory.ore)
		var in_range := false
		for entry in layout:
			in_range = in_range or _in_any_station(entry["cell"])
		if _line_has_start(joined):
			score -= 3.0
		else:
			score += 8.0 if in_range else 2.0
		return score
	var factory_end := Vector2i(9999, 9999)
	for end_cell in [front, back]:
		if island.buildings.get(end_cell) == target:
			factory_end = end_cell
	if factory_end.x != 9999:
		var length := layout.size() + (RailNetwork.line_cells(island, joined).size() if joins else 0)
		score += 30.0 if length >= GameState.rules.min_train_route else 4.0
	else:
		var start_cell: Vector2i = joined if joins else first["cell"]
		var before := _manhattan(start_cell, target.cell)
		var after := _manhattan(free_end, target.cell)
		score += (before - after) * 3.0
		if not joins:
			if _has_line_towards(target):
				score -= 8.0  # do not start a second line for the same factory
			if not _in_any_station(first["cell"]) and not _in_any_station(last["cell"]):
				score -= 4.0
			if before < GameState.rules.min_train_route + 1:
				score -= 6.0  # too close to the factory to be a useful start
	if joins:
		score += 6.0
	score += _mine_bonus(layout, target.ore)
	return score


func _mine_bonus(layout: Array[Dictionary], ore: String) -> float:
	var bonus := 0.0
	for entry in layout:
		for building: Building in game.island.all_buildings():
			var mine := building as Mine
			if mine and mine.ore == ore and mine.covers(entry["cell"]):
				bonus += 4.0
	return bonus


## True if a train may start somewhere on the line through `c`.
func _line_has_start(c: Vector2i) -> bool:
	for cell: Vector2i in RailNetwork.line_cells(game.island, c):
		if game.island.buildings.get(cell) is Rail and _in_any_station(cell) \
				and (RailNetwork.route(game.island, cell).get("path", []) as Array).size() >= GameState.rules.min_train_route:
			return true
	return false


func _score_mine(id: String, c: Vector2i) -> float:
	var ore := "gold" if id == "mine_gold" else "silver"
	var score := 0.0
	for offset in GridUtil.area_offsets(_area_shape(id)):
		var rail := game.island.buildings.get(c + offset) as Rail
		if rail:
			var route := RailNetwork.route(game.island, c + offset)
			if not route.is_empty() and (route["factory"] as Factory).ore == ore:
				score += 6.0
			else:
				score += 1.0
	var target := _target_factory()
	if target and target.ore == ore:
		score += maxf(0.0, 6.0 - _manhattan(c, target.cell))
	return score - 1.0


## The factory the bot builds towards: the first one without a finished line,
## otherwise the one with the most missing loads.
func _target_factory() -> Factory:
	var best: Factory = null
	for factory in game.island.factories:
		if not _factory_connected(factory):
			return factory
		if best == null or factory.missing() > best.missing():
			best = factory
	return best


func _all_connected() -> bool:
	for factory in game.island.factories:
		if not _factory_connected(factory):
			return false
	return true


func _factory_connected(factory: Factory) -> bool:
	for d in 4:
		var c: Vector2i = factory.cell + GridUtil.DIR_VECTORS[d]
		var rail := game.island.buildings.get(c) as Rail
		if rail and rail.openings().has(GridUtil.opposite(d)):
			return true
	return false


func _has_line_towards(factory: Factory) -> bool:
	for building: Building in game.island.all_buildings():
		if building is Rail and _manhattan(building.cell, factory.cell) <= 5:
			return true
	return false


func _halt_useful(c: Vector2i) -> bool:
	for dir_vector in GridUtil.DIR_VECTORS:
		var n: Vector2i = c + dir_vector
		if game.island.buildings.get(n) is Rail and _in_any_station(n) \
				and (RailNetwork.route(game.island, n).get("path", []) as Array).size() >= GameState.rules.min_train_route:
			return true
	return false


func _in_any_station(c: Vector2i) -> bool:
	for station in game.island.stations():
		if station.covers(c):
			return true
	return false


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


# --- 3. Actions ---

## Ore already promised to trains sent this round (they load it while driving).
var _promised := 0


func _spend_actions() -> void:
	_promised = 0
	var guard := 0
	while GameState.actions > 0 and guard < 10:
		guard += 1
		if not _do_one_action():
			break


func _do_one_action() -> bool:
	var island := game.island
	# Best start cell per factory: in station range, longest stretch of matching mines.
	var best_start := Vector2i.ZERO
	var best_value := 0
	var best_factory: Factory = null
	for building: Building in island.all_buildings():
		if not building is Rail or game.train_problem(building.cell) != "":
			continue
		var route := RailNetwork.route(island, building.cell)
		var factory: Factory = route["factory"]
		var stock := _stock_on(route["path"], factory.ore)
		var value := mini(stock, mini(4, factory.missing() + 1)) * 10 + (route["path"] as Array).size()
		if value > best_value:
			best_value = value
			best_start = building.cell
			best_factory = factory
	var stock := 0
	if best_factory:
		stock = _stock_on(RailNetwork.route(island, best_start)["path"], best_factory.ore) - _promised
	if stock >= 2:
		_promised += 4
		_log("  train from %s (%d cells, %d ore on the way)" % [best_start,
			(RailNetwork.route(island, best_start)["path"] as Array).size(), stock])
		return game.send_train(best_start)
	# Not enough ore on any line: dig a mine that serves a line (not automated, not full).
	for building: Building in island.all_buildings():
		var mine := building as Mine
		if mine and not mine.is_full() and _mine_serves_line(mine):
			game.tap_cell(mine.cell)
			return true
	for building: Building in island.all_buildings():
		var crafter := building as ItemCrafter
		if crafter and crafter.is_ready_to_collect():
			game.tap_cell(crafter.cell)
			return true
	if stock >= 1:
		_promised += 4
		return game.send_train(best_start)
	return false


## Ore lying in mines along `path` that trains to a factory of `ore` would pick up.
func _stock_on(path: Array, ore: String) -> int:
	var total := 0
	for building: Building in game.island.all_buildings():
		var mine := building as Mine
		if mine == null or mine.ore != ore:
			continue
		for c: Vector2i in path:
			if mine.covers(c):
				total += mine.stock
				break
	return total


## True if a train sent from a station could pass this mine on its way to a matching factory.
func _mine_serves_line(mine: Mine) -> bool:
	for offset in mine.area_offsets():
		var c := mine.cell + offset
		if not game.island.buildings.get(c) is Rail:
			continue
		var route := RailNetwork.route(game.island, c)
		if not route.is_empty() and (route["factory"] as Factory).ore == mine.ore:
			return true
	return false


# --- Helpers ---

func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func _distance_to_rails(c: Vector2i) -> float:
	var best := 6.0
	for building: Building in game.island.all_buildings():
		if building is Rail:
			best = minf(best, Vector2(c - building.cell).length())
	return best


func _area_shape(id: String) -> String:
	if not _area_cache.has(id):
		var building := GameData.building_scene(id).instantiate() as Building
		_area_cache[id] = building.area_shape
		building.free()
	return _area_cache[id]


func _on_building_placed(_building: Building) -> void:
	if _first_auto_round < 0 and _automation_count() > 0:
		_first_auto_round = GameState.round_index + 1


func _automation_count() -> int:
	var count := 0
	for building: Building in game.island.all_buildings():
		if building.automated or building is Halt:
			count += 1
	return count


func _log_round(round_number: int) -> void:
	var orders: Array[String] = []
	for factory in game.island.factories:
		orders.append("%s %d/%d(%dR)" % [factory.ore, factory.delivered, factory.order_amount, factory.rounds_left])
	print("round %d: coins=%d items=%s done=%d missed=%d sent=%d rp=%d research=%s auto=%d land=%d orders=%s" % [
		round_number, GameState.coins, GameState.items, GameState.stats["orders_done"],
		GameState.stats["orders_missed"], GameState.stats["trains_sent"], GameState.research_points,
		GameState.researched, _automation_count(), game.island.land.size(), " ".join(orders)])


func _finish() -> void:
	_results.append({
		"orders_done": GameState.stats["orders_done"],
		"orders_missed": GameState.stats["orders_missed"],
		"coins": GameState.coins,
		"factories": game.island.factories.size(),
		"research": GameState.researched.size(),
		"auto": _automation_count(),
		"first_auto": _first_auto_round,
		"land": game.island.land.size(),
	})
	var r: Dictionary = _results[-1]
	if verbose:
		print("game over after %d rounds: %s" % [_rounds_per_game, r])
	else:
		print("game %d/%d: %s" % [_results.size(), _games_total, r])
	if _results.size() < _games_total:
		game.get_tree().reload_current_scene.call_deferred()
		return
	if _games_total > 1:
		_print_summary()
	get_tree().quit()


func _print_summary() -> void:
	var n := float(_results.size())
	var keys := ["orders_done", "orders_missed", "coins", "factories", "research", "auto", "land"]
	var parts: Array[String] = []
	for key in keys:
		var total := 0.0
		for r in _results:
			total += float(r[key])
		parts.append("%s %.1f" % [key, total / n])
	var autos: Array[int] = []
	for r in _results:
		if int(r["first_auto"]) > 0:
			autos.append(int(r["first_auto"]))
	var first_auto := "never"
	if not autos.is_empty():
		var sum := 0
		for a in autos:
			sum += a
		first_auto = "round %.1f (%d/%d games)" % [float(sum) / autos.size(), autos.size(), _results.size()]
	print("=== rules=%s, %d games x %d rounds ===" % [GameState.rules_id, _results.size(), _rounds_per_game])
	print("avg " + ", ".join(parts) + ", first automation " + first_auto)


func _log(text: String) -> void:
	if verbose:
		print(text)
