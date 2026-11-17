class_name Marketplace
extends Building
## Lets the player swap one inventory item 1:1 for one of its offers, once per round.
## Offers come from the item deck and are replaced every few rounds
## (Unity: numberOfCards = 6, cycleOfUpdates = 3).

signal changed

@export var offer_count := 6
@export var refresh_every_rounds := 3

var offers: Array[String] = []
var used_this_round := false
var rounds_until_refresh := 0

@onready var _model_active: Node3D = $Model
@onready var _model_used: Node3D = $ModelUsed


func _ready() -> void:
	_refresh_offers()
	_update_model()


func can_trade(offer_index: int, give_item: String) -> bool:
	return not used_this_round \
		and offer_index >= 0 and offer_index < offers.size() \
		and offers[offer_index] != give_item \
		and GameState.item_count(give_item) > 0


## The player gives `give_item` and gets the offer; the given item becomes the new offer.
func trade(offer_index: int, give_item: String) -> void:
	if not can_trade(offer_index, give_item):
		return
	GameState.trade_item(give_item, offers[offer_index])
	offers[offer_index] = give_item
	used_this_round = true
	_update_model()
	changed.emit()


func on_round_end() -> void:
	used_this_round = false
	rounds_until_refresh -= 1
	if rounds_until_refresh <= 0:
		_refresh_offers()
	_update_model()
	changed.emit()


func _refresh_offers() -> void:
	GameState.return_item_cards(offers)
	offers = GameState.draw_item_cards(offer_count)
	rounds_until_refresh = refresh_every_rounds


## Grey roof (marketplace_deaktive) once today's trade is used.
func _update_model() -> void:
	_model_active.visible = not used_this_round
	_model_used.visible = used_this_round
