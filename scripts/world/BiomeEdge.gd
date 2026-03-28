## BiomeEdge
## Generates a walkable transition mesh between two adjacent hex areas.
## Visual style (width, color, slope extent) is driven by data/biome_transitions.json
## based on the biome pair. Also registers neighbor awareness on both areas.
##
## Place as a sibling of the Area nodes. Set area_a_path and area_b_path to
## the relative NodePaths of the two areas (e.g. NodePath("../CrestportBay")).
class_name BiomeEdge
extends StaticBody3D

@export var area_a_path: NodePath = NodePath()
@export var area_b_path: NodePath = NodePath()

## Hex inradius (center to flat edge) matching EasternFrontier's circumradius of 199.
const HEX_INRADIUS := 172.4

static var _data: Dictionary = {}


func _ready() -> void:
	_ensure_data_loaded()
	_build()


static func _ensure_data_loaded() -> void:
	if not _data.is_empty():
		return
	var f := FileAccess.open("res://data/biome_transitions.json", FileAccess.READ)
	if f == null:
		push_warning("BiomeEdge: could not open biome_transitions.json")
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		_data = parsed


func _build() -> void:
	if area_a_path.is_empty() or area_b_path.is_empty():
		return
	var node_a: Node3D = get_node_or_null(area_a_path)
	var node_b: Node3D = get_node_or_null(area_b_path)
	if node_a == null or node_b == null:
		push_warning("BiomeEdge: could not resolve area nodes (%s, %s)" % [area_a_path, area_b_path])
		return

	var biome_a: String = _get_biome(node_a)
	var biome_b: String = _get_biome(node_b)
	var transition: Dictionary = _get_transition(biome_a, biome_b)

	var pos_a: Vector3 = node_a.global_position
	var pos_b: Vector3 = node_b.global_position
	var dir_xz := Vector3(pos_b.x - pos_a.x, 0.0, pos_b.z - pos_a.z).normalized()

	var extend: float = transition.get("extend_into_each", 30.0)
	var offset := dir_xz * (HEX_INRADIUS - extend)

	# Surface points: step into each hex from the shared edge
	var point_a := Vector3(pos_a.x + offset.x, pos_a.y, pos_a.z + offset.z)
	var point_b := Vector3(pos_b.x - offset.x, pos_b.y, pos_b.z - offset.z)

	_generate_mesh(point_a, point_b, transition)

	# Tell each area who its neighbours are
	_register_with_area(node_a, node_b, biome_b)
	_register_with_area(node_b, node_a, biome_a)


func _get_biome(node: Node3D) -> String:
	var raw = node.get("biome")
	return raw as String if raw is String else ""


func _get_transition(biome_a: String, biome_b: String) -> Dictionary:
	var key: String = (biome_a + "|" + biome_b) if biome_a <= biome_b \
			else (biome_b + "|" + biome_a)
	var table: Dictionary = _data.get("transitions", {})
	if table.has(key):
		return table[key]
	push_warning("BiomeEdge: no transition defined for '%s' — using default" % key)
	return _data.get("default", {
		"width": 15.0, "extend_into_each": 30.0, "color": [0.5, 0.5, 0.45, 1.0]
	})


func _generate_mesh(point_a: Vector3, point_b: Vector3, transition: Dictionary) -> void:
	var ab := point_b - point_a
	var length := ab.length()
	if length < 0.01:
		return

	var forward := ab.normalized()
	var right := Vector3(forward.z, 0.0, -forward.x).normalized()
	var up := forward.cross(right).normalized()

	transform = Transform3D(Basis(right, up, -forward), (point_a + point_b) * 0.5)

	var width: float = transition.get("width", 15.0)
	var c = transition.get("color", [0.5, 0.5, 0.45, 1.0])
	var color := Color(c[0], c[1], c[2], c[3])
	var size := Vector3(width, 1.0, length)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color

	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.set_surface_override_material(0, mat)
	add_child(mi)

	var shape := BoxShape3D.new()
	shape.size = size
	var cs := CollisionShape3D.new()
	cs.shape = shape
	add_child(cs)


func _register_with_area(area: Node3D, neighbor: Node3D, neighbor_biome: String) -> void:
	if area.has_method("register_neighbor_biome"):
		var neighbor_id: String = neighbor.get("area_id") as String if \
				neighbor.get("area_id") is String else ""
		area.register_neighbor_biome(neighbor_id, neighbor_biome)


## Returns the transition definition for this edge (biome pair key, style, etc.)
func get_transition_data() -> Dictionary:
	return _get_transition(_get_biome(get_node_or_null(area_a_path)),
			_get_biome(get_node_or_null(area_b_path)))
