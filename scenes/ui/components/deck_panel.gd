class_name DeckPanel
extends PanelContainer
## Deck window (view only): what is in the deck (always GameRules.deck_size cards) and which
## cards the collection holds. The deck only changes through the card choice after every
## finished order (RewardPanel) and through curse cards.

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
	_deck_list = _scroll_list(lists, "Im Deck")
	_collection_list = _scroll_list(lists, "Sammlung (kann bei der Kartenwahl kommen)")
	column.add_child(UiKit.button("Schließen", close, 22, 52.0))
	GameState.cards_changed.connect(_refresh_later)
	GameState.research_changed.connect(_refresh_later)
	hide()


func open() -> void:
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
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)
	parent.add_child(box)
	return list


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
		var row := _card_row("%d× %s" % [counts[card_id], CardShape.card_name(card_id)], card_id)
		if GameState.is_curse(card_id):
			row.modulate = Color(1, 0.6, 0.55)
		_deck_list.add_child(row)
	for card_id in GameState.collection:
		if GameState.rules.reward_excluded.has(card_id):
			continue
		_collection_list.add_child(_card_row(CardShape.card_name(card_id), card_id))
	_status.text = "%d Karten · Stapel %d · Ablage %d · Hand %d\nNach jedem erfüllten Auftrag wählst du eine neue Karte und eine, die dafür rausfliegt." % [
		GameState.deck_cards().size(), GameState.draw_pile.size(), GameState.discard_pile.size(),
		GameState.hand.size()]


func _card_row(text: String, card_id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(UiKit.icon(GameData.icon(CardShape.icon_id(card_id)), Vector2(30, 30)))
	var label := UiKit.label(17, text)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(label)
	return row
