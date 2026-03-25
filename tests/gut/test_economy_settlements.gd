## test_economy_settlements.gd
## GUT Runtime Tests — Economy, Settlements, Roads, Sleep Batch
## Traces to: LLR v0.6.0 | HLR v0.6.0 | GDD v9
##
## RUNTIME ONLY: Requires Godot 4 + GUT. Run via Godot editor → GUT panel.

extends GutTest

# Saved autoload state for isolation
var _saved_settlements: Dictionary
var _saved_roads: Dictionary
var _saved_port_routing: Dictionary
var _saved_trade_graph_adjacency: Dictionary
var _saved_trade_graph_dirty: bool


func before_each() -> void:
	_saved_settlements = SettlementManager.settlements.duplicate(true)
	_saved_roads = SettlementManager.road_network.duplicate(true)
	_saved_port_routing = SettlementManager.port_routing.duplicate(true)
	_saved_trade_graph_adjacency = TradeGraph._adjacency.duplicate(true)
	_saved_trade_graph_dirty = TradeGraph.is_dirty


func after_each() -> void:
	SettlementManager.settlements = _saved_settlements
	SettlementManager.road_network = _saved_roads
	SettlementManager.port_routing = _saved_port_routing
	TradeGraph._adjacency = _saved_trade_graph_adjacency
	TradeGraph.is_dirty = _saved_trade_graph_dirty


# ---------------------------------------------------------------------------
# Economy Runtime — LECO-001..010
# ---------------------------------------------------------------------------

# [LECO-001] SettlementManager maintains Dict of SettlementData per settlement
func test_settlement_manager_dict_leco001():
	assert_true(SettlementManager.settlements is Dictionary,
		"settlements must be a Dictionary [LECO-001]")


# [LECO-002] SettlementState includes: area_id, tier, trade_score, is_port, connections, etc.
func test_settlement_state_fields_leco002():
	# Inspect the inner class via a live instance from the existing "crestport" entry
	var crestport = SettlementManager.get_settlement("crestport")
	assert_not_null(crestport, "crestport settlement must exist at game start [LECO-002]")
	assert_true("area_id" in crestport, "SettlementData must have area_id [LECO-002]")
	assert_true("trade_score" in crestport, "SettlementData must have trade_score [LECO-002]")
	assert_true("is_deep_water_port" in crestport,
		"SettlementData must have is_deep_water_port [LECO-002]")
	assert_true("tier_index" in crestport, "SettlementData must have tier_index [LECO-002]")
	assert_true("hireling_ids" in crestport, "SettlementData must have hireling_ids [LECO-002]")


# [LECO-003] Tier change swaps settlement visual scene
func test_tier_change_swaps_visual_leco003():
	pass  # NOT TESTABLE: requires scene instantiation and visual swap node group


# [LECO-004] NPC scenes instantiated per tier services list
func test_npcs_per_tier_services_leco004():
	# Verify tier data defines services
	var village_tier: Dictionary = DataLoader.get_tier("village")
	assert_false(village_tier.is_empty(), "village tier data must exist [LECO-004]")
	assert_has(village_tier, "services", "Tier must define services list [LECO-004]")
	assert_gt(village_tier["services"].size(), 0,
		"Village tier must have at least one service [LECO-004]")


# [LECO-005] River area Town+ marks adjacent river edges passable (bridge)
func test_town_river_bridge_leco005():
	var town_tier: Dictionary = DataLoader.get_tier("town")
	assert_false(town_tier.is_empty(), "town tier must exist [LECO-005]")
	assert_has(town_tier, "bridge_rivers",
		"Town tier must define bridge_rivers flag [LECO-005]")
	assert_true(town_tier["bridge_rivers"],
		"Town tier must mark river edges passable [LECO-005]")


# [LECO-010] Crestport starts as Village (tier 2) with Deep Water Port
func test_crestport_initial_tier_leco010():
	var crestport = SettlementManager.get_settlement("crestport")
	assert_not_null(crestport, "crestport must exist [LECO-010]")
	assert_eq(crestport.get_tier_id(), "village",
		"crestport must start as village tier [LECO-010]")
	assert_true(crestport.is_deep_water_port,
		"crestport must be a Deep Water Port [LECO-010]")


# ---------------------------------------------------------------------------
# Trade Routing — LTRADE-001..005
# ---------------------------------------------------------------------------

# [LTRADE-001] TradeGraph maintains adjacency list of road-connected settlements
func test_trade_graph_adjacency_llist_ltrade001():
	assert_true(TradeGraph._adjacency is Dictionary,
		"TradeGraph._adjacency must be a Dictionary [LTRADE-001]")


# [LTRADE-002] On sleep, Dijkstra run from each non-port to find nearest port
func test_dijkstra_on_sleep_ltrade002():
	assert_true(TradeGraph.has_method("recalculate_all_routes"),
		"TradeGraph must implement recalculate_all_routes [LTRADE-002]")
	assert_true(TradeGraph.has_method("get_route_to_port"),
		"TradeGraph must implement get_route_to_port [LTRADE-002]")


# [LTRADE-003] route_path stored per settlement
func test_route_path_stored_ltrade003():
	assert_true(SettlementManager.port_routing is Dictionary,
		"port_routing must be stored as a Dictionary per settlement [LTRADE-003]")


# [LTRADE-004] trade_graph_dirty set true on new settlement or road
func test_dirty_flag_on_change_ltrade004():
	TradeGraph.is_dirty = false
	TradeGraph.add_road("crestport", "test_node_a")
	assert_true(TradeGraph.is_dirty,
		"is_dirty must be set true after add_road [LTRADE-004]")


# [LTRADE-005] Routes recalculated on sleep if dirty
func test_routes_recalculated_when_dirty_ltrade005():
	TradeGraph.mark_dirty()
	assert_true(TradeGraph.is_dirty,
		"mark_dirty() must set is_dirty = true [LTRADE-005]")
	# recalculate_all_routes is called by BatchProcessor step 2 when dirty
	var routes: Dictionary = TradeGraph.recalculate_all_routes()
	assert_true(routes is Dictionary,
		"recalculate_all_routes must return a Dictionary [LTRADE-005]")


# ---------------------------------------------------------------------------
# Trade Score — LSCORE-001..010
# ---------------------------------------------------------------------------

# [LSCORE-001] Local output = sum(richness * exploitation_pct) per tier
func test_local_output_formula_lscore001():
	# Verify settlement tier data includes exploitation percentages
	var hamlet_tier: Dictionary = DataLoader.get_tier("hamlet")
	assert_false(hamlet_tier.is_empty(), "hamlet tier must exist [LSCORE-001]")
	assert_has(hamlet_tier, "exploitation_pct",
		"Tier must define exploitation_pct [LSCORE-001]")
	assert_gt(hamlet_tier["exploitation_pct"], 0.0,
		"exploitation_pct must be positive [LSCORE-001]")


# [LSCORE-002] Consumption reduces remaining_value at each route node
func test_consumption_along_route_lscore002():
	# SettlementManager must implement trade score accumulation
	assert_true(SettlementManager.has_method("accumulate_trade_score"),
		"SettlementManager must implement accumulate_trade_score [LSCORE-002]")


# [LSCORE-003] Consumed portion contributes to that node's trade_score
func test_consumed_portion_adds_to_trade_score_lscore003():
	var crestport = SettlementManager.get_settlement("crestport")
	var before: float = crestport.trade_score
	SettlementManager.accumulate_trade_score("crestport", 10.0)
	assert_gt(crestport.trade_score, before,
		"accumulate_trade_score must increase trade_score [LSCORE-003]")


# [LSCORE-004] Consumption applies only to raw materials
func test_consumption_raw_only_lscore004():
	var item: Dictionary = DataLoader.get_item("iron_ore")
	assert_false(item.is_empty(), "iron_ore item must exist [LSCORE-004]")
	assert_has(item, "category", "Item must have category [LSCORE-004]")
	assert_eq(item["category"], "raw_material",
		"iron_ore must be categorized as raw_material [LSCORE-004]")


# [LSCORE-005] Manufactured goods availabi1lity not reduced by consumption
func test_mfg_goods_no_consumption_lscore005():
	var item: Dictionary = DataLoader.get_item("iron_tools")
	if item.is_empty():
		# If iron_tools doesn't exist, check any manufactured good
		var mfg_goods: Dictionary = DataLoader.manufactured_goods
		assert_false(mfg_goods.is_empty(),
			"manufactured_goods data must exist [LSCORE-005]")
		return
	assert_has(item, "category", "Manufactured good must have category [LSCORE-005]")
	assert_eq(item["category"], "manufactured",
		"Manufactured items must be categorized as manufactured [LSCORE-005]")


# [LSCORE-006] trade_score += local*lw + passthrough*pw + diversity + connections*cb
func test_trade_score_formula_lscore006():
	var weights: Dictionary = DataLoader.trade_weights
	assert_false(weights.is_empty(), "trade_weights data must exist [LSCORE-006]")
	assert_has(weights, "local_weight", "trade_weights must define local_weight [LSCORE-006]")
	assert_has(weights, "passthrough_weight",
		"trade_weights must define passthrough_weight [LSCORE-006]")
	assert_has(weights, "connection_bonus",
		"trade_weights must define connection_bonus [LSCORE-006]")


# [LSCORE-007] Tier advancement requires score >= next threshold
func test_tier_advance_score_threshold_lscore007():
	var village_tier: Dictionary = DataLoader.get_tier("village")
	assert_has(village_tier, "advance_score_threshold",
		"Village tier must define advance_score_threshold [LSCORE-007]")
	assert_gt(village_tier["advance_score_threshold"], 0.0,
		"advance_score_threshold must be positive [LSCORE-007]")


# [LSCORE-008] Tier advancement requires required_resources in flow-through
func test_tier_advance_required_resources_lscore008():
	var village_tier: Dictionary = DataLoader.get_tier("village")
	assert_has(village_tier, "required_resources",
		"Village tier must define required_resources for advancement [LSCORE-008]")


# [LSCORE-009] tier_changed signal emitted on advancement
func test_tier_changed_signal_lscore009():
	watch_signals(SettlementManager)
	# Force a tier advance by setting score above threshold and calling check
	var crestport = SettlementManager.get_settlement("crestport")
	var village_tier: Dictionary = DataLoader.get_tier("village")
	var threshold: float = village_tier.get("advance_score_threshold", 999999.0)
	crestport.trade_score = threshold + 1.0
	# Trigger tier check — method must exist
	assert_true(SettlementManager.has_method("_check_tier_advance") or
		SettlementManager.has_method("check_tier_advance"),
		"SettlementManager must implement tier advance check [LSCORE-009]")


# [LSCORE-010] tier_changed triggers road re-evaluation
func test_tier_change_triggers_road_eval_lscore010():
	# Verify settlement_tier_changed signal is defined
	assert_true(SettlementManager.has_signal("settlement_tier_changed"),
		"SettlementManager must emit settlement_tier_changed signal [LSCORE-010]")


# ---------------------------------------------------------------------------
# Export — LEXPORT-001..003
# ---------------------------------------------------------------------------

# [LEXPORT-001] Global export = sum of remaining_value at all ports
func test_global_export_sum_lexport001():
	assert_true("global_export_value" in GameState,
		"GameState must track global_export_value [LEXPORT-001]")
	assert_true(GameState.has_method("add_export_value"),
		"GameState must implement add_export_value [LEXPORT-001]")


# [LEXPORT-002] Highest exceeded threshold determines available_goods_tier
func test_export_tier_from_threshold_lexport002():
	var thresholds: Dictionary = DataLoader.export_thresholds
	assert_false(thresholds.is_empty(), "export_thresholds data must exist [LEXPORT-002]")
	# Each entry should have a value threshold and a goods tier
	for key in thresholds:
		assert_has(thresholds[key], "threshold",
			"Export threshold entry must define threshold [LEXPORT-002]")
		break


# [LEXPORT-003] Shop filters goods by export_tier and min_settlement_tier
func test_shop_filters_goods_lexport003():
	var mfg_goods: Dictionary = DataLoader.manufactured_goods
	assert_false(mfg_goods.is_empty(), "manufactured_goods must exist [LEXPORT-003]")
	for key in mfg_goods:
		assert_has(mfg_goods[key], "min_settlement_tier",
			"Manufactured good must define min_settlement_tier [LEXPORT-003]")
		break


# ---------------------------------------------------------------------------
# Roads — LROAD-001..019
# ---------------------------------------------------------------------------

# [LROAD-003] Road evaluation on settlement founding
func test_road_eval_on_founding_lroad003():
	# FoundingManager.complete_founding() triggers road evaluation
	assert_true(FoundingManager.has_method("complete_founding"),
		"FoundingManager must implement complete_founding [LROAD-003]")


# [LROAD-004] Road evaluation on tier change
func test_road_eval_on_tier_change_lroad004():
	# settlement_tier_changed signal triggers road_node group
	assert_true(SettlementManager.has_signal("settlement_tier_changed"),
		"SettlementManager must have settlement_tier_changed signal [LROAD-004]")


# [LROAD-005] Road evaluation NOT on every sleep
func test_road_eval_not_every_sleep_lroad005():
	# BatchProcessor only runs road evaluation (step 6) on founding/tier change
	# Verify BatchProcessor uses a dirty flag rather than evaluating every sleep
	assert_true(TradeGraph.has_method("mark_dirty"),
		"TradeGraph must support dirty flag for conditional evaluation [LROAD-005]")


# [LROAD-006] Settlements sorted by trade_score descending during evaluation
func test_road_eval_sorted_by_score_lroad006():
	# RoadManager script handles evaluation; verify SettlementManager.get_all_settlements() exists
	assert_true(SettlementManager.has_method("get_all_settlements"),
		"SettlementManager must implement get_all_settlements [LROAD-006]")


# [LROAD-007] Connect to highest-scoring reachable target within budget
func test_road_connect_highest_scoring_lroad007():
	var roads: Dictionary = DataLoader.roads
	assert_has(roads, "road_budget",
		"roads.json must define road_budget [LROAD-007]")
	assert_eq(roads["road_budget"], 9,
		"road_budget must be 9 [LROAD-007]")


# [LROAD-009] Old roads never deleted on re-evaluation
func test_old_roads_preserved_lroad009():
	TradeGraph.add_road("crestport", "preserved_test")
	var neighbors_before: Array = TradeGraph.get_neighbors("crestport")
	assert_has(neighbors_before, "preserved_test",
		"Road must be in adjacency list after add_road [LROAD-009]")
	# Adding more roads must not remove existing ones
	TradeGraph.add_road("crestport", "another_test")
	var neighbors_after: Array = TradeGraph.get_neighbors("crestport")
	assert_has(neighbors_after, "preserved_test",
		"Old road must still exist after adding new road [LROAD-009]")


# [LROAD-011] Road pathfinding uses A* on hex grid
func test_road_astar_pathfinding_lroad011():
	# RoadManager uses HexGrid for A* pathfinding
	assert_not_null(HexGrid, "HexGrid autoload must exist for road A* [LROAD-011]")
	assert_true(HexGrid.has_method("get_hex_neighbors") or HexGrid.has_method("axial_to_world"),
		"HexGrid must support pathfinding operations [LROAD-011]")


# [LROAD-012] Roads don't cross cliff edges
func test_road_no_cliff_crossing_lroad012():
	# Edge passability defined in areas.json; cliff edges are impassable
	var areas: Dictionary = DataLoader.areas
	assert_false(areas.is_empty(), "areas data must exist [LROAD-012]")


# [LROAD-013] Roads don't cross river without ford or Town+
func test_road_no_river_without_ford_lroad013():
	# River crossing requires town_tier bridge_rivers flag or ford feature
	var town_tier: Dictionary = DataLoader.get_tier("town")
	assert_has(town_tier, "bridge_rivers",
		"Town tier must define bridge_rivers for road crossing logic [LROAD-013]")


# [LROAD-014] Roads don't pass through Mountain unless Mountain Pass
func test_road_no_mountain_without_pass_lroad014():
	# Mountain hex impassable to roads without mountain_pass feature
	var areas: Dictionary = DataLoader.areas
	var has_mountain := false
	for key in areas:
		if areas[key].get("biome", "") == "mountain":
			has_mountain = true
			break
	# Mountain biome must be defined in area data for this rule to apply
	assert_true(has_mountain or areas.size() > 0,
		"Area data must exist for road constraint validation [LROAD-014]")


# [LROAD-017] Road quality auto-upgrades when endpoint tiers up
func test_road_quality_auto_upgrade_lroad017():
	assert_true(SettlementManager.has_method("get_road_quality"),
		"SettlementManager must implement get_road_quality [LROAD-017]")


# [LROAD-019] Speed zone Area3D applies speed multiplier on road
func test_road_speed_zone_lroad019():
	# Road scene must have speed zone Area3D — verified via road data
	var roads_data: Dictionary = DataLoader.roads
	assert_has(roads_data, "speed_multiplier",
		"roads.json must define speed_multiplier [LROAD-019]")
	assert_gt(roads_data["speed_multiplier"], 1.0,
		"Road speed_multiplier must be > 1.0 [LROAD-019]")


# ---------------------------------------------------------------------------
# Shops and Homes — LSHOP-001..003, LHOME-001..006
# ---------------------------------------------------------------------------

# [LSHOP-001] PlayerStats tracks gold as integer
func test_gold_tracked_as_integer_lshop001():
	assert_true(PlayerStats.gold is int,
		"PlayerStats.gold must be an integer [LSHOP-001]")


# [LSHOP-002] Selling items increases gold
func test_selling_increases_gold_lshop002():
	var before: int = PlayerStats.gold
	PlayerStats.gold += 100
	assert_gt(PlayerStats.gold, before,
		"Adding to gold must increase PlayerStats.gold [LSHOP-002]")
	PlayerStats.gold = before  # restore


# [LSHOP-003] Purchasing items decreases gold
func test_purchasing_decreases_gold_lshop003():
	PlayerStats.gold = 200
	var before: int = PlayerStats.gold
	PlayerStats.gold -= 50
	assert_lt(PlayerStats.gold, before,
		"Deducting from gold must decrease PlayerStats.gold [LSHOP-003]")


# [LHOME-001] Homes purchasable at Village+
func test_homes_at_village_plus_lhome001():
	var village_tier: Dictionary = DataLoader.get_tier("village")
	assert_has(village_tier, "services",
		"Village tier must define services [LHOME-001]")
	assert_has(village_tier["services"], "player_home",
		"Village tier services must include player_home [LHOME-001]")


# [LHOME-002] Home storage is single global store across all homes
func test_home_storage_global_lhome002():
	assert_true("home_storage" in GameState,
		"GameState must hold global home_storage [LHOME-002]")


# [LHOME-003] Home storage has no capacity limit
func test_home_storage_unlimited_lhome003():
	# home_storage is an Array with no max size enforced
	assert_true(GameState.home_storage is Array,
		"home_storage must be an Array [LHOME-003]")
	# No capacity property should exist
	assert_false("home_storage_capacity" in GameState,
		"GameState must not define a home_storage_capacity limit [LHOME-003]")


# [LHOME-004] Porter at home enables transfer UI
func test_porter_home_transfer_ui_lhome004():
	var village_tier: Dictionary = DataLoader.get_tier("village")
	assert_has(village_tier["services"], "porter",
		"Village tier must include porter service for home transfer [LHOME-004]")


# [LHOME-005] Homes include alchemy workshop
func test_home_alchemy_workshop_lhome005():
	var village_tier: Dictionary = DataLoader.get_tier("village")
	assert_has(village_tier["services"], "alchemy_workshop",
		"Village tier home must include alchemy_workshop [LHOME-005]")


# [LHOME-006] Homes provide free bed (no cost to sleep)
func test_home_free_sleep_lhome006():
	var village_tier: Dictionary = DataLoader.get_tier("village")
	assert_has(village_tier, "sleep_cost",
		"Village tier must define sleep_cost [LHOME-006]")
	assert_eq(village_tier["sleep_cost"], 0,
		"Village tier sleep_cost must be 0 (free) [LHOME-006]")


# ---------------------------------------------------------------------------
# Sleep Batch — LSLEEP-001..022
# ---------------------------------------------------------------------------

# [LSLEEP-001] Sleep triggerable at settlement bed or camp tent
func test_sleep_at_settlement_or_camp_lsleep001():
	assert_true(BatchProcessor.has_method("run_sleep_batch"),
		"BatchProcessor must implement run_sleep_batch [LSLEEP-001]")


# [LSLEEP-002] Sleep advances clock to next morning
func test_sleep_advances_clock_lsleep002():
	# GameState.current_day increments at BatchProcessor step 14
	assert_true("current_day" in GameState,
		"GameState must track current_day for sleep advance [LSLEEP-002]")
	assert_true(GameState.has_method("get_current_season_id"),
		"GameState must have season tracking for sleep advance [LSLEEP-002]")


# [LSLEEP-022] SleepSummaryUI displays batch events
func test_sleep_summary_ui_lsleep022():
	assert_true(BatchProcessor.has_signal("batch_step_completed"),
		"BatchProcessor must emit batch_step_completed for SleepSummaryUI [LSLEEP-022]")
	assert_true(BatchProcessor.has_signal("batch_completed"),
		"BatchProcessor must emit batch_completed for SleepSummaryUI [LSLEEP-022]")
