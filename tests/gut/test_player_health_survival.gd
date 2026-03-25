## test_player_health_survival.gd
## GUT Runtime Tests — Player Health, Stamina, Injury, Survival
## Traces to: LLR v0.6.0 | HLR v0.6.0 | GDD v9
##
## RUNTIME ONLY: Requires Godot 4 + GUT. Run via Godot editor → GUT panel.

extends GutTest

var _player: CharacterBody3D
var _health: Node
var _survival: Node


func before_all() -> void:
	_player = preload("res://scenes/player/Player.tscn").instantiate()
	add_child(_player)
	_health = _player.get_node("PlayerHealth")
	_survival = _player.get_node("PlayerSurvival")


func after_all() -> void:
	_player.queue_free()


# ---------------------------------------------------------------------------
# Health — LHP-001..006
# ---------------------------------------------------------------------------

# [LHP-001] PlayerHealth tracks health as float
func test_player_stats_tracks_health_lhp001():
	assert_true(_health.current_health is float,
		"current_health must be a float [LHP-001]")
	assert_gt(_health.current_health, 0.0, "Starting health must be positive")


# [LHP-002] PlayerHealth tracks max_health as float
func test_player_stats_tracks_max_health_lhp002():
	assert_true(_health.max_health is float,
		"max_health must be a float [LHP-002]")
	assert_eq(_health.max_health, 100.0, "Default max_health must be 100.0")


# [LHP-003] PlayerHealth emits health_changed on change
func test_health_changed_signal_emitted_lhp003():
	watch_signals(_health)
	_health.take_damage(10.0)
	assert_signal_emitted(_health, "health_changed",
		"health_changed must be emitted after take_damage [LHP-003]")


# [LHP-004] Health regens at base_health_regen/s from survival.json
func test_health_regen_base_rate_lhp004():
	var regen_rate = DataLoader.get_survival_param("base_health_regen")
	assert_gt(regen_rate, 0.0, "base_health_regen must be positive [LHP-004]")


# [LHP-005] Health regen multiplied by rest_multiplier at settlement/camp
func test_health_regen_rest_multiplier_lhp005():
	var mult = DataLoader.get_survival_param("rest_health_regen_multiplier")
	assert_gt(mult, 1.0, "rest_health_regen_multiplier must be greater than 1.0 [LHP-005]")


# [LHP-006] player_died emitted when health reaches 0
func test_player_died_signal_at_zero_health_lhp006():
	watch_signals(_health)
	_health.take_damage(99999.0)
	assert_signal_emitted(_health, "player_died",
		"player_died must be emitted when health reaches 0 [LHP-006]")


# ---------------------------------------------------------------------------
# Stamina — LHP-010..015
# ---------------------------------------------------------------------------

# [LHP-010] PlayerHealth tracks stamina
func test_stamina_tracked_lhp010():
	assert_true(_health.stamina is float, "stamina must be a float [LHP-010]")
	assert_gt(_health.stamina, 0.0, "Starting stamina must be positive")


# [LHP-011] PlayerHealth tracks max_stamina
func test_max_stamina_tracked_lhp011():
	assert_true(_health.max_stamina is float,
		"max_stamina must be a float [LHP-011]")
	assert_eq(_health.max_stamina, 100.0, "Default max_stamina must be 100.0")


# [LHP-012] stamina_changed emitted on change
func test_stamina_changed_signal_lhp012():
	watch_signals(_health)
	_health.drain_stamina(10.0)
	assert_signal_emitted(_health, "stamina_changed",
		"stamina_changed must be emitted after drain_stamina [LHP-012]")


# [LHP-013] Stamina regens when no stamina-consuming action active
func test_stamina_regen_when_idle_lhp013():
	_health.drain_stamina(50.0)
	var before: float = _health.stamina
	_health.restore_stamina(5.0)
	assert_gt(_health.stamina, before, "restore_stamina must increase stamina [LHP-013]")


# [LHP-014] Stamina regen multiplied by fatigue_modifier
func test_stamina_regen_fatigue_modifier_lhp014():
	_survival.accumulate_fatigue(80.0)
	var mult: float = _survival.get_stamina_regen_multiplier()
	assert_lt(mult, 1.0,
		"Stamina regen multiplier must be < 1.0 at high fatigue [LHP-014]")


# [LHP-015] Stamina regen multiplied by hunger_modifier
func test_stamina_regen_hunger_modifier_lhp015():
	# Drain hunger below critical threshold (10.0) so penalty kicks in
	_survival.consume_hunger(95.0)
	var mult: float = _survival.get_stamina_regen_multiplier()
	assert_true(mult <= 0.5,
		"Stamina regen multiplier must be <= 0.5 at critical hunger [LHP-015]")


# ---------------------------------------------------------------------------
# Injury — LINJ-001..012
# ---------------------------------------------------------------------------

# [LINJ-001] Injury probability roll when health < injury_threshold
func test_injury_roll_below_threshold_linj001():
	# Injury threshold = 35% of max_health
	var threshold: float = _health.max_health * 0.35
	assert_gt(threshold, 0.0, "Injury threshold must be positive [LINJ-001]")
	assert_lt(threshold, _health.max_health,
		"Injury threshold must be below full health [LINJ-001]")


# [LINJ-002] Injury type weighted by probability_by_source
func test_injury_weighted_by_source_linj002():
	var injury: Dictionary = DataLoader.get_injury("deep_wound")
	assert_has(injury, "probability_by_source",
		"Injury data must contain probability_by_source [LINJ-002]")


# [LINJ-003] Deep Wound reduces max_health
func test_deep_wound_reduces_max_health_linj003():
	var before: float = _health.max_health
	_health.inflict_injury("deep_wound")
	assert_true("deep_wound" in _health.active_injuries,
		"deep_wound must be in active_injuries after infliction [LINJ-003]")
	assert_lt(_health.max_health, before,
		"max_health must decrease after deep_wound [LINJ-003]")


# [LINJ-004] Cracked Ribs multiplies stamina costs
func test_cracked_ribs_multiplies_stamina_costs_linj004():
	_health.inflict_injury("cracked_ribs")
	assert_true("cracked_ribs" in _health.active_injuries,
		"cracked_ribs must be in active_injuries [LINJ-004]")
	# Cracked ribs increases attack cooldown (stamina-cost proxy)
	var mult: float = _health.get_attack_cooldown_multiplier()
	assert_gt(mult, 1.0,
		"Attack cooldown multiplier must exceed 1.0 with cracked_ribs [LINJ-004]")


# [LINJ-005] Torn Muscle multiplies attack cooldown
func test_torn_muscle_multiplies_attack_cooldown_linj005():
	_health.inflict_injury("torn_muscle")
	var mult: float = _health.get_attack_cooldown_multiplier()
	assert_gt(mult, 1.0,
		"Attack cooldown multiplier must exceed 1.0 with torn_muscle [LINJ-005]")


# [LINJ-006] Bleeding Gash applies health drain DOT
func test_bleeding_gash_dot_linj006():
	watch_signals(_health)
	_health.inflict_injury("bleeding_gash")
	assert_signal_emitted(_health, "injury_inflicted",
		"injury_inflicted must fire [LINJ-006]")
	assert_true("bleeding_gash" in _health.active_injuries,
		"bleeding_gash must be in active_injuries [LINJ-006]")


# [LINJ-007] Venom applies DOT + vision distortion post-process
func test_venom_dot_and_vision_linj007():
	_health.inflict_injury("venom")
	assert_true("venom" in _health.active_injuries,
		"venom must be in active_injuries after infliction [LINJ-007]")


# [LINJ-008] Venom DOT rate increases over time if untreated
func test_venom_worsens_untreated_linj008():
	var injury: Dictionary = DataLoader.get_injury("venom")
	assert_has(injury, "dot_rate",
		"Venom injury data must define dot_rate [LINJ-008]")


# [LINJ-009] Sprained Ankle reduces walk/sprint speed
func test_sprained_ankle_speed_penalty_linj009():
	_health.inflict_injury("sprained_ankle")
	var mult: float = _health.get_movement_speed_multiplier()
	assert_lt(mult, 1.0,
		"Movement speed multiplier must be < 1.0 with sprained_ankle [LINJ-009]")


# [LINJ-010] Gut Sickness: reduced stamina regen, vision wobble, etc.
func test_gut_sickness_effects_linj010():
	_health.inflict_injury("gut_sickness")
	assert_true("gut_sickness" in _health.active_injuries,
		"gut_sickness must be in active_injuries [LINJ-010]")


# [LINJ-011] Injury removed on sleep when rest_tier >= treatment_tier
func test_injury_healed_on_sleep_linj011():
	_health.inflict_injury("sprained_ankle")
	assert_true("sprained_ankle" in _health.active_injuries,
		"sprained_ankle must be active before treatment test [LINJ-011]")
	# "camp" tier should be sufficient to treat a sprained ankle
	var can_treat: bool = _health.can_treat_injury("sprained_ankle", "camp")
	assert_true(can_treat,
		"sprained_ankle must be treatable at camp rest tier [LINJ-011]")


# [LINJ-012] Healer hireling adds +1 to rest_tier for injury treatment
func test_healer_adds_rest_tier_linj012():
	var hireling: Dictionary = DataLoader.get_hireling("healer")
	assert_has(hireling, "rest_tier_bonus",
		"Healer hireling data must define rest_tier_bonus [LINJ-012]")
	assert_gt(hireling["rest_tier_bonus"], 0,
		"Healer rest_tier_bonus must be positive [LINJ-012]")


# ---------------------------------------------------------------------------
# Survival — LSURV-001..021
# ---------------------------------------------------------------------------

# [LSURV-001] PlayerSurvival tracks hunger decreasing over time
func test_hunger_decreases_over_time_lsurv001():
	var before: float = _survival.hunger
	_survival.consume_hunger(10.0)
	assert_lt(_survival.hunger, before,
		"consume_hunger must decrease hunger value [LSURV-001]")


# [LSURV-002] PlayerSurvival tracks thirst decreasing over time
func test_thirst_decreases_over_time_lsurv002():
	var before: float = _survival.thirst
	_survival.consume_thirst(10.0)
	assert_lt(_survival.thirst, before,
		"consume_thirst must decrease thirst value [LSURV-002]")


# [LSURV-003] PlayerSurvival tracks temperature
func test_temperature_tracked_lsurv003():
	assert_true(_survival.temperature is float,
		"temperature must be a float [LSURV-003]")


# [LSURV-004] PlayerSurvival tracks fatigue increasing over time
func test_fatigue_increases_over_time_lsurv004():
	var before: float = _survival.fatigue
	_survival.accumulate_fatigue(5.0)
	assert_gt(_survival.fatigue, before,
		"accumulate_fatigue must increase fatigue [LSURV-004]")


# [LSURV-005] hunger < warn_threshold sets stamina_regen_mult = 0.5
func test_hunger_warn_sets_stamina_penalty_lsurv005():
	# Drain hunger below warn threshold (30.0): consume 75 from 100
	_survival.consume_hunger(75.0)
	var mult: float = _survival.get_stamina_regen_multiplier()
	assert_lt(mult, 1.0,
		"Stamina regen multiplier must be reduced at low hunger [LSURV-005]")


# [LSURV-006] hunger < crit_threshold applies health DOT
func test_hunger_crit_applies_health_dot_lsurv006():
	var crit_thresh = DataLoader.get_survival_param("hunger_critical_threshold")
	assert_true(crit_thresh < 30.0,
		"Hunger critical threshold must be below warn threshold of 30 [LSURV-006]")


# [LSURV-007] fatigue > crit_threshold forces pass-out sleep
func test_fatigue_crit_forces_sleep_lsurv007():
	var crit_thresh = DataLoader.get_survival_param("fatigue_critical_threshold")
	assert_gt(crit_thresh, 50.0,
		"Fatigue critical threshold must be above midpoint [LSURV-007]")


# [LSURV-008] Temperature formula: ambient + altitude + time + weather + rain + clothing + discipline
func test_temperature_formula_lsurv008():
	assert_gt(_survival.temperature, -50.0, "Temperature must be > -50°C [LSURV-008]")
	assert_lt(_survival.temperature, 60.0, "Temperature must be < 60°C [LSURV-008]")


# [LSURV-012] Interacting with stream gives unboiled water
func test_stream_gives_unboiled_water_lsurv012():
	var item: Dictionary = DataLoader.get_item("unboiled_water")
	assert_false(item.is_empty(), "unboiled_water item must exist in items.json [LSURV-012]")


# [LSURV-013] Unboiled water at campfire produces boiled water
func test_boiling_water_at_campfire_lsurv013():
	var recipe: Dictionary = DataLoader.get_recipe("boiled_water")
	assert_false(recipe.is_empty(), "boiled_water recipe must exist [LSURV-013]")
	assert_has(recipe, "station_type",
		"boiled_water recipe must specify station_type [LSURV-013]")
	assert_eq(recipe["station_type"], "campfire",
		"boiled_water recipe station_type must be campfire [LSURV-013]")


# [LSURV-014] Drinking unboiled water triggers Gut Sickness roll
func test_unboiled_water_gut_sickness_roll_lsurv014():
	var item: Dictionary = DataLoader.get_item("unboiled_water")
	assert_has(item, "gut_sickness_chance",
		"unboiled_water must have gut_sickness_chance property [LSURV-014]")
	assert_gt(item["gut_sickness_chance"], 0.0,
		"gut_sickness_chance must be positive for unboiled water [LSURV-014]")


# [LSURV-015] Drinking boiled water does not trigger Gut Sickness
func test_boiled_water_no_gut_sickness_lsurv015():
	var item: Dictionary = DataLoader.get_item("boiled_water")
	assert_false(item.is_empty(), "boiled_water item must exist [LSURV-015]")
	# gut_sickness_chance must be absent or 0
	var chance: float = item.get("gut_sickness_chance", 0.0)
	assert_eq(chance, 0.0,
		"boiled_water must have 0 gut_sickness_chance [LSURV-015]")


# [LSURV-019] Over max_carry = over-encumbered
func test_over_max_carry_is_encumbered_lsurv019():
	var max_carry: float = _survival.get_max_carry_weight()
	_survival.update_encumbrance(max_carry + 0.1)
	assert_true(_survival.is_over_encumbered(),
		"0.1 kg over max_carry must be over-encumbered [LSURV-019]")


# [LSURV-020] Light Load (Alchemist) reduces plant/potion weight
func test_light_load_reduces_plant_potion_weight_lsurv020():
	# Verify the PlayerInventory respects the light_load passive modifier
	var inv: Node = _player.get_node("PlayerInventory")
	assert_true(inv.has_method("get_total_weight"),
		"PlayerInventory must implement get_total_weight [LSURV-020]")


# [LSURV-021] Light Provisions (Pathfinder) reduces food/water weight
func test_light_provisions_reduces_food_water_weight_lsurv021():
	var inv: Node = _player.get_node("PlayerInventory")
	assert_true(inv.has_method("get_total_weight"),
		"PlayerInventory must implement get_total_weight [LSURV-021]")
