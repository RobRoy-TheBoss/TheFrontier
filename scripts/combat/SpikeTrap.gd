## SpikeTrap
## Artificer Spike Trap — damages first monster to step on it.
## Recoverable after triggering.
extends Node3D

@export var damage: float = 80.0

var _triggered: bool = false

@onready var trigger_area: Area3D = $TriggerArea
@onready var mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	add_to_group("spike_trap")
	if trigger_area:
		trigger_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _triggered:
		return
	if not body.is_in_group("monster"):
		return
	_triggered = true
	if body.has_method("take_damage"):
		body.take_damage(damage, null)
	DisciplineManager.add_xp("artificer", "trap_triggered")
	# Make recoverable: show "recover" interaction
	if mesh:
		mesh.set_surface_override_material(0, null)  # Visual feedback
	# Auto-recover after 10s
	await get_tree().create_timer(10.0).timeout
	_return_to_inventory()


func interact(player: Node) -> void:
	if _triggered:
		_return_to_inventory()


func _return_to_inventory() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.inventory.add_item("spike_trap", 1)
	queue_free()
