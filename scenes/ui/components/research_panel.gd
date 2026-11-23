class_name ResearchPanel
extends PanelContainer
## Research window: milestones give research points; research unlocks cards for the
## collection (then swap them into the deck) or extra actions.

signal research_requested(index: int)

var _points: Label
var _research_list: VBoxContainer
var _milestone_list: VBoxContainer


func _ready() -> void:
	var column := UiKit.setup_dialog(self, 20, 820.0)
	column.add_child(UiKit.label(28, "Forschung"))
	_points = UiKit.label(20)
	column.add_child(_points)
	var lists := HBoxContainer.new()
	lists.add_theme_constant_override("separation", 20)
	column.add_child(lists)
	_research_list = _list(lists, "Forschen", 480)
	_milestone_list = _list(lists, "Meilensteine (geben Punkte)", 300)
	column.add_child(UiKit.button("Schließen", hide, 22, 52.0))
	GameState.research_changed.connect(_refresh_later)
	hide()


func open() -> void:
	_refresh()
	show()


func _list(parent: Control, title: String, width: float) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_child(UiKit.label(18, title))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(width, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	parent.add_child(box)
	return list


## Buttons must not be freed while their own pressed signal runs.
func _refresh_later() -> void:
	_refresh.call_deferred()


func _refresh() -> void:
	if not is_node_ready():
		return
	_points.text = "Forschungspunkte: %d" % GameState.research_points
	for list in [_research_list, _milestone_list]:
		for child in list.get_children():
			list.remove_child(child)
			child.queue_free()
	var research := GameState.rules.research
	for i in research.size():
		var entry: Dictionary = research[i]
		var done := GameState.researched.has(entry["id"])
		var text := "%s  (%d P)\n%s" % [entry["name"], int(entry["cost"]), entry.get("description", "")]
		if done:
			text = "%s – erforscht\n%s" % [entry["name"], entry.get("description", "")]
		var button := UiKit.button(text, research_requested.emit.bind(i), 16, 58.0)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = not GameState.can_research(entry)
		_research_list.add_child(button)
	var milestones := GameState.rules.milestones
	for i in milestones.size():
		var milestone: Dictionary = milestones[i]
		var done := GameState.milestone_done(i)
		var label := UiKit.label(16, "%s %s  (+%d P)  %d/%d" % ["[x]" if done else "[ ]", milestone["name"],
			int(milestone["points"]), mini(int(GameState.stats.get(milestone["stat"], 0)), int(milestone["target"])),
			int(milestone["target"])])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.modulate = Color(0.6, 1.0, 0.6) if done else Color.WHITE
		_milestone_list.add_child(label)
