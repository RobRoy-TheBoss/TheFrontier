## test_survival_needs.gd
## GUT Runtime Tests — Survival Needs (SURV-001)
## Traces to: LSURV-001..027
##
## RUNTIME ONLY: Requires Godot 4 + GUT. Run via Godot editor → GUT panel.

extends GutTest

var _player: CharacterBody3D
var _survival: PlayerSurvival
var _health: PlayerHealth

# Mirror survival.json values so tests are data-driven and readable
const HUNGER_DRAIN_PER_SEC: float = 0.002
const THIRST_DRAIN_PER_SEC: float = 0.004
const HUNGER_LOW_THRESHOLD: float = 30.0
const HUNGER_CRIT_THRESHOLD: float = 10.0
const THIRST_LOW_THRESHOLD: float = 30.0
const THIRST_CRIT_THRESHOLD: float = 10.0
const THIRST_LOW_FATIGUE_ACCEL: float = 1.5
const THIRST_LOW_CARRY_REDUCTION: float = 0.20  # 20%
const BASE_CARRY_WEIGHT: float = 50.0


func before_all() -> void:
	_player = preload("res://scenes/player/Player.tscn").instantiate()
	add_child(_player)
	_survival = _player.get_node("PlayerSurvival")
	_health = _player.get_node("PlayerHealth")
	GameState.is_paused_for_ui = false
	GameState.is_sleeping = false


func before_each() -> void:
	_survival.hunger = 100.0
	_survival.thirst = 100.0
	_survival.fatigue = 0.0
	_health.is_dead = false
	_health.current_health = _health.max_health


func after_all() -> void:
	_player.queue_free()


# ---------------------------------------------------------------------------
# [LSURV-001] Hunger decreases passively over time
# ---------------------------------------------------------------------------

func test_hunger_decreases_each_process_tick_lsurv001():
	var before: float = _survival.hunger
	_survival._process_hunger(1.0)
	assert_lt(_survival.hunger, before,
		"_process_hunger(1.0) must reduce hunger [LSURV-001]")


func test_hunger_drain_matches_data_rate_lsurv001():
	_survival.hunger = 100.0
	_survival._process_hunger(1.0)
	var expected: float = 100.0 - HUNGER_DRAIN_PER_SEC
	assert_almost_eq(_survival.hunger, expected, 0.0001,
		"Hunger must drain by drain_per_second * delta per tick [LSURV-001]")


func test_hunger_drain_scales_with_delta_lsurv001():
	# Simulate 1 in-game hour (3600 s) — hunger drops by 0.002 * 3600 = 7.2
	_survival.hunger = 100.0
	_survival._process_hunger(3600.0)
	var expected: float = max(0.0, 100.0 - HUNGER_DRAIN_PER_SEC * 3600.0)
	assert_almost_eq(_survival.hunger, expected, 0.01,
		"Hunger drain must scale linearly with delta [LSURV-001]")


func test_hunger_never_goes_below_zero_lsurv001():
	_survival.hunger = 0.5
	_survival._process_hunger(1000.0)
	assert_gte(_survival.hunger, 0.0,
		"Hunger must clamp to 0.0, never go negative [LSURV-001]")


func test_hunger_emits_signal_on_drain_lsurv001():
	watch_signals(_survival)
	_survival._process_hunger(1.0)
	assert_signal_emitted(_survival, "hunger_changed",
		"hunger_changed signal must emit each process tick [LSURV-001]")


func test_hunger_signal_carries_correct_values_lsurv001():
	_survival.hunger = 50.0
	watch_signals(_survival)
	_survival._process_hunger(1.0)
	var args: Array = get_signal_parameters(_survival, "hunger_changed")
	assert_almost_eq(float(args[0]), 50.0 - HUNGER_DRAIN_PER_SEC, 0.001,
		"hunger_changed arg[0] must be the new hunger value [LSURV-001]")
	assert_almost_eq(float(args[1]), 100.0, 0.001,
		"hunger_changed arg[1] must be max hunger (100.0) [LSURV-001]")


# ---------------------------------------------------------------------------
# [LSURV-002] Thirst decreases passively over time
# ---------------------------------------------------------------------------

func test_thirst_decreases_each_process_tick_lsurv002():
	var before: float = _survival.thirst
	_survival._process_thirst(1.0)
	assert_lt(_survival.thirst, before,
		"_process_thirst(1.0) must reduce thirst [LSURV-002]")


func test_thirst_drain_matches_data_rate_lsurv002():
	_survival.thirst = 100.0
	_survival._process_thirst(1.0)
	var expected: float = 100.0 - THIRST_DRAIN_PER_SEC
	assert_almost_eq(_survival.thirst, expected, 0.0001,
		"Thirst must drain by drain_per_second * delta per tick [LSURV-002]")


func test_thirst_drain_scales_with_delta_lsurv002():
	# Simulate 1 in-game hour — thirst drops by 0.004 * 3600 = 14.4
	_survival.thirst = 100.0
	_survival._process_thirst(3600.0)
	var expected: float = max(0.0, 100.0 - THIRST_DRAIN_PER_SEC * 3600.0)
	assert_almost_eq(_survival.thirst, expected, 0.01,
		"Thirst drain must scale linearly with delta [LSURV-002]")


func test_thirst_never_goes_below_zero_lsurv002():
	_survival.thirst = 0.5
	_survival._process_thirst(1000.0)
	assert_gte(_survival.thirst, 0.0,
		"Thirst must clamp to 0.0, never go negative [LSURV-002]")


func test_thirst_emits_signal_on_drain_lsurv002():
	watch_signals(_survival)
	_survival._process_thirst(1.0)
	assert_signal_emitted(_survival, "thirst_changed",
		"thirst_changed signal must emit each process tick [LSURV-002]")


func test_thirst_drains_faster_than_hunger_lsurv002():
	# Thirst drain 0.004/s vs hunger 0.002/s — thirst should be lower after equal time
	_survival.hunger = 100.0
	_survival.thirst = 100.0
	_survival._process_hunger(100.0)
	var hunger_after: float = _survival.hunger
	_survival.thirst = 100.0
	_survival._process_thirst(100.0)
	var thirst_after: float = _survival.thirst
	assert_lt(thirst_after, hunger_after,
		"Thirst must deplete faster than hunger over equal time [LSURV-002]")


# ---------------------------------------------------------------------------
# [LSURV-005] Hunger < warn threshold emits warning and reduces stamina regen
# ---------------------------------------------------------------------------

func test_hunger_low_emits_warning_lsurv005():
	_survival.hunger = HUNGER_LOW_THRESHOLD - 0.1
	watch_signals(_survival)
	_survival._process_hunger(0.01)  # tiny delta — keep hunger low but not critical
	assert_signal_emitted(_survival, "survival_warning",
		"survival_warning must fire when hunger is at low threshold [LSURV-005]")


func test_hunger_low_reduces_stamina_regen_multiplier_lsurv005():
	_survival.hunger = HUNGER_LOW_THRESHOLD - 1.0
	var mult: float = _survival.get_stamina_regen_multiplier()
	assert_lt(mult, 1.0,
		"Stamina regen multiplier must be < 1.0 at low hunger [LSURV-005]")
	assert_almost_eq(mult, 0.5, 0.001,
		"Stamina regen multiplier must be 0.5 at low hunger [LSURV-005]")


# ---------------------------------------------------------------------------
# [LSURV-006] Hunger <= critical threshold: health DOT + critical warning
# ---------------------------------------------------------------------------

func test_hunger_critical_emits_critical_warning_lsurv006():
	_survival.hunger = HUNGER_CRIT_THRESHOLD - 0.1
	watch_signals(_survival)
	_survival._process_hunger(1.0)
	var args: Array = get_signal_parameters(_survival, "survival_warning")
	assert_eq(args[0], "hunger",
		"survival_warning need arg must be 'hunger' at critical [LSURV-006]")
	assert_eq(args[1], "critical",
		"survival_warning level arg must be 'critical' at critical hunger [LSURV-006]")


func test_hunger_critical_drains_health_lsurv006():
	_survival.hunger = HUNGER_CRIT_THRESHOLD - 0.1
	var hp_before: float = _health.current_health
	_survival._process_hunger(1.0)
	assert_lt(_health.current_health, hp_before,
		"Health must decrease when hunger is critical [LSURV-006]")


# ---------------------------------------------------------------------------
# [LSURV-009] Thirst < warn threshold emits warning
# ---------------------------------------------------------------------------

func test_thirst_low_emits_warning_lsurv009():
	_survival.thirst = THIRST_LOW_THRESHOLD - 0.1
	watch_signals(_survival)
	_survival._process_thirst(0.01)
	assert_signal_emitted(_survival, "survival_warning",
		"survival_warning must fire when thirst is at low threshold [LSURV-009]")


func test_thirst_low_warning_args_lsurv009():
	_survival.thirst = THIRST_LOW_THRESHOLD - 0.1
	watch_signals(_survival)
	_survival._process_thirst(0.01)
	var args: Array = get_signal_parameters(_survival, "survival_warning")
	assert_eq(args[0], "thirst",
		"survival_warning need arg must be 'thirst' [LSURV-009]")
	assert_eq(args[1], "low",
		"survival_warning level arg must be 'low' for thirst warn [LSURV-009]")


# ---------------------------------------------------------------------------
# [LSURV-022] Thirst < warn threshold accelerates fatigue gain by 1.5×
# ---------------------------------------------------------------------------

func test_thirst_low_accelerates_fatigue_gain_lsurv022():
	# Normal fatigue gain at full thirst
	_survival.thirst = 100.0
	_survival.fatigue = 0.0
	_survival.accumulate_fatigue(10.0)
	var normal_gain: float = _survival.fatigue

	# Fatigue gain at low thirst
	_survival.thirst = THIRST_LOW_THRESHOLD - 1.0
	_survival.fatigue = 0.0
	_survival.accumulate_fatigue(10.0)
	var low_thirst_gain: float = _survival.fatigue

	assert_gt(low_thirst_gain, normal_gain,
		"Fatigue gain must be higher when thirst is low [LSURV-022]")
	assert_almost_eq(low_thirst_gain, normal_gain * THIRST_LOW_FATIGUE_ACCEL, 0.01,
		"Fatigue gain must be multiplied by low_fatigue_acceleration (1.5×) at low thirst [LSURV-022]")


func test_thirst_above_low_does_not_accelerate_fatigue_lsurv022():
	_survival.thirst = THIRST_LOW_THRESHOLD + 1.0
	_survival.fatigue = 0.0
	_survival.accumulate_fatigue(10.0)
	# Should be 10.0 — no acceleration at normal thirst
	assert_almost_eq(_survival.fatigue, 10.0, 0.01,
		"Fatigue gain must not be accelerated when thirst is above low threshold [LSURV-022]")


# ---------------------------------------------------------------------------
# [LSURV-023] Thirst <= critical threshold reduces max carry weight by 20%
# ---------------------------------------------------------------------------

func test_thirst_critical_reduces_max_carry_weight_lsurv023():
	var normal_carry: float = _survival.get_max_carry_weight()
	_survival.thirst = THIRST_CRIT_THRESHOLD - 0.1
	var reduced_carry: float = _survival.get_max_carry_weight()
	assert_lt(reduced_carry, normal_carry,
		"Max carry weight must decrease when thirst is critical [LSURV-023]")
	var expected: float = normal_carry * (1.0 - THIRST_LOW_CARRY_REDUCTION)
	assert_almost_eq(reduced_carry, expected, 0.1,
		"Max carry weight must be reduced by 20%% at critical thirst [LSURV-023]")


func test_thirst_above_critical_does_not_reduce_carry_lsurv023():
	var normal_carry: float = _survival.get_max_carry_weight()
	_survival.thirst = THIRST_CRIT_THRESHOLD + 1.0
	var carry: float = _survival.get_max_carry_weight()
	assert_almost_eq(carry, normal_carry, 0.01,
		"Max carry weight must not be reduced when thirst is above critical [LSURV-023]")


# ---------------------------------------------------------------------------
# [LSURV-004] Fatigue increases via accumulate_fatigue
# ---------------------------------------------------------------------------

func test_fatigue_increases_on_accumulate_lsurv004():
	var before: float = _survival.fatigue
	_survival.accumulate_fatigue(5.0)
	assert_gt(_survival.fatigue, before,
		"accumulate_fatigue must increase fatigue [LSURV-004]")


func test_fatigue_clamps_to_max_lsurv004():
	var f_max: float = 100.0
	_survival.fatigue = f_max - 1.0
	_survival.accumulate_fatigue(999.0)
	assert_lte(_survival.fatigue, f_max,
		"Fatigue must not exceed max (100.0) [LSURV-004]")


func test_high_fatigue_reduces_stamina_regen_multiplier_lsurv004():
	_survival.fatigue = 80.0  # above high_threshold (70)
	var mult: float = _survival.get_stamina_regen_multiplier()
	assert_lt(mult, 1.0,
		"Stamina regen multiplier must be < 1.0 at high fatigue [LSURV-004]")
	assert_almost_eq(mult, 0.6, 0.001,
		"Stamina regen multiplier must be 0.6 at high fatigue [LSURV-004]")


# ---------------------------------------------------------------------------
# Sleep depletion — apply_sleep_hunger_thirst
# ---------------------------------------------------------------------------

func test_sleep_drains_hunger_by_correct_amount():
	_survival.hunger = 100.0
	_survival.apply_sleep_hunger_thirst()
	var expected_drain: float = HUNGER_DRAIN_PER_SEC * 28800.0  # 8 hours
	var expected: float = max(0.0, 100.0 - expected_drain)
	assert_almost_eq(_survival.hunger, expected, 0.01,
		"apply_sleep_hunger_thirst must drain 8h worth of hunger (%.2f)" % expected_drain)


func test_sleep_drains_thirst_by_correct_amount():
	_survival.thirst = 100.0
	_survival.apply_sleep_hunger_thirst()
	var expected_drain: float = THIRST_DRAIN_PER_SEC * 28800.0  # 8 hours
	var expected: float = max(0.0, 100.0 - expected_drain)
	assert_almost_eq(_survival.thirst, expected, 0.01,
		"apply_sleep_hunger_thirst must drain 8h worth of thirst (%.2f)" % expected_drain)


func test_sleep_thirst_drain_greater_than_hunger_drain():
	_survival.hunger = 100.0
	_survival.thirst = 100.0
	_survival.apply_sleep_hunger_thirst()
	var thirst_lost: float = 100.0 - _survival.thirst
	var hunger_lost: float = 100.0 - _survival.hunger
	assert_gt(thirst_lost, hunger_lost,
		"Thirst must drain more than hunger over a full sleep period")


func test_reset_fatigue_sets_to_zero():
	_survival.fatigue = 75.0
	_survival.reset_fatigue()
	assert_almost_eq(_survival.fatigue, 0.0, 0.001,
		"reset_fatigue must set fatigue to 0.0 after sleep")


# ---------------------------------------------------------------------------
# Direct consume methods
# ---------------------------------------------------------------------------

func test_consume_hunger_reduces_by_amount():
	_survival.hunger = 80.0
	_survival.consume_hunger(30.0)
	assert_almost_eq(_survival.hunger, 50.0, 0.001,
		"consume_hunger(30) must reduce hunger from 80 to 50")


func test_consume_thirst_reduces_by_amount():
	_survival.thirst = 60.0
	_survival.consume_thirst(20.0)
	assert_almost_eq(_survival.thirst, 40.0, 0.001,
		"consume_thirst(20) must reduce thirst from 60 to 40")


func test_consume_hunger_clamps_to_zero():
	_survival.hunger = 5.0
	_survival.consume_hunger(100.0)
	assert_almost_eq(_survival.hunger, 0.0, 0.001,
		"consume_hunger past 0 must clamp to 0.0")


func test_consume_thirst_clamps_to_zero():
	_survival.thirst = 5.0
	_survival.consume_thirst(100.0)
	assert_almost_eq(_survival.thirst, 0.0, 0.001,
		"consume_thirst past 0 must clamp to 0.0")


# ---------------------------------------------------------------------------
# Encumbrance
# ---------------------------------------------------------------------------

func test_over_max_carry_is_encumbered():
	var max_carry: float = _survival.get_max_carry_weight()
	_survival.update_encumbrance(max_carry + 0.1)
	assert_true(_survival.is_over_encumbered(),
		"0.1 kg over max_carry must trigger is_over_encumbered")


func test_at_hard_cap():
	var hard_cap: float = _survival.get_hard_carry_limit()
	_survival.update_encumbrance(hard_cap)
	assert_true(_survival.is_at_hard_cap(),
		"Weight at hard cap must trigger is_at_hard_cap")


func test_under_carry_weight_not_encumbered():
	_survival.update_encumbrance(1.0)
	assert_false(_survival.is_over_encumbered(),
		"1 kg must not be over-encumbered")
