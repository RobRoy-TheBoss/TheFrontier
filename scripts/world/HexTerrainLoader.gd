## HexTerrainLoader
## Loads a .glb terrain mesh and attaches it to the parent Area's Terrain node.
##
## Baking: check "Bake Assets" in the inspector to run the scatterer once and
## write results to res://data/scatter/{area_id}.json. At runtime, if that file
## exists the assets are instantiated from it directly — no mesh sampling needed.
## Check "Clear Baked Assets" to delete the JSON and revert to runtime scattering.
## Check "Bake All Areas" on any HexTerrainLoader to bake every area in the scene.
@tool
extends Node

@export var terrain_mesh_path: String = ""

@export_group("Baking")
@export var bake_assets: bool = false:
	set(value):
		bake_assets = false
		if value:
			call_deferred(&"_bake")

@export var clear_baked_assets: bool = false:
	set(value):
		clear_baked_assets = false
		if value:
			call_deferred(&"_clear")

@export var bake_all_areas: bool = false:
	set(value):
		bake_all_areas = false
		if value:
			call_deferred(&"_bake_all")


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if terrain_mesh_path == "":
		return
	var packed = load(terrain_mesh_path) as PackedScene
	if packed == null:
		push_warning("HexTerrainLoader: could not load " + terrain_mesh_path)
		return
	var terrain_node = get_parent().get_node_or_null("Terrain")
	if terrain_node == null:
		push_warning("HexTerrainLoader: no Terrain child found on " + get_parent().name)
		return
	var instance = packed.instantiate()
	terrain_node.add_child(instance)
	_generate_collision(instance)
	# Layer 3 (bit 2): terrain-only layer so Decals can target ground exclusively.
	for mi in _all_mesh_instances(instance):
		(mi as MeshInstance3D).layers = 1 << 2
	var bake_path := _bake_path()
	if FileAccess.file_exists(bake_path):
		_load_baked(terrain_node, bake_path)


# ---------------------------------------------------------------------------
# Bake / clear
# ---------------------------------------------------------------------------

func _bake() -> void:
	if terrain_mesh_path == "":
		push_error("HexTerrainLoader: terrain_mesh_path is empty")
		return
	var area := get_parent()
	var terrain_node := area.get_node_or_null("Terrain") as Node3D
	if terrain_node == null:
		push_error("HexTerrainLoader: no Terrain child found")
		return
	var packed := load(terrain_mesh_path) as PackedScene
	if packed == null:
		push_error("HexTerrainLoader: could not load " + terrain_mesh_path)
		return
	var mesh_root := packed.instantiate()
	terrain_node.add_child(mesh_root)
	var placements := HexAssetScatterer.scatter_dry_run(area, terrain_node)
	print("HexTerrainLoader: dry-run returned %d placements for %s" % [placements.size(), area.name])
	mesh_root.free()
	if placements.is_empty():
		push_warning("HexTerrainLoader: scatter produced no placements — check biome and mesh")
		return
	var scatter_dir := DirAccess.open("res://")
	if scatter_dir == null:
		push_error("HexTerrainLoader: could not open res:// — %s" % error_string(DirAccess.get_open_error()))
		return
	scatter_dir.make_dir_recursive("data/scatter")
	var file := FileAccess.open(_bake_path(), FileAccess.WRITE)
	if file == null:
		push_error("HexTerrainLoader: could not write %s — %s" % [_bake_path(), error_string(FileAccess.get_open_error())])
		return
	file.store_string(JSON.stringify(placements, "\t"))
	file.close()
	print("HexTerrainLoader: baked %d assets → %s" % [placements.size(), _bake_path()])


func _bake_all() -> void:
	var root := get_tree().edited_scene_root if Engine.is_editor_hint() else get_tree().root
	var all := _find_all_loaders(root)
	print("HexTerrainLoader: baking %d areas..." % all.size())
	for loader in all:
		loader._bake()
	print("HexTerrainLoader: all areas baked.")


func _find_all_loaders(node: Node) -> Array:
	var result := []
	if node.get_script() == get_script():
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_all_loaders(child))
	return result


func _clear() -> void:
	var path := _bake_path()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("HexTerrainLoader: cleared bake — ", path)
	else:
		print("HexTerrainLoader: no bake file to clear — ", path)


func _bake_path() -> String:
	if terrain_mesh_path != "":
		return "res://data/scatter/%s.json" % terrain_mesh_path.get_file().get_basename()
	return "res://data/scatter/%s.json" % get_parent().name


func _load_baked(terrain_node: Node, path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if not data is Array:
		return

	# Group placements by asset path
	var groups: Dictionary = {}
	for entry in data:
		var ap: String = entry["path"]
		if not groups.has(ap):
			groups[ap] = []
		groups[ap].append(entry)

	# One MultiMeshInstance3D per mesh surface — thousands of nodes → a handful
	for asset_path: String in groups:
		var packed := load(asset_path) as PackedScene
		if packed == null:
			continue
		var template := packed.instantiate()
		var entries: Array = groups[asset_path]

		for mi in _all_mesh_instances(template):
			var mesh_inst := mi as MeshInstance3D
			if mesh_inst.mesh == null:
				continue
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = mesh_inst.mesh
			mm.instance_count = entries.size()
			for i in range(entries.size()):
				var e: Dictionary = entries[i]
				var p: Array = e["pos"]
				var s: float = float(e.get("scale", 1.0))
				mm.set_instance_transform(i, Transform3D(
					Basis(Vector3.UP, float(e["rot_y"])).scaled(Vector3(s, s, s)),
					Vector3(float(p[0]), float(p[1]), float(p[2]))
				))
			var mmi := MultiMeshInstance3D.new()
			mmi.multimesh = mm
			terrain_node.add_child(mmi)

		template.free()


# ---------------------------------------------------------------------------

func _generate_collision(root: Node) -> void:
	for node in _all_mesh_instances(root):
		node.create_trimesh_collision()


func _all_mesh_instances(node: Node) -> Array:
	var result := []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_all_mesh_instances(child))
	return result
