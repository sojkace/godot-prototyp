extends Control
## Title screen: pick a rule variant and a level, then the game scene starts.
## Test arguments (`--autoplay`, `--simulate=N`, `--demo-build`, `--demo-market`, `--level=N`)
## skip the menu; `--rules=<variant>` is read by GameState.

const GAME_SCENE := "res://scenes/main.tscn"
const SKIP_MENU_ARGS: Array[String] = ["--autoplay", "--demo-build", "--demo-market"]

@onready var _level_buttons: VBoxContainer = %LevelButtons
@onready var _quit_button: Button = %QuitButton

var _rules_picker: OptionButton
var _rules_description: Label


func _ready() -> void:
	_build_rules_picker()
	_build_level_buttons()
	# Quitting makes no sense on phones / in the browser.
	_quit_button.visible = not OS.has_feature("mobile") and not OS.has_feature("web")
	_quit_button.pressed.connect(get_tree().quit)

	var skip_menu := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			GameState.level_index = int(arg.trim_prefix("--level=")) - 1
			skip_menu = true
		elif SKIP_MENU_ARGS.has(arg) or arg.begins_with("--simulate="):
			skip_menu = true
	if skip_menu:
		start_level.call_deferred(GameState.level_index)


func start_level(index: int) -> void:
	GameState.level_index = index
	get_tree().change_scene_to_file(GAME_SCENE)


## Dropdown with every file in data/rules/ (only shown if there is more than one).
func _build_rules_picker() -> void:
	var ids := GameState.available_rules()
	_rules_picker = OptionButton.new()
	_rules_picker.custom_minimum_size = Vector2(0, 64)
	_rules_picker.add_theme_font_size_override("font_size", 24)
	for id in ids:
		_rules_picker.add_item(id)
		if id == GameState.rules_id:
			_rules_picker.select(_rules_picker.item_count - 1)
	_rules_picker.item_selected.connect(_on_rules_selected)
	_rules_description = UiKit.label(18)
	_rules_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var column := _level_buttons.get_parent()
	column.add_child(_rules_picker)
	column.move_child(_rules_picker, _level_buttons.get_index())
	column.add_child(_rules_description)
	column.move_child(_rules_description, _level_buttons.get_index())
	_rules_picker.visible = ids.size() > 1
	_rules_description.visible = ids.size() > 1
	_update_rules_text()


func _on_rules_selected(index: int) -> void:
	GameState.load_rules(_rules_picker.get_item_text(index))
	_update_rules_text()
	_build_level_buttons()


func _update_rules_text() -> void:
	var rules := GameState.rules
	_rules_picker.text = "Regeln: " + rules.title
	_rules_description.text = rules.description


func _build_level_buttons() -> void:
	for child in _level_buttons.get_children():
		child.queue_free()
	var levels := GameState.rules.levels
	for i in levels.size():
		var level: Dictionary = levels[i]
		var button := Button.new()
		button.text = "%s\n%s" % [level["name"], level.get("description", "")]
		button.custom_minimum_size = Vector2(0, 110)
		button.add_theme_font_size_override("font_size", 26)
		button.pressed.connect(start_level.bind(i))
		_level_buttons.add_child(button)
