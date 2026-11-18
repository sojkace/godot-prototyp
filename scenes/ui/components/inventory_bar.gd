class_name InventoryBar
extends HBoxContainer
## Shows icon + count for every item; updates itself from GameState.

const ICON_SIZE := Vector2(40, 40)

var _labels := {}  # item id -> Label


func _ready() -> void:
	for item in GameData.ITEMS:
		var item_icon := UiKit.icon(GameData.icon(item), ICON_SIZE)
		item_icon.tooltip_text = GameData.item_name(item)
		var count := UiKit.label(26)
		count.custom_minimum_size = Vector2(36, 0)
		add_child(item_icon)
		add_child(count)
		_labels[item] = count
	GameState.items_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for item in _labels:
		(_labels[item] as Label).text = str(GameState.item_count(item))
