"""
hex_river_reference.py

Run in Blender's Scripting workspace: open the Text Editor, paste or load
this file, then click Run Script.

Creates a "Hex Reference" collection containing:
  - A wireframe hex boundary mesh (circumradius 200, flat-top, vertices E/W)
  - Six corner empties at each hex vertex (E, NE, NW, W, SW, SE)
  - Per-edge river profile empties — 7 points per edge showing exactly where
    your mesh vertices must land for a seamless river crossing

Blender coordinate convention used here:
  X = east/west,  Y = north/south,  Z = up (terrain sits at Z=0)

Edit the parameters below to match your river design before running.
"""

import bpy
import math
from mathutils import Vector

# ---------------------------------------------------------------------------
# Parameters
# ---------------------------------------------------------------------------
HEX_R         = 200.0  # circumradius — vertex to center, must match Godot value
CHANNEL_HW    =  10.0  # half-width of river channel along the edge
BANK_HW       =  25.0  # half-width to top of bank along the edge
CHANNEL_DEPTH =   2.0  # depth of channel below terrain level (Z = -CHANNEL_DEPTH)
EMPTY_SIZE    =   4.0  # viewport display size of empties

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def get_or_create_collection(name, parent=None):
    if name in bpy.data.collections:
        col = bpy.data.collections[name]
    else:
        col = bpy.data.collections.new(name)
    target = parent if parent else bpy.context.scene.collection
    if col.name not in [c.name for c in target.children]:
        target.children.link(col)
    return col


def add_empty(name, location, collection, display_type='PLAIN_AXES'):
    bpy.ops.object.empty_add(type=display_type, location=location)
    obj = bpy.context.active_object
    obj.name = name
    obj.empty_display_size = EMPTY_SIZE
    for c in list(obj.users_collection):
        c.objects.unlink(obj)
    collection.objects.link(obj)
    return obj


# ---------------------------------------------------------------------------
# Hex vertex positions — flat-top hex, vertices pointing E and W
# ---------------------------------------------------------------------------

S32 = math.sqrt(3) / 2.0
R   = HEX_R

VERTS = {
    'E':  Vector(( R,        0,       0)),
    'NE': Vector(( R / 2,    R * S32, 0)),
    'NW': Vector((-R / 2,    R * S32, 0)),
    'W':  Vector((-R,        0,       0)),
    'SW': Vector((-R / 2,   -R * S32, 0)),
    'SE': Vector(( R / 2,   -R * S32, 0)),
}

# Each edge: (name, vertex_A, vertex_B) going clockwise
EDGES = [
    ('N',  'NW', 'NE'),
    ('NE', 'NE', 'E'),
    ('SE', 'E',  'SE'),
    ('S',  'SE', 'SW'),
    ('SW', 'SW', 'W'),
    ('NW', 'W',  'NW'),
]

# ---------------------------------------------------------------------------
# Profile points along a river edge, measured from the edge midpoint
# (offset, z_height, label)
# offset=None means use the actual vertex position (corner)
# ---------------------------------------------------------------------------

PROFILE = [
    (None,        0,              'corner_A'),
    (-BANK_HW,    0,              'bank_left'),
    (-CHANNEL_HW, -CHANNEL_DEPTH, 'channel_left'),
    ( 0,          -CHANNEL_DEPTH, 'channel_mid'),
    ( CHANNEL_HW, -CHANNEL_DEPTH, 'channel_right'),
    ( BANK_HW,    0,              'bank_right'),
    (None,        0,              'corner_B'),
]

# ---------------------------------------------------------------------------
# Build the reference collection
# ---------------------------------------------------------------------------

root_col    = get_or_create_collection("Hex Reference")
corners_col = get_or_create_collection("Corners",     root_col)
edges_col   = get_or_create_collection("River Edges", root_col)

# Hex boundary wireframe
vert_order = ['E', 'NE', 'NW', 'W', 'SW', 'SE']
mesh = bpy.data.meshes.new("HexBoundary")
mesh.from_pydata(
    [(VERTS[n].x, VERTS[n].y, VERTS[n].z) for n in vert_order],
    [(0,1),(1,2),(2,3),(3,4),(4,5),(5,0)],
    []
)
hex_obj = bpy.data.objects.new("HexBoundary", mesh)
hex_obj.display_type = 'WIRE'
root_col.objects.link(hex_obj)

# Corner empties
for name, pos in VERTS.items():
    add_empty(f"corner_{name}", tuple(pos), corners_col, 'ARROWS')

# River profile empties — one sub-collection per edge
for edge_name, va_name, vb_name in EDGES:
    edge_col  = get_or_create_collection(f"Edge_{edge_name}", edges_col)
    va        = VERTS[va_name]
    vb        = VERTS[vb_name]
    mid       = (va + vb) / 2.0
    direction = (vb - va).normalized()

    for offset, z, label in PROFILE:
        if offset is None:
            pos = va.copy() if label == 'corner_A' else vb.copy()
        else:
            pos = mid + direction * offset
        pos.z = z
        add_empty(f"{edge_name}_{label}", tuple(pos), edge_col)

print(f"Hex river reference built — {len(EDGES)} edges, {len(PROFILE)} points each.")
