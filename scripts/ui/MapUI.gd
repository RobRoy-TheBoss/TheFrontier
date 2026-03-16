## MapUI
## Displays the map item. No player position shown. Shows terrain, settlements,
## named landmarks, and roads. Map data comes from map item instance.
extends Control

@onready var map_texture: TextureRect = $Panel/MapTexture
@onready var settlement_markers: Control = $Panel/SettlementMarkers
@onready var landmark_labels: Control = $Panel/LandmarkLabels

var _current_map_data: Dictionary = {}


func _ready() -> void:
	add_to_group("map_ui")
	visible = false


func toggle() -> void:
	visible = not visible
	if visible:
		_load_current_map()


func _load_current_map() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	# Find map item in inventory
	for entry in player.inventory.items:
		if entry["item_id"] == "map_item":
			_current_map_data = entry.get("map_data", {})
			_render_map()
			return


func _render_map() -> void:
	if _current_map_data.is_empty():
		return
	# Clear existing markers
	for child in settlement_markers.get_children():
		child.queue_free()
	for child in landmark_labels.get_children():
		child.queue_free()

	# Render settlement markers
	var map_bounds: Dictionary = _current_map_data.get("bounds", {})
	for sid in SettlementManager.settlements:
		var s: SettlementManager.SettlementData = SettlementManager.settlements[sid]
		if not _current_map_data.get("known_settlements", []).has(sid):
			continue
		var marker := Label.new()
		marker.text = "●"
		var screen_pos := _world_to_map_coords(s.position, map_bounds)
		marker.position = screen_pos
		var tier := GameData.get_tier_by_index(s.tier_index)
		match tier.get("id", "trading_post"):
			"trading_post": marker.add_theme_color_override("font_color", Color.WHITE)
			"village": marker.add_theme_color_override("font_color", Color.YELLOW)
			"town": marker.add_theme_color_override("font_color", Color.ORANGE)
			"city": marker.add_theme_color_override("font_color", Color.GOLD)
		settlement_markers.add_child(marker)

	# Render named landmarks
	for landmark_id in GameState.named_landmarks:
		var player_name: String = GameState.named_landmarks[landmark_id]
		var landmark_node: Node = null
		for n in get_tree().get_nodes_in_group("landmark"):
			if n.landmark_id == landmark_id:
				landmark_node = n
				break
		if landmark_node == null:
			continue
		var lbl := Label.new()
		lbl.text = player_name
		var screen_pos := _world_to_map_coords(landmark_node.global_position, map_bounds)
		lbl.position = screen_pos
		lbl.add_theme_color_override("font_color", Color.LIGHT_BLUE)
		landmark_labels.add_child(lbl)


func _world_to_map_coords(world_pos: Vector3, bounds: Dictionary) -> Vector2:
	if bounds.is_empty():
		return Vector2.ZERO
	var map_size := Vector2(600, 400)  # Map display size in pixels
	var world_min := Vector2(bounds.get("min_x", -500), bounds.get("min_z", -500))
	var world_max := Vector2(bounds.get("max_x", 500), bounds.get("max_z", 500))
	var world_range := world_max - world_min
	var normalized := Vector2(
		(world_pos.x - world_min.x) / world_range.x,
		(world_pos.z - world_min.y) / world_range.y
	)
	return normalized * map_size
