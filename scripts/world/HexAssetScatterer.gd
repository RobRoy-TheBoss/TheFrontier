## HexAssetScatterer
## Procedurally scatters assets across a hex terrain tile using direct mesh sampling.
## Placement is filtered by terrain texture colour — blue-dominant pixels (water)
## are skipped so assets only appear on land.
##
## Assets are placed by:
##   1. Generating jittered candidate points within the hex boundary
##   2. Looking up the terrain triangle under each point via a spatial grid
##   3. Interpolating Y height and UV from barycentric coords
##   4. Sampling the terrain texture; skipping if the pixel is water-coloured
##   5. Writing {path, pos, rot_y} for the caller to instantiate
##
## Density is per-asset: 1.0 = one asset per slot, 0.1 = 10% chance per slot.
## Seeded by area world position for determinism.
class_name HexAssetScatterer
extends RefCounted

const HEX_RADIUS := 200.0       # circumradius of hex tile (COL_STEP=300 → R=200)
const GRID_CELL := 20.0         # spatial bucket size in world units
const MIN_SLOPE_DOT := 0.7      # dot(normal, UP) minimum — 1.0=flat, 0.0=vertical; 0.7 ≈ 45°
const WATER_LEVEL := 8.5        # world Y — no assets placed at or below this height
const HILLTOP_THRESHOLD := 8.0  # within this many metres of the peak = hilltop zone
const HILLTOP_THIN_CHANCE := 0.5 # probability of skipping a tree in the hilltop zone

const _N := "res://assets/models/Stylized Nature MegaKit[Standard]/glTF/"

const BIOME_ASSETS := {
	# --- Active biomes (matched by hex_templates.json biome_type) ---

	"hills": {
		"slot_spacing": 5.0,
		"assets": [
			{ "path": _N + "CommonTree_1.gltf",       "density": 0.03, "scale": 1.5 },
			{ "path": _N + "CommonTree_3.gltf",       "density": 0.03, "scale": 1.5 },
			{ "path": _N + "CommonTree_5.gltf",       "density": 0.02, "scale": 1.5 },
			{ "path": _N + "Bush_Common.gltf",        "density": 0.04, "scale": 1.0 },
			{ "path": _N + "Grass_Wispy_Tall.gltf",   "density": 0.50, "scale": 1.0, "multimesh": true },
			{ "path": _N + "Grass_Common_Short.gltf", "density": 0.50, "scale": 1.0, "multimesh": true },
			{ "path": _N + "Rock_Medium_1.gltf",      "density": 0.04, "scale": 1.0 },
			{ "path": _N + "Rock_Medium_2.gltf",      "density": 0.03, "scale": 1.0 },
			{ "path": _N + "Pebble_Round_1.gltf",     "density": 0.06, "scale": 1.0, "multimesh": true },
			{ "path": _N + "Pebble_Round_3.gltf",     "density": 0.05, "scale": 1.0, "multimesh": true },
		],
	},
	"coastal": {
		"slot_spacing": 2.5,
		"assets": [
			{ "path": _N + "CommonTree_1.gltf",          "density": 0.025, "scale": 1.5 },
			{ "path": _N + "CommonTree_3.gltf",          "density": 0.02, "scale": 1.5 },
			{ "path": _N + "CommonTree_5.gltf",          "density": 0.02, "scale": 1.5 },
			{ "path": _N + "TwistedTree_1.gltf",         "density": 0.005, "scale": 0.75 },
			{ "path": _N + "DeadTree_2.gltf",            "density": 0.005, "scale": 1.0 },
			{ "path": _N + "Bush_Common_Flowers.gltf",   "density": 0.005, "scale": 1.0 },
			{ "path": _N + "Grass_Wispy_Short.gltf",     "density": 0.50, "scale": 1.0, "multimesh": true },
			{ "path": _N + "Grass_Wispy_Tall.gltf",      "density": 0.50, "scale": 1.0, "multimesh": true },
			{ "path": _N + "Pebble_Round_2.gltf",        "density": 0.08, "scale": 1.0, "multimesh": true },
			{ "path": _N + "Rock_Medium_1.gltf",         "density": 0.01, "scale": 1.0 },
		],
	},
	"mountain": {
		"slot_spacing": 28.0,
		"assets": [
			{ "path": _N + "Pine_1.gltf",               "density": 0.10, "scale": 1.0 },
			{ "path": _N + "Pine_3.gltf",               "density": 0.08, "scale": 1.0 },
			{ "path": _N + "Pine_5.gltf",               "density": 0.07, "scale": 1.0 },
			{ "path": _N + "DeadTree_1.gltf",           "density": 0.06, "scale": 1.0 },
			{ "path": _N + "DeadTree_3.gltf",           "density": 0.04, "scale": 1.0 },
			{ "path": _N + "Rock_Medium_1.gltf",        "density": 0.18, "scale": 1.0 },
			{ "path": _N + "Rock_Medium_2.gltf",        "density": 0.15, "scale": 1.0 },
			{ "path": _N + "Rock_Medium_3.gltf",        "density": 0.12, "scale": 1.0 },
			{ "path": _N + "RockPath_Round_Wide.gltf",  "density": 0.08, "scale": 1.0, "multimesh": true },
			{ "path": _N + "Pebble_Square_1.gltf",      "density": 0.10, "scale": 1.0, "multimesh": true },
			{ "path": _N + "Pebble_Square_4.gltf",      "density": 0.08, "scale": 1.0, "multimesh": true },
		],
	},
	"river": {
		"slot_spacing": 5.0,
		"assets": [
			{ "path": _N + "CommonTree_2.gltf",         "density": 0.05, "scale": 1.5 },
			{ "path": _N + "CommonTree_4.gltf",         "density": 0.05, "scale": 1.5 },
			{ "path": _N + "CommonTree_1.gltf",         "density": 0.04, "scale": 1.5 },
			{ "path": _N + "TwistedTree_3.gltf",        "density": 0.02, "scale": 0.75 },
			{ "path": _N + "TwistedTree_5.gltf",        "density": 0.01, "scale": 0.75 },
			{ "path": _N + "DeadTree_1.gltf",           "density": 0.01, "scale": 1.0 },
			{ "path": _N + "Bush_Common_Flowers.gltf",  "density": 0.05, "scale": 1.0 },
			{ "path": _N + "Grass_Wispy_Tall.gltf",     "density": 0.50, "scale": 1.0, "multimesh": true },
			{ "path": _N + "Fern_1.gltf",               "density": 0.15, "scale": 1.0, "multimesh": true },
			{ "path": _N + "Plant_1.gltf",              "density": 0.10, "scale": 1.0, "multimesh": true },
			{ "path": _N + "Mushroom_Laetiporus.gltf",  "density": 0.01, "scale": 1.0 },
		],
	},

	# --- Reserve biomes (for future hex templates) ---

	"forest": {
		"slot_spacing": 6.0,
		"assets": [
			{ "path": _N + "CommonTree_1.gltf",       "density": 0.23, "scale": 1.5 },
			{ "path": _N + "CommonTree_2.gltf",       "density": 0.20, "scale": 1.5 },
			{ "path": _N + "CommonTree_3.gltf",       "density": 0.17, "scale": 1.5 },
			{ "path": _N + "CommonTree_4.gltf",       "density": 0.16, "scale": 1.5 },
			{ "path": _N + "CommonTree_5.gltf",       "density": 0.14, "scale": 1.5 },
			{ "path": _N + "TwistedTree_2.gltf",      "density": 0.03, "scale": 0.75 },
			{ "path": _N + "DeadTree_4.gltf",         "density": 0.02, "scale": 1.0 },
			{ "path": _N + "DeadTree_5.gltf",         "density": 0.02, "scale": 1.0 },
			{ "path": _N + "Bush_Common.gltf",        "density": 0.16, "scale": 1.0 },
			{ "path": _N + "Fern_1.gltf",             "density": 0.20, "scale": 1.0, "multimesh": true },
			{ "path": _N + "Mushroom_Common.gltf",    "density": 0.03, "scale": 1.0 },
			{ "path": _N + "Rock_Medium_1.gltf",      "density": 0.02, "scale": 1.0 },
		],
	},
	"plains": {
		"slot_spacing": 32.0,
		"assets": [
			{ "path": _N + "Grass_Common_Short.gltf", "density": 0.50, "scale": 1.0, "multimesh": true },
			{ "path": _N + "Grass_Common_Tall.gltf",  "density": 0.50, "scale": 1.0, "multimesh": true },
			{ "path": _N + "Clover_1.gltf",           "density": 0.12, "scale": 1.0, "multimesh": true },
			{ "path": _N + "Flower_3_Group.gltf",     "density": 0.08, "scale": 1.0, "multimesh": true },
			{ "path": _N + "CommonTree_1.gltf",       "density": 0.05, "scale": 1.5 },
			{ "path": _N + "Bush_Common.gltf",        "density": 0.06, "scale": 1.0 },
		],
	},
	"swamp": {
		"slot_spacing": 18.0,
		"assets": [
			{ "path": _N + "TwistedTree_2.gltf",      "density": 0.20, "scale": 0.75 },
			{ "path": _N + "TwistedTree_4.gltf",      "density": 0.15, "scale": 0.75 },
			{ "path": _N + "Plant_7_Big.gltf",        "density": 0.14, "scale": 1.0, "multimesh": true },
			{ "path": _N + "Grass_Wispy_Tall.gltf",   "density": 0.50, "scale": 1.0, "multimesh": true },
			{ "path": _N + "Mushroom_Common.gltf",    "density": 0.10, "scale": 1.0 },
			{ "path": _N + "Mushroom_Laetiporus.gltf","density": 0.07, "scale": 1.0 },
		],
	},
}


static func scatter(area: Node3D, parent_node: Node3D) -> void:
	var results := scatter_dry_run(area, parent_node)

	# Split into regular instances and multimesh batches (grouped by path).
	var regular: Array = []
	var mm_groups: Dictionary = {}  # path -> Array of entries
	for entry in results:
		if entry.get("multimesh", false):
			var path: String = entry["path"]
			if not mm_groups.has(path):
				mm_groups[path] = []
			mm_groups[path].append(entry)
		else:
			regular.append(entry)

	# Place regular instances (trees, large rocks, etc.).
	for entry in regular:
		var packed := load(entry["path"]) as PackedScene
		if packed == null:
			continue
		var p: Array = entry["pos"]
		var inst := packed.instantiate()
		inst.position = Vector3(p[0], p[1], p[2])
		inst.rotation.y = entry["rot_y"]
		var s: float = entry.get("scale", 1.0)
		inst.scale = Vector3(s, s, s)
		parent_node.add_child(inst)

	# Place multimesh batches — one MMI per unique asset path.
	for path: String in mm_groups:
		var entries: Array = mm_groups[path]
		var mesh := _extract_mesh(path)
		if mesh == null:
			# Fallback: place as regular instances if mesh extraction fails.
			for entry in entries:
				var packed := load(entry["path"]) as PackedScene
				if packed == null:
					continue
				var p: Array = entry["pos"]
				var inst := packed.instantiate()
				inst.position = Vector3(p[0], p[1], p[2])
				inst.rotation.y = entry["rot_y"]
				var s: float = entry.get("scale", 1.0)
				inst.scale = Vector3(s, s, s)
				parent_node.add_child(inst)
			continue

		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.instance_count = entries.size()
		mm.mesh = mesh

		for i in entries.size():
			var e: Dictionary = entries[i]
			var p: Array = e["pos"]
			var s: float = e.get("scale", 1.0)
			var basis := Basis(Vector3.UP, e["rot_y"]).scaled(Vector3(s, s, s))
			mm.set_instance_transform(i, Transform3D(basis, Vector3(p[0], p[1], p[2])))

		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		parent_node.add_child(mmi)


# Loads a PackedScene and extracts the first Mesh found in its node tree.
static func _extract_mesh(path: String) -> Mesh:
	var packed := load(path) as PackedScene
	if packed == null:
		return null
	var inst := packed.instantiate()
	var mesh := _find_mesh_in(inst)
	inst.free()
	return mesh


static func _find_mesh_in(node: Node) -> Mesh:
	if node is MeshInstance3D:
		return (node as MeshInstance3D).mesh
	for child in node.get_children():
		var m := _find_mesh_in(child)
		if m != null:
			return m
	return null


# Returns [{path, pos:[x,y,z], rot_y}, ...] in parent_node local space.
static func scatter_dry_run(area: Node3D, parent_node: Node3D) -> Array:
	var biome := area.get("biome") as String if area.get("biome") is String else ""
	var biome_data: Dictionary = BIOME_ASSETS.get(biome, {})
	if biome_data.is_empty():
		return []
	var asset_list: Array = biome_data["assets"]
	var slot_spacing: float = biome_data["slot_spacing"]

	var mesh_data := _collect_mesh_data(parent_node)
	var tris: PackedVector3Array = mesh_data["tris"]
	if tris.is_empty():
		return []
	var uvs: PackedVector2Array   = mesh_data["uvs"]
	var tri_images: Array         = mesh_data["tri_images"]
	var grid := _build_grid(tris)

	var rng := RandomNumberGenerator.new()
	var pos := area.global_position
	rng.seed = int(abs(pos.x) * 73 + abs(pos.z) * 137)

	var slots := _hex_slots(pos, slot_spacing)
	var excludes: Array = area.get_tree().get_nodes_in_group("scatter_exclude") if area.is_inside_tree() else []
	var dbg_no_hit := 0; var dbg_excluded := 0; var dbg_water_y := 0; var dbg_water_color := 0

	# Pass 1: collect valid candidates and find max Y (for hilltop thinning)
	var valid: Array = []  # [{candidate: Vector3, hit: Dictionary}]
	var max_y := -INF
	for slot in slots:
		var jx: float = (rng.randf() - 0.5) * slot_spacing
		var jz: float = (rng.randf() - 0.5) * slot_spacing
		var candidate := Vector3(slot.x + jx, 0.0, slot.z + jz)

		var excluded := false
		for ex in excludes:
			var ep: Vector3 = ex.global_position
			var dx: float = candidate.x - ep.x
			var dz: float = candidate.z - ep.z
			if dx * dx + dz * dz < ex.radius * ex.radius:
				excluded = true
				break
		if excluded:
			dbg_excluded += 1
			continue

		var hit := _sample_surface(tris, uvs, tri_images, grid, candidate)
		if hit.is_empty():
			dbg_no_hit += 1
			continue
		if hit["y"] <= WATER_LEVEL:
			dbg_water_y += 1
			continue
		if _is_water(hit["color"]):
			dbg_water_color += 1
			continue

		valid.append({"candidate": candidate, "hit": hit})
		if hit["y"] > max_y:
			max_y = hit["y"]

	# Pass 2: place assets, thinning hilltop zone for forest biome
	var results: Array = []
	var hilltop_biome := biome == "forest"
	for entry in valid:
		var candidate: Vector3 = entry["candidate"]
		var hit: Dictionary = entry["hit"]

		if hilltop_biome and hit["y"] >= max_y - HILLTOP_THRESHOLD:
			if rng.randf() < HILLTOP_THIN_CHANCE:
				continue

		for asset_def in asset_list:
			if rng.randf() > asset_def["density"]:
				continue
			var local_pos := parent_node.to_local(Vector3(candidate.x, hit["y"], candidate.z))
			results.append({
				"path": asset_def["path"],
				"pos": [local_pos.x, local_pos.y, local_pos.z],
				"rot_y": rng.randf() * TAU,
				"scale": asset_def.get("scale", 1.0),
				"multimesh": asset_def.get("multimesh", false),
			})
			break  # one asset per slot

	print("HexAssetScatterer [%s]: slots=%d excluded=%d no_hit=%d water_y=%d water_color=%d placed=%d" % [
		area.name, slots.size(), dbg_excluded, dbg_no_hit, dbg_water_y, dbg_water_color, results.size()])
	return results


# ---------------------------------------------------------------------------
# Mesh data collection
# ---------------------------------------------------------------------------

# Returns {tris, uvs, tri_images} — all parallel: 3 entries per triangle in
# tris/uvs, one entry per triangle in tri_images (Image or null).
static func _collect_mesh_data(root: Node) -> Dictionary:
	var tris := PackedVector3Array()
	var uvs  := PackedVector2Array()
	var tri_images: Array = []

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
			var uv_raw = arrays[Mesh.ARRAY_TEX_UV]
			var has_uv := uv_raw is PackedVector2Array and (uv_raw as PackedVector2Array).size() == verts.size()
			var uv_arr: PackedVector2Array = uv_raw if has_uv else PackedVector2Array()
			var indices = arrays[Mesh.ARRAY_INDEX]

			# Grab albedo texture image for this surface
			var image: Image = null
			var mat = mi.get_surface_override_material(surf)
			if mat == null:
				mat = mesh.surface_get_material(surf)
			if mat is BaseMaterial3D:
				var tex := (mat as BaseMaterial3D).albedo_texture
				if tex != null:
					image = tex.get_image()
					if image != null and image.is_compressed():
						image = image.duplicate()
						image.decompress()

			if indices == null or (indices is PackedInt32Array and (indices as PackedInt32Array).size() == 0):
				var vi := 0
				while vi + 2 < verts.size():
					tris.append(gt * verts[vi]);      tris.append(gt * verts[vi + 1]);      tris.append(gt * verts[vi + 2])
					uvs.append(uv_arr[vi] if has_uv else Vector2.ZERO)
					uvs.append(uv_arr[vi + 1] if has_uv else Vector2.ZERO)
					uvs.append(uv_arr[vi + 2] if has_uv else Vector2.ZERO)
					tri_images.append(image)
					vi += 3
			else:
				var idx := indices as PackedInt32Array
				var ii := 0
				while ii + 2 < idx.size():
					tris.append(gt * verts[idx[ii]]); tris.append(gt * verts[idx[ii+1]]); tris.append(gt * verts[idx[ii+2]])
					uvs.append(uv_arr[idx[ii]]     if has_uv else Vector2.ZERO)
					uvs.append(uv_arr[idx[ii + 1]] if has_uv else Vector2.ZERO)
					uvs.append(uv_arr[idx[ii + 2]] if has_uv else Vector2.ZERO)
					tri_images.append(image)
					ii += 3

	return {"tris": tris, "uvs": uvs, "tri_images": tri_images}


# ---------------------------------------------------------------------------
# Surface sampling
# ---------------------------------------------------------------------------

# Returns {y, color} for the first triangle covering world_xz, or {} if none.
static func _sample_surface(tris: PackedVector3Array, uvs: PackedVector2Array,
		tri_images: Array, grid: Dictionary, world_xz: Vector3) -> Dictionary:
	var cx := floori(world_xz.x / GRID_CELL)
	var cz := floori(world_xz.z / GRID_CELL)
	var key := Vector2i(cx, cz)
	if not grid.has(key):
		return {}
	for idx: int in grid[key]:
		var a := tris[idx]; var b := tris[idx + 1]; var c := tris[idx + 2]
		var bary := _bary2d(a, b, c, world_xz.x, world_xz.z)
		if bary.x < 0.0:
			continue
		# Skip near-vertical surfaces
		var normal := (b - a).cross(c - a).normalized()
		if absf(normal.y) < MIN_SLOPE_DOT:
			continue
		var y: float = bary.x * a.y + bary.y * b.y + bary.z * c.y
		var uv: Vector2 = bary.x * uvs[idx] + bary.y * uvs[idx + 1] + bary.z * uvs[idx + 2]
		var image: Image = tri_images[idx / 3]
		var color := _sample_image(image, uv) if image != null else Color.WHITE
		return {"y": y, "color": color}
	return {}


# Barycentric coords in XZ. Returns Vector3(-1,0,0) if point is outside triangle.
static func _bary2d(a: Vector3, b: Vector3, c: Vector3, px: float, pz: float) -> Vector3:
	var denom: float = (b.z - c.z) * (a.x - c.x) + (c.x - b.x) * (a.z - c.z)
	if absf(denom) < 1e-6:
		return Vector3(-1, 0, 0)
	var u: float = ((b.z - c.z) * (px - c.x) + (c.x - b.x) * (pz - c.z)) / denom
	var v: float = ((c.z - a.z) * (px - c.x) + (a.x - c.x) * (pz - c.z)) / denom
	var w: float = 1.0 - u - v
	if u < 0.0 or v < 0.0 or w < 0.0:
		return Vector3(-1, 0, 0)
	return Vector3(u, v, w)


static func _sample_image(image: Image, uv: Vector2) -> Color:
	var w := image.get_width()
	var h := image.get_height()
	var px := posmod(int(uv.x * w), w)
	var py := posmod(int(uv.y * h), h)
	return image.get_pixel(px, py)


# True if blue clearly dominates — indicates water/ocean painted area.
static func _is_water(color: Color) -> bool:
	return color.b > color.r + 0.15 and color.b > color.g + 0.1


# ---------------------------------------------------------------------------
# Spatial grid
# ---------------------------------------------------------------------------

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


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

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
			if absf(lx) <= HEX_RADIUS and absf(lz) <= HEX_RADIUS:
				slots.append(Vector3(area_world_pos.x + lx, 0.0, area_world_pos.z + lz))
	return slots
