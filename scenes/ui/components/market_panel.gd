class_name MarketPanel
extends PanelContainer
## Trade window of one marketplace: pick an offer, then tap the item you give for it.

signal closed
## Short result message for a toast, e.g. "Getauscht: -1 Holz, +1 Glas".
signal traded(message: String)

var _market: Marketplace
var _selected_offer := -1
var _status: Label
var _offer_grid: GridContainer
var _give_row: HBoxContainer


func _ready() -> void:
	var column := UiKit.setup_dialog(self)
	column.add_child(UiKit.label(28, "Marktplatz"))
	column.add_child(UiKit.label(18, "1. Ware wählen   2. tippen, was du dafür gibst"))

	_offer_grid = GridContainer.new()
	_offer_grid.columns = 3
	_offer_grid.add_theme_constant_override("h_separation", 10)
	_offer_grid.add_theme_constant_override("v_separation", 10)
	column.add_child(_offer_grid)

	column.add_child(UiKit.label(20, "Du gibst:"))
	_give_row = HBoxContainer.new()
	_give_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_give_row.add_theme_constant_override("separation", 10)
	column.add_child(_give_row)
	for item in GameData.ITEMS:
		var give := Button.new()
		give.icon = GameData.icon(item)
		give.expand_icon = true
		give.custom_minimum_size = Vector2(110, 80)
		give.add_theme_font_size_override("font_size", 22)
		give.set_meta("item", item)
		give.pressed.connect(_on_give_pressed.bind(item))
		_give_row.add_child(give)

	_status = UiKit.label(18)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(420, 0)
	column.add_child(_status)
	column.add_child(UiKit.button("Schließen", close))
	GameState.items_changed.connect(_refresh)
	hide()


func open(market: Marketplace) -> void:
	_set_market(market)
	_selected_offer = -1
	show()
	_refresh()


func close() -> void:
	_set_market(null)
	hide()
	closed.emit()


func _set_market(market: Marketplace) -> void:
	if _market and is_instance_valid(_market) and _market.changed.is_connected(_refresh):
		_market.changed.disconnect(_refresh)
	_market = market
	if _market:
		_market.changed.connect(_refresh)


func _refresh() -> void:
	if _market == null or not is_instance_valid(_market):
		return
	for child in _offer_grid.get_children():
		child.queue_free()
	for i in _market.offers.size():
		var item := _market.offers[i]
		var offer := Button.new()
		offer.toggle_mode = true
		offer.button_pressed = i == _selected_offer
		offer.icon = GameData.icon(item)
		offer.expand_icon = true
		offer.text = GameData.item_name(item)
		offer.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		offer.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		offer.custom_minimum_size = Vector2(140, 110)
		offer.add_theme_font_size_override("font_size", 20)
		offer.disabled = _market.is_used_up()
		offer.pressed.connect(_on_offer_pressed.bind(i))
		_offer_grid.add_child(offer)
	for give: Button in _give_row.get_children():
		var item: String = give.get_meta("item")
		give.text = str(GameState.item_count(item))
		give.disabled = _selected_offer < 0 or not _market.can_trade(_selected_offer, item)
	var refresh_text := "Neue Waren in %d Runde(n)." % _market.rounds_until_refresh
	if _market.is_used_up():
		_status.text = "Diese Runde schon getauscht. " + refresh_text
	else:
		_status.text = "Noch %d Tausch diese Runde. %s" % [_market.trades_left, refresh_text]


func _on_offer_pressed(index: int) -> void:
	_selected_offer = index if _selected_offer != index else -1
	_refresh()


func _on_give_pressed(item: String) -> void:
	if _market and _market.can_trade(_selected_offer, item):
		var got := GameData.item_name(_market.offers[_selected_offer])
		_market.trade(_selected_offer, item)
		_selected_offer = -1
		traded.emit("Getauscht: -1 %s, +1 %s" % [GameData.item_name(item), got])
