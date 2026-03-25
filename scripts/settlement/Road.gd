## Road
## Visual road connection between two settlements.
## Quality (and visuals) determined by the lower tier of the two connected settlements.
class_name Road
extends Path3D

@export var settlement_a_id: String = ""
@export var settlement_b_id: String = ""

var _road_quality: Dictionary = {}

@onready var path_follow: PathFollow3D = $PathFollow3D


func _ready() -> void:
	add_to_group("road_node")
	SettlementManager.settlement_tier_changed.connect(_on_tier_changed)
	update_road_quality()


func update_road_quality() -> void:
	_road_quality = SettlementManager.get_road_quality(settlement_a_id, settlement_b_id)
	_update_visuals()


func _update_visuals() -> void:
	if _road_quality.is_empty():
		return
	# Apply road surface material based on quality
	var visual_ref: String = _road_quality.get("visual_ref", "road_game_trail")
	# Placeholder: swap material based on visual_ref
	# In real impl: load material from assets/textures/roads/{visual_ref}.tres


func get_speed_multiplier() -> float:
	return _road_quality.get("speed_multiplier", 1.0)


func _on_tier_changed(sid: String, _new_tier: String) -> void:
	if sid == settlement_a_id or sid == settlement_b_id:
		update_road_quality()


func is_player_on_road(player_pos: Vector3, tolerance: float = 3.0) -> bool:
	# Check if player is within tolerance of this road path
	if curve == null:
		return false
	var closest := curve.get_closest_point(to_local(player_pos))
	return to_local(player_pos).distance_to(closest) < tolerance
