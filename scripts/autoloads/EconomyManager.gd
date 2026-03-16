## EconomyManager
## Autoload singleton. Manages per-settlement trade score accumulation,
## pass-through traffic bonuses, export value tracking, and manufactured goods tiers.
extends Node

const LUXURY_ITEMS := ["gold_ore", "silver_ore", "fur", "gems", "monster_materials"]


func process_trade_batch() -> void:
	var weights: Dictionary = GameData.settlement_tiers.get("trade_score_weights", {
		"local_resource_output": 1.0,
		"pass_through_traffic": 0.6,
		"resource_diversity_multiplier": 1.3,
		"connection_count_bonus": 0.2
	})

	# Build pass-through traffic counts
	var pass_through_counts := {}
	for sid in SettlementManager.port_routing:
		var route_sid: String = sid
		var port_id: String = SettlementManager.port_routing.get(sid, "")
		if port_id == "" or port_id == route_sid:
			continue
		# Walk the path and count each intermediate node
		var path := _get_path_to_port(route_sid, port_id)
		for i in range(1, path.size() - 1):
			var intermediate: String = path[i]
			pass_through_counts[intermediate] = pass_through_counts.get(intermediate, 0) + 1

	# Accumulate per-settlement trade scores
	for sid in SettlementManager.settlements:
		var s: SettlementManager.SettlementData = SettlementManager.settlements[sid]
		var score := 0.0

		# Local resource output
		var local_out := _calculate_local_output(s)
		score += local_out * weights.get("local_resource_output", 1.0)

		# Pass-through traffic
		var traffic: int = pass_through_counts.get(sid, 0)
		score += traffic * weights.get("pass_through_traffic", 0.6)

		# Resource diversity multiplier
		var diversity := s.discovered_resources.size()
		if diversity > 1:
			score *= 1.0 + (diversity - 1) * (weights.get("resource_diversity_multiplier", 1.3) - 1.0)

		# Connection count bonus
		var connections: int = SettlementManager.road_network.get(sid, []).size()
		score += connections * weights.get("connection_count_bonus", 0.2) * 10.0

		SettlementManager.accumulate_trade_score(sid, score)

	# Process luxury exports reaching ports
	_process_port_exports()


func _calculate_local_output(s: SettlementManager.SettlementData) -> float:
	var total := 0.0
	for res_id in s.discovered_resources:
		total += s.discovered_resources[res_id]  # richness value
	return total


func _process_port_exports() -> void:
	var export_gain := 0
	for sid in SettlementManager.settlements:
		var s: SettlementManager.SettlementData = SettlementManager.settlements[sid]
		if not s.is_deep_water_port:
			continue
		# Count luxury goods flowing through this port
		for res_id in s.discovered_resources:
			if res_id in LUXURY_ITEMS:
				export_gain += int(s.discovered_resources[res_id])
	if export_gain > 0:
		GameState.add_export_value(export_gain)


func _get_path_to_port(start_id: String, port_id: String) -> Array:
	if start_id == port_id:
		return [start_id]
	var prev := {}
	var visited := {}
	var queue := [start_id]
	visited[start_id] = true

	while queue.size() > 0:
		var current: String = queue.pop_front()
		for neighbor in SettlementManager.road_network.get(current, []):
			if neighbor in visited:
				continue
			visited[neighbor] = true
			prev[neighbor] = current
			if neighbor == port_id:
				return _reconstruct_path(prev, start_id, port_id)
			queue.append(neighbor)
	return []


func _reconstruct_path(prev: Dictionary, start_id: String, end_id: String) -> Array:
	var path := []
	var current := end_id
	while current != start_id:
		path.push_front(current)
		current = prev.get(current, "")
		if current == "":
			return []
	path.push_front(start_id)
	return path


func player_sell_item(item_id: String, quantity: int, settlement_id: String) -> int:
	var item := GameData.get_item(item_id)
	if item.is_empty():
		return 0
	var base_value: int = item.get("value", 0)
	var total := base_value * quantity
	# Add to export value if luxury
	if item_id in LUXURY_ITEMS:
		GameState.add_export_value(total / 10)
	return total


func get_manufactured_goods_available(settlement_tier_index: int) -> Array:
	if settlement_tier_index < 3:  # Must be City
		return []
	var goods_tier := GameState.manufactured_goods_tier
	# Return goods appropriate for current export tier
	return []  # Populated once manufactured_goods.json is defined
