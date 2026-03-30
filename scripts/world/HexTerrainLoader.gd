## HexTerrainLoader
## Loads a .glb terrain mesh and attaches it to the parent Area's Terrain node.
## Supports baked asset placement: click "Bake Assets" in the editor inspector
## to run the scatterer once and save results into the scene. At runtime,
## baked assets are used as-is — no scattering computation occurs.
@tool
extends Node

const BAKED_GROUP := "baked_scatter"

@export var terrain_mesh_path: String = ""

@export_tool_button("Bake Assets") var _bake_button = _bake
@export_tool_button("Clear Baked Assets") var _clear_button = _clear


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
	# Skip scattering if assets were already baked into the scene
	if not _has_baked_assets(terrain_node):
		HexAssetScatterer.scatter(get_parent(), terrain_node)


# ---------------------------------------------------------------------------
# Editor bake / clear
# ---------------------------------------------------------------------------

func _bake() -> void:
	if not Engine.is_editor_hint():
		return
	var terrain_node = get_parent().get_node_or_null("Terrain")
	if terrain_node == null:
		push_error("HexTerrainLoader: no Terrain child found — cannot bake")
		return
	_clear_existing(terrain_node)
	# Find the already-instantiated terrain mesh (child of Terrain that is not a baked asset)
	var mesh_root: Node = null
	for child in terrain_node.get_children():
		if not child.is_in_group(BAKED_GROUP):
			mesh_root = child
			break
	if mesh_root == null:
		push_error("HexTerrainLoader: terrain mesh not loaded — run the scene first or load it manually")
		return
	HexAssetScatterer.scatter(get_parent(), terrain_node)
	# Tag newly added children as baked so we can identify/clear them later
	for child in terrain_node.get_children():
		if not child.is_in_group(BAKED_GROUP) and child != mesh_root:
			child.add_to_group(BAKED_GROUP, true)
	# Persist the changes into the scene on disk
	var edited_scene := get_tree().edited_scene_root
	if edited_scene:
		var scene_path := edited_scene.scene_file_path
		if scene_path != "":
			var packed_scene := PackedScene.new()
			packed_scene.pack(edited_scene)
			ResourceSaver.save(packed_scene, scene_path)
			print("HexTerrainLoader: baked assets saved to ", scene_path)


func _clear() -> void:
	if not Engine.is_editor_hint():
		return
	var terrain_node = get_parent().get_node_or_null("Terrain")
	if terrain_node == null:
		return
	_clear_existing(terrain_node)
	var edited_scene := get_tree().edited_scene_root
	if edited_scene:
		var scene_path := edited_scene.scene_file_path
		if scene_path != "":
			var packed_scene := PackedScene.new()
			packed_scene.pack(edited_scene)
			ResourceSaver.save(packed_scene, scene_path)
			print("HexTerrainLoader: cleared baked assets from ", scene_path)


func _clear_existing(terrain_node: Node) -> void:
	for child in terrain_node.get_children():
		if child.is_in_group(BAKED_GROUP):
			child.queue_free()


func _has_baked_assets(terrain_node: Node) -> bool:
	for child in terrain_node.get_children():
		if child.is_in_group(BAKED_GROUP):
			return true
	return false


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
