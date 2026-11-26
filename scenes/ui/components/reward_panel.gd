class_name RewardPanel
extends PanelContainer
## Card choice after a finished order (GameState.pending_rewards): pick one of the offered
## collection cards, then the deck card it replaces; or take coins instead.
## Opens by itself while a choice is waiting and the round is not running (see Hud).

signal card_chosen(in_card: String, out_card: String)
signal coins_chosen

const CARD_SIZE := Vector2(170, 190)

## Card picked in step 1 ("" = still choosing the new card).
var _picked := ""
var _title: Label
var _hint: Label
var _content: VBoxContainer


func _ready() -> void:
	var column := UiKit.setup_dialog(self, 22, 720.0)
	_title = UiKit.label(28)
	column.add_child(_title)
	_hint = UiKit.label(18)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_hint)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 12)
	column.add_child(_content)
	hide()


func open() -> void:
	_picked = ""
	_refresh()
	show()


## Buttons must not be freed while their own pressed signal runs.
func refresh_later() -> void:
	_refresh.call_deferred()


func _refresh() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	if GameState.pending_rewards <= 0:
		hide()
		return
	var waiting := GameState.pending_rewards
	if _picked == "":
		_title.text = "Auftrag erfüllt – wähle eine Karte"
		_hint.text = "Die Karte kommt ins Deck, dafür fliegt eine andere raus (das Deck bleibt bei %d Karten)." \
			% GameState.rules.deck_size
		if waiting > 1:
			_hint.text += "\nNoch %d weitere Wahl(en) danach." % (waiting - 1)
		_content.add_child(_offer_row())
		_content.add_child(UiKit.button("Keine Karte, lieber %d Münzen" % GameState.rules.reward_coins,
			_take_coins, 20, 52.0))
	else:
		_title.text = "Welche Karte fliegt raus?"
		_hint.text = "Für „%s“ verlässt eine Karte das Deck. Fluchkarten (rot) wirst du so los." \
			% CardShape.card_name(_picked)
		_content.add_child(_deck_grid())
		_content.add_child(UiKit.button("Zurück", _pick.bind(""), 20, 48.0))


func _offer_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	var counts := GameState.deck_counts()
	for card_id in GameState.reward_offer():
		var button := Button.new()
		button.custom_minimum_size = CARD_SIZE
		button.pressed.connect(_pick.bind(card_id))
		button.tooltip_text = HandBar.tooltip(card_id)
		var inner := VBoxContainer.new()
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		button.add_child(inner)
		var visuals := HBoxContainer.new()
		visuals.alignment = BoxContainer.ALIGNMENT_CENTER
		visuals.mouse_filter = Control.MOUSE_FILTER_IGNORE
		visuals.add_child(UiKit.icon(GameData.icon(CardShape.icon_id(card_id)), Vector2(60, 68)))
		var shape := ShapePreview.new()
		shape.custom_minimum_size = Vector2(60, 68)
		shape.card_id = card_id
		visuals.add_child(shape)
		inner.add_child(visuals)
		var name_label := UiKit.label(18, CardShape.card_name(card_id))
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inner.add_child(name_label)
		inner.add_child(UiKit.label(14, "%d im Deck" % int(counts.get(card_id, 0))))
		row.add_child(button)
	return row


func _deck_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	var counts := GameState.deck_counts()
	var ids: Array = counts.keys()
	# Curses first, then by name.
	ids.sort_custom(func(a: String, b: String) -> bool:
		if GameState.is_curse(a) != GameState.is_curse(b):
			return GameState.is_curse(a)
		return CardShape.card_name(a) < CardShape.card_name(b))
	for card_id: String in ids:
		var button := UiKit.button("%d× %s" % [counts[card_id], CardShape.card_name(card_id)],
			_replace.bind(card_id), 17, 44.0)
		button.custom_minimum_size.x = 220
		button.icon = GameData.icon(CardShape.icon_id(card_id))
		button.expand_icon = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_constant_override("icon_max_width", 30)
		if GameState.is_curse(card_id):
			button.modulate = Color(1, 0.6, 0.55)
		grid.add_child(button)
	return grid


func _pick(card_id: String) -> void:
	_picked = card_id
	refresh_later()


func _replace(out_card: String) -> void:
	var in_card := _picked
	_picked = ""
	card_chosen.emit(in_card, out_card)
	refresh_later()


func _take_coins() -> void:
	_picked = ""
	coins_chosen.emit()
	refresh_later()
