# Render UI icons (transparent PNG) for items and buildings from art_src/blender/3DObj.blend
# into assets/ui/icons/<id>.png.
#
#   flatpak run org.blender.Blender --background "$PWD/art_src/blender/3DObj.blend" \
#       --python "$PWD/tools/blender/render_icons.py"

import bpy
import os
from mathutils import Vector

REPO = os.path.abspath(os.path.join(os.path.dirname(bpy.data.filepath), "..", ".."))
OUT_DIR = os.path.join(REPO, "assets", "ui", "icons")
SIZE = 256

# icon id -> object name in the .blend
ICONS = {
    "wood": "wood",
    "stone": "stone",
    "metal": "metal",
    "glass": "glass",
    "fabric": "fabric",
    "coin": "coin",
    "heart": "heart_normal",
    "rail_straight": "rail_strait",
    "rail_curve": "rail_curve",
    "mine_gold": "mine_gold",
    "mine_silver": "mine_siver",
    "itemcrafter": "itemcrafter",
    "marketplace": "marketplace",
    "flag_normal": "flag_normal",
    "flag_pointy": "flag_pointy",
    "observer": "observer",
    "train": "train_1_4",
    "train_big": "train_2_8",
    "power_station": "power_station",
}

scene = bpy.context.scene
scene.render.engine = "BLENDER_WORKBENCH"
scene.display.shading.light = "STUDIO"
scene.display.shading.color_type = "TEXTURE"
scene.render.film_transparent = True
scene.render.resolution_x = scene.render.resolution_y = SIZE
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"

for c in bpy.data.collections:
    c.hide_render = False
for lc in bpy.context.view_layer.layer_collection.children:
    lc.exclude = False

cam = bpy.data.objects.new("IconCam", bpy.data.cameras.new("IconCam"))
cam.data.type = "ORTHO"
scene.collection.objects.link(cam)
scene.camera = cam

# The runtime icon slot ("texture" material) references a missing image -> render it plain white.
icon_mat = bpy.data.materials.get("texture")
if icon_mat and icon_mat.use_nodes:
    for node in icon_mat.node_tree.nodes:
        if node.type == "TEX_IMAGE":
            node.image = None
    icon_mat.diffuse_color = (0.9, 0.9, 0.9, 1.0)

os.makedirs(OUT_DIR, exist_ok=True)
for o in bpy.data.objects:
    o.hide_render = True

for icon_id, obj_name in ICONS.items():
    obj = bpy.data.objects[obj_name]
    obj.hide_render = False
    corners = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    zs = [c.z for c in corners]
    # buildings sit on a 10 m pillar: frame only the top part
    mn = Vector((min(c.x for c in corners), min(c.y for c in corners), max(min(zs), -0.4)))
    mx = Vector((max(c.x for c in corners), max(c.y for c in corners), max(zs)))
    center = (mn + mx) / 2
    size = max((mx - mn).length, 0.05)
    cam.location = center + Vector((1, -1, 1.1)).normalized() * size * 3
    cam.rotation_euler = (center - cam.location).to_track_quat("-Z", "Y").to_euler()
    cam.data.ortho_scale = size * 1.05
    cam.data.clip_end = size * 10
    scene.render.filepath = os.path.join(OUT_DIR, icon_id + ".png")
    bpy.ops.render.render(write_still=True)
    obj.hide_render = True

print("ICONS_DONE", len(ICONS))
