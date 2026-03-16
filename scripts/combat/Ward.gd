## Ward
## Ritualist Ward ability — monsters cannot enter the radius for duration seconds.
extends Node3D

var radius: float = 3.0
var duration: float = 60.0
var _timer: float = 0.0

@onready var block_area: Area3D = $BlockArea
@onready var ward_mesh: MeshInstance3D = $WardMesh


func _ready() -> void:
	add_to_group("ward")
	if block_area:
		block_area.body_entered.connect(_on_body_entered)


func setup(in_radius: float, in_duration: float) -> void:
	radius = in_radius
	duration = in_duration
	_timer = duration
	var shape := block_area.get_node_or_null("CollisionShape3D")
	if shape:
		var sphere := SphereShape3D.new()
		sphere.radius = radius
		shape.shape = sphere
	# Scale visual
	if ward_mesh:
		ward_mesh.scale = Vector3(radius * 2, 0.1, radius * 2)


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		queue_free()
	# Fade out near expiry
	if ward_mesh and _timer < 5.0:
		var alpha := _timer / 5.0
		ward_mesh.set_instance_shader_parameter("alpha", alpha)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("monster"):
		# Push monster back out of ward
		var dir := (body.global_position - global_position).normalized()
		dir.y = 0
		body.global_position = global_position + dir * (radius + 0.5)
		if body.has_method("flee_from"):
			body.flee_from(global_position)
