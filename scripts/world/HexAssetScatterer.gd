## HexAssetScatterer
## Procedurally scatters assets across a hex terrain tile using direct mesh sampling.
## Called by HexTerrainLoader after the terrain mesh is added to the scene.
##
## Assets are placed by:
##   1. Generating jittered candidate points within the hex boundary
##   2. Looking up the terrain triangle under each point via a spatial grid
##   3. Interpolating the Y height from that triangle
##   4. Instantiating the asset at that position with a random Y rotation
##
## No physics raycasts are used — height is read directly from mesh geometry.
## Density is per-asset: 1.0 = one asset per slot, 0.1 = 10% chance per slot.
## Seeded by area world position for determinism.
class_name HexAssetScatterer
extends RefCounted

const HEX_RADIUS := 200.0  # circumradius of hex tile (COL_STEP=300 → R=200)
const GRID_CELL := 20.0   # spatial bucket size in world units

const BIOME_ASSETS := {
	"forest": {
		"slot_spacing": 5.0,
		"assets": [
			{ "path": "res://assets/models/kenney_fantasy-town-kit/Models/GLB format/tree.glb",            "density": 0.5 },
			{ "path": "res://assets/models/kenney_fantasy-town-kit/Models/GLB format/tree-high.glb",       "density": 0.5 },
			{ "path": "res://assets/models/kenney_fantasy-town-kit/Models/GLB format/tree-crooked.glb",    "density": 0.5 },
			{ "path": "res://assets/models/kenney_retro-medieval-kit/Models/GLB format/tree-large.glb",    "density": 0.02 },
			{ "path": "res://assets/models/kenney_retro-medieval-kit/Models/GLB format/tree-shrub.glb",    "density": 0.01 },
			{ "path": "res://assets/models/kenney_fantasy-town-kit/Models/GLB format/rock-small.glb",      "density": 0.01 },
		],
	},
	"coast": {
		"slot_spacing": 40.0,
		"assets": [
			{ "path": "res://assets/models/kenney_fantasy-town-kit/Models/GLB format/rock-large.glb",      "density": 0.08 },
			{ "path": "res://assets/models/kenney_fantasy-town-kit/Models/GLB format/rock-small.glb",      "density": 0.12 },
			{ "path": "res://assets/models/kenney_fantasy-town-kit/Models/GLB format/rock-wide.glb",       "density": 0.06 },
		],
	},
	"mountain": {
		"slot_spacing": 35.0,
		"assets": [
			{ "path": "res://assets/models/kenney_fantasy-town-kit/Models/GLB format/rock-large.glb",      "density": 0.20 },
			{ "path": "res://assets/models/kenney_fantasy-town-kit/Models/GLB format/rock-wide.glb",       "density": 0.15 },
			{ "path": "res://assets/models/kenney_fantasy-town-kit/Models/GLB format/rock-small.glb",      "density": 0.15 },
		],
	},
	"mountain_pass": {
		"slot_spacing": 40.0,
		"assets": [
			{ "path": "res://assets/models/kenney_fantasy-town-kit/Models/GLB format/rock-large.glb",      "density": 0.10 },
			{ "path": "res://assets/models/kenney_fantasy-town-kit/Models/GLB format/rock-small.glb",      "density": 0.10 },
			{ "path": "res://assets/models/kenney_retro-medieval-kit/Models/GLB format/tree-shrub.glb",    "density": 0.08 },
		],
	},
	"swamp": {
		"slot_spacing": 25.0,
		"assets": [
			{ "path": "res://assets/models/kenney_fantasy-town-kit/Models/GLB format/tree-crooked.glb",    "density": 0.25 },
			{ "path": "res://assets/models/kenney_retro-medieval-kit/Models/GLB format/tree-shrub.glb",    "density": 0.15 },
			{ "path": "res://assets/models/kenney_fantasy-town-kit/Models/GLB format/rock-small.glb",      "density": 0.05 },
		],
	},
	"plains": {
		"slot_spacing": 50.0,
		"assets": [
			{ "path": "res://assets/models/kenney_retro-medieval-kit/Models/GLB format/tree-shrub.glb",    "density": 0.08 },
			{ "path": "res://assets/models/kenney_fantasy-town-kit/Models/GLB format/rock-small.glb",      "density": 0.04 },
			{ "path": "res://assets/models/kenney_fantasy-town-kit/Models/GLB format/tree.glb",            "density": 0.05 },
		],
	},
}


static func scatter(area: Node3D, parent_node: Node3D) -> void:
	var biome := area.get("biome") as String if area.get("biome") is String else ""
	var biome_data: Dictionary = BIOME_ASSETS.get(biome, {})
	if biome_data.is_empty():
		return
	var asset_list: Array = biome_data["assets"]
	var slot_spacing: float = biome_data["slot_spacing"]

	var triangles := _collect_triangles(parent_node)
	if triangles.is_empty():
		return
	var grid := _build_grid(triangles)

	var rng := RandomNumberGenerator.new()
	var pos := area.global_position
	rng.seed = int(abs(pos.x) * 73 + abs(pos.z) * 137)

	var slots := _hex_slots(pos, slot_spacing)

	for slot in slots:
		var jx: float = (rng.randf() - 0.5) * slot_spacing
		var jz: float = (rng.randf() - 0.5) * slot_spacing
		var candidate := Vector3(slot.x + jx, 0.0, slot.z + jz)

		for asset_def in asset_list:
			if rng.randf() > asset_def["density"]:
				continue
			var y := _sample_height(triangles, grid, candidate)
			if y == INF:
				continue
			var packed := load(asset_def["path"]) as PackedScene
			if packed == null:
				continue
			var instance := packed.instantiate()
			instance.position = parent_node.to_local(Vector3(candidate.x, y, candidate.z))
			instance.rotate_y(rng.randf() * TAU)
			parent_node.add_child(instance)
			break  # one asset per slot


# Build a flat array of world-space triangle vertices (3 consecutive = 1 triangle)
static func _collect_triangles(root: Node) -> PackedVector3Array:
	var tris := PackedVector3Array()
	for mi: MeshInstance3D in _all_mesh_instances(root):
		var mesh := mi.mesh
		if mesh == null:
			continue
		var gt := mi.global_transform
		for surf in range(mesh.get_surface_count()):
			var arrays := mesh.surface_get_arrays(surf)
			if arrays.is_empty():
				continue
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices = arrays[Mesh.ARRAY_INDEX]
			if indices == null or (indices is PackedInt32Array and indices.size() == 0):
				# Unindexed — vertices are already sequential triangles
				var vi := 0
				while vi + 2 < verts.size():
					tris.append(gt * verts[vi])
					tris.append(gt * verts[vi + 1])
					tris.append(gt * verts[vi + 2])
					vi += 3
			else:
				var idx := indices as PackedInt32Array
				var ii := 0
				while ii + 2 < idx.size():
					tris.append(gt * verts[idx[ii]])
					tris.append(gt * verts[idx[ii + 1]])
					tris.append(gt * verts[idx[ii + 2]])
					ii += 3
	return tris


# Build a spatial grid: Vector2i cell → Array of triangle start indices.
# Each triangle is registered in every cell its XZ bounding box overlaps.
static func _build_grid(triangles: PackedVector3Array) -> Dictionary:
	var grid := {}
	var i := 0
	while i + 2 < triangles.size():
		var a := triangles[i]
		var b := triangles[i + 1]
		var c := triangles[i + 2]
		var min_x := minf(a.x, minf(b.x, c.x))
		var max_x := maxf(a.x, maxf(b.x, c.x))
		var min_z := minf(a.z, minf(b.z, c.z))
		var max_z := maxf(a.z, maxf(b.z, c.z))
		var cx0 := floori(min_x / GRID_CELL)
		var cx1 := floori(max_x / GRID_CELL)
		var cz0 := floori(min_z / GRID_CELL)
		var cz1 := floori(max_z / GRID_CELL)
		for cx in range(cx0, cx1 + 1):
			for cz in range(cz0, cz1 + 1):
				var key := Vector2i(cx, cz)
				if not grid.has(key):
					grid[key] = []
				grid[key].append(i)
		i += 3
	return grid


# Return the interpolated world Y at (world_xz.x, ?, world_xz.z) using the spatial grid,
# or INF if no triangle covers that XZ position.
static func _sample_height(triangles: PackedVector3Array, grid: Dictionary, world_xz: Vector3) -> float:
	var cx := floori(world_xz.x / GRID_CELL)
	var cz := floori(world_xz.z / GRID_CELL)
	var key := Vector2i(cx, cz)
	if not grid.has(key):
		return INF
	for idx: int in grid[key]:
		var y := _triangle_y_at(triangles[idx], triangles[idx + 1], triangles[idx + 2], world_xz.x, world_xz.z)
		if y != INF:
			return y
	return INF


# Barycentric test + interpolation in XZ. Returns INF if point is outside triangle.
static func _triangle_y_at(a: Vector3, b: Vector3, c: Vector3, px: float, pz: float) -> float:
	var denom: float = (b.z - c.z) * (a.x - c.x) + (c.x - b.x) * (a.z - c.z)
	if absf(denom) < 1e-6:
		return INF
	var u: float = ((b.z - c.z) * (px - c.x) + (c.x - b.x) * (pz - c.z)) / denom
	var v: float = ((c.z - a.z) * (px - c.x) + (a.x - c.x) * (pz - c.z)) / denom
	var w: float = 1.0 - u - v
	if u < 0.0 or v < 0.0 or w < 0.0:
		return INF
	return u * a.y + v * b.y + w * c.y


static func _all_mesh_instances(node: Node) -> Array:
	var result := []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_all_mesh_instances(child))
	return result


static func _hex_slots(area_world_pos: Vector3, slot_spacing: float) -> Array:
	var slots := []
	var steps := int(HEX_RADIUS / slot_spacing)
	for gx in range(-steps, steps + 1):
		for gz in range(-steps, steps + 1):
			var lx := gx * slot_spacing
			var lz := gz * slot_spacing
			# Broad square pass — _sample_height returning INF is the real boundary filter
			if absf(lx) <= HEX_RADIUS and absf(lz) <= HEX_RADIUS:
				slots.append(Vector3(area_world_pos.x + lx, 0.0, area_world_pos.z + lz))
	return slots
