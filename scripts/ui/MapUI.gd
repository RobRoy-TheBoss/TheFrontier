## MapUI
## Displays the hex map. Tiles are revealed as the player discovers areas.
## In god mode all tiles are shown.
extends Control

@onready var settlement_markers: Control = $Panel/SettlementMarkers
@onready var landmark_labels:    Control = $Panel/LandmarkLabels

var _canvas: Control = null
var _tile_defs: Array = []   # raw tile list from map JSON


func _ready() -> void:
	add_to_group("map_ui")
	visible = false
	_load_tile_defs()
	_setup_canvas()


func toggle() -> void:
	visible = not visible
	if visible:
		_refresh()


func _setup_canvas() -> void:
	_canvas = Control.new()
	_canvas.name = "HexMapCanvas"
	_canvas.set_script(load("res://scripts/ui/HexMapCanvas.gd"))
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$Panel.add_child(_canvas)
	# Keep markers/labels on top
	$Panel.move_child(_canvas, 0)


func _load_tile_defs() -> void:
	var path := "res://data/maps/%s.json" % WorldManager.current_map_id
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data is Dictionary and data.has("tiles"):
		_tile_defs = data["tiles"]


func _refresh() -> void:
	if _canvas == null or _tile_defs.is_empty():
		return

	var player   := get_tree().get_first_node_in_group("player")
	var god_mode: bool = player != null and player.movement.god_mode

	# Auto-discover starting tile (col 0, row 0) so map is never blank at start
	_ensure_starting_tile_discovered()

	var entries: Array = []
	for tile in _tile_defs:
		var col: int     = int(tile["col"])
		var row: int     = int(tile["row"])
		var mesh: String = tile.get("mesh", "")
		var area_id      := "%d_%d_%s" % [col, row, mesh.get_basename()]
		var discovered   := god_mode or WorldManager.area_data.has(area_id)
		entries.append({ "col": col, "row": row, "mesh": mesh, "facing": int(tile.get("facing", 0)), "discovered": discovered })

	_canvas.tile_entries = entries
	_canvas.queue_redraw()
	_render_overlays()


func _ensure_starting_tile_discovered() -> void:
	for tile in _tile_defs:
		if int(tile["col"]) == 0 and int(tile["row"]) == 0:
			var mesh: String = tile.get("mesh", "")
			var area_id      := "0_0_%s" % mesh.get_basename()
			if not WorldManager.area_data.has(area_id):
				WorldManager.enter_area(area_id)
			return


func _render_overlays() -> void:
	for child in settlement_markers.get_children():
		child.queue_free()
	for child in landmark_labels.get_children():
		child.queue_free()

	for sid in SettlementManager.settlements:
		var s: SettlementManager.SettlementData = SettlementManager.settlements[sid]
		var marker := Label.new()
		marker.text = "●"
		marker.position = _world_to_canvas(Vector3(s.position.x, 0, s.position.z))
		var tier := GameData.get_tier_by_index(s.tier_index)
		match tier.get("id", "trading_post"):
			"trading_post": marker.add_theme_color_override("font_color", Color.WHITE)
			"village":      marker.add_theme_color_override("font_color", Color.YELLOW)
			"town":         marker.add_theme_color_override("font_color", Color.ORANGE)
			"city":         marker.add_theme_color_override("font_color", Color.GOLD)
		settlement_markers.add_child(marker)

	for landmark_id in GameState.named_landmarks:
		var player_name: String = GameState.named_landmarks[landmark_id]
		for n in get_tree().get_nodes_in_group("landmark"):
			if n.landmark_id == landmark_id:
				var lbl := Label.new()
				lbl.text = player_name
				lbl.position = _world_to_canvas(n.global_position)
				lbl.add_theme_color_override("font_color", Color.LIGHT_BLUE)
				landmark_labels.add_child(lbl)
				break


func _world_to_canvas(world_pos: Vector3) -> Vector2:
	if _canvas == null or _tile_defs.is_empty():
		return Vector2.ZERO
	var scale_factor: float = _canvas._compute_scale()
	var offset: Vector2     = _canvas._compute_offset(scale_factor)
	return Vector2(world_pos.x * scale_factor, world_pos.z * scale_factor) + offset
