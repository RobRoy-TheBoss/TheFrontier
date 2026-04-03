## HexTerrain
## Procedurally generates the hex terrain mesh and collision for an Area.
## Attach as a StaticBody3D child of the Area's Terrain node.
## The parent Area's transform (30° rotation + elevation) is inherited
## automatically — no angle computation needed here.
##
## Seam blending (future): call set_corner_height(i, local_y) + rebuild()
## to blend edge heights with an adjacent area. No structural changes needed.
class_name HexTerrain
extends StaticBody3D

## World-space Y of the water surface.
@export var water_level: float = 0.0
## World-space Y of the base of the cliff (below water).
@export var hex_depth: float = -8.0

const HEX_CIRCUMRADIUS := 199.0
## cos(60°) — neighbour counts as closing an edge if within 60° of its outward dir.
const NEIGHBOR_DOT := 0.5

var _corner_heights: Array[float] = []


func _ready() -> void:
	_build()


func rebuild() -> void:
	for child in get_children():
		child.queue_free()
	_build()


## Set a corner's local Y then call rebuild() to apply seam blending.
func set_corner_height(corner_idx: int, local_y: float) -> void:
	if _corner_heights.size() == 6:
		_corner_heights[corner_idx] = local_y


func _build() -> void:
	# Expected hierarchy: Area → Terrain → HexTerrain (self)
	var area: Node3D = get_parent().get_parent() as Node3D
	if area == null or not area.has_method("on_player_enter"):
		push_warning("HexTerrain: unexpected parent hierarchy (expected Area/Terrain/HexTerrain)")
		return

	# Convert world Y targets to local Y (area's local frame, surface = local 0).
	var surface_world_y := area.global_position.y
	var open_y  := water_level - surface_world_y  # e.g. 0 - 2 = -2 for coast
	var depth_y := hex_depth   - surface_world_y  # e.g. -8 - 2 = -10 for coast

	_corner_heights = _compute_corner_heights(area, open_y)

	# --- Generate mesh in LOCAL space ---
	# Parent transform handles world position and 30° rotation automatically.
	var center := Vector3.ZERO
	var corners: Array[Vector3] = []
	for i in range(6):
		var a := i * PI / 3.0
		corners.append(Vector3(cos(a) * HEX_CIRCUMRADIUS, _corner_heights[i], sin(a) * HEX_CIRCUMRADIUS))

	var verts:   PackedVector3Array = []
	var normals: PackedVector3Array = []
	var indices: PackedInt32Array   = []

	# Top surface: fan of 6 triangles from centre
	for i in range(6):
		var ca := corners[i]
		var cb := corners[(i + 1) % 6]
		var n  := (cb - center).cross(ca - center).normalized()
		var base := verts.size()
		verts.append_array([center, ca, cb])
		normals.append_array([n, n, n])
		indices.append_array([base, base + 1, base + 2])

	# Side walls: vertical quad from corner heights down to depth_y
	for i in range(6):
		var ca_top := corners[i]
		var cb_top := corners[(i + 1) % 6]
		var ca_bot := Vector3(ca_top.x, depth_y, ca_top.z)
		var cb_bot := Vector3(cb_top.x, depth_y, cb_top.z)
		var n      := (cb_top - ca_top).cross(ca_bot - ca_top).normalized()
		var base   := verts.size()
		verts.append_array([ca_top, cb_top, cb_bot, ca_bot])
		normals.append_array([n, n, n, n])
		indices.append_array([base, base + 1, base + 2, base, base + 2, base + 3])

	# Build mesh
	var arr := Array()
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_INDEX]  = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = _biome_color(area)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.set_surface_override_material(0, mat)
	add_child(mi)

	# Collision
	var faces: PackedVector3Array = []
	for j in range(0, indices.size(), 3):
		faces.append(verts[indices[j]])
		faces.append(verts[indices[j + 1]])
		faces.append(verts[indices[j + 2]])
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	add_child(cs)


## Corner i (between edge i-1 and edge i) drops to open_y if either adjacent
## edge faces open water, otherwise stays at 0.0 (local surface).
func _compute_corner_heights(area: Node3D, open_y: float) -> Array[float]:
	var my_xz := Vector2(area.global_position.x, area.global_position.z)

	var sibling_xz: Array[Vector2] = []
	for sibling in area.get_parent().get_children():
		if sibling == area:
			continue
		if sibling.get("area_id") is String:
			sibling_xz.append(Vector2(sibling.global_position.x, sibling.global_position.z))

	var edge_open: Array[bool] = []
	for i in range(6):
		# Local outward direction → world space via the area's rotation basis.
		# This correctly applies the 30° hex rotation without any atan2 magic.
		var local_dir  := Vector3(cos((i + 0.5) * PI / 3.0), 0.0, sin((i + 0.5) * PI / 3.0))
		var world_dir  := area.global_transform.basis * local_dir
		var outward    := Vector2(world_dir.x, world_dir.z).normalized()

		var has_neighbor := false
		for spos in sibling_xz:
			if (spos - my_xz).normalized().dot(outward) > NEIGHBOR_DOT:
				has_neighbor = true
				break
		edge_open.append(not has_neighbor)

	var heights: Array[float] = []
	for i in range(6):
		var prev := (i - 1 + 6) % 6
		heights.append(open_y if (edge_open[prev] or edge_open[i]) else 0.0)
	return heights


func _biome_color(area: Node3D) -> Color:
	var biome := area.get("biome") as String if area.get("biome") is String else ""
	match biome:
		"coast":         return Color(0.93, 0.87, 0.62, 1)
		"forest":        return Color(0.22, 0.52, 0.18, 1)
		"mountain":      return Color(0.58, 0.55, 0.50, 1)
		"swamp":         return Color(0.30, 0.38, 0.20, 1)
		"mountain_pass": return Color(0.52, 0.50, 0.44, 1)
		"plains":        return Color(0.62, 0.78, 0.38, 1)
		_:               return Color(0.55, 0.52, 0.46, 1)
