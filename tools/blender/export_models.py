# Export every model from art_src/blender/3DObj.blend as its own .glb into assets/models/.
#
# Run headless (paths must be absolute for the Blender Flatpak):
#   flatpak run org.blender.Blender --background "$PWD/art_src/blender/3DObj.blend" \
#       --python "$PWD/tools/blender/export_models.py"
# Optional env: PREVIEW_DIR=/abs/path -> also renders one preview PNG per exported model.
#
# What it does (the .blend itself is never saved/modified):
# - Bakes the PixPal shader UV shift into the UVs:  v' = v - (VALUE/36) * attributes.blue(u, v)
#   (the original node setup does this at render time; glTF cannot express it).
# - Replaces all PixPal materials with one simple material using the palette base color
#   (closest filtering, roughness 1, metallic 0) so Godot gets plain textures.
# - Slots without material get the palette material; the runtime-icon slot ("texture")
#   becomes a plain white "ItemIcon" material that Godot can swap at runtime.
# - Scales by 0.5 so one grid cell is 1 m in Godot (was 2 m in Unity/Blender).

import bpy
import os
from mathutils import Vector

BLEND_DIR = os.path.dirname(bpy.data.filepath)
REPO = os.path.abspath(os.path.join(BLEND_DIR, "..", ".."))
PALETTE_DIR = os.path.join(REPO, "art_src", "imphenziaPixPal")
OUT_DIR = os.path.join(REPO, "assets", "models")
PREVIEW_DIR = os.environ.get("PREVIEW_DIR", "")

SCALE = 0.5
PIXPAL_VALUE = 4.0  # "Value" node in the original PixPal material

SKIP = {"Camera", "Sun", "grid_default"}

# old name -> (category, new name)
RENAME = {
    "Cube": ("items", "gold"),
    "wather": ("buildings", "water"),
    "mine_siver": ("buildings", "mine_silver"),
    "rail_strait": ("buildings", "rail_straight"),
    "grid_falg_pointy": ("grids", "grid_flag_pointy"),
    "IconToCollect": ("icons", "icon_to_collect"),
    "BuildState": ("buildings", "build_state"),
}


def category_for(name):
    if name in RENAME:
        return RENAME[name]
    if name.startswith("train"):
        return ("trains", name)
    if name.startswith("grid_"):
        return ("grids", name)
    if name in {"coin", "explosive", "fabric", "glass", "metal", "stone", "wood",
                "heart_broken", "heart_normal"}:
        return ("items", name)
    return ("buildings", name)


def load_png(name):
    path = os.path.join(PALETTE_DIR, name)
    img = bpy.data.images.load(path, check_existing=True)
    return img


attributes = load_png("ImphenziaPixPal_Attributes.png")
base_color = load_png("ImphenziaPixPal_BaseColor.png")
AW, AH = attributes.size
attr_px = list(attributes.pixels[:])


def attr_blue(u, v):
    # closest-pixel lookup with repeat wrapping, like the "Closest" image node
    x = int((u % 1.0) * AW) % AW
    y = int((v % 1.0) * AH) % AH
    return attr_px[(y * AW + x) * 4 + 2]


def make_palette_material():
    mat = bpy.data.materials.new("PixPal")
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = base_color
    tex.interpolation = "Closest"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 1.0
    bsdf.inputs["Metallic"].default_value = 0.0
    return mat


def make_icon_material():
    mat = bpy.data.materials.new("ItemIcon")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (1, 1, 1, 1)
    bsdf.inputs["Roughness"].default_value = 1.0
    return mat


PIXPAL = make_palette_material()
ICON = make_icon_material()


def is_pixpal(mat):
    return mat is None or mat.name.startswith("ImphenziaPixPal")


def prepare_copy(src):
    obj = src.copy()
    obj.data = src.data.copy()
    obj.animation_data_clear()
    obj.parent = None
    obj.matrix_world = src.matrix_world.copy()
    me = obj.data

    # bake palette UV shift for faces that use the palette
    slot_is_pixpal = [is_pixpal(s.material) for s in obj.material_slots] or [True]
    uv = me.uv_layers.active
    if uv is not None:
        for poly in me.polygons:
            idx = poly.material_index if poly.material_index < len(slot_is_pixpal) else 0
            if not slot_is_pixpal[idx]:
                continue
            for li in poly.loop_indices:
                u, v = uv.data[li].uv
                uv.data[li].uv = (u, v - (PIXPAL_VALUE / 36.0) * attr_blue(u, v))

    # swap materials
    if not obj.material_slots:
        me.materials.append(PIXPAL)
    for i, slot in enumerate(obj.material_slots):
        if is_pixpal(slot.material):
            me.materials[i] = PIXPAL
        else:
            me.materials[i] = ICON
    return obj


def render_preview(obj, path):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "TEXTURE"
    scene.render.resolution_x = scene.render.resolution_y = 256
    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        cam = bpy.data.objects.new("PreviewCam", bpy.data.cameras.new("PreviewCam"))
        cam.data.type = "ORTHO"
        scene.collection.objects.link(cam)
    scene.camera = cam
    corners = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    zs = [c.z for c in corners]
    mn = Vector((min(c.x for c in corners), min(c.y for c in corners), max(min(zs), -0.5)))
    mx = Vector((max(c.x for c in corners), max(c.y for c in corners), max(zs)))
    center = (mn + mx) / 2
    size = max((mx - mn).length, 0.05)
    cam.location = center + Vector((1, -1, 0.9)).normalized() * size * 3
    cam.rotation_euler = (center - cam.location).to_track_quat("-Z", "Y").to_euler()
    cam.data.ortho_scale = size * 1.15
    cam.data.clip_end = size * 10
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def main():
    scene = bpy.context.scene
    for o in bpy.data.objects:
        o.hide_render = True
    sources = [o for o in bpy.data.objects if o.type == "MESH" and o.name not in SKIP]
    exported = []
    for src in sources:
        cat, name = category_for(src.name)
        obj = prepare_copy(src)
        obj.name = name
        scene.collection.objects.link(obj)
        obj.hide_render = False
        obj.hide_viewport = False
        obj.hide_set(False)

        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        obj.location = (0, 0, 0)
        obj.scale = (obj.scale[0] * SCALE, obj.scale[1] * SCALE, obj.scale[2] * SCALE)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

        out_dir = os.path.join(OUT_DIR, cat)
        os.makedirs(out_dir, exist_ok=True)
        out = os.path.join(out_dir, name + ".glb")
        bpy.ops.export_scene.gltf(
            filepath=out,
            export_format="GLB",
            use_selection=True,
            export_apply=True,
            export_yup=True,
            export_animations=False,
            export_cameras=False,
            export_image_format="NONE",  # palette is applied in Godot (shared material)
            export_lights=False,
        )
        if PREVIEW_DIR:
            os.makedirs(PREVIEW_DIR, exist_ok=True)
            render_preview(obj, os.path.join(PREVIEW_DIR, f"{cat}__{name}.png"))
        exported.append(f"{cat}/{name}.glb")
        obj.hide_render = True
        bpy.data.objects.remove(obj, do_unlink=True)
    print("EXPORTED", len(exported))
    for e in exported:
        print("  ", e)


main()
