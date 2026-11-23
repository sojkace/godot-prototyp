class_name DeckPanel
extends PanelContainer
## Deck window: the deck always has GameRules.deck_size cards. Pick a card of the deck
## (left), then a card of the collection (right) to swap it in. Costs coins.

signal swap_requested(out_card: String, in_card: String)

var _selected := ""
var _deck_list: VBoxContainer
var _collection_list: VBoxContainer
var _status: Label


func _ready() -> void:
	var column := UiKit.setup_dialog(self, 20, 760.0)
	column.add_child(UiKit.label(28, "Deck"))
	_status = UiKit.label(17)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_status)
	var lists := HBoxContainer.new()
	lists.add_theme_constant_override("separation", 20)
	column.add_child(lists)
	_deck_list = _scroll_list(lists, "Im Deck (antippen zum Rausnehmen)")
	_collection_list = _scroll_list(lists, "Sammlung (antippen zum Reinnehmen)")
	column.add_child(UiKit.button("Schließen", close, 22, 52.0))
	GameState.cards_changed.connect(_refresh_later)
	GameState.research_changed.connect(_refresh_later)
	GameState.coins_changed.connect(_refresh_later.unbind(1))
	hide()


func open() -> void:
	_selected = ""
	_refresh()
	show()


func close() -> void:
	hide()


func _scroll_list(parent: Control, title: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(UiKit.label(18, title))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(360, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	parent.add_child(box)
	return list


## Buttons must not be freed while their own pressed signal runs.
func _refresh_later() -> void:
	_refresh.call_deferred()


func _refresh() -> void:
	if not is_node_ready():
		return
	for list in [_deck_list, _collection_list]:
		for child in list.get_children():
			list.remove_child(child)
			child.queue_free()
	var counts := GameState.deck_counts()
	var ids: Array = counts.keys()
	ids.sort_custom(func(a: String, b: String) -> bool: return CardShape.card_name(a) < CardShape.card_name(b))
	for card_id: String in ids:
		var button := _card_button("%d× %s" % [counts[card_id], CardShape.card_name(card_id)], card_id)
		button.toggle_mode = true
		button.button_pressed = card_id == _selected
		button.pressed.connect(_select.bind(card_id))
		if GameState.is_curse(card_id):
			button.modulate = Color(1, 0.6, 0.55)
		_deck_list.add_child(button)
	for card_id in GameState.collection:
		var count: int = counts.get(card_id, 0)
		var button := _card_button("%s%s" % [CardShape.card_name(card_id),
			"  (%d im Deck)" % count if count > 0 else ""], card_id)
		button.disabled = _selected == "" or not GameState.can_swap(_selected, card_id)
		button.pressed.connect(_swap.bind(card_id))
		_collection_list.add_child(button)
	var text := "%d Karten · Stapel %d · Ablage %d · Tauschen kostet %d Münzen (Fluchkarte %d)" % [
		GameState.deck_cards().size(), GameState.draw_pile.size(), GameState.discard_pile.size(),
		GameState.rules.swap_cost, GameState.rules.curse_swap_cost]
	if _selected != "":
		text += "\nRaus: %s für %d Münzen – jetzt rechts die neue Karte wählen" % [
			CardShape.card_name(_selected), GameState.swap_price(_selected)]
	_status.text = text


func _card_button(text: String, card_id: String) -> Button:
	var button := UiKit.button(text, func() -> void: pass, 17, 40.0)
	button.icon = GameData.icon(CardShape.icon_id(card_id))
	button.expand_icon = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_constant_override("icon_max_width", 32)
	return button


func _select(card_id: String) -> void:
	_selected = "" if _selected == card_id else card_id
	_refresh_later()


func _swap(card_id: String) -> void:
	if _selected == "":
		return
	swap_requested.emit(_selected, card_id)
	if not GameState.deck_counts().has(_selected):
		_selected = ""
	_refresh_later()
