## RampConnector
## Procedurally builds a walkable ramp mesh and collision between two
## world-space surface points. Set point_a / point_b to the ramp endpoints
## (on the hex top surfaces); geometry is created at runtime.
class_name RampConnector
extends StaticBody3D

@export var point_a: Vector3 = Vector3.ZERO
@export var point_b: Vector3 = Vector3.ZERO
@export var width: float = 15.0

func _ready() -> void:
	_build()

func _build() -> void:
	var ab: Vector3 = point_b - point_a
	var ramp_length: float = ab.length()
	if ramp_length < 0.01:
		return

	var forward: Vector3 = ab.normalized()
	# Lateral axis: perpendicular to forward, kept horizontal
	var right: Vector3 = Vector3(forward.z, 0.0, -forward.x).normalized()
	# Surface normal: cross in this order gives upward-facing normal for a
	# ramp that rises from point_a to point_b
	var up: Vector3 = forward.cross(right).normalized()

	transform = Transform3D(Basis(right, up, -forward), (point_a + point_b) * 0.5)

	var size := Vector3(width, 1.0, ramp_length)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.52, 0.47, 0.38, 1)

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
