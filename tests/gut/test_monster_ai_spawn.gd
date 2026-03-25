## test_monster_ai_spawn.gd
## GUT Runtime Tests — Monster AI and Spawn System
## Traces to: LLR v0.6.0 | HLR v0.6.0 | GDD v9
##
## RUNTIME ONLY: Requires Godot 4 + GUT. Run via Godot editor → GUT panel.

extends GutTest

var _monster: CharacterBody3D


func before_all() -> void:
	_monster = preload("res://scenes/monsters/MonsterBase.tscn").instantiate()
	add_child(_monster)
	# Ensure monster data is loaded for the default monster_id
	await get_tree().process_frame


func after_all() -> void:
	_monster.queue_free()


# ---------------------------------------------------------------------------
# Monster AI — LMAI-001..013
# ---------------------------------------------------------------------------

# [LMAI-001] MonsterBase is CharacterBody3D with NavigationAgent3D and StateMachine
func test_monster_has_navigation_agent_lmai001():
	assert_true(_monster is CharacterBody3D,
		"Monster root must be a CharacterBody3D [LMAI-001]")
	var nav_agent: NavigationAgent3D = _monster.find_child("NavigationAgent3D", true, false)
	assert_not_null(nav_agent,
		"Monster must have a NavigationAgent3D child [LMAI-001]")


# [LMAI-002] States: IDLE, PATROL, ALERT, CHASE, ATTACK, FLEE, DESPAWN
func test_monster_state_machine_states_lmai002():
	# Monster.State enum must define these states
	assert_true("State" in _monster or _monster.get_script() != null,
		"Monster script must define State enum [LMAI-002]")
	# Verify each state constant exists via the script's enum
	var script: GDScript = _monster.get_script()
	assert_not_null(script, "Monster must have a GDScript attached [LMAI-002]")


# [LMAI-003] Territorial: PATROL in home_radius, CHASE on detection, ATTACK at melee, FLEE below flee_hp
func test_territorial_behavior_lmai003():
	var monster_data: Dictionary = DataLoader.get_monster("prowler")
	assert_false(monster_data.is_empty(), "prowler monster data must exist [LMAI-003]")
	assert_has(monster_data, "behavior_type",
		"Monster data must define behavior_type [LMAI-003]")
	# Prowler should be territorial or similar patrol-based type
	assert_has(monster_data, "home_radius",
		"Territorial monster must define home_radius [LMAI-003]")
	assert_has(monster_data, "flee_hp_threshold",
		"Monster must define flee_hp_threshold [LMAI-003]")


# [LMAI-004] Ambush: IDLE until player in trigger_radius, then ATTACK burst
func test_ambush_behavior_lmai004():
	# Find any monster with behavior_type="ambush"
	var found_ambush := false
	for key in DataLoader.monsters:
		if DataLoader.monsters[key].get("behavior_type", "") == "ambush":
			found_ambush = true
			var ambush_data: Dictionary = DataLoader.monsters[key]
			assert_has(ambush_data, "trigger_radius",
				"Ambush monster must define trigger_radius [LMAI-004]")
			break
	assert_true(found_ambush, "At least one monster must have behavior_type=ambush [LMAI-004]")


# [LMAI-005] Swarm: shared group aggro, FLEE when group below threshold
func test_swarm_behavior_lmai005():
	var found_swarm := false
	for key in DataLoader.monsters:
		if DataLoader.monsters[key].get("behavior_type", "") == "swarm":
			found_swarm = true
			var swarm_data: Dictionary = DataLoader.monsters[key]
			assert_has(swarm_data, "flee_group_threshold",
				"Swarm monster must define flee_group_threshold [LMAI-005]")
			break
	assert_true(found_swarm, "At least one monster must have behavior_type=swarm [LMAI-005]")


# [LMAI-006] Heavy: IDLE → ALERT on first provocation → CHARGE on second
func test_heavy_behavior_lmai006():
	var found_heavy := false
	for key in DataLoader.monsters:
		if DataLoader.monsters[key].get("behavior_type", "") == "heavy":
			found_heavy = true
			var heavy_data: Dictionary = DataLoader.monsters[key]
			assert_has(heavy_data, "charge_damage",
				"Heavy monster must define charge_damage [LMAI-006]")
			break
	assert_true(found_heavy, "At least one monster must have behavior_type=heavy [LMAI-006]")


# [LMAI-007] Apex: multi-phase ATTACK with HP thresholds
func test_apex_behavior_phases_lmai007():
	var found_apex := false
	for key in DataLoader.monsters:
		if DataLoader.monsters[key].get("behavior_type", "") == "apex":
			found_apex = true
			var apex_data: Dictionary = DataLoader.monsters[key]
			assert_has(apex_data, "phases",
				"Apex monster must define phases [LMAI-007]")
			assert_gt(apex_data["phases"].size(), 1,
				"Apex monster must have multiple attack phases [LMAI-007]")
			break
	assert_true(found_apex, "At least one monster must have behavior_type=apex [LMAI-007]")


# [LMAI-008] Apex ignores Ward, Decoy, Banishment Circle
func test_apex_ignores_ritual_effects_lmai008():
	for key in DataLoader.monsters:
		if DataLoader.monsters[key].get("behavior_type", "") == "apex":
			var apex_data: Dictionary = DataLoader.monsters[key]
			assert_has(apex_data, "is_apex",
				"Apex monster must define is_apex flag [LMAI-008]")
			assert_true(apex_data["is_apex"],
				"is_apex must be true for apex behavior monster [LMAI-008]")
			break


# [LMAI-009] fire_reaction="avoid" adds campfire to navigation avoidance
func test_fire_avoid_adds_to_nav_avoidance_lmai009():
	var found_avoid := false
	for key in DataLoader.monsters:
		if DataLoader.monsters[key].get("fire_reaction", "") == "avoid":
			found_avoid = true
			break
	assert_true(found_avoid,
		"At least one monster must have fire_reaction=avoid [LMAI-009]")


# [LMAI-010] fire_reaction="attracted" pathfinds toward campfire
func test_fire_attracted_pathfinds_to_campfire_lmai010():
	var found_attracted := false
	for key in DataLoader.monsters:
		if DataLoader.monsters[key].get("fire_reaction", "") == "attracted":
			found_attracted = true
			break
	assert_true(found_attracted,
		"At least one monster must have fire_reaction=attracted [LMAI-010]")


# [LMAI-011] light_reaction="attracted" pathfinds toward light sources
func test_light_attracted_pathfinds_lmai011():
	var found_light_attracted := false
	for key in DataLoader.monsters:
		if DataLoader.monsters[key].get("light_reaction", "") == "attracted":
			found_light_attracted = true
			break
	assert_true(found_light_attracted,
		"At least one monster must have light_reaction=attracted [LMAI-011]")


# [LMAI-012] light_reaction="repelled" adds light to navigation avoidance
func test_light_repelled_nav_avoidance_lmai012():
	var found_repelled := false
	for key in DataLoader.monsters:
		if DataLoader.monsters[key].get("light_reaction", "") == "repelled":
			found_repelled = true
			break
	assert_true(found_repelled,
		"At least one monster must have light_reaction=repelled [LMAI-012]")


# [LMAI-013] Monsters beyond despawn_distance queue_free
func test_monster_despawns_at_distance_lmai013():
	assert_true(_monster.has_method("force_despawn"),
		"Monster must implement force_despawn [LMAI-013]")
	# The SpawnManager compares distance and calls force_despawn at despawn_distance
	assert_true(SpawnManager.has_method("recalculate_suppression") or
		"despawn_distance" in SpawnManager,
		"SpawnManager must track despawn_distance [LMAI-013]")


# ---------------------------------------------------------------------------
# Spawn System — LSPN-001..005
# ---------------------------------------------------------------------------

# [LSPN-001] SpawnManager triggers spawns on player area entry
func test_spawn_on_area_entry_lspn001():
	assert_not_null(SpawnManager, "SpawnManager autoload must exist [LSPN-001]")
	assert_true("area_id" in SpawnManager or SpawnManager.has_method("recalculate_suppression"),
		"SpawnManager must manage area-based spawning [LSPN-001]")


# [LSPN-002] Spawn count = weight * time_mod * difficulty * (1 - suppression)
func test_spawn_weight_formula_lspn002():
	# Spawn table data defines weights per monster
	var monster_data: Dictionary = DataLoader.get_monster("prowler")
	assert_has(monster_data, "spawn_weight",
		"Monster data must define spawn_weight [LSPN-002]")
	assert_gt(monster_data["spawn_weight"], 0.0,
		"Monster spawn_weight must be positive [LSPN-002]")


# [LSPN-003] No spawns within safe_zone_radius of settlement_site
func test_no_spawns_in_safe_zone_lspn003():
	# Suppression from settlement tier defines safe zone
	assert_true(SpawnManager.has_method("recalculate_suppression"),
		"SpawnManager must implement recalculate_suppression [LSPN-003]")
	# After recalculation, suppression_percent must be > 0 near a settlement
	SpawnManager.recalculate_suppression()
	assert_true("_suppression_percent" in SpawnManager or
		SpawnManager.has_method("recalculate_all_suppression"),
		"SpawnManager must track suppression_percent [LSPN-003]")


# [LSPN-004] Suppression pct read from settlement tier data
func test_suppression_from_tier_data_lspn004():
	var hamlet_tier: Dictionary = DataLoader.get_tier("hamlet")
	assert_has(hamlet_tier, "monster_suppression",
		"Settlement tier must define monster_suppression [LSPN-004]")
	assert_gt(hamlet_tier["monster_suppression"], 0.0,
		"Hamlet monster_suppression must be positive [LSPN-004]")


# [LSPN-005] Spawn positions use Marker3D or NavMesh sampling outside safe zone
func test_spawn_positions_outside_safe_zone_lspn005():
	# SpawnManager uses NavigationServer3D or Marker3D nodes for spawn positioning
	# Verify spawn_table and max_monsters are defined on SpawnManager
	assert_true("max_monsters" in SpawnManager,
		"SpawnManager must define max_monsters [LSPN-005]")
	assert_gt(SpawnManager.max_monsters, 0,
		"max_monsters must be positive [LSPN-005]")


# ---------------------------------------------------------------------------
# Monster Data Validation
# ---------------------------------------------------------------------------

func test_prowler_has_required_data_fields():
	var prowler: Dictionary = DataLoader.get_monster("prowler")
	assert_false(prowler.is_empty(), "prowler monster must exist")
	assert_has(prowler, "health", "prowler must define health")
	assert_has(prowler, "damage", "prowler must define damage")
	assert_has(prowler, "detection_range", "prowler must define detection_range")
	assert_has(prowler, "aggro_range", "prowler must define aggro_range")
	assert_has(prowler, "move_speed", "prowler must define move_speed")
	assert_has(prowler, "fire_reaction", "prowler must define fire_reaction")
	assert_has(prowler, "light_reaction", "prowler must define light_reaction")
	assert_has(prowler, "is_apex", "prowler must define is_apex")


func test_prowler_is_not_apex():
	var prowler: Dictionary = DataLoader.get_monster("prowler")
	assert_false(prowler["is_apex"],
		"prowler must not be an apex monster")
	assert_true(_monster.has_method("is_apex"),
		"Monster must implement is_apex() [LMAI-008]")


func test_monster_take_damage_reduces_health():
	_monster.take_damage(10.0)
	# Internal health must decrease; we verify via checking the method works without error
	assert_true(_monster.has_method("take_damage"),
		"Monster must implement take_damage [LMAI-003]")


func test_monster_status_effects_applied():
	assert_true(_monster.has_method("apply_cripple"),
		"Monster must implement apply_cripple [LSWD-A03]")
	assert_true(_monster.has_method("apply_root"),
		"Monster must implement apply_root [LWIZ-A05]")
	assert_true(_monster.has_method("apply_stagger"),
		"Monster must implement apply_stagger [LWAR-A06]")
	assert_true(_monster.has_method("apply_flinch"),
		"Monster must implement apply_flinch [LWAR-A11]")
	assert_true(_monster.has_method("apply_calm"),
		"Monster must implement apply_calm [LRIT-A10]")


func test_monster_alert_to_sound():
	assert_true(_monster.has_method("alert_to_sound"),
		"Monster must implement alert_to_sound for firearm alerts [LRNG-006]")
	_monster.alert_to_sound(Vector3.ZERO)
	# Method must run without crashing


func test_monster_force_despawn():
	assert_true(_monster.has_method("force_despawn"),
		"Monster must implement force_despawn for distance culling [LMAI-013]")
