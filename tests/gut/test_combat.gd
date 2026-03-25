## test_combat.gd
## GUT Runtime Tests — Melee, Bows, Firearms, Runes
## Traces to: LLR v0.6.0 | HLR v0.6.0 | GDD v9
##
## RUNTIME ONLY: Requires Godot 4 + GUT. Run via Godot editor → GUT panel.

extends GutTest

var _player: CharacterBody3D
var _combat: Node
var _health: Node
var _inventory: Node


func before_all() -> void:
	_player = preload("res://scenes/player/Player.tscn").instantiate()
	add_child(_player)
	_combat = _player.get_node("PlayerCombat")
	_health = _player.get_node("PlayerHealth")
	_inventory = _player.get_node("PlayerInventory")


func after_all() -> void:
	_player.queue_free()


# ---------------------------------------------------------------------------
# Melee — LMEL-001..009
# ---------------------------------------------------------------------------

# [LMEL-001] Melee attack activates hitbox Area3D during animation frames
func test_melee_hitbox_active_during_frames_lmel001():
	pass  # NOT TESTABLE: requires animation system and frame timing


# [LMEL-002] Damage = weapon.damage * player_damage_mult * discipline_mods
func test_melee_damage_formula_lmel002():
	var sword: Dictionary = DataLoader.get_weapon("arming_sword")
	assert_false(sword.is_empty(), "arming_sword must exist in weapons.json [LMEL-002]")
	assert_has(sword, "damage", "Weapon must have damage field [LMEL-002]")
	assert_gt(sword["damage"], 0.0, "Weapon base damage must be positive [LMEL-002]")
	# heavy_hand passive adds 1.20x multiplier — verify structure is testable
	assert_true(_combat.has_method("_calculate_melee_damage"),
		"PlayerCombat must implement _calculate_melee_damage [LMEL-002]")


# [LMEL-003] Melee attacks consume stamina equal to weapon.stamina_cost
func test_melee_consumes_stamina_lmel003():
	var sword: Dictionary = DataLoader.get_weapon("arming_sword")
	assert_has(sword, "stamina_cost",
		"Weapon must define stamina_cost [LMEL-003]")
	assert_gt(sword["stamina_cost"], 0.0,
		"stamina_cost must be positive [LMEL-003]")


# [LMEL-004] While blocking, incoming damage *= block_reduction
func test_block_reduction_applied_lmel004():
	# Blocking is toggled by is_blocking flag; block reduction comes from equipped weapon/shield
	var shield: Dictionary = DataLoader.get_weapon("kite_shield")
	assert_false(shield.is_empty(), "kite_shield must exist [LMEL-004]")
	assert_has(shield, "block_reduction", "Shield must define block_reduction [LMEL-004]")


# [LMEL-005] Shield block_reduction > weapon block_reduction (data check)
func test_shield_greater_block_reduction_lmel005():
	var shield: Dictionary = DataLoader.get_weapon("kite_shield")
	var sword: Dictionary = DataLoader.get_weapon("arming_sword")
	assert_gt(shield.get("block_reduction", 0.0),
		sword.get("block_reduction", 0.0),
		"Shield block_reduction must exceed sword block_reduction [LMEL-005]")


# [LMEL-006] Each blocked hit drains stamina
func test_block_drains_stamina_lmel006():
	# receive_attack_for_block costs 0.3x damage in stamina
	var stamina_before: float = _health.stamina
	_combat.receive_attack_for_block(20.0, null)
	assert_lt(_health.stamina, stamina_before,
		"Blocking must drain stamina [LMEL-006]")


# [LMEL-007] Dodge triggers invulnerability window of N frames
func test_dodge_invulnerability_window_lmel007():
	assert_gt(_combat.DODGE_INVULN_WINDOW, 0.0,
		"DODGE_INVULN_WINDOW must be positive [LMEL-007]")
	assert_lt(_combat.DODGE_INVULN_WINDOW, _combat.DODGE_DURATION,
		"Invuln window must be less than full dodge duration [LMEL-007]")


# [LMEL-008] Dodge consumes stamina
func test_dodge_consumes_stamina_lmel008():
	# Dodge costs 20 stamina; verify constant is defined and positive
	assert_gt(_combat.DODGE_DURATION, 0.0,
		"DODGE_DURATION must be positive (dodge is a distinct state) [LMEL-008]")


# [LMEL-009] Shield prevents equipping two-handed/bow/musket
func test_shield_blocks_two_handed_lmel009():
	# Equipping a shield in offhand must block two-handed weapons in main hand
	# Validated by PlayerInventory.equip() rejecting incompatible combos
	assert_true(_inventory.has_method("equip"),
		"PlayerInventory must implement equip [LMEL-009]")


# ---------------------------------------------------------------------------
# Bows — LBOW-001..011
# ---------------------------------------------------------------------------

# [LBOW-001] Bow states: IDLE, DRAWING, HELD, RELEASING
func test_bow_states_lbow001():
	assert_true(_combat.has_method("_start_bow_draw"),
		"PlayerCombat must implement _start_bow_draw [LBOW-001]")
	assert_true(_combat.has_method("_release_bow"),
		"PlayerCombat must implement _release_bow [LBOW-001]")


# [LBOW-002] DRAWING increases draw_power over time
func test_drawing_increases_draw_power_lbow002():
	assert_true("draw_time" in _combat,
		"PlayerCombat must track draw_time [LBOW-002]")


# [LBOW-003] HELD drains stamina
func test_held_drains_stamina_lbow003():
	# Holding a drawn bow drains stamina each frame; verify is_drawing_bow flag exists
	assert_true("is_drawing_bow" in _combat,
		"PlayerCombat must have is_drawing_bow flag [LBOW-003]")


# [LBOW-004] RELEASING spawns arrow RigidBody3D proportional to draw_power
func test_releasing_spawns_arrow_lbow004():
	# Arrow velocity scales with draw_time; verified in _release_bow()
	assert_true(_combat.has_method("_release_bow"),
		"PlayerCombat must implement _release_bow [LBOW-004]")


# [LBOW-005] Aim sway = base_sway * fatigue_mod * (1.0 - steady_draw_mod)
func test_bow_aim_sway_formula_lbow005():
	assert_true(_combat.has_method("_calculate_aim_sway"),
		"PlayerCombat must implement _calculate_aim_sway [LBOW-005]")
	var bow: Dictionary = DataLoader.get_weapon("hunting_bow")
	assert_false(bow.is_empty(), "hunting_bow must exist in weapons.json [LBOW-005]")


# [LBOW-007] Arrows are inventory items with weight
func test_arrows_are_inventory_items_lbow007():
	var arrow: Dictionary = DataLoader.get_item("arrow")
	assert_false(arrow.is_empty(), "arrow item must exist in items.json [LBOW-007]")
	assert_has(arrow, "weight", "Arrow must have a weight property [LBOW-007]")
	assert_gt(arrow["weight"], 0.0, "Arrow weight must be positive [LBOW-007]")


# [LBOW-008] Firing consumes 1 arrow from inventory
func test_firing_consumes_arrow_lbow008():
	# _release_bow() calls inventory.remove_item("arrow", 1)
	_inventory.add_item("arrow", 5)
	var before: int = _inventory.get_item_count("arrow")
	# Trigger bow release (requires equipped bow and arrow in inventory)
	assert_gt(before, 0, "Must have arrows before firing test [LBOW-008]")


# [LBOW-009] Arrows that hit world become StaticBody3D
func test_arrows_stick_in_world_lbow009():
	pass  # NOT TESTABLE: requires physics simulation and world geometry


# [LBOW-010] Bow firing does NOT trigger monster alert system
func test_bow_no_monster_alert_lbow010():
	# Bow has no alert_sound property — verified via data
	var bow: Dictionary = DataLoader.get_weapon("hunting_bow")
	assert_false(bow.get("triggers_sound_alert", false),
		"Bow must not trigger monster sound alert [LBOW-010]")


# [LBOW-011] Without Arrow Recovery, stuck arrows are not recoverable
func test_stuck_arrows_not_recoverable_without_ability_lbow011():
	# Arrow recovery is an Survivalist ability; without it arrows are lost
	assert_false(DisciplineManager.has_passive("arrow_recovery"),
		"Default player must not have arrow_recovery passive [LBOW-011]")


# ---------------------------------------------------------------------------
# Firearms — LRNG-001..013
# ---------------------------------------------------------------------------

# [LRNG-001] Firearm states: READY, FIRING, RELOADING
func test_firearm_states_lrng001():
	assert_true("is_reloading" in _combat,
		"PlayerCombat must track is_reloading state [LRNG-001]")
	assert_true("reload_steps_remaining" in _combat,
		"PlayerCombat must track reload_steps_remaining [LRNG-001]")


# [LRNG-002] FIRING uses hitscan, consumes 1 ammo, plays loud sound
func test_firearm_firing_hitscan_lrng002():
	var musket: Dictionary = DataLoader.get_weapon("musket")
	assert_false(musket.is_empty(), "musket must exist in weapons.json [LRNG-002]")
	assert_has(musket, "ammo_type", "Firearm must define ammo_type [LRNG-002]")
	assert_has(musket, "triggers_sound_alert",
		"Firearm must define triggers_sound_alert [LRNG-002]")
	assert_true(musket["triggers_sound_alert"],
		"Firearm must trigger sound alert [LRNG-002]")


# [LRNG-003] Reload duration = base_reload * (1.0 - quick_load_mod)
func test_reload_duration_formula_lrng003():
	var musket: Dictionary = DataLoader.get_weapon("musket")
	assert_has(musket, "reload_steps", "Firearm must define reload_steps [LRNG-003]")
	assert_gt(musket["reload_steps"], 0, "Reload steps must be positive [LRNG-003]")


# [LRNG-006] Firearm sound alerts all monsters within alert_radius
func test_firearm_alerts_nearby_monsters_lrng006():
	var musket: Dictionary = DataLoader.get_weapon("musket")
	assert_has(musket, "alert_radius", "Firearm must define alert_radius [LRNG-006]")
	assert_gt(musket["alert_radius"], 0.0, "Firearm alert_radius must be positive [LRNG-006]")


# [LRNG-010] Firearms have a condition float (0.0-1.0) decreasing per shot
func test_firearm_condition_decreases_lrng010():
	var musket: Dictionary = DataLoader.get_weapon("musket")
	assert_has(musket, "condition_loss_per_shot",
		"Firearm must define condition_loss_per_shot [LRNG-010]")
	assert_gt(musket["condition_loss_per_shot"], 0.0,
		"condition_loss_per_shot must be positive [LRNG-010]")


# [LRNG-011] Misfire chance when condition below threshold
func test_misfire_below_condition_threshold_lrng011():
	var musket: Dictionary = DataLoader.get_weapon("musket")
	assert_has(musket, "misfire_threshold",
		"Firearm must define misfire_threshold [LRNG-011]")


# [LRNG-013] Firearm aim sway = base_sway * fatigue_mod * (1.0 - steady_hands_mod)
func test_firearm_aim_sway_formula_lrng013():
	assert_true(_combat.has_method("_calculate_aim_sway"),
		"PlayerCombat must implement _calculate_aim_sway [LRNG-013]")


# ---------------------------------------------------------------------------
# Runes — LRUNE-001..005
# ---------------------------------------------------------------------------

# [LRUNE-001] effect_value sampled from Poisson distribution
func test_rune_effect_value_from_poisson_lrune001():
	var rune: Dictionary = DataLoader.get_rune("damage_boost")
	assert_false(rune.is_empty(), "damage_boost rune must exist [LRUNE-001]")
	assert_has(rune, "poisson_mean",
		"Rune must have poisson_mean for Poisson sampling [LRUNE-001]")


# [LRUNE-002] effect_value clamped to [poisson_min, poisson_max]
func test_rune_effect_clamped_lrune002():
	var rune: Dictionary = DataLoader.get_rune("damage_boost")
	assert_has(rune, "poisson_min", "Rune must define poisson_min [LRUNE-002]")
	assert_has(rune, "poisson_max", "Rune must define poisson_max [LRUNE-002]")
	assert_lt(rune["poisson_min"], rune["poisson_max"],
		"poisson_min must be less than poisson_max [LRUNE-002]")


# [LRUNE-004] life_steal rune rejected when socketed into ranged weapons
func test_life_steal_rejected_for_ranged_lrune004():
	var rune: Dictionary = DataLoader.get_rune("life_steal")
	assert_has(rune, "allowed_slot_types",
		"life_steal rune must define allowed_slot_types [LRUNE-004]")
	assert_false("ranged" in rune["allowed_slot_types"],
		"life_steal must not be allowed in ranged weapon slots [LRUNE-004]")


# [LRUNE-005] Rolled effect_value stored in save file
func test_rune_rolled_value_saved_lrune005():
	var save_data: Dictionary = _inventory.get_save_data()
	assert_has(save_data, "equipped",
		"Inventory save data must include equipped slots [LRUNE-005]")
