class_name Marketplace
extends Building
## Lets the player swap inventory items 1:1 for its offers (GameRules.market_trades_per_round
## per round). Offers come from the item deck and are replaced every few rounds
## (Unity: numberOfCards = 6, cycleOfUpdates = 3).

signal changed

var offers: Array[String] = []
var trades_left := 0
var rounds_until_refresh := 0

@onready var _model_active: Node3D = $Model
@onready var _model_used: Node3D = $ModelUsed


func _ready() -> void:
	if is_preview:
		return
	trades_left = GameState.rules.market_trades_per_round
	_refresh_offers()
	_update_model()


func is_used_up() -> bool:
	return trades_left <= 0


func can_trade(offer_index: int, give_item: String) -> bool:
	return not is_used_up() \
		and offer_index >= 0 and offer_index < offers.size() \
		and offers[offer_index] != give_item \
		and GameState.item_count(give_item) > 0


## The player gives `give_item` and gets the offer; the given item becomes the new offer.
func trade(offer_index: int, give_item: String) -> void:
	if not can_trade(offer_index, give_item):
		return
	GameState.trade_item(give_item, offers[offer_index])
	offers[offer_index] = give_item
	trades_left -= 1
	_update_model()
	changed.emit()


func on_tapped() -> void:
	Events.market_requested.emit(self)


func on_round_end() -> void:
	trades_left = GameState.rules.market_trades_per_round
	rounds_until_refresh -= 1
	if rounds_until_refresh <= 0:
		_refresh_offers()
	_update_model()
	changed.emit()


func _refresh_offers() -> void:
	GameState.return_item_cards(offers)
	offers = GameState.draw_item_cards(GameState.rules.market_offer_count)
	rounds_until_refresh = GameState.rules.market_refresh_rounds


## Grey roof (marketplace_deaktive) once this round's trades are used.
func _update_model() -> void:
	_model_active.visible = not is_used_up()
	_model_used.visible = is_used_up()
