extends Control
## Title screen: pick a level, then the game scene starts.
## Test arguments (`--autoplay`, `--demo-build`, `--demo-market`, `--level=N`) skip the menu.

const GAME_SCENE := "res://scenes/main.tscn"
const SKIP_MENU_ARGS: Array[String] = ["--autoplay", "--demo-build", "--demo-market"]

@onready var _level_buttons: VBoxContainer = %LevelButtons
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	for i in GameData.LEVELS.size():
		var level: Dictionary = GameData.LEVELS[i]
		var button := Button.new()
		button.text = "%s\n%s" % [level["name"], level["description"]]
		button.custom_minimum_size = Vector2(0, 110)
		button.add_theme_font_size_override("font_size", 26)
		button.pressed.connect(start_level.bind(i))
		_level_buttons.add_child(button)
	# Quitting makes no sense on phones / in the browser.
	_quit_button.visible = not OS.has_feature("mobile") and not OS.has_feature("web")
	_quit_button.pressed.connect(get_tree().quit)

	var skip_menu := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			GameState.level_index = int(arg.trim_prefix("--level=")) - 1
			skip_menu = true
		elif SKIP_MENU_ARGS.has(arg):
			skip_menu = true
	if skip_menu:
		start_level.call_deferred(GameState.level_index)


func start_level(index: int) -> void:
	GameState.level_index = index
	get_tree().change_scene_to_file(GAME_SCENE)
