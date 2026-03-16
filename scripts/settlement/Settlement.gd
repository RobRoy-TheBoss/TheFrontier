## Settlement
## Runtime node representing a settlement in the world.
## Reads state from SettlementManager and updates visual representation accordingly.
extends Node3D

@export var settlement_id: String = "crestport"

@onready var tier_visuals: Node3D = $TierVisuals
@onready var safe_zone_area: Area3D = $SafeZone
@onready var interaction_area: Area3D = $InteractionArea
@onready var npc_root: Node3D = $NPCs

var _current_tier_index: int = -1


func _ready() -> void:
	add_to_group("settlement_node")
	SettlementManager.settlement_tier_changed.connect(_on_tier_changed)
	_sync_to_manager()


func _sync_to_manager() -> void:
	var s := SettlementManager.get_settlement(settlement_id)
	if s == null:
		return
	s.position = global_position
	update_visual_for_tier()
	_update_safe_zone()


func update_visual_for_tier() -> void:
	var s := SettlementManager.get_settlement(settlement_id)
	if s == null:
		return
	if s.tier_index == _current_tier_index:
		return
	_current_tier_index = s.tier_index
	# Show/hide tier-appropriate child nodes
	for i in range(tier_visuals.get_child_count()):
		var child := tier_visuals.get_child(i)
		child.visible = (i == _current_tier_index)


func _update_safe_zone() -> void:
	var s := SettlementManager.get_settlement(settlement_id)
	if s == null or safe_zone_area == null:
		return
	var tier := GameData.get_tier_by_index(s.tier_index)
	var radius: float = tier.get("safe_zone_radius", 40.0)
	var shape := safe_zone_area.get_node_or_null("CollisionShape3D")
	if shape and shape.shape is SphereShape3D:
		shape.shape.radius = radius


func _on_tier_changed(sid: String, new_tier: String) -> void:
	if sid != settlement_id:
		return
	update_visual_for_tier()
	_update_safe_zone()


func interact(player: Node) -> void:
	var s := SettlementManager.get_settlement(settlement_id)
	if s == null:
		return
	var ui := get_tree().get_first_node_in_group("settlement_ui")
	if ui and ui.has_method("show_settlement"):
		ui.show_settlement(settlement_id)


func report_flag_founding(area_id: String) -> void:
	# Called when player returns and reports a planted flag
	SettlementManager.found_settlement(area_id, settlement_id)
