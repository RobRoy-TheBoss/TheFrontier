## RoadManager
## Spawns and manages road Path3D nodes between connected settlements.
## Tracks which road the player is currently on for speed bonuses.
extends Node

signal road_speed_changed(multiplier: float)

var _roads: Dictionary = {}  # "id_a:id_b" -> Road node
var _player_on_road: Road = null

const ROAD_SCENE := "res://scenes/settlement/Road.tscn"


func _ready() -> void:
	SettlementManager.settlement_founded.connect(_on_settlement_founded)
	SettlementManager.trade_routes_updated.connect(_rebuild_roads)


func _physics_process(_delta: float) -> void:
	_check_player_road()


func _on_settlement_founded(_settlement_id: String) -> void:
	_rebuild_roads()


func _rebuild_roads() -> void:
	# Remove roads that no longer exist
	var current_edges := _get_all_edges()
	for key in _roads.keys():
		if not key in current_edges:
			if is_instance_valid(_roads[key]):
				_roads[key].queue_free()
			_roads.erase(key)
	# Add new roads
	for edge in current_edges:
		if not _roads.has(edge):
			_spawn_road(edge)


func _get_all_edges() -> Array:
	var edges := []
	for sid in SettlementManager.road_network:
		for neighbor in SettlementManager.road_network[sid]:
			var key := _edge_key(sid, neighbor)
			if not key in edges:
				edges.append(key)
	return edges


func _spawn_road(edge_key: String) -> void:
	var parts := edge_key.split(":")
	if parts.size() != 2:
		return
	var sid_a: String = parts[0]
	var sid_b: String = parts[1]
	var s_a := SettlementManager.get_settlement(sid_a)
	var s_b := SettlementManager.get_settlement(sid_b)
	if s_a == null or s_b == null:
		return

	var road_res := load(ROAD_SCENE)
	if road_res == null:
		# Fallback: create a simple Path3D
		var road := Path3D.new()
		road.set_script(load("res://scripts/settlement/Road.gd"))
		road.settlement_a_id = sid_a
		road.settlement_b_id = sid_b
		road.curve = Curve3D.new()
		road.curve.add_point(s_a.position)
		road.curve.add_point(s_b.position)
		get_tree().root.add_child(road)
		_roads[edge_key] = road
		return

	var road: Road = road_res.instantiate()
	road.settlement_a_id = sid_a
	road.settlement_b_id = sid_b
	road.curve = Curve3D.new()
	road.curve.add_point(s_a.position)
	road.curve.add_point(s_b.position)
	get_tree().root.add_child(road)
	_roads[edge_key] = road


func _check_player_road() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var player_pos := player.global_position
	var on_road: Road = null
	for key in _roads:
		var road: Road = _roads[key]
		if not is_instance_valid(road):
			continue
		if road.is_player_on_road(player_pos):
			on_road = road
			break
	if on_road != _player_on_road:
		_player_on_road = on_road
		var mult := on_road.get_speed_multiplier() if on_road != null else 1.0
		player.movement.set_road_speed_bonus(mult - 1.0)
		road_speed_changed.emit(mult)


func _edge_key(a: String, b: String) -> String:
	var parts := [a, b]
	parts.sort()
	return parts[0] + ":" + parts[1]
