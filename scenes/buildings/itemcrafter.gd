class_name ItemCrafter
extends Building
## Workshop: after every round it has GameRules.items_per_crafter items of one random kind
## ready (drawn from the item deck). A sign with the item floats above it; the player taps
## the workshop to collect (one action). Uncollected items do not pile up.
## Automated (master card): the items go straight into the inventory.

const ICON_MATERIAL_NAME := "ItemIcon"

## Item kind waiting to be collected ("" = nothing ready).
var ready_item := ""

@onready var _collect_icon: Node3D = $CollectIcon
var _icon_tween: Tween


func _ready() -> void:
	_collect_icon.hide()


func is_ready_to_collect() -> bool:
	return ready_item != ""


func on_round_end() -> void:
	if is_ready_to_collect():
		return
	ready_item = GameState.draw_item_cards(1)[0]
	if automated:
		collect()
	else:
		_show_icon()


func tap_costs_action() -> bool:
	return is_ready_to_collect()


func on_tapped() -> void:
	collect()


func can_automate() -> bool:
	return true


func collect() -> void:
	if not is_ready_to_collect():
		return
	var delivered: Array[String] = []
	for i in GameState.rules.items_per_crafter:
		delivered.append(ready_item)
	ready_item = ""
	GameState.add_items(delivered)
	Events.items_delivered.emit(delivered, self)
	_hide_icon()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.1, 0.9, 1.1), 0.1)
	tween.tween_property(self, "scale", Vector3.ONE, 0.2)


func _show_icon() -> void:
	_set_icon_texture(_collect_icon, GameData.icon(ready_item))
	_set_icon_texture($Model, GameData.icon(ready_item))
	_collect_icon.show()
	_collect_icon.position.y = 0.45
	if _icon_tween:
		_icon_tween.kill()
	_icon_tween = create_tween().set_loops()
	_icon_tween.tween_property(_collect_icon, "rotation:y", TAU, 2.0).from(0.0)
	var bob := create_tween().set_loops()
	bob.tween_property(_collect_icon, "position:y", 0.6, 0.6).set_trans(Tween.TRANS_SINE)
	bob.tween_property(_collect_icon, "position:y", 0.45, 0.6).set_trans(Tween.TRANS_SINE)
	_collect_icon.set_meta("bob", bob)


func _hide_icon() -> void:
	if _icon_tween:
		_icon_tween.kill()
	if _collect_icon.has_meta("bob"):
		(_collect_icon.get_meta("bob") as Tween).kill()
	_collect_icon.hide()
	_set_icon_texture($Model, null)


## Puts `texture` on every surface that uses the "ItemIcon" material below `root`.
func _set_icon_texture(root: Node, texture: Texture2D) -> void:
	for mesh_instance: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		for i in mesh_instance.get_surface_override_material_count():
			var base := mesh_instance.mesh.surface_get_material(i)
			if base == null or base.resource_name != ICON_MATERIAL_NAME:
				continue
			var material := (base as StandardMaterial3D).duplicate() as StandardMaterial3D
			material.albedo_texture = texture
			mesh_instance.set_surface_override_material(i, material)
