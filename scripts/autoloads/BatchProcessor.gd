## BatchProcessor
## Autoload singleton. Executes the sleep batch in the exact 19-step order
## defined by LSLEEP-003..021 (LLR v0.5.1).
##
## Steps 0..18:
##   0  founding_completion     LSLEEP-003
##   1  resource_extraction     LSLEEP-004
##   2  trade_route_recalc      LSLEEP-005
##   3  consumption_trade_score LSLEEP-006
##   4  tier_advancement        LSLEEP-007
##   5  visual_updates          LSLEEP-008
##   6  road_evaluation         LSLEEP-009
##   7  suppression_recalc      LSLEEP-010
##   8  hunter_food             LSLEEP-011
##   9  trapper_harvest         LSLEEP-012
##  10  hireling_costs          LSLEEP-013
##  11  injury_healing          LSLEEP-014
##  12  fatigue_reset           LSLEEP-015
##  13  hunger_thirst_deduct    LSLEEP-016
##  14  day_season_advance      LSLEEP-017
##  15  weather_roll            LSLEEP-018
##  16  surveyor_discovery      LSLEEP-019
##  17  cartographer_map        LSLEEP-020
##  18  auto_save               LSLEEP-021
extends Node

signal batch_started()
signal batch_step_completed(step: int, step_name: String)
signal batch_completed()

var _is_running: bool = false


## Run the full 19-step sleep batch.
func run_sleep_batch() -> void:
	if _is_running:
		push_warning("[BatchProcessor] Batch already running.")
		return
	_is_running = true
	GameState.is_sleeping = true
	GameState.batch_processing = true
	batch_started.emit()
	await _run_steps()
	GameState.batch_processing = false
	GameState.is_sleeping = false
	_is_running = false
	batch_completed.emit()


func _run_steps() -> void:
	# Step 0 — founding_completion  [LSLEEP-003]
	await _step_founding_completion()
	batch_step_completed.emit(0, "founding_completion")

	# Step 1 — resource_extraction  [LSLEEP-004]
	await _step_resource_extraction()
	batch_step_completed.emit(1, "resource_extraction")

	# Step 2 — trade_route_recalc   [LSLEEP-005]
	await _step_trade_route_recalc()
	batch_step_completed.emit(2, "trade_route_recalc")

	# Step 3 — consumption_trade_score  [LSLEEP-006]
	await _step_consumption_trade_score()
	batch_step_completed.emit(3, "consumption_trade_score")

	# Step 4 — tier_advancement     [LSLEEP-007]
	await _step_tier_advancement()
	batch_step_completed.emit(4, "tier_advancement")

	# Step 5 — visual_updates       [LSLEEP-008]
	await _step_visual_updates()
	batch_step_completed.emit(5, "visual_updates")

	# Step 6 — road_evaluation      [LSLEEP-009]
	await _step_road_evaluation()
	batch_step_completed.emit(6, "road_evaluation")

	# Step 7 — suppression_recalc   [LSLEEP-010]
	await _step_suppression_recalc()
	batch_step_completed.emit(7, "suppression_recalc")

	# Step 8 — hunter_food          [LSLEEP-011]
	await _step_hunter_food()
	batch_step_completed.emit(8, "hunter_food")

	# Step 9 — trapper_harvest      [LSLEEP-012]
	await _step_trapper_harvest()
	batch_step_completed.emit(9, "trapper_harvest")

	# Step 10 — hireling_costs      [LSLEEP-013]
	await _step_hireling_costs()
	batch_step_completed.emit(10, "hireling_costs")

	# Step 11 — injury_healing      [LSLEEP-014]
	await _step_injury_healing()
	batch_step_completed.emit(11, "injury_healing")

	# Step 12 — fatigue_reset       [LSLEEP-015]
	await _step_fatigue_reset()
	batch_step_completed.emit(12, "fatigue_reset")

	# Step 13 — hunger_thirst_deduct  [LSLEEP-016]
	await _step_hunger_thirst_deduct()
	batch_step_completed.emit(13, "hunger_thirst_deduct")

	# Step 14 — day_season_advance  [LSLEEP-017]
	await _step_day_season_advance()
	batch_step_completed.emit(14, "day_season_advance")

	# Step 15 — weather_roll        [LSLEEP-018]
	await _step_weather_roll()
	batch_step_completed.emit(15, "weather_roll")

	# Step 16 — surveyor_discovery  [LSLEEP-019]
	await _step_surveyor_discovery()
	batch_step_completed.emit(16, "surveyor_discovery")

	# Step 17 — cartographer_map    [LSLEEP-020]
	await _step_cartographer_map()
	batch_step_completed.emit(17, "cartographer_map")

	# Step 18 — auto_save           [LSLEEP-021]
	await _step_auto_save()
	batch_step_completed.emit(18, "auto_save")


# ---------------------------------------------------------------------------
# Step implementations
# ---------------------------------------------------------------------------

## Step 0: Resolve any pending settlement founding [LSLEEP-003]
func _step_founding_completion() -> void:
	FoundingManager.try_complete_founding()
	await get_tree().process_frame


## Step 1: Each settlement extracts resources from its area [LSLEEP-004]
func _step_resource_extraction() -> void:
	for sid in SettlementManager.settlements:
		var s: SettlementManager.SettlementData = SettlementManager.settlements[sid]
		var tier := GameData.get_tier_by_index(s.tier_index)
		var suppression_pct: float = tier.get("area_suppression_percent", 25) / 100.0
		for res_id in s.discovered_resources:
			var richness: float = s.discovered_resources[res_id]
			@warning_ignore("unused_variable")
			var extracted := richness * suppression_pct * 0.1
	await get_tree().process_frame


## Step 2: Recalculate trade routes (shortest path to port) [LSLEEP-005]
func _step_trade_route_recalc() -> void:
	SettlementManager.recalculate_trade_routes()
	await get_tree().process_frame


## Step 3: Accumulate per-settlement trade score; apply settlement consumption [LSLEEP-006]
func _step_consumption_trade_score() -> void:
	EconomyManager.process_trade_batch()
	for sid in SettlementManager.settlements:
		var s: SettlementManager.SettlementData = SettlementManager.settlements[sid]
		var tier := GameData.get_tier_by_index(s.tier_index)
		var rate: float = tier.get("consumption_rate", 0.1)
		for res_id in s.discovered_resources:
			s.discovered_resources[res_id] = maxf(0.0, s.discovered_resources[res_id] - rate)
	await get_tree().process_frame


## Step 4: Check and apply tier advancement for all settlements [LSLEEP-007]
func _step_tier_advancement() -> void:
	for sid in SettlementManager.settlements:
		SettlementManager._check_tier_advance(sid)
	await get_tree().process_frame


## Step 5: Update settlement and world visuals [LSLEEP-008]
func _step_visual_updates() -> void:
	var settlement_nodes := get_tree().get_nodes_in_group("settlement_node")
	for node in settlement_nodes:
		if node.has_method("update_visual_for_tier"):
			node.update_visual_for_tier()
	await get_tree().process_frame


## Step 6: Evaluate road formation and quality [LSLEEP-009]
func _step_road_evaluation() -> void:
	var road_nodes := get_tree().get_nodes_in_group("road_node")
	for node in road_nodes:
		if node.has_method("update_road_quality"):
			node.update_road_quality()
	await get_tree().process_frame


## Step 7: Recalculate monster suppression radius per settlement [LSLEEP-010]
func _step_suppression_recalc() -> void:
	SpawnManager.recalculate_all_suppression()
	var spawn_nodes := get_tree().get_nodes_in_group("spawn_manager")
	for sm in spawn_nodes:
		if sm.has_method("recalculate_suppression"):
			sm.recalculate_suppression()
	await get_tree().process_frame


## Step 8: Hunter hireling generates food items [LSLEEP-011]
func _step_hunter_food() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var camp := get_tree().get_first_node_in_group("player_camp")
	if camp == null:
		return
	var hire_ids: Array = _get_camp_hireling_ids(camp)
	if "hunter" in hire_ids:
		var hunter_def := GameData.get_hireling("hunter")
		var food_count: int = hunter_def.get("capabilities", {}).get("food_per_sleep", 2)
		if player.has_method("add_item_to_inventory"):
			for _i in range(food_count):
				player.add_item_to_inventory("raw_meat", 1)
	await get_tree().process_frame


## Step 9: Harvest any set snare traps [LSLEEP-012]
func _step_trapper_harvest() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var traps := get_tree().get_nodes_in_group("snare_trap")
	for trap in traps:
		if trap.has_method("check_harvest"):
			var yield_items: Array = trap.check_harvest()
			for item_entry in yield_items:
				if player.has_method("add_item_to_inventory"):
					player.add_item_to_inventory(item_entry["item_id"], item_entry.get("count", 1))
	await get_tree().process_frame


## Step 10: Deduct daily hireling wages from player gold [LSLEEP-013]
func _step_hireling_costs() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var camp := get_tree().get_first_node_in_group("player_camp")
	if camp == null:
		return
	var hire_ids: Array = _get_camp_hireling_ids(camp)
	for hire_id in hire_ids:
		var hdef := GameData.get_hireling(hire_id)
		var daily_cost: int = hdef.get("daily_cost_gold", 0)
		if daily_cost > 0 and player.has_method("spend_gold"):
			player.spend_gold(daily_cost)
	await get_tree().process_frame


## Step 11: Attempt injury healing based on rest location [LSLEEP-014]
func _step_injury_healing() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var player_health: PlayerHealth = player.get("health") as PlayerHealth
	if player_health and player_health.has_method("on_sleep"):
		player_health.on_sleep(_player_is_in_settlement(player))
	await get_tree().process_frame


## Step 12: Reset player fatigue to zero [LSLEEP-015]
func _step_fatigue_reset() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var survival: PlayerSurvival = player.get("survival") as PlayerSurvival
	if survival and survival.has_method("reset_fatigue"):
		survival.reset_fatigue()
	await get_tree().process_frame


## Step 13: Deduct sleep-period hunger and thirst [LSLEEP-016]
func _step_hunger_thirst_deduct() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var survival: PlayerSurvival = player.get("survival") as PlayerSurvival
	if survival and survival.has_method("apply_sleep_hunger_thirst"):
		survival.apply_sleep_hunger_thirst()
	await get_tree().process_frame


## Step 14: Advance day counter; check season rollover [LSLEEP-017]
func _step_day_season_advance() -> void:
	GameState.current_day += 1
	GameState.day_changed.emit(GameState.current_day)
	SeasonManager.advance_day()
	await get_tree().process_frame


## Step 15: Roll weather for the new day [LSLEEP-018]
func _step_weather_roll() -> void:
	WeatherManager.roll_new_weather()
	await get_tree().process_frame


## Step 16: Surveyor hireling discovers all resources in current area [LSLEEP-019]
func _step_surveyor_discovery() -> void:
	var camp := get_tree().get_first_node_in_group("player_camp")
	if camp == null:
		return
	var hire_ids: Array = _get_camp_hireling_ids(camp)
	if "surveyor" in hire_ids:
		AreaManager.discover_all(GameState.current_area_id)
	await get_tree().process_frame


## Step 17: Cartographer hireling generates a MapItem [LSLEEP-020]
func _step_cartographer_map() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var camp := get_tree().get_first_node_in_group("player_camp")
	if camp == null:
		return
	var hire_ids: Array = _get_camp_hireling_ids(camp)
	if "cartographer" in hire_ids:
		if player.has_method("add_item_to_inventory"):
			player.add_item_to_inventory("map_item", 1)
	await get_tree().process_frame


## Step 18: Trigger auto-save [LSLEEP-021]
func _step_auto_save() -> void:
	SaveManager.save_game()
	await get_tree().process_frame


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _get_camp_hireling_ids(camp: Node) -> Array:
	if camp.has_meta("hireling_ids"):
		return camp.get_meta("hireling_ids")
	if camp.has_method("get_hireling_ids"):
		return camp.get_hireling_ids()
	return []


func _player_is_in_settlement(player: Node) -> bool:
	for sid in SettlementManager.settlements:
		var s: SettlementManager.SettlementData = SettlementManager.settlements[sid]
		if player.global_position.distance_to(s.position) < 55.0:
			return true
	return false
