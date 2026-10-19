"""
Builds the streamed assets (stream/*.ydr + stream/double_plumbob.ytyp) from double_plumbob.blend.

Requirements: Blender 4.2+ with Sollumz 2.8+ and PyMateria (Windows only, for native export).

    blender -b _source/double_plumbob.blend --python _source/build.py

Adding a colour: put textures/plumbob_<colour>.dds (256x256, DXT1) next to the others,
add it to COLORS below, rebuild, then add it to Config.Colors in config.lua.
"""
import os

import bpy

COLORS = ("green", "orange", "red")
BASE = "double_plumbob"

HERE = os.path.dirname(os.path.abspath(__file__))
TEXTURES = os.path.join(HERE, "textures")
STREAM = os.path.normpath(os.path.join(HERE, "..", "stream"))

# Never culled by distance: the script moves the prop above a player's head.
LOD_DIST = 9998.0


def duplicate_variant(root, model, color):
    name = f"{BASE}_{color}"

    new_root = root.copy()
    new_root.name = name
    bpy.context.scene.collection.objects.link(new_root)

    new_model = model.copy()
    new_model.data = model.data.copy()
    new_model.name = f"{name}.model"
    new_model.parent = new_root
    bpy.context.scene.collection.objects.link(new_model)

    mat = model.material_slots[0].material.copy()
    mat.name = name
    new_model.material_slots[0].material = mat

    image = bpy.data.images.load(os.path.join(TEXTURES, f"plumbob_{color}.dds"))
    image.name = f"plumbob_{color}"
    for node in mat.node_tree.nodes:
        if node.type == "TEX_IMAGE" and node.name == "DiffuseSampler":
            node.image = image
            node.texture_properties.embedded = True

    return new_root


def export(objects, ytyp_only=False):
    bpy.context.view_layer.update()
    for obj in bpy.context.scene.objects:
        obj.select_set(False)
    for obj in objects:
        obj.select_set(True)
        for child in obj.children_recursive:
            child.select_set(True)

    op = bpy.ops.sollumz.export_ytyp_io if ytyp_only else bpy.ops.sollumz.export_assets
    result = op(
        directory=STREAM + os.sep,
        direct_export=True,
        use_custom_settings=True,
        target_formats={"NATIVE"},
        target_versions={"GEN8"},
        limit_to_selected=True,
    )
    if result != {"FINISHED"}:
        raise RuntimeError(f"export failed: {result}")


def main():
    os.makedirs(STREAM, exist_ok=True)

    root = bpy.data.objects[BASE]
    model = bpy.data.objects[f"{BASE}.model"]

    variants = [duplicate_variant(root, model, color) for color in COLORS]
    bpy.data.objects.remove(model)
    bpy.data.objects.remove(root)

    export(variants)

    scene = bpy.context.scene
    bpy.ops.sollumz.createytyp()
    ytyp = scene.ytyps[scene.ytyp_index]
    ytyp.name = BASE

    for obj in variants:
        arch = ytyp.new_archetype("sollumz_archetype_base")
        arch.asset = obj  # fills name, asset type and embedded texture dictionary
        arch.name = obj.name
        arch.lod_dist = LOD_DIST
        arch.flags.flag6 = True  # 32, same as the original archetype
        arch.physics_dictionary = ""

    export([], ytyp_only=True)
    print(f"[build] done -> {STREAM}")


main()
