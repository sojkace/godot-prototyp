@tool
extends EditorScenePostImport
## Runs on every imported .glb (set as default in project.godot [importer_defaults]).
## Replaces the materials exported from Blender with the shared project materials,
## so all models use one palette texture instead of one copy per model.

const PIXPAL_MATERIAL := preload("res://assets/materials/pixpal.tres")
const ICON_MATERIAL := preload("res://assets/materials/item_icon.tres")


func _post_import(scene: Node) -> Object:
	_apply_materials(scene)
	return scene


func _apply_materials(node: Node) -> void:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance and mesh_instance.mesh:
		var mesh := mesh_instance.mesh
		for i in mesh.get_surface_count():
			var mat := mesh.surface_get_material(i)
			var mat_name: String = mat.resource_name if mat else ""
			if mat_name == "ItemIcon":
				mesh.surface_set_material(i, ICON_MATERIAL)
			else:
				mesh.surface_set_material(i, PIXPAL_MATERIAL)
	for child in node.get_children():
		_apply_materials(child)
