## BatchProcessor
## Autoload singleton. Runs the sleep batch in the correct order defined by SLEEP-179.
## Order: (1) resource extraction, (2) trade routing, (3) per-settlement trade score,
##        (4) tier checks, (5) visual updates, (6) road formation/quality,
##        (7) area suppression recalc, (8) Hunter food gen, (9) Trapper harvest.
extends Node

signal batch_started()
signal batch_step_completed(step: int, step_name: String)
signal batch_completed()

var _is_running: bool = false


func run_sleep_batch() -> void:
	if _is_running:
		push_warning("[BatchProcessor] Batch already running.")
		return
	_is_running = true
	GameState.batch_processing = true
	batch_started.emit()
	await _run_steps()
	GameState.batch_processing = false
	_is_running = false
	batch_completed.emit()


func _run_steps() -> void:
	# Step 1: Resource extraction
	await _step_resource_extraction()
	batch_step_completed.emit(1, "Resource Extraction")

	# Step 2: Trade routing (shortest path to port)
	await _step_trade_routing()
	batch_step_completed.emit(2, "Trade Routing")

	# Step 3: Per-settlement trade score accumulation
	await _step_trade_score()
	batch_step_completed.emit(3, "Trade Score")

	# Step 4: Tier checks
	await _step_tier_checks()
	batch_step_completed.emit(4, "Tier Checks")

	# Step 5: Visual updates (settlements change appearance)
	await _step_visual_updates()
	batch_step_completed.emit(5, "Visual Updates")

	# Step 6: Road formation and quality
	await _step_road_formation()
	batch_step_completed.emit(6, "Road Formation")

	# Step 7: Area suppression recalculation
	await _step_suppression_recalc()
	batch_step_completed.emit(7, "Suppression Recalc")

	# Step 8: Hunter food generation
	await _step_hunter_food()
	batch_step_completed.emit(8, "Hunter Food")

	# Step 9: Trapper harvest
	await _step_trapper_harvest()
	batch_step_completed.emit(9, "Trapper Harvest")


func _step_resource_extraction() -> void:
	# Each settlement extracts resources from its area based on tier suppression
	for sid in SettlementManager.settlements:
		var s: SettlementManager.SettlementData = SettlementManager.settlements[sid]
		var tier := GameData.get_tier_by_index(s.tier_index)
		var suppression_pct: float = tier.get("area_suppression_percent", 25) / 100.0
		for res_id in s.discovered_resources:
			var richness: float = s.discovered_resources[res_id]
			var extracted := richness * suppression_pct * 0.1  # Scale factor
			# Pass extracted to economy — future: add to trade flow
	await get_tree().process_frame


func _step_trade_routing() -> void:
	SettlementManager.recalculate_trade_routes()
	await get_tree().process_frame


func _step_trade_score() -> void:
	EconomyManager.process_trade_batch()
	await get_tree().process_frame


func _step_tier_checks() -> void:
	# Tier advancement is handled inside SettlementManager.accumulate_trade_score
	# This step forces a recheck in case of manual score additions
	for sid in SettlementManager.settlements:
		SettlementManager._check_tier_advance(sid)
	await get_tree().process_frame


func _step_visual_updates() -> void:
	# Signal all settlement nodes to update their visual representation
	var settlement_nodes := get_tree().get_nodes_in_group("settlement_node")
	for node in settlement_nodes:
		if node.has_method("update_visual_for_tier"):
			node.update_visual_for_tier()
	await get_tree().process_frame


func _step_road_formation() -> void:
	# Signal road nodes to update quality visuals
	var road_nodes := get_tree().get_nodes_in_group("road_node")
	for node in road_nodes:
		if node.has_method("update_road_quality"):
			node.update_road_quality()
	await get_tree().process_frame


func _step_suppression_recalc() -> void:
	# Notify spawn managers in each area to recalculate suppression
	var spawn_managers := get_tree().get_nodes_in_group("spawn_manager")
	for sm in spawn_managers:
		if sm.has_method("recalculate_suppression"):
			sm.recalculate_suppression()
	await get_tree().process_frame


func _step_hunter_food() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	# Check if a Hunter hireling is employed at the player's camp
	var camp := get_tree().get_first_node_in_group("player_camp")
	if camp == null or not camp.has_method("get_hireling_ids"):
		return
	for hire_id in camp.get_hireling_ids():
		if hire_id == "hunter":
			var hunter_def := GameData.get_hireling("hunter")
			var food_count: int = hunter_def.get("capabilities", {}).get("food_per_sleep", 0)
			if player.has_method("add_item_to_inventory"):
				for i in range(food_count):
					player.add_item_to_inventory("raw_meat", 1)
	await get_tree().process_frame


func _step_trapper_harvest() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	# Check active snare traps
	var traps := get_tree().get_nodes_in_group("snare_trap")
	for trap in traps:
		if trap.has_method("check_harvest"):
			var yield_items: Array = trap.check_harvest()
			for item_entry in yield_items:
				if player.has_method("add_item_to_inventory"):
					player.add_item_to_inventory(item_entry["item_id"], item_entry["count"])
	await get_tree().process_frame
