## SettlementManager
## Autoload singleton. Owns all settlement runtime state.
## Tracks tiers, trade scores, road connections, port routing.
extends Node

signal settlement_founded(settlement_id: String)
signal settlement_tier_changed(settlement_id: String, new_tier: String)
signal trade_routes_updated()

# settlement_id -> SettlementData
var settlements: Dictionary = {}

# Adjacency list for road network: settlement_id -> [connected_settlement_id, ...]
var road_network: Dictionary = {}

# Cached shortest paths to ports: settlement_id -> port_settlement_id
var port_routing: Dictionary = {}

# Pending founding: area_id -> { "purchased_at": settlement_id, "flag_carrier": player_ref }
var pending_foundings: Dictionary = {}


class SettlementData:
	var id: String
	var area_id: String
	var tier_index: int = 0
	var trade_score: float = 0.0
	var is_deep_water_port: bool = false
	var is_player_home: bool = false
	var discovered_resources: Dictionary = {}  # resource_id -> richness
	var position: Vector3 = Vector3.ZERO
	var hireling_ids: Array = []
	var last_rested_here: bool = false

	func get_tier_id() -> String:
		var t: Dictionary = DataLoader.get_tier_by_index(tier_index)
		return t.get("id", "hamlet")

	func has_service(service: String) -> bool:
		var t: Dictionary = DataLoader.get_tier_by_index(tier_index)
		return service in t.get("services", [])


func _ready() -> void:
	# Crestport starts as a Trading Post with a Deep Water Port tag
	_register_starting_settlement()


func _register_starting_settlement() -> void:
	var crestport := SettlementData.new()
	crestport.id = "crestport"
	crestport.area_id = "area_crestport"
	crestport.tier_index = 2  # index 2 = village tier
	crestport.is_deep_water_port = true
	crestport.position = Vector3(0, 0, 0)  # Placeholder; set by world data
	settlements["crestport"] = crestport
	road_network["crestport"] = []


func found_settlement(area_id: String, purchased_at_id: String) -> void:
	var new_id := "settlement_" + area_id
	if settlements.has(new_id):
		push_warning("[SettlementManager] Settlement already exists for area: " + area_id)
		return
	var data := SettlementData.new()
	data.id = new_id
	data.area_id = area_id
	data.tier_index = 0
	settlements[new_id] = data
	road_network[new_id] = []
	_connect_nearest_settlements(new_id)
	settlement_founded.emit(new_id)
	recalculate_trade_routes()


func _connect_nearest_settlements(new_id: String) -> void:
	# Connect to the nearest existing settlement (placeholder; real impl uses Area adjacency)
	var new_data: SettlementData = settlements[new_id]
	var nearest_id := ""
	var nearest_dist := INF
	for sid in settlements:
		if sid == new_id:
			continue
		var other: SettlementData = settlements[sid]
		var dist := new_data.position.distance_to(other.position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_id = sid
	if nearest_id != "":
		road_network[new_id].append(nearest_id)
		road_network[nearest_id].append(new_id)


func recalculate_trade_routes() -> void:
	# Dijkstra from each settlement to its nearest deep-water port
	port_routing.clear()
	var ports := []
	for sid in settlements:
		var s: SettlementData = settlements[sid]
		if s.is_deep_water_port:
			ports.append(sid)

	for sid in settlements:
		var best_port := _find_nearest_port(sid, ports)
		port_routing[sid] = best_port

	trade_routes_updated.emit()


func _find_nearest_port(start_id: String, ports: Array) -> String:
	if start_id in ports:
		return start_id
	# BFS / Dijkstra over road_network
	var dist := { start_id: 0 }
	var prev := {}
	var queue := [start_id]
	var visited := {}

	while queue.size() > 0:
		queue.sort_custom(func(a, b): return dist.get(a, INF) < dist.get(b, INF))
		var current: String = queue.pop_front()
		if current in visited:
			continue
		visited[current] = true
		if current in ports:
			return current
		for neighbor in road_network.get(current, []):
			var new_dist: float = dist.get(current, INF) + 1.0
			if new_dist < dist.get(neighbor, INF):
				dist[neighbor] = new_dist
				prev[neighbor] = current
				queue.append(neighbor)
	return ""


func accumulate_trade_score(settlement_id: String, amount: float) -> void:
	if not settlements.has(settlement_id):
		return
	var s: SettlementData = settlements[settlement_id]
	s.trade_score += amount
	_check_tier_advance(settlement_id)


func _check_tier_advance(settlement_id: String) -> void:
	var s: SettlementData = settlements[settlement_id]
	var next_tier_index: int = s.tier_index + 1
	var next_tier: Dictionary = DataLoader.get_tier_by_index(next_tier_index)
	if next_tier.is_empty():
		return  # Already max tier
	if s.trade_score < next_tier.get("trade_score_threshold", INF):
		return
	# Check resource requirements
	var required: Array = next_tier.get("required_resources", [])
	for res in required:
		if not s.discovered_resources.has(res):
			return
	s.tier_index = next_tier_index
	settlement_tier_changed.emit(settlement_id, next_tier.get("id", ""))


func get_settlement(id: String) -> SettlementData:
	return settlements.get(id, null)


func get_all_settlements() -> Array:
	return settlements.values()


func get_road_quality(id_a: String, id_b: String) -> Dictionary:
	var s_a: SettlementData = settlements.get(id_a)
	var s_b: SettlementData = settlements.get(id_b)
	if s_a == null or s_b == null:
		return {}
	var min_tier := mini(s_a.tier_index, s_b.tier_index)
	var tier_a_name: String = DataLoader.get_tier_by_index(s_a.tier_index).get("id", "trading_post")
	var tier_b_name: String = DataLoader.get_tier_by_index(s_b.tier_index).get("id", "trading_post")
	var key := _road_key(tier_a_name, tier_b_name)
	return {}


func _road_key(tier_a: String, tier_b: String) -> String:
	var tiers := [tier_a, tier_b]
	tiers.sort()
	return tiers[0] + "_" + tiers[1]


func get_save_data() -> Dictionary:
	var data := {}
	for sid in settlements:
		var s: SettlementData = settlements[sid]
		data[sid] = {
			"area_id": s.area_id,
			"tier_index": s.tier_index,
			"trade_score": s.trade_score,
			"is_deep_water_port": s.is_deep_water_port,
			"position": { "x": s.position.x, "y": s.position.y, "z": s.position.z },
			"hireling_ids": s.hireling_ids,
			"discovered_resources": s.discovered_resources
		}
	return { "settlements": data, "road_network": road_network }


func apply_save_data(data: Dictionary) -> void:
	settlements.clear()
	road_network.clear()
	var sdata: Dictionary = data.get("settlements", {})
	for sid in sdata:
		var entry: Dictionary = sdata[sid]
		var s := SettlementData.new()
		s.id = sid
		s.area_id = entry.get("area_id", "")
		s.tier_index = entry.get("tier_index", 0)
		s.trade_score = entry.get("trade_score", 0.0)
		s.is_deep_water_port = entry.get("is_deep_water_port", false)
		var pos: Dictionary = entry.get("position", {})
		s.position = Vector3(pos.get("x", 0), pos.get("y", 0), pos.get("z", 0))
		s.hireling_ids = entry.get("hireling_ids", [])
		s.discovered_resources = entry.get("discovered_resources", {})
		settlements[sid] = s
	road_network = data.get("road_network", {})
	recalculate_trade_routes()
