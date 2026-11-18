extends Node
## Global state of the current run: active rules, coins, hearts, round, items and card decks.
## Every number comes from `rules` (a GameRules resource), so rule variants can be swapped
## without touching code.

signal coins_changed(value: int)
signal hearts_changed(value: int)
signal round_changed(round_number: int)
signal items_changed
signal decks_changed
signal game_over(won: bool)

const RULES_DIR := "res://data/rules/"
const DEFAULT_RULES := "default"

## Active rule variant (file name without extension, see RULES_DIR).
var rules_id := DEFAULT_RULES
var rules: GameRules

## Index into rules.levels; set by the main menu before the game scene starts.
var level_index := 0

var coins := 0:
	set(value):
		coins = value
		coins_changed.emit(coins)

var hearts := 0:
	set(value):
		hearts = maxi(value, 0)
		hearts_changed.emit(hearts)

## 0-based index into the current level's rounds.
var round_index := 0:
	set(value):
		round_index = value
		round_changed.emit(round_index + 1)

## item id -> count
var items := {}
## deck id -> Array of building ids (front = top card)
var _draw_piles := {}
## deck id -> Array of played building ids
var _discard_piles := {}
var _item_pile: Array[String] = []


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--rules="):
			rules_id = arg.trim_prefix("--rules=")
	load_rules(rules_id)


# --- Rules ---

## File names (without extension) of all rule variants in RULES_DIR.
static func available_rules() -> Array[String]:
	var result: Array[String] = []
	for file in DirAccess.get_files_at(RULES_DIR):
		# Exported builds list "x.tres.remap" instead of "x.tres".
		file = file.trim_suffix(".remap")
		if file.ends_with(".tres"):
			result.append(file.get_basename())
	result.sort()
	return result


func load_rules(id: String) -> void:
	var path := RULES_DIR + id + ".tres"
	if not ResourceLoader.exists(path):
		push_warning("Rules '%s' not found, using '%s'" % [id, DEFAULT_RULES])
		id = DEFAULT_RULES
		path = RULES_DIR + id + ".tres"
	rules_id = id
	rules = load(path) as GameRules
	reset()


func reset() -> void:
	coins = rules.start_coins
	hearts = rules.start_hearts
	round_index = 0
	items = rules.start_items.duplicate()
	_item_pile = _shuffled(rules.item_deck)
	_draw_piles.clear()
	_discard_piles.clear()
	for deck_id in rules.deck_order:
		_draw_piles[deck_id] = _shuffled(rules.decks[deck_id]["cards"])
		_discard_piles[deck_id] = []
	items_changed.emit()
	decks_changed.emit()


# --- Level & rounds ---

func level() -> Dictionary:
	return rules.levels[clampi(level_index, 0, rules.levels.size() - 1)]


func rounds() -> Array:
	return level()["rounds"]


func round_count() -> int:
	return rounds().size()


## Trains of the current round as a string of train codes, e.g. "sb".
func trains_this_round() -> String:
	return rounds()[mini(round_index, round_count() - 1)]


## Call after all trains of a round arrived. Returns true if the run goes on.
func finish_round() -> bool:
	if hearts <= 0:
		game_over.emit(false)
		return false
	if round_index + 1 >= round_count():
		game_over.emit(true)
		return false
	round_index += 1
	return true


# --- Items ---

func item_count(item: String) -> int:
	return items.get(item, 0)


func add_items(list: Array[String]) -> void:
	for item in list:
		items[item] = item_count(item) + 1
	items_changed.emit()


## Draws `count` item cards from the item deck into the inventory. Returns what was drawn.
func deliver_items(count: int) -> Array[String]:
	var drawn := draw_item_cards(count)
	add_items(drawn)
	return drawn


## Takes cards from the item deck (refilled when empty) without adding them anywhere.
func draw_item_cards(count: int) -> Array[String]:
	var drawn: Array[String] = []
	for i in count:
		if _item_pile.is_empty():
			_item_pile = _shuffled(rules.item_deck)
		drawn.append(_item_pile.pop_back())
	return drawn


## Puts item cards back into the item deck (e.g. old marketplace offers).
func return_item_cards(cards: Array[String]) -> void:
	_item_pile.append_array(cards)
	_item_pile.shuffle()


## Swaps one inventory item for another (marketplace).
func trade_item(give: String, get_item: String) -> void:
	items[give] = item_count(give) - 1
	items[get_item] = item_count(get_item) + 1
	items_changed.emit()


# --- Card decks ---

func deck_ids() -> Array[String]:
	return rules.deck_order


func deck_name(deck_id: String) -> String:
	return rules.decks[deck_id].get("name", deck_id)


func deck_cost(deck_id: String) -> Array:
	return rules.decks[deck_id]["cost"]


func top_card(deck_id: String) -> String:
	var pile: Array = _draw_piles.get(deck_id, [])
	return pile[0] if not pile.is_empty() else ""


func cards_left(deck_id: String) -> int:
	return (_draw_piles.get(deck_id, []) as Array).size()


func can_afford(deck_id: String) -> bool:
	for item in deck_cost(deck_id):
		if item_count(item) < 1:
			return false
	return top_card(deck_id) != ""


## Pays the deck's cost and moves its top card to the discard pile.
## An empty deck is refilled from its shuffled discard pile.
func play_card(deck_id: String) -> void:
	for item in deck_cost(deck_id):
		items[item] = item_count(item) - 1
	_move_top_to_discard(deck_id)
	items_changed.emit()
	decks_changed.emit()


func can_discard(deck_id: String) -> bool:
	return coins >= rules.discard_cost and top_card(deck_id) != ""


## Moves the top card to the discard pile without building it. Costs coins.
func discard_top(deck_id: String) -> void:
	if not can_discard(deck_id):
		return
	coins -= rules.discard_cost
	_move_top_to_discard(deck_id)
	decks_changed.emit()


func _move_top_to_discard(deck_id: String) -> void:
	var pile: Array = _draw_piles[deck_id]
	var discard: Array = _discard_piles[deck_id]
	discard.append(pile.pop_front())
	if pile.is_empty():
		pile.append_array(discard)
		pile.shuffle()
		discard.clear()


## Expands {id: count} into a shuffled list.
func _shuffled(counts: Dictionary) -> Array[String]:
	var list: Array[String] = []
	for id in counts:
		for i in int(counts[id]):
			list.append(id)
	list.shuffle()
	return list
