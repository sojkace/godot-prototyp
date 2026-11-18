class_name PauseMenu
extends PanelContainer
## Pause dialog: pauses the tree while visible. Needs PROCESS_MODE_ALWAYS on a parent.

signal restart_pressed
signal menu_pressed


func _ready() -> void:
	var column := UiKit.setup_dialog(self, 24, 360.0)
	column.add_child(UiKit.label(32, "Pause"))
	column.add_child(UiKit.button("Weiter", set_paused.bind(false)))
	column.add_child(UiKit.button("Neu starten", restart_pressed.emit))
	column.add_child(UiKit.button("Hauptmenü", menu_pressed.emit))
	hide()


func set_paused(paused: bool) -> void:
	get_tree().paused = paused
	visible = paused
