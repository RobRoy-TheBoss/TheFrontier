## HexTerrainLoader
## Loads a .glb terrain mesh, tints it with the Area's biome color,
## and attaches it to the parent Area's Terrain node.
extends Node

@export var terrain_mesh_path: String = ""


func _ready() -> void:
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
	HexAssetScatterer.scatter(get_parent(), terrain_node)



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
