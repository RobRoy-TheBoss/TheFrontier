## HexTerrainLoader
## Loads a .glb terrain mesh, tints it with the Area's biome color,
## and attaches it to the parent Area's Terrain node.
extends Node

@export var terrain_mesh_path: String = ""

const BIOME_COLORS := {
	"coast":         Color(0.93, 0.87, 0.62),
	"forest":        Color(0.22, 0.52, 0.18),
	"mountain":      Color(0.58, 0.55, 0.50),
	"swamp":         Color(0.30, 0.38, 0.20),
	"mountain_pass": Color(0.52, 0.50, 0.44),
	"plains":        Color(0.62, 0.78, 0.38),
}

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
	_apply_biome_color(instance)
	_generate_collision(instance)


func _apply_biome_color(root: Node) -> void:
	var area = get_parent()
	var biome := area.get("biome") as String if area.get("biome") is String else ""
	var color: Color = BIOME_COLORS.get(biome, Color(0.55, 0.52, 0.46))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	for node in _all_mesh_instances(root):
		node.set_surface_override_material(0, mat)


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
