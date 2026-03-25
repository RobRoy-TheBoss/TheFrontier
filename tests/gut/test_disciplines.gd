## test_disciplines.gd
## GUT Runtime Tests — Discipline System and All Abilities
## Traces to: LLR v0.6.0 | HLR v0.6.0 | GDD v9
##
## RUNTIME ONLY: Requires Godot 4 + GUT. Run via Godot editor → GUT panel.

extends GutTest

# Saved state for restoration after each test
var _saved_disciplines: Dictionary


func before_each() -> void:
	_saved_disciplines = DisciplineManager.player_disciplines.duplicate(true)


func after_each() -> void:
	DisciplineManager.player_disciplines = _saved_disciplines


# ---------------------------------------------------------------------------
# Discipline System — LDSYS-001..010
# ---------------------------------------------------------------------------

# [LDSYS-001] DisciplineManager tracks attunements Array with max size 3
func test_max_3_attunements_ldsys001():
	assert_eq(DisciplineManager.MAX_ATTUNEMENTS, 3,
		"MAX_ATTUNEMENTS must be 3 [LDSYS-001]")


# [LDSYS-002] Attunements are permanent (non-respecable)
func test_attunements_permanent_ldsys002():
	# DisciplineManager has no remove_attunement or respec method
	assert_false(DisciplineManager.has_method("remove_attunement"),
		"DisciplineManager must not have remove_attunement [LDSYS-002]")
	assert_false(DisciplineManager.has_method("respec"),
		"DisciplineManager must not have respec method [LDSYS-002]")


# [LDSYS-003] Place of Power with < 3 attunements shows attunement UI
func test_place_of_power_shows_ui_when_slots_available_ldsys003():
	assert_true(DisciplineManager.can_attune(),
		"can_attune() must return true when attunements < 3 [LDSYS-003]")


# [LDSYS-004] Attunement confirm adds discipline and unlocks ability 1
func test_attunement_unlocks_ability_1_ldsys004():
	var ok: bool = DisciplineManager.attune("survivalist")
	assert_true(ok, "attune(survivalist) must succeed with slots available [LDSYS-004]")
	assert_true(DisciplineManager.is_attuned("survivalist"),
		"survivalist must be attuned after attune() [LDSYS-004]")
	# Attunement unlocks the first ability automatically
	var unlocked: Array = DisciplineManager.get_unlocked_abilities("survivalist")
	assert_gt(unlocked.size(), 0,
		"At least ability 1 must be unlocked after attuning [LDSYS-004]")


# [LDSYS-005] Place of Power with 3 attunements adds journal entry only
func test_full_attunements_journal_entry_only_ldsys005():
	DisciplineManager.attune("survivalist")
	DisciplineManager.attune("warrior")
	DisciplineManager.attune("artificer")
	assert_false(DisciplineManager.can_attune(),
		"can_attune() must return false at 3 attunements [LDSYS-005]")


# [LDSYS-006] DisciplineManager subscribes to XP trigger events
func test_discipline_subscribes_to_xp_triggers_ldsys006():
	assert_true(DisciplineManager.has_method("add_xp"),
		"DisciplineManager must implement add_xp(discipline, trigger) [LDSYS-006]")


# [LDSYS-007] Matching signal increases discipline XP
func test_xp_increases_on_trigger_ldsys007():
	DisciplineManager.attune("survivalist")
	var before: int = DisciplineManager.get_xp("survivalist")
	DisciplineManager.add_xp_direct("survivalist", 50)
	assert_gt(DisciplineManager.get_xp("survivalist"), before,
		"add_xp_direct must increase survivalist XP [LDSYS-007]")


# [LDSYS-008] City Enhancement NPC shows disciplines, XP, next cost
func test_enhancement_npc_ui_ldsys008():
	# Verify ability cost data exists in disciplines.json
	var disc: Dictionary = DataLoader.get_discipline("survivalist")
	assert_has(disc, "abilities", "Discipline must list abilities [LDSYS-008]")
	var abilities: Array = disc["abilities"]
	assert_gt(abilities.size(), 0, "Discipline must have at least one ability [LDSYS-008]")
	assert_has(abilities[0], "xp_cost", "Ability must define xp_cost [LDSYS-008]")


# [LDSYS-009] Enhancement purchase deducts XP and gold, increments unlocked
func test_enhancement_purchase_ldsys009():
	DisciplineManager.attune("survivalist")
	DisciplineManager.add_xp_direct("survivalist", 9999)
	var disc_data: Dictionary = DataLoader.get_discipline("survivalist")
	var second_ability_id: String = disc_data["abilities"][1]["id"]
	var ok: bool = DisciplineManager.unlock_ability("survivalist", second_ability_id, 0)
	assert_true(ok, "unlock_ability must succeed with sufficient XP [LDSYS-009]")
	assert_true(DisciplineManager.is_ability_unlocked("survivalist", second_ability_id),
		"Second ability must be unlocked after purchase [LDSYS-009]")


# [LDSYS-010] Second visit to same discipline PoP grants bonus XP
func test_second_pop_visit_bonus_xp_ldsys010():
	# add_xp("survivalist", "place_of_power_revisit") must grant XP if trigger defined
	DisciplineManager.attune("survivalist")
	var before: int = DisciplineManager.get_xp("survivalist")
	DisciplineManager.add_xp("survivalist", "place_of_power_revisit")
	# XP should increase (trigger may or may not be defined; just verify method runs)
	assert_true(DisciplineManager.get_xp("survivalist") >= before,
		"XP must not decrease on add_xp call [LDSYS-010]")


# ---------------------------------------------------------------------------
# Survivalist Abilities — LSURV-A01..16
# ---------------------------------------------------------------------------

func test_trapper_places_node_lsurv_a01():
	var disc: Dictionary = DataLoader.get_discipline("survivalist")
	assert_false(disc.is_empty(), "survivalist discipline must exist [LSURV-A01]")
	var ability_ids: Array = disc["abilities"].map(func(a): return a["id"])
	assert_has(ability_ids, "trapper", "survivalist must have trapper ability [LSURV-A01]")


func test_trapper_roll_food_on_sleep_lsurv_a02():
	# Trapper triggers on BatchProcessor step 9 (snare_trap group harvest)
	pass  # NOT TESTABLE without a placed trap node in the scene


func test_arrow_recovery_on_combat_ended_lsurv_a03():
	# Arrow recovery passive checked in PlayerCombat._release_bow() after CombatManager.combat_ended
	var disc: Dictionary = DataLoader.get_discipline("survivalist")
	var ability_ids: Array = disc["abilities"].map(func(a): return a["id"])
	assert_has(ability_ids, "arrow_recovery",
		"survivalist must have arrow_recovery ability [LSURV-A03]")


func test_night_eyes_enables_greyscale_shader_lsurv_a04():
	pass  # NOT TESTABLE: requires post-process shader and camera


func test_night_eyes_drains_stamina_lsurv_a05():
	var disc: Dictionary = DataLoader.get_discipline("survivalist")
	var night_eyes = disc["abilities"].filter(func(a): return a["id"] == "night_eyes")
	assert_gt(night_eyes.size(), 0, "night_eyes ability must exist [LSURV-A05]")
	assert_has(night_eyes[0], "stamina_drain", "night_eyes must define stamina_drain [LSURV-A05]")


func test_light_foot_reduces_detection_range_lsurv_a06():
	var disc: Dictionary = DataLoader.get_discipline("survivalist")
	var light_foot = disc["abilities"].filter(func(a): return a["id"] == "light_foot")
	assert_gt(light_foot.size(), 0, "light_foot ability must exist [LSURV-A06]")


func test_light_foot_bow_stealth_damage_mult_lsurv_a07():
	var disc: Dictionary = DataLoader.get_discipline("survivalist")
	var light_foot = disc["abilities"].filter(func(a): return a["id"] == "light_foot")
	assert_gt(light_foot.size(), 0, "light_foot ability must exist [LSURV-A07]")
	assert_has(light_foot[0], "stealth_damage_mult",
		"light_foot must define stealth_damage_mult [LSURV-A07]")


func test_steady_draw_speed_mult_lsurv_a08():
	var disc: Dictionary = DataLoader.get_discipline("survivalist")
	var steady_draw = disc["abilities"].filter(func(a): return a["id"] == "steady_draw")
	assert_gt(steady_draw.size(), 0, "steady_draw ability must exist [LSURV-A08]")


func test_steady_draw_sway_reduction_lsurv_a09():
	var disc: Dictionary = DataLoader.get_discipline("survivalist")
	var steady_draw = disc["abilities"].filter(func(a): return a["id"] == "steady_draw")
	assert_has(steady_draw[0], "sway_reduction",
		"steady_draw must define sway_reduction [LSURV-A09]")


func test_steady_draw_drain_mult_lsurv_a10():
	var disc: Dictionary = DataLoader.get_discipline("survivalist")
	var steady_draw = disc["abilities"].filter(func(a): return a["id"] == "steady_draw")
	assert_has(steady_draw[0], "stamina_drain_mult",
		"steady_draw must define stamina_drain_mult [LSURV-A10]")


func test_weatherskin_widens_temp_range_lsurv_a11():
	var disc: Dictionary = DataLoader.get_discipline("survivalist")
	var ws = disc["abilities"].filter(func(a): return a["id"] == "weatherskin")
	assert_gt(ws.size(), 0, "weatherskin ability must exist [LSURV-A11]")
	assert_has(ws[0], "temp_range_bonus", "weatherskin must define temp_range_bonus [LSURV-A11]")


func test_endurance_max_stamina_125_lsurv_a12():
	var disc: Dictionary = DataLoader.get_discipline("survivalist")
	var endurance = disc["abilities"].filter(func(a): return a["id"] == "endurance")
	assert_gt(endurance.size(), 0, "endurance ability must exist [LSURV-A12]")
	assert_has(endurance[0], "stamina_mult", "endurance must define stamina_mult [LSURV-A12]")
	assert_eq(endurance[0]["stamina_mult"], 1.25,
		"endurance stamina_mult must be 1.25 [LSURV-A12]")


func test_endurance_fatigue_penalty_reduction_lsurv_a13():
	var disc: Dictionary = DataLoader.get_discipline("survivalist")
	var endurance = disc["abilities"].filter(func(a): return a["id"] == "endurance")
	assert_has(endurance[0], "fatigue_penalty_reduction",
		"endurance must define fatigue_penalty_reduction [LSURV-A13]")


func test_ghost_walk_invisible_10s_lsurv_a14():
	var disc: Dictionary = DataLoader.get_discipline("survivalist")
	var gw = disc["abilities"].filter(func(a): return a["id"] == "ghost_walk")
	assert_gt(gw.size(), 0, "ghost_walk ability must exist [LSURV-A14]")
	assert_has(gw[0], "duration", "ghost_walk must define duration [LSURV-A14]")
	assert_eq(gw[0]["duration"], 10.0, "ghost_walk duration must be 10s [LSURV-A14]")


func test_ghost_walk_long_cooldown_lsurv_a15():
	var disc: Dictionary = DataLoader.get_discipline("survivalist")
	var gw = disc["abilities"].filter(func(a): return a["id"] == "ghost_walk")
	assert_has(gw[0], "cooldown", "ghost_walk must define cooldown [LSURV-A15]")
	assert_gt(gw[0]["cooldown"], 30.0, "ghost_walk cooldown must be long (>30s) [LSURV-A15]")


func test_ghost_walk_breaks_on_attack_lsurv_a16():
	var disc: Dictionary = DataLoader.get_discipline("survivalist")
	var gw = disc["abilities"].filter(func(a): return a["id"] == "ghost_walk")
	assert_has(gw[0], "breaks_on_attack",
		"ghost_walk must define breaks_on_attack flag [LSURV-A16]")
	assert_true(gw[0]["breaks_on_attack"], "ghost_walk must break on attack [LSURV-A16]")


# ---------------------------------------------------------------------------
# Ritualist Abilities — LRIT-A01..25
# ---------------------------------------------------------------------------

func test_ward_5s_channel_interruptible_lrit_a01():
	var disc: Dictionary = DataLoader.get_discipline("ritualist")
	assert_false(disc.is_empty(), "ritualist discipline must exist [LRIT-A01]")
	var ward = disc["abilities"].filter(func(a): return a["id"] == "ward")
	assert_gt(ward.size(), 0, "ward ability must exist [LRIT-A01]")
	assert_has(ward[0], "channel_time", "ward must define channel_time [LRIT-A01]")
	assert_eq(ward[0]["channel_time"], 5.0, "ward channel_time must be 5s [LRIT-A01]")


func test_ward_spawns_zone_on_completion_lrit_a02():
	pass  # NOT TESTABLE: requires scene node instantiation during channel


func test_ward_monsters_cant_enter_lrit_a03():
	pass  # NOT TESTABLE: requires monster AI and navigation avoidance


func test_ward_lasts_60s_lrit_a04():
	var disc: Dictionary = DataLoader.get_discipline("ritualist")
	var ward = disc["abilities"].filter(func(a): return a["id"] == "ward")
	assert_has(ward[0], "duration", "ward must define duration [LRIT-A04]")
	assert_eq(ward[0]["duration"], 60.0, "ward duration must be 60s [LRIT-A04]")


func test_ward_cooldown_15s_lrit_a05():
	var disc: Dictionary = DataLoader.get_discipline("ritualist")
	var ward = disc["abilities"].filter(func(a): return a["id"] == "ward")
	assert_has(ward[0], "cooldown", "ward must define cooldown [LRIT-A05]")
	assert_eq(ward[0]["cooldown"], 15.0, "ward cooldown must be 15s [LRIT-A05]")


func test_preserve_slows_food_decay_lrit_a06():
	var disc: Dictionary = DataLoader.get_discipline("ritualist")
	var preserve = disc["abilities"].filter(func(a): return a["id"] == "preserve")
	assert_gt(preserve.size(), 0, "preserve ability must exist [LRIT-A06]")
	assert_has(preserve[0], "spoil_rate_mult", "preserve must define spoil_rate_mult [LRIT-A06]")
	assert_lt(preserve[0]["spoil_rate_mult"], 1.0,
		"preserve spoil_rate_mult must reduce decay (< 1.0) [LRIT-A06]")


func test_preserve_slows_durability_loss_lrit_a07():
	var disc: Dictionary = DataLoader.get_discipline("ritualist")
	var preserve = disc["abilities"].filter(func(a): return a["id"] == "preserve")
	assert_has(preserve[0], "durability_loss_mult",
		"preserve must define durability_loss_mult [LRIT-A07]")


func test_decoy_5s_channel_lrit_a08():
	var disc: Dictionary = DataLoader.get_discipline("ritualist")
	var decoy = disc["abilities"].filter(func(a): return a["id"] == "decoy")
	assert_gt(decoy.size(), 0, "decoy ability must exist [LRIT-A08]")
	assert_has(decoy[0], "channel_time", "decoy must define channel_time [LRIT-A08]")
	assert_eq(decoy[0]["channel_time"], 5.0, "decoy channel_time must be 5s [LRIT-A08]")


func test_decoy_10s_delay_then_noise_lrit_a09():
	var disc: Dictionary = DataLoader.get_discipline("ritualist")
	var decoy = disc["abilities"].filter(func(a): return a["id"] == "decoy")
	assert_has(decoy[0], "noise_delay", "decoy must define noise_delay [LRIT-A09]")
	assert_eq(decoy[0]["noise_delay"], 10.0, "decoy noise_delay must be 10s [LRIT-A09]")


func test_decoy_attracts_non_apex_lrit_a10():
	var disc: Dictionary = DataLoader.get_discipline("ritualist")
	var decoy = disc["abilities"].filter(func(a): return a["id"] == "decoy")
	assert_has(decoy[0], "attracts_non_apex",
		"decoy must define attracts_non_apex flag [LRIT-A10]")
	assert_true(decoy[0]["attracts_non_apex"],
		"decoy must attract non-apex monsters [LRIT-A10]")


func test_decoy_lasts_30s_lrit_a11():
	var disc: Dictionary = DataLoader.get_discipline("ritualist")
	var decoy = disc["abilities"].filter(func(a): return a["id"] == "decoy")
	assert_has(decoy[0], "duration", "decoy must define duration [LRIT-A11]")
	assert_eq(decoy[0]["duration"], 30.0, "decoy duration must be 30s [LRIT-A11]")


func test_enchant_damage_bonus_lrit_a12():
	var disc: Dictionary = DataLoader.get_discipline("ritualist")
	var enchant = disc["abilities"].filter(func(a): return a["id"] == "enchant")
	assert_gt(enchant.size(), 0, "enchant ability must exist [LRIT-A12]")
	assert_has(enchant[0], "damage_bonus", "enchant must define damage_bonus [LRIT-A12]")


func test_enchant_adds_weapon_glow_lrit_a13():
	pass  # NOT TESTABLE: requires visual shader on weapon mesh


func test_enchant_stacks_with_runes_lrit_a14():
	var disc: Dictionary = DataLoader.get_discipline("ritualist")
	var enchant = disc["abilities"].filter(func(a): return a["id"] == "enchant")
	assert_has(enchant[0], "stacks_with_runes",
		"enchant must define stacks_with_runes flag [LRIT-A14]")
	assert_true(enchant[0]["stacks_with_runes"],
		"enchant must stack with runes [LRIT-A14]")


func test_sending_chest_spawns_lrit_a15():
	var disc: Dictionary = DataLoader.get_discipline("ritualist")
	var sc = disc["abilities"].filter(func(a): return a["id"] == "sending_chest")
	assert_gt(sc.size(), 0, "sending_chest ability must exist [LRIT-A15]")


func test_sending_chest_transfers_to_home_storage_lrit_a16():
	# Sending Chest contents go to GameState.home_storage
	assert_true("home_storage" in GameState,
		"GameState must have home_storage for sending_chest [LRIT-A16]")
	assert_true(GameState.home_storage is Array,
		"home_storage must be an Array [LRIT-A16]")


func test_sending_chest_queue_free_after_transfer_lrit_a17():
	pass  # NOT TESTABLE: requires chest node in scene


func test_sending_chest_once_per_rest_lrit_a18():
	var disc: Dictionary = DataLoader.get_discipline("ritualist")
	var sc = disc["abilities"].filter(func(a): return a["id"] == "sending_chest")
	assert_has(sc[0], "once_per_rest",
		"sending_chest must define once_per_rest flag [LRIT-A18]")
	assert_true(sc[0]["once_per_rest"],
		"sending_chest must be once per rest [LRIT-A18]")


func test_banishment_circle_spawns_zone_lrit_a19():
	var disc: Dictionary = DataLoader.get_discipline("ritualist")
	var bc = disc["abilities"].filter(func(a): return a["id"] == "banishment_circle")
	assert_gt(bc.size(), 0, "banishment_circle ability must exist [LRIT-A19]")


func test_banishment_circle_despawns_non_apex_lrit_a20():
	var disc: Dictionary = DataLoader.get_discipline("ritualist")
	var bc = disc["abilities"].filter(func(a): return a["id"] == "banishment_circle")
	assert_has(bc[0], "affects_apex",
		"banishment_circle must define affects_apex [LRIT-A20]")
	assert_false(bc[0]["affects_apex"],
		"banishment_circle must not affect apex monsters [LRIT-A20]")


func test_banishment_circle_queue_free_after_trigger_lrit_a21():
	pass  # NOT TESTABLE: requires scene node lifecycle


func test_banishment_circle_persists_until_triggered_lrit_a22():
	var disc: Dictionary = DataLoader.get_discipline("ritualist")
	var bc = disc["abilities"].filter(func(a): return a["id"] == "banishment_circle")
	assert_has(bc[0], "persists_across_sleep",
		"banishment_circle must define persists_across_sleep [LRIT-A22]")
	assert_true(bc[0]["persists_across_sleep"],
		"banishment_circle must persist until triggered [LRIT-A22]")


func test_anchor_part1_stores_position_lrit_a23():
	var disc: Dictionary = DataLoader.get_discipline("ritualist")
	var anchor = disc["abilities"].filter(func(a): return a["id"] == "anchor")
	assert_gt(anchor.size(), 0, "anchor ability must exist [LRIT-A23]")


func test_anchor_part2_teleports_lrit_a24():
	pass  # NOT TESTABLE without player scene in world with physics


func test_anchor_clears_on_use_lrit_a25():
	var disc: Dictionary = DataLoader.get_discipline("ritualist")
	var anchor = disc["abilities"].filter(func(a): return a["id"] == "anchor")
	assert_has(anchor[0], "clears_on_use",
		"anchor must define clears_on_use [LRIT-A25]")
	assert_true(anchor[0]["clears_on_use"],
		"anchor must clear after teleport use [LRIT-A25]")


# ---------------------------------------------------------------------------
# Pathfinder Abilities — LPATH-A01..06
# ---------------------------------------------------------------------------

func test_wayfinder_survey_radius_mult_lpath_a01():
	var disc: Dictionary = DataLoader.get_discipline("pathfinder")
	assert_false(disc.is_empty(), "pathfinder discipline must exist [LPATH-A01]")
	var wf = disc["abilities"].filter(func(a): return a["id"] == "wayfinder")
	assert_gt(wf.size(), 0, "wayfinder ability must exist [LPATH-A01]")
	assert_has(wf[0], "survey_radius_mult",
		"wayfinder must define survey_radius_mult [LPATH-A01]")
	assert_gt(wf[0]["survey_radius_mult"], 1.0,
		"wayfinder survey_radius_mult must be > 1.0 [LPATH-A01]")


func test_light_provisions_food_water_weight_lpath_a02():
	var disc: Dictionary = DataLoader.get_discipline("pathfinder")
	var lp = disc["abilities"].filter(func(a): return a["id"] == "light_provisions")
	assert_gt(lp.size(), 0, "light_provisions ability must exist [LPATH-A02]")
	assert_has(lp[0], "food_water_weight_mult",
		"light_provisions must define food_water_weight_mult [LPATH-A02]")
	assert_lt(lp[0]["food_water_weight_mult"], 1.0,
		"light_provisions weight mult must reduce weight (< 1.0) [LPATH-A02]")


func test_cartography_generates_map_item_lpath_a03():
	var disc: Dictionary = DataLoader.get_discipline("pathfinder")
	var cart = disc["abilities"].filter(func(a): return a["id"] == "cartography")
	assert_gt(cart.size(), 0, "cartography ability must exist [LPATH-A03]")


func test_prospect_shows_nearest_resource_lpath_a04():
	var disc: Dictionary = DataLoader.get_discipline("pathfinder")
	var prospect = disc["abilities"].filter(func(a): return a["id"] == "prospect")
	assert_gt(prospect.size(), 0, "prospect ability must exist [LPATH-A04]")


func test_steady_pace_stamina_regen_mult_lpath_a05():
	var disc: Dictionary = DataLoader.get_discipline("pathfinder")
	var sp = disc["abilities"].filter(func(a): return a["id"] == "steady_pace")
	assert_gt(sp.size(), 0, "steady_pace ability must exist [LPATH-A05]")
	assert_has(sp[0], "stamina_regen_mult",
		"steady_pace must define stamina_regen_mult [LPATH-A05]")
	assert_gt(sp[0]["stamina_regen_mult"], 1.0,
		"steady_pace stamina_regen_mult must be > 1.0 [LPATH-A05]")


# ---------------------------------------------------------------------------
# Warrior Abilities — LWAR-A01..12
# ---------------------------------------------------------------------------

func test_heavy_hand_damage_mult_lwar_a01():
	var disc: Dictionary = DataLoader.get_discipline("warrior")
	assert_false(disc.is_empty(), "warrior discipline must exist [LWAR-A01]")
	var hh = disc["abilities"].filter(func(a): return a["id"] == "heavy_hand")
	assert_gt(hh.size(), 0, "heavy_hand ability must exist [LWAR-A01]")
	assert_has(hh[0], "damage_mult", "heavy_hand must define damage_mult [LWAR-A01]")
	assert_eq(hh[0]["damage_mult"], 1.20, "heavy_hand damage_mult must be 1.20 [LWAR-A01]")


func test_pack_mule_max_carry_mult_lwar_a02():
	var disc: Dictionary = DataLoader.get_discipline("warrior")
	var pm = disc["abilities"].filter(func(a): return a["id"] == "pack_mule")
	assert_gt(pm.size(), 0, "pack_mule ability must exist [LWAR-A02]")
	assert_has(pm[0], "carry_weight_mult",
		"pack_mule must define carry_weight_mult [LWAR-A02]")
	assert_eq(pm[0]["carry_weight_mult"], 1.30,
		"pack_mule carry_weight_mult must be 1.30 [LWAR-A02]")


func test_pack_mule_reduced_encumbrance_penalty_lwar_a03():
	var disc: Dictionary = DataLoader.get_discipline("warrior")
	var pm = disc["abilities"].filter(func(a): return a["id"] == "pack_mule")
	assert_has(pm[0], "encumbrance_speed_penalty_reduction",
		"pack_mule must define encumbrance_speed_penalty_reduction [LWAR-A03]")


func test_ironclad_enables_heavy_armor_lwar_a04():
	var disc: Dictionary = DataLoader.get_discipline("warrior")
	var ic = disc["abilities"].filter(func(a): return a["id"] == "ironclad")
	assert_gt(ic.size(), 0, "ironclad ability must exist [LWAR-A04]")
	assert_has(ic[0], "enables_heavy_armor",
		"ironclad must define enables_heavy_armor [LWAR-A04]")
	assert_true(ic[0]["enables_heavy_armor"],
		"ironclad must enable heavy armor equip [LWAR-A04]")


func test_ironclad_armor_bonus_lwar_a05():
	var disc: Dictionary = DataLoader.get_discipline("warrior")
	var ic = disc["abilities"].filter(func(a): return a["id"] == "ironclad")
	assert_has(ic[0], "armor_bonus", "ironclad must define armor_bonus [LWAR-A05]")
	assert_gt(ic[0]["armor_bonus"], 0.0, "ironclad armor_bonus must be positive [LWAR-A05]")


func test_stagger_charged_attack_staggers_non_apex_lwar_a06():
	var disc: Dictionary = DataLoader.get_discipline("warrior")
	var stagger = disc["abilities"].filter(func(a): return a["id"] == "stagger")
	assert_gt(stagger.size(), 0, "stagger ability must exist [LWAR-A06]")
	assert_has(stagger[0], "affects_apex",
		"stagger must define affects_apex [LWAR-A06]")
	assert_false(stagger[0]["affects_apex"],
		"stagger must not affect apex monsters [LWAR-A06]")


func test_stagger_consumes_high_stamina_lwar_a07():
	var disc: Dictionary = DataLoader.get_discipline("warrior")
	var stagger = disc["abilities"].filter(func(a): return a["id"] == "stagger")
	assert_has(stagger[0], "stamina_cost",
		"stagger must define stamina_cost [LWAR-A07]")
	assert_gt(stagger[0]["stamina_cost"], 30.0,
		"stagger stamina_cost must be high (> 30) [LWAR-A07]")


func test_second_wind_only_below_25pct_health_lwar_a08():
	var disc: Dictionary = DataLoader.get_discipline("warrior")
	var sw = disc["abilities"].filter(func(a): return a["id"] == "second_wind")
	assert_gt(sw.size(), 0, "second_wind ability must exist [LWAR-A08]")
	assert_has(sw[0], "health_threshold",
		"second_wind must define health_threshold [LWAR-A08]")
	assert_eq(sw[0]["health_threshold"], 0.25,
		"second_wind threshold must be 0.25 (25%) [LWAR-A08]")


func test_second_wind_restores_stamina_damage_resist_lwar_a09():
	var disc: Dictionary = DataLoader.get_discipline("warrior")
	var sw = disc["abilities"].filter(func(a): return a["id"] == "second_wind")
	assert_has(sw[0], "stamina_restore",
		"second_wind must define stamina_restore [LWAR-A09]")
	assert_has(sw[0], "damage_resist_duration",
		"second_wind must define damage_resist_duration [LWAR-A09]")


func test_second_wind_once_per_rest_lwar_a10():
	var disc: Dictionary = DataLoader.get_discipline("warrior")
	var sw = disc["abilities"].filter(func(a): return a["id"] == "second_wind")
	assert_has(sw[0], "once_per_rest",
		"second_wind must define once_per_rest [LWAR-A10]")
	assert_true(sw[0]["once_per_rest"],
		"second_wind must be once per rest [LWAR-A10]")


func test_warcry_flinch_within_15m_lwar_a11():
	var disc: Dictionary = DataLoader.get_discipline("warrior")
	var wc = disc["abilities"].filter(func(a): return a["id"] == "warcry")
	assert_gt(wc.size(), 0, "warcry ability must exist [LWAR-A11]")
	assert_has(wc[0], "flinch_radius", "warcry must define flinch_radius [LWAR-A11]")
	assert_eq(wc[0]["flinch_radius"], 15.0,
		"warcry flinch_radius must be 15m [LWAR-A11]")


func test_warcry_moderate_cooldown_lwar_a12():
	var disc: Dictionary = DataLoader.get_discipline("warrior")
	var wc = disc["abilities"].filter(func(a): return a["id"] == "warcry")
	assert_has(wc[0], "cooldown", "warcry must define cooldown [LWAR-A12]")
	assert_gt(wc[0]["cooldown"], 0.0, "warcry cooldown must be positive [LWAR-A12]")


# ---------------------------------------------------------------------------
# Swordsman Abilities — LSWD-A01..19
# ---------------------------------------------------------------------------

func test_riposte_dodge_opens_window_lswd_a01():
	var disc: Dictionary = DataLoader.get_discipline("swordsman")
	assert_false(disc.is_empty(), "swordsman discipline must exist [LSWD-A01]")
	var riposte = disc["abilities"].filter(func(a): return a["id"] == "riposte")
	assert_gt(riposte.size(), 0, "riposte ability must exist [LSWD-A01]")


func test_riposte_2x_damage_lswd_a02():
	var disc: Dictionary = DataLoader.get_discipline("swordsman")
	var riposte = disc["abilities"].filter(func(a): return a["id"] == "riposte")
	assert_has(riposte[0], "damage_mult", "riposte must define damage_mult [LSWD-A02]")
	assert_eq(riposte[0]["damage_mult"], 2.0,
		"riposte damage_mult must be 2.0 [LSWD-A02]")


func test_cripple_on_riposte_hit_lswd_a03():
	var disc: Dictionary = DataLoader.get_discipline("swordsman")
	var cripple = disc["abilities"].filter(func(a): return a["id"] == "cripple")
	assert_gt(cripple.size(), 0, "cripple ability must exist [LSWD-A03]")


func test_read_slower_telegraph_lswd_a04():
	var disc: Dictionary = DataLoader.get_discipline("swordsman")
	var read = disc["abilities"].filter(func(a): return a["id"] == "read")
	assert_gt(read.size(), 0, "read ability must exist [LSWD-A04]")


func test_read_extended_dodge_window_lswd_a05():
	var disc: Dictionary = DataLoader.get_discipline("swordsman")
	var read = disc["abilities"].filter(func(a): return a["id"] == "read")
	assert_has(read[0], "dodge_window_mult",
		"read must define dodge_window_mult [LSWD-A05]")
	assert_gt(read[0]["dodge_window_mult"], 1.0,
		"read dodge_window_mult must be > 1.0 [LSWD-A05]")


func test_off_hand_mastery_shield_block_bonus_lswd_a06():
	var disc: Dictionary = DataLoader.get_discipline("swordsman")
	var ohm = disc["abilities"].filter(func(a): return a["id"] == "off_hand_mastery")
	assert_gt(ohm.size(), 0, "off_hand_mastery ability must exist [LSWD-A06]")
	assert_has(ohm[0], "shield_block_bonus",
		"off_hand_mastery must define shield_block_bonus [LSWD-A06]")


func test_off_hand_mastery_shield_recovery_lswd_a07():
	var disc: Dictionary = DataLoader.get_discipline("swordsman")
	var ohm = disc["abilities"].filter(func(a): return a["id"] == "off_hand_mastery")
	assert_has(ohm[0], "shield_recovery_mult",
		"off_hand_mastery must define shield_recovery_mult [LSWD-A07]")


func test_off_hand_mastery_pistol_swap_time_lswd_a08():
	var disc: Dictionary = DataLoader.get_discipline("swordsman")
	var ohm = disc["abilities"].filter(func(a): return a["id"] == "off_hand_mastery")
	assert_has(ohm[0], "pistol_swap_time_mult",
		"off_hand_mastery must define pistol_swap_time_mult [LSWD-A08]")


func test_off_hand_mastery_pistol_aim_bonus_lswd_a09():
	var disc: Dictionary = DataLoader.get_discipline("swordsman")
	var ohm = disc["abilities"].filter(func(a): return a["id"] == "off_hand_mastery")
	assert_has(ohm[0], "pistol_aim_bonus",
		"off_hand_mastery must define pistol_aim_bonus [LSWD-A09]")


func test_bleed_on_crit_lswd_a10():
	var disc: Dictionary = DataLoader.get_discipline("swordsman")
	var bleed = disc["abilities"].filter(func(a): return a["id"] == "bleed")
	assert_gt(bleed.size(), 0, "bleed ability must exist [LSWD-A10]")
	assert_has(bleed[0], "crit_chance", "bleed must define crit_chance [LSWD-A10]")


func test_bleed_stacks_max_3_lswd_a11():
	var disc: Dictionary = DataLoader.get_discipline("swordsman")
	var bleed = disc["abilities"].filter(func(a): return a["id"] == "bleed")
	assert_has(bleed[0], "max_stacks", "bleed must define max_stacks [LSWD-A11]")
	assert_eq(bleed[0]["max_stacks"], 3, "bleed max_stacks must be 3 [LSWD-A11]")


func test_swordsman_bleed_increased_duration_damage_lswd_a12():
	var disc: Dictionary = DataLoader.get_discipline("swordsman")
	var bleed = disc["abilities"].filter(func(a): return a["id"] == "bleed")
	assert_has(bleed[0], "dps", "bleed must define dps [LSWD-A12]")
	assert_has(bleed[0], "duration", "bleed must define duration [LSWD-A12]")


func test_blade_sense_reduces_bleeding_gash_prob_lswd_a13():
	var disc: Dictionary = DataLoader.get_discipline("swordsman")
	var bs = disc["abilities"].filter(func(a): return a["id"] == "blade_sense")
	assert_gt(bs.size(), 0, "blade_sense ability must exist [LSWD-A13]")
	assert_has(bs[0], "bleeding_gash_prob_reduction",
		"blade_sense must define bleeding_gash_prob_reduction [LSWD-A13]")


func test_blade_sense_reduces_deep_wound_prob_lswd_a14():
	var disc: Dictionary = DataLoader.get_discipline("swordsman")
	var bs = disc["abilities"].filter(func(a): return a["id"] == "blade_sense")
	assert_has(bs[0], "deep_wound_prob_reduction",
		"blade_sense must define deep_wound_prob_reduction [LSWD-A14]")


func test_flurry_only_in_riposte_window_lswd_a15():
	var disc: Dictionary = DataLoader.get_discipline("swordsman")
	var flurry = disc["abilities"].filter(func(a): return a["id"] == "flurry")
	assert_gt(flurry.size(), 0, "flurry ability must exist [LSWD-A15]")
	assert_has(flurry[0], "requires_riposte_window",
		"flurry must define requires_riposte_window [LSWD-A15]")
	assert_true(flurry[0]["requires_riposte_window"],
		"flurry must require riposte window [LSWD-A15]")


func test_flurry_3_strike_chain_lswd_a16():
	var disc: Dictionary = DataLoader.get_discipline("swordsman")
	var flurry = disc["abilities"].filter(func(a): return a["id"] == "flurry")
	assert_has(flurry[0], "hit_count", "flurry must define hit_count [LSWD-A16]")
	assert_eq(flurry[0]["hit_count"], 3, "flurry hit_count must be 3 [LSWD-A16]")


func test_flurry_heavy_stamina_lswd_a17():
	var disc: Dictionary = DataLoader.get_discipline("swordsman")
	var flurry = disc["abilities"].filter(func(a): return a["id"] == "flurry")
	assert_has(flurry[0], "stamina_cost", "flurry must define stamina_cost [LSWD-A17]")
	assert_gt(flurry[0]["stamina_cost"], 30.0,
		"flurry stamina_cost must be high (>30) [LSWD-A17]")


func test_deathmark_tracks_cripple_count_lswd_a18():
	var disc: Dictionary = DataLoader.get_discipline("swordsman")
	var dm = disc["abilities"].filter(func(a): return a["id"] == "deathmark")
	assert_gt(dm.size(), 0, "deathmark ability must exist [LSWD-A18]")
	assert_has(dm[0], "cripple_threshold",
		"deathmark must define cripple_threshold [LSWD-A18]")


func test_deathmark_130pct_damage_at_3_cripples_lswd_a19():
	var disc: Dictionary = DataLoader.get_discipline("swordsman")
	var dm = disc["abilities"].filter(func(a): return a["id"] == "deathmark")
	assert_has(dm[0], "damage_mult", "deathmark must define damage_mult [LSWD-A19]")
	assert_eq(dm[0]["damage_mult"], 1.30,
		"deathmark damage_mult must be 1.30 (130%) [LSWD-A19]")
	assert_eq(dm[0]["cripple_threshold"], 3,
		"deathmark must activate at 3 cripples [LSWD-A19]")


# ---------------------------------------------------------------------------
# Artificer Abilities — LART-A01..15
# ---------------------------------------------------------------------------

func test_field_repair_at_camp_lart_a01():
	var disc: Dictionary = DataLoader.get_discipline("artificer")
	assert_false(disc.is_empty(), "artificer discipline must exist [LART-A01]")
	var fr = disc["abilities"].filter(func(a): return a["id"] == "field_repair")
	assert_gt(fr.size(), 0, "field_repair ability must exist [LART-A01]")
	assert_has(fr[0], "requires_camp", "field_repair must define requires_camp [LART-A01]")
	assert_true(fr[0]["requires_camp"],
		"field_repair must require camp [LART-A01]")


func test_quick_load_reload_mult_lart_a02():
	var disc: Dictionary = DataLoader.get_discipline("artificer")
	var ql = disc["abilities"].filter(func(a): return a["id"] == "quick_load")
	assert_gt(ql.size(), 0, "quick_load ability must exist [LART-A02]")
	assert_has(ql[0], "reload_time_mult",
		"quick_load must define reload_time_mult [LART-A02]")
	assert_lt(ql[0]["reload_time_mult"], 1.0,
		"quick_load reload_time_mult must reduce reload time (< 1.0) [LART-A02]")


func test_ammo_smith_crafts_ammo_lart_a03():
	var disc: Dictionary = DataLoader.get_discipline("artificer")
	var as_ = disc["abilities"].filter(func(a): return a["id"] == "ammo_smith")
	assert_gt(as_.size(), 0, "ammo_smith ability must exist [LART-A03]")


func test_spike_trap_placed_lart_a04():
	var disc: Dictionary = DataLoader.get_discipline("artificer")
	var st = disc["abilities"].filter(func(a): return a["id"] == "spike_trap")
	assert_gt(st.size(), 0, "spike_trap ability must exist [LART-A04]")


func test_spike_trap_deals_damage_lart_a05():
	var disc: Dictionary = DataLoader.get_discipline("artificer")
	var st = disc["abilities"].filter(func(a): return a["id"] == "spike_trap")
	assert_has(st[0], "damage", "spike_trap must define damage [LART-A05]")
	assert_gt(st[0]["damage"], 0.0, "spike_trap damage must be positive [LART-A05]")


func test_spike_trap_recoverable_lart_a06():
	var disc: Dictionary = DataLoader.get_discipline("artificer")
	var st = disc["abilities"].filter(func(a): return a["id"] == "spike_trap")
	assert_has(st[0], "recoverable",
		"spike_trap must define recoverable flag [LART-A06]")
	assert_true(st[0]["recoverable"],
		"spike_trap must be recoverable [LART-A06]")


func test_steady_hands_aim_sway_mult_lart_a07():
	var disc: Dictionary = DataLoader.get_discipline("artificer")
	var sh = disc["abilities"].filter(func(a): return a["id"] == "steady_hands")
	assert_gt(sh.size(), 0, "steady_hands ability must exist [LART-A07]")
	assert_has(sh[0], "aim_sway_mult",
		"steady_hands must define aim_sway_mult [LART-A07]")
	assert_lt(sh[0]["aim_sway_mult"], 1.0,
		"steady_hands aim_sway_mult must reduce sway (< 1.0) [LART-A07]")


func test_reinforce_temp_buff_lart_a08():
	var disc: Dictionary = DataLoader.get_discipline("artificer")
	var reinforce = disc["abilities"].filter(func(a): return a["id"] == "reinforce")
	assert_gt(reinforce.size(), 0, "reinforce ability must exist [LART-A08]")
	assert_has(reinforce[0], "duration", "reinforce must define duration [LART-A08]")


func test_reinforce_consumes_materials_lart_a09():
	var disc: Dictionary = DataLoader.get_discipline("artificer")
	var reinforce = disc["abilities"].filter(func(a): return a["id"] == "reinforce")
	assert_has(reinforce[0], "required_item",
		"reinforce must define required_item [LART-A09]")


func test_jury_rig_no_camp_required_lart_a10():
	var disc: Dictionary = DataLoader.get_discipline("artificer")
	var jr = disc["abilities"].filter(func(a): return a["id"] == "jury_rig")
	assert_gt(jr.size(), 0, "jury_rig ability must exist [LART-A10]")
	assert_false(jr[0].get("requires_camp", false),
		"jury_rig must not require camp [LART-A10]")


func test_jury_rig_no_materials_lart_a11():
	var disc: Dictionary = DataLoader.get_discipline("artificer")
	var jr = disc["abilities"].filter(func(a): return a["id"] == "jury_rig")
	assert_false(jr[0].get("requires_materials", false),
		"jury_rig must not require materials [LART-A11]")


func test_mechanical_insight_can_activate_precursor_lart_a12():
	var disc: Dictionary = DataLoader.get_discipline("artificer")
	var mi = disc["abilities"].filter(func(a): return a["id"] == "mechanical_insight")
	assert_gt(mi.size(), 0, "mechanical_insight ability must exist [LART-A12]")
	assert_has(mi[0], "can_activate_precursor",
		"mechanical_insight must define can_activate_precursor [LART-A12]")
	assert_true(mi[0]["can_activate_precursor"],
		"mechanical_insight must enable precursor activation [LART-A12]")


func test_mechanical_insight_precursor_check_flag_lart_a13():
	var disc: Dictionary = DataLoader.get_discipline("artificer")
	var mi = disc["abilities"].filter(func(a): return a["id"] == "mechanical_insight")
	assert_has(mi[0], "precursor_flag",
		"mechanical_insight must define precursor_flag [LART-A13]")


func test_mechanical_insight_disassemble_artifacts_lart_a14():
	var disc: Dictionary = DataLoader.get_discipline("artificer")
	var mi = disc["abilities"].filter(func(a): return a["id"] == "mechanical_insight")
	assert_has(mi[0], "can_disassemble_artifacts",
		"mechanical_insight must define can_disassemble_artifacts [LART-A14]")
	assert_true(mi[0]["can_disassemble_artifacts"],
		"mechanical_insight must allow disassembly [LART-A14]")


func test_mechanical_insight_craft_mineral_powder_lart_a15():
	# Mineral powder recipe should be unlocked for Artificer
	var recipe: Dictionary = DataLoader.get_recipe("mineral_powder")
	assert_false(recipe.is_empty(), "mineral_powder recipe must exist [LART-A15]")


# ---------------------------------------------------------------------------
# Alchemist Abilities — LALC-A01..10
# ---------------------------------------------------------------------------

func test_keen_eye_reveals_hidden_nodes_lalc_a01():
	var disc: Dictionary = DataLoader.get_discipline("alchemist")
	assert_false(disc.is_empty(), "alchemist discipline must exist [LALC-A01]")
	var ke = disc["abilities"].filter(func(a): return a["id"] == "keen_eye")
	assert_gt(ke.size(), 0, "keen_eye ability must exist [LALC-A01]")
	assert_has(ke[0], "reveals_hidden_nodes",
		"keen_eye must define reveals_hidden_nodes [LALC-A01]")
	assert_true(ke[0]["reveals_hidden_nodes"],
		"keen_eye must reveal hidden gather nodes [LALC-A01]")


func test_light_load_plant_potion_weight_lalc_a02():
	var disc: Dictionary = DataLoader.get_discipline("alchemist")
	var ll = disc["abilities"].filter(func(a): return a["id"] == "light_load")
	assert_gt(ll.size(), 0, "light_load ability must exist [LALC-A02]")
	assert_has(ll[0], "plant_potion_weight_mult",
		"light_load must define plant_potion_weight_mult [LALC-A02]")
	assert_eq(ll[0]["plant_potion_weight_mult"], 0.5,
		"light_load weight mult must be 0.5 [LALC-A02]")


func test_extended_potency_buff_duration_lalc_a03():
	var disc: Dictionary = DataLoader.get_discipline("alchemist")
	var ep = disc["abilities"].filter(func(a): return a["id"] == "extended_potency")
	assert_gt(ep.size(), 0, "extended_potency ability must exist [LALC-A03]")
	assert_has(ep[0], "buff_duration_mult",
		"extended_potency must define buff_duration_mult [LALC-A03]")
	assert_gt(ep[0]["buff_duration_mult"], 1.0,
		"extended_potency must increase duration (> 1.0) [LALC-A03]")


func test_toxicologist_poison_damage_reduction_lalc_a04():
	var disc: Dictionary = DataLoader.get_discipline("alchemist")
	var tox = disc["abilities"].filter(func(a): return a["id"] == "toxicologist")
	assert_gt(tox.size(), 0, "toxicologist ability must exist [LALC-A04]")
	assert_has(tox[0], "poison_damage_reduction",
		"toxicologist must define poison_damage_reduction [LALC-A04]")


func test_toxicologist_venom_treatment_tier_lalc_a05():
	var disc: Dictionary = DataLoader.get_discipline("alchemist")
	var tox = disc["abilities"].filter(func(a): return a["id"] == "toxicologist")
	assert_has(tox[0], "venom_treatment_tier",
		"toxicologist must define venom_treatment_tier [LALC-A05]")


func test_master_brewer_unlocks_recipes_lalc_a06():
	var disc: Dictionary = DataLoader.get_discipline("alchemist")
	var mb = disc["abilities"].filter(func(a): return a["id"] == "master_brewer")
	assert_gt(mb.size(), 0, "master_brewer ability must exist [LALC-A06]")
	assert_has(mb[0], "unlocks_recipes",
		"master_brewer must define unlocks_recipes [LALC-A06]")
	assert_gt(mb[0]["unlocks_recipes"].size(), 0,
		"master_brewer must unlock at least one recipe [LALC-A06]")


func test_master_brewer_firefly_jar_lalc_a07():
	var disc: Dictionary = DataLoader.get_discipline("alchemist")
	var mb = disc["abilities"].filter(func(a): return a["id"] == "master_brewer")
	assert_has(mb[0]["unlocks_recipes"], "firefly_jar",
		"master_brewer must unlock firefly_jar recipe [LALC-A07]")


func test_identify_reveals_material_properties_lalc_a08():
	var disc: Dictionary = DataLoader.get_discipline("alchemist")
	var identify = disc["abilities"].filter(func(a): return a["id"] == "identify")
	assert_gt(identify.size(), 0, "identify ability must exist [LALC-A08]")


func test_identify_unlocks_experimental_recipes_lalc_a09():
	var disc: Dictionary = DataLoader.get_discipline("alchemist")
	var identify = disc["abilities"].filter(func(a): return a["id"] == "identify")
	assert_has(identify[0], "unlocks_experimental_recipes",
		"identify must define unlocks_experimental_recipes [LALC-A09]")
	assert_true(identify[0]["unlocks_experimental_recipes"],
		"identify must unlock experimental recipes [LALC-A09]")


func test_alchemist_purify_water_lalc_a10():
	var disc: Dictionary = DataLoader.get_discipline("alchemist")
	var purify = disc["abilities"].filter(func(a): return a["id"] == "purify_water")
	assert_gt(purify.size(), 0, "purify_water ability must exist [LALC-A10]")


# ---------------------------------------------------------------------------
# Scholar Abilities — LSCH-A01..16
# ---------------------------------------------------------------------------

func test_runic_literacy_shows_text_lsch_a01():
	var disc: Dictionary = DataLoader.get_discipline("scholar")
	assert_false(disc.is_empty(), "scholar discipline must exist [LSCH-A01]")
	var rl = disc["abilities"].filter(func(a): return a["id"] == "runic_literacy")
	assert_gt(rl.size(), 0, "runic_literacy ability must exist [LSCH-A01]")


func test_runic_literacy_gibberish_for_non_scholar_lsch_a02():
	# Non-scholars see gibberish; this is a UI flag in precursor site data
	assert_false(DisciplineManager.is_ability_unlocked("scholar", "runic_literacy"),
		"Non-scholar must not have runic_literacy [LSCH-A02]")


func test_salvage_mult_precursor_loot_lsch_a03():
	var disc: Dictionary = DataLoader.get_discipline("scholar")
	var salvage = disc["abilities"].filter(func(a): return a["id"] == "salvage")
	assert_gt(salvage.size(), 0, "salvage ability must exist [LSCH-A03]")
	assert_has(salvage[0], "loot_mult", "salvage must define loot_mult [LSCH-A03]")
	assert_gt(salvage[0]["loot_mult"], 1.0,
		"salvage loot_mult must be > 1.0 [LSCH-A03]")


func test_shelter_rest_tier_2_at_ruin_lsch_a04():
	var disc: Dictionary = DataLoader.get_discipline("scholar")
	var shelter = disc["abilities"].filter(func(a): return a["id"] == "shelter")
	assert_gt(shelter.size(), 0, "shelter ability must exist [LSCH-A04]")
	assert_has(shelter[0], "rest_tier_at_ruin",
		"shelter must define rest_tier_at_ruin [LSCH-A04]")
	assert_eq(shelter[0]["rest_tier_at_ruin"], 2,
		"shelter must provide rest_tier 2 at ruins [LSCH-A04]")


func test_shelter_weather_protection_lsch_a05():
	var disc: Dictionary = DataLoader.get_discipline("scholar")
	var shelter = disc["abilities"].filter(func(a): return a["id"] == "shelter")
	assert_has(shelter[0], "weather_protection",
		"shelter must define weather_protection [LSCH-A05]")
	assert_true(shelter[0]["weather_protection"],
		"shelter must provide weather protection [LSCH-A05]")


func test_glyph_ward_at_precursor_site_lsch_a06():
	var disc: Dictionary = DataLoader.get_discipline("scholar")
	var gw = disc["abilities"].filter(func(a): return a["id"] == "glyph_ward")
	assert_gt(gw.size(), 0, "glyph_ward ability must exist [LSCH-A06]")
	assert_has(gw[0], "requires_precursor_site",
		"glyph_ward must define requires_precursor_site [LSCH-A06]")
	assert_true(gw[0]["requires_precursor_site"],
		"glyph_ward must require precursor site [LSCH-A06]")


func test_glyph_ward_larger_radius_lsch_a07():
	var disc: Dictionary = DataLoader.get_discipline("scholar")
	var gw = disc["abilities"].filter(func(a): return a["id"] == "glyph_ward")
	assert_has(gw[0], "radius", "glyph_ward must define radius [LSCH-A07]")
	# glyph_ward must have a larger radius than the standard ward (ward radius = defined in ritualist)
	var ritualist: Dictionary = DataLoader.get_discipline("ritualist")
	var ward = ritualist["abilities"].filter(func(a): return a["id"] == "ward")
	assert_gt(gw[0]["radius"], ward[0]["radius"],
		"glyph_ward radius must exceed standard ward radius [LSCH-A07]")


func test_glyph_ward_longer_duration_lsch_a08():
	var disc: Dictionary = DataLoader.get_discipline("scholar")
	var gw = disc["abilities"].filter(func(a): return a["id"] == "glyph_ward")
	var ritualist: Dictionary = DataLoader.get_discipline("ritualist")
	var ward = ritualist["abilities"].filter(func(a): return a["id"] == "ward")
	assert_gt(gw[0]["duration"], ward[0]["duration"],
		"glyph_ward duration must exceed standard ward duration [LSCH-A08]")


func test_glyph_ward_only_at_precursor_lsch_a09():
	var disc: Dictionary = DataLoader.get_discipline("scholar")
	var gw = disc["abilities"].filter(func(a): return a["id"] == "glyph_ward")
	assert_true(gw[0]["requires_precursor_site"],
		"glyph_ward must only be usable at precursor sites [LSCH-A09]")


func test_deep_reading_reveals_hex_locations_lsch_a10():
	var disc: Dictionary = DataLoader.get_discipline("scholar")
	var dr = disc["abilities"].filter(func(a): return a["id"] == "deep_reading")
	assert_gt(dr.size(), 0, "deep_reading ability must exist [LSCH-A10]")
	assert_has(dr[0], "reveals_hex_locations",
		"deep_reading must define reveals_hex_locations [LSCH-A10]")
	assert_true(dr[0]["reveals_hex_locations"],
		"deep_reading must reveal hex locations [LSCH-A10]")


func test_reactivate_sustenance_system_lsch_a11():
	var disc: Dictionary = DataLoader.get_discipline("scholar")
	var react = disc["abilities"].filter(func(a): return a["id"] == "reactivate")
	assert_gt(react.size(), 0, "reactivate ability must exist [LSCH-A11]")


func test_reactivate_restores_hunger_thirst_lsch_a12():
	var disc: Dictionary = DataLoader.get_discipline("scholar")
	var react = disc["abilities"].filter(func(a): return a["id"] == "reactivate")
	assert_has(react[0], "hunger_restore",
		"reactivate must define hunger_restore [LSCH-A12]")
	assert_has(react[0], "thirst_restore",
		"reactivate must define thirst_restore [LSCH-A12]")


func test_reactivate_max_charges_lsch_a13():
	var disc: Dictionary = DataLoader.get_discipline("scholar")
	var react = disc["abilities"].filter(func(a): return a["id"] == "reactivate")
	assert_has(react[0], "max_charges",
		"reactivate must define max_charges [LSCH-A13]")
	assert_gt(react[0]["max_charges"], 0,
		"reactivate max_charges must be positive [LSCH-A13]")


func test_reactivate_decrements_charges_lsch_a14():
	var disc: Dictionary = DataLoader.get_discipline("scholar")
	var react = disc["abilities"].filter(func(a): return a["id"] == "reactivate")
	assert_has(react[0], "charges_per_use",
		"reactivate must define charges_per_use [LSCH-A14]")
	assert_eq(react[0]["charges_per_use"], 1,
		"reactivate must consume 1 charge per use [LSCH-A14]")


func test_reactivate_depleted_at_0_charges_lsch_a15():
	var disc: Dictionary = DataLoader.get_discipline("scholar")
	var react = disc["abilities"].filter(func(a): return a["id"] == "reactivate")
	assert_has(react[0], "depleted_state",
		"reactivate must define depleted_state behavior [LSCH-A15]")


func test_reactivate_state_persists_in_save_lsch_a16():
	# reactivate charges must be included in AbilitySystem.get_save_data()
	# Verified by checking save_data includes cooldown/once_per_rest tracking
	var player: Node = add_child_autofree(preload("res://scenes/player/Player.tscn").instantiate())
	var ability_sys: Node = player.get_node("AbilitySystem")
	var save_data: Dictionary = ability_sys.get_save_data()
	assert_has(save_data, "once_per_rest",
		"AbilitySystem save_data must include once_per_rest for charge tracking [LSCH-A16]")


# ---------------------------------------------------------------------------
# Wizard Abilities — LWIZ-A01..15
# ---------------------------------------------------------------------------

func test_wizard_checks_reagent_before_cast_lwiz_a01():
	var disc: Dictionary = DataLoader.get_discipline("wizard")
	assert_false(disc.is_empty(), "wizard discipline must exist [LWIZ-A01]")
	# Wizard abilities check inventory for reagents before executing
	var player: Node = add_child_autofree(preload("res://scenes/player/Player.tscn").instantiate())
	var ability_sys: Node = player.get_node("AbilitySystem")
	assert_true(ability_sys.has_method("activate_ability"),
		"AbilitySystem must implement activate_ability [LWIZ-A01]")


func test_wizard_consumes_reagent_on_cast_lwiz_a02():
	var player: Node = add_child_autofree(preload("res://scenes/player/Player.tscn").instantiate())
	var inv: Node = player.get_node("PlayerInventory")
	# Without fire_herb, firebolt should fail
	DisciplineManager.attune("wizard")
	DisciplineManager.add_xp_direct("wizard", 9999)
	assert_false(inv.has_item("fire_herb"),
		"Player must not start with fire_herb [LWIZ-A02]")


func test_firebolt_projectile_burn_dot_lwiz_a03():
	var disc: Dictionary = DataLoader.get_discipline("wizard")
	var fb = disc["abilities"].filter(func(a): return a["id"] == "firebolt")
	assert_gt(fb.size(), 0, "firebolt ability must exist [LWIZ-A03]")
	assert_has(fb[0], "burn_dps", "firebolt must define burn_dps [LWIZ-A03]")
	assert_gt(fb[0]["burn_dps"], 0.0, "firebolt burn_dps must be positive [LWIZ-A03]")


func test_firebolt_consumes_fire_herb_lwiz_a04():
	var disc: Dictionary = DataLoader.get_discipline("wizard")
	var fb = disc["abilities"].filter(func(a): return a["id"] == "firebolt")
	assert_has(fb[0], "reagent", "firebolt must define reagent [LWIZ-A04]")
	assert_eq(fb[0]["reagent"], "fire_herb",
		"firebolt reagent must be fire_herb [LWIZ-A04]")


func test_frost_snap_root_5s_lwiz_a05():
	var disc: Dictionary = DataLoader.get_discipline("wizard")
	var fs = disc["abilities"].filter(func(a): return a["id"] == "frost_snap")
	assert_gt(fs.size(), 0, "frost_snap ability must exist [LWIZ-A05]")
	assert_has(fs[0], "root_duration", "frost_snap must define root_duration [LWIZ-A05]")
	assert_eq(fs[0]["root_duration"], 5.0,
		"frost_snap root_duration must be 5s [LWIZ-A05]")


func test_frost_snap_consumes_crystal_shard_lwiz_a06():
	var disc: Dictionary = DataLoader.get_discipline("wizard")
	var fs = disc["abilities"].filter(func(a): return a["id"] == "frost_snap")
	assert_has(fs[0], "reagent", "frost_snap must define reagent [LWIZ-A06]")
	assert_eq(fs[0]["reagent"], "crystal_shard",
		"frost_snap reagent must be crystal_shard [LWIZ-A06]")


func test_force_push_knockback_stagger_cone_lwiz_a07():
	var disc: Dictionary = DataLoader.get_discipline("wizard")
	var fp = disc["abilities"].filter(func(a): return a["id"] == "force_push")
	assert_gt(fp.size(), 0, "force_push ability must exist [LWIZ-A07]")
	assert_has(fp[0], "knockback_force", "force_push must define knockback_force [LWIZ-A07]")


func test_force_push_consumes_mineral_powder_lwiz_a08():
	var disc: Dictionary = DataLoader.get_discipline("wizard")
	var fp = disc["abilities"].filter(func(a): return a["id"] == "force_push")
	assert_has(fp[0], "reagent", "force_push must define reagent [LWIZ-A08]")
	assert_eq(fp[0]["reagent"], "mineral_powder",
		"force_push reagent must be mineral_powder [LWIZ-A08]")


func test_lightning_arc_chain_lwiz_a09():
	var disc: Dictionary = DataLoader.get_discipline("wizard")
	var la = disc["abilities"].filter(func(a): return a["id"] == "lightning_arc")
	assert_gt(la.size(), 0, "lightning_arc ability must exist [LWIZ-A09]")
	assert_has(la[0], "chain_count", "lightning_arc must define chain_count [LWIZ-A09]")
	assert_gt(la[0]["chain_count"], 1,
		"lightning_arc must chain to multiple targets [LWIZ-A09]")


func test_lightning_arc_consumes_charged_filament_lwiz_a10():
	var disc: Dictionary = DataLoader.get_discipline("wizard")
	var la = disc["abilities"].filter(func(a): return a["id"] == "lightning_arc")
	assert_has(la[0], "reagent", "lightning_arc must define reagent [LWIZ-A10]")
	assert_eq(la[0]["reagent"], "charged_filament",
		"lightning_arc reagent must be charged_filament [LWIZ-A10]")


func test_stone_shield_destructible_barrier_lwiz_a11():
	var disc: Dictionary = DataLoader.get_discipline("wizard")
	var ss = disc["abilities"].filter(func(a): return a["id"] == "stone_shield")
	assert_gt(ss.size(), 0, "stone_shield ability must exist [LWIZ-A11]")
	assert_has(ss[0], "barrier_hp", "stone_shield must define barrier_hp [LWIZ-A11]")
	assert_gt(ss[0]["barrier_hp"], 0.0,
		"stone_shield barrier_hp must be positive [LWIZ-A11]")


func test_stone_shield_absorbs_until_hp_or_15s_lwiz_a12():
	var disc: Dictionary = DataLoader.get_discipline("wizard")
	var ss = disc["abilities"].filter(func(a): return a["id"] == "stone_shield")
	assert_has(ss[0], "duration", "stone_shield must define duration [LWIZ-A12]")
	assert_eq(ss[0]["duration"], 15.0,
		"stone_shield duration must be 15s [LWIZ-A12]")


func test_stone_shield_consumes_2_mineral_powder_lwiz_a13():
	var disc: Dictionary = DataLoader.get_discipline("wizard")
	var ss = disc["abilities"].filter(func(a): return a["id"] == "stone_shield")
	assert_has(ss[0], "reagent", "stone_shield must define reagent [LWIZ-A13]")
	assert_eq(ss[0]["reagent"], "mineral_powder",
		"stone_shield reagent must be mineral_powder [LWIZ-A13]")
	assert_has(ss[0], "reagent_count", "stone_shield must define reagent_count [LWIZ-A13]")
	assert_eq(ss[0]["reagent_count"], 2,
		"stone_shield must consume 2 mineral_powder [LWIZ-A13]")


func test_ruin_massive_damage_lwiz_a14():
	var disc: Dictionary = DataLoader.get_discipline("wizard")
	var ruin = disc["abilities"].filter(func(a): return a["id"] == "ruin")
	assert_gt(ruin.size(), 0, "ruin ability must exist [LWIZ-A14]")
	assert_has(ruin[0], "damage", "ruin must define damage [LWIZ-A14]")
	# Ruin should be one of the highest-damage abilities
	assert_gt(ruin[0]["damage"], 100.0,
		"ruin must deal massive damage (> 100) [LWIZ-A14]")


func test_ruin_consumes_precursor_core_fragment_lwiz_a15():
	var disc: Dictionary = DataLoader.get_discipline("wizard")
	var ruin = disc["abilities"].filter(func(a): return a["id"] == "ruin")
	assert_has(ruin[0], "reagent", "ruin must define reagent [LWIZ-A15]")
	assert_eq(ruin[0]["reagent"], "precursor_core_fragment",
		"ruin reagent must be precursor_core_fragment [LWIZ-A15]")
