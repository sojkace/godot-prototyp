extends Node
## Global state of the current run: active rules, coins, actions, round, the card deck
## (draw pile, hand, discard pile), collection, research and milestones.
## Every number comes from `rules` (a GameRules resource), so rule variants can be swapped
## without touching code.

signal coins_changed(value: int)
signal round_changed(round_number: int)
signal actions_changed(value: int)
## Hand, deck composition or piles changed.
signal cards_changed
## Research points, finished research or collection changed.
signal research_changed
## A card choice became due or was made (see pending_rewards).
signal rewards_changed
signal milestone_reached(milestone: Dictionary)

const RULES_DIR := "res://data/rules/"
const DEFAULT_RULES := "default"

## Active rule variant (file name without extension, see RULES_DIR).
var rules_id := DEFAULT_RULES
var rules: GameRules

var coins := 0:
	set(value):
		coins = value
		coins_changed.emit(coins)

## 0-based round counter (the game is endless).
var round_index := 0:
	set(value):
		round_index = value
		round_changed.emit(round_index + 1)

## Actions left this round.
var actions := 0:
	set(value):
		actions = maxi(value, 0)
		actions_changed.emit(actions)

## The deck: always rules.deck_size card ids, spread over these places.
var draw_pile: Array[String] = []
var hand: Array[String] = []
var discard_pile: Array[String] = []

## Card ids that may be swapped into the deck.
var collection: Array[String] = []
var research_points := 0
## Card choices waiting for the player (one per finished order).
var pending_rewards := 0
## The current choice: GameRules.reward_choices card ids (empty until asked for).
var _offer: Array[String] = []
## Freshly researched cards; they come first in the next card choice.
var _fresh_cards: Array[String] = []
## Ids of finished research entries.
var researched: Array[String] = []

## Counters for milestones and statistics: orders_done, orders_missed, trains_sent,
## cards_played, land, factories, manual_actions, curses.
var stats := {}
var _milestones_done: Array[int] = []


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
	round_index = 0
	collection = rules.start_collection.duplicate()
	research_points = 0
	researched.clear()
	pending_rewards = 0
	_offer.clear()
	_fresh_cards.clear()
	stats = {"orders_done": 0, "orders_missed": 0, "trains_sent": 0, "cards_played": 0,
		"land": 0, "factories": 0, "manual_actions": 0, "curses": 0}
	_milestones_done.clear()
	draw_pile = _shuffled(rules.start_deck)
	hand.clear()
	discard_pile.clear()
	if draw_pile.size() != rules.deck_size:
		push_warning("start_deck has %d cards, deck_size is %d" % [draw_pile.size(), rules.deck_size])
	actions = max_actions()
	cards_changed.emit()
	research_changed.emit()
	rewards_changed.emit()


# --- Round & actions ---

func max_actions() -> int:
	var result := rules.actions_per_round
	for entry in rules.research:
		if researched.has(entry["id"]):
			result += int(entry.get("actions", 0))
	return result


## Spends one action (play a card, tap a mine, send a train). False if none is left.
func spend_action() -> bool:
	if actions <= 0:
		return false
	actions -= 1
	add_stat("manual_actions")
	return true


## Next round: actions refill and the hand is filled up again (unplayed cards stay).
func next_round() -> void:
	round_index += 1
	actions = max_actions()
	draw_hand()


func draw_hand() -> void:
	while hand.size() < rules.hand_size:
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				break
			draw_pile = discard_pile.duplicate()
			draw_pile.shuffle()
			discard_pile.clear()
		hand.append(draw_pile.pop_back())
	cards_changed.emit()


# --- Stats & milestones ---

func add_stat(stat: String, amount := 1) -> void:
	set_stat(stat, int(stats.get(stat, 0)) + amount)


func set_stat(stat: String, value: int) -> void:
	stats[stat] = value
	_check_milestones()


func _check_milestones() -> void:
	for i in rules.milestones.size():
		var milestone: Dictionary = rules.milestones[i]
		if _milestones_done.has(i) or int(stats.get(milestone["stat"], 0)) < int(milestone["target"]):
			continue
		_milestones_done.append(i)
		research_points += int(milestone["points"])
		milestone_reached.emit(milestone)
		research_changed.emit()


func milestone_done(index: int) -> bool:
	return _milestones_done.has(index)


# --- Research ---

func can_research(entry: Dictionary) -> bool:
	return not researched.has(entry["id"]) and research_points >= int(entry["cost"])


func do_research(entry: Dictionary) -> void:
	if not can_research(entry):
		return
	research_points -= int(entry["cost"])
	researched.append(entry["id"])
	for card_id: String in entry.get("unlocks", []):
		if not collection.has(card_id):
			collection.append(card_id)
			_fresh_cards.append(card_id)
	if entry.has("actions"):
		actions += int(entry["actions"])
	research_changed.emit()


# --- Cards ---

## A "slot" is an index into the hand.
func card_in_slot(slot: int) -> String:
	return hand[slot] if slot >= 0 and slot < hand.size() else ""


## Moves the card to the discard pile (its empty slot is refilled next round).
## The action it costs is spent by Main.
func play_slot(slot: int) -> void:
	var card_id := card_in_slot(slot)
	if card_id == "":
		return
	hand.remove_at(slot)
	discard_pile.append(card_id)
	add_stat("cards_played")
	cards_changed.emit()


func can_discard(slot: int) -> bool:
	return card_in_slot(slot) != "" and coins >= rules.discard_cost


## Throws a card away for coins and draws a new one into the hand.
func discard_slot(slot: int) -> void:
	if not can_discard(slot):
		return
	coins -= rules.discard_cost
	discard_pile.append(card_in_slot(slot))
	hand.remove_at(slot)
	draw_hand()


# --- Deck building ---

## Every card of the deck, wherever it is right now.
func deck_cards() -> Array[String]:
	var result: Array[String] = draw_pile.duplicate()
	result.append_array(hand)
	result.append_array(discard_pile)
	return result


## card id -> count over the whole deck.
func deck_counts() -> Dictionary:
	var counts := {}
	for card_id in deck_cards():
		counts[card_id] = counts.get(card_id, 0) + 1
	return counts


func is_curse(card_id: String) -> bool:
	return CardShape.definition(card_id).get("curse", false)


# --- Card choice (after every finished order) ---

func add_reward() -> void:
	pending_rewards += 1
	rewards_changed.emit()


## The cards of the current choice: freshly researched ones first, the rest at random
## from the collection (no curses, nothing from GameRules.reward_excluded).
func reward_offer() -> Array[String]:
	if pending_rewards <= 0:
		return []
	if _offer.is_empty():
		for card_id in _fresh_cards:
			if _offer.size() < rules.reward_choices:
				_offer.append(card_id)
		var pool: Array[String] = []
		for card_id in collection:
			if not is_curse(card_id) and not rules.reward_excluded.has(card_id) and not _offer.has(card_id):
				pool.append(card_id)
		pool.shuffle()
		while _offer.size() < rules.reward_choices and not pool.is_empty():
			_offer.append(pool.pop_back())
	return _offer


## Takes `in_card` from the offer into the deck in place of one copy of `out_card`.
func choose_reward(in_card: String, out_card: String) -> bool:
	if not reward_offer().has(in_card) or not deck_counts().has(out_card):
		return false
	_replace_one(out_card, in_card)
	_fresh_cards.erase(in_card)
	_finish_reward()
	cards_changed.emit()
	return true


## Takes GameRules.reward_coins instead of a card.
func choose_reward_coins() -> void:
	if pending_rewards <= 0:
		return
	coins += rules.reward_coins
	_finish_reward()


func _finish_reward() -> void:
	pending_rewards -= 1
	_offer.clear()
	rewards_changed.emit()


## An expired order: a random normal card of the deck turns into a curse card.
func add_curse() -> void:
	var candidates: Array[String] = []
	for card_id in deck_cards():
		if not is_curse(card_id):
			candidates.append(card_id)
	if candidates.is_empty():
		return
	_replace_one(candidates.pick_random(), rules.curse_card)
	add_stat("curses")
	cards_changed.emit()


## Replaces a copy in the draw pile first (so the change shows up soon), then elsewhere.
func _replace_one(out_card: String, in_card: String) -> void:
	for pile: Array[String] in [draw_pile, discard_pile, hand]:
		var index := pile.find(out_card)
		if index >= 0:
			pile[index] = in_card
			if pile == draw_pile:
				draw_pile.shuffle()
			return


## Expands {id: count} into a shuffled list.
func _shuffled(counts: Dictionary) -> Array[String]:
	var list: Array[String] = []
	for id in counts:
		for i in int(counts[id]):
			list.append(id)
	list.shuffle()
	return list
