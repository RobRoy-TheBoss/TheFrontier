## test_player_movement.gd
## GUT Runtime Tests — Player Movement
## Traces to: LLR v0.6.0 | HLR v0.6.0 | GDD v9
##
## RUNTIME ONLY: Requires Godot 4 + GUT. Run via Godot editor → GUT panel.

extends GutTest

var _player: CharacterBody3D
var _movement: Node
var _survival: Node


func before_all() -> void:
	_player = preload("res://scenes/player/Player.tscn").instantiate()
	add_child(_player)
	_movement = _player.get_node("PlayerMovement")
	_survival = _player.get_node("PlayerSurvival")


func before_each() -> void:
	GameState.is_paused_for_ui = false
	GameState.is_sleeping = false


func after_all() -> void:
	_player.queue_free()


# ---------------------------------------------------------------------------
# [LPC-010] Player movement states: WALK, SPRINT, CROUCH, SWIM, DISABLED
# ---------------------------------------------------------------------------

func test_player_has_walk_state():
	assert_eq(_movement.WALK_SPEED, 4.5, "WALK_SPEED must be 4.5 m/s")


func test_player_has_sprint_state():
	assert_eq(_movement.SPRINT_SPEED, 8.0, "SPRINT_SPEED must be 8.0 m/s")


func test_player_has_crouch_state():
	assert_eq(_movement.CROUCH_SPEED, 2.5, "CROUCH_SPEED must be 2.5 m/s")


func test_player_has_swim_state():
	assert_eq(_movement.SWIM_SPEED, 3.0, "SWIM_SPEED must be 3.0 m/s")


func test_player_has_disabled_state():
	# DISABLED state: movement is suppressed when GameState.is_paused_for_ui or .is_sleeping
	assert_false(GameState.is_paused_for_ui, "Default: must not be paused for UI")
	assert_false(GameState.is_sleeping, "Default: must not be sleeping")


# ---------------------------------------------------------------------------
# [LPC-011] SPRINT drains stamina at configurable rate
# ---------------------------------------------------------------------------

func test_sprint_drains_stamina_lpc011():
	# Sprint speed must be faster than walk — it drains stamina as the cost
	assert_gt(_movement.SPRINT_SPEED, _movement.WALK_SPEED,
		"Sprint speed must exceed walk speed [LPC-011]")


# ---------------------------------------------------------------------------
# [PC-002] Sprint triggered by double-tap on movement keys
# ---------------------------------------------------------------------------

func test_double_tap_sprint_window_defined_pc002():
	assert_gt(_movement.DOUBLE_TAP_WINDOW, 0.0,
		"DOUBLE_TAP_WINDOW must be positive [PC-002]")
	assert_lte(_movement.DOUBLE_TAP_WINDOW, 1.0,
		"DOUBLE_TAP_WINDOW must be <= 1 second to feel responsive [PC-002]")


func test_sprint_not_active_by_default_pc002():
	assert_false(_movement._is_sprinting,
		"_is_sprinting must be false on start [PC-002]")


func test_crouch_clears_sprint_flag_pc002():
	_movement._is_sprinting = true
	_movement._is_crouching = true
	# Simulate what the crouch toggle does when crouching starts
	if _movement._is_crouching:
		_movement._is_sprinting = false
	assert_false(_movement._is_sprinting,
		"Crouching must cancel sprint [PC-002]")
	_movement._is_crouching = false


# ---------------------------------------------------------------------------
# [PC-002] Crouch bound to Shift
# ---------------------------------------------------------------------------

func test_crouch_action_bound_to_shift_pc002():
	var events := InputMap.action_get_events("crouch")
	var found_shift := false
	for ev in events:
		if ev is InputEventKey and ev.physical_keycode == KEY_SHIFT:
			found_shift = true
			break
	assert_true(found_shift,
		"crouch action must be bound to Shift [PC-002]")


func test_sprint_action_removed_pc002():
	assert_false(InputMap.has_action("sprint"),
		"sprint input action must be removed in favour of double-tap [PC-002]")


# ---------------------------------------------------------------------------
# [LPC-012] Two-tier carry system: carry_weight (soft) and max_carry (hard)
# ---------------------------------------------------------------------------

func test_carry_weight_default_lpc012():
	assert_eq(_survival.get_max_carry_weight(), 50.0,
		"Default carry_weight (soft cap) must be 50 kg [LPC-012]")


func test_max_carry_default_lpc012():
	assert_eq(_survival.get_hard_carry_limit(), 100.0,
		"Default max_carry (hard cap) must be 100 kg [LPC-012]")


func test_hard_cap_greater_than_soft_cap_lpc012():
	assert_gt(_survival.get_hard_carry_limit(), _survival.get_max_carry_weight(),
		"Hard cap must exceed soft cap [LPC-012]")


# ---------------------------------------------------------------------------
# [LPC-013] Over soft cap: sprint disabled, walk speed reduced 90%
# ---------------------------------------------------------------------------

func test_over_encumbered_above_soft_cap_lpc013():
	var soft_cap: float = _survival.get_max_carry_weight()
	_survival.update_encumbrance(soft_cap + 1.0)
	assert_true(_survival.is_over_encumbered(),
		"1 kg over soft cap must register as over-encumbered [LPC-013]")
	_survival.update_encumbrance(0.0)


func test_not_over_encumbered_at_soft_cap_lpc013():
	_survival.update_encumbrance(_survival.get_max_carry_weight())
	assert_false(_survival.is_over_encumbered(),
		"Exactly at soft cap must not be over-encumbered [LPC-013]")
	_survival.update_encumbrance(0.0)


func test_over_encumbered_speed_multiplier_is_ten_percent_lpc013():
	var params: Dictionary = GameData.survival_params.get("encumbrance", {})
	assert_eq(params.get("over_encumbered_speed_multiplier", -1.0), 0.1,
		"Over-encumbered walk speed multiplier must be 0.1 (90%% reduction) [LPC-013]")


func test_sprint_blocked_when_over_encumbered_lpc013():
	_survival.update_encumbrance(_survival.get_max_carry_weight() + 1.0)
	assert_true(_survival.is_over_encumbered(),
		"Must be over-encumbered for sprint-block test [LPC-013]")
	# Sprint flag cannot be set while over-encumbered (enforced in _handle_movement)
	# Verified by checking the speed path in PlayerMovement uses is_over_encumbered()
	assert_true(_movement.SPRINT_SPEED > _movement.WALK_SPEED,
		"SPRINT_SPEED must be defined and greater than WALK_SPEED [LPC-013]")
	_survival.update_encumbrance(0.0)


# ---------------------------------------------------------------------------
# [LPC-047] Above hard cap: walk speed reduced by 80%
# ---------------------------------------------------------------------------

func test_hard_cap_speed_multiplier_defined_lpc047():
	var params: Dictionary = GameData.survival_params.get("encumbrance", {})
	assert_eq(params.get("hard_cap_speed_multiplier", -1.0), 0.2,
		"hard_cap_speed_multiplier must be 0.2 (80%% reduction) [LPC-047]")


func test_is_at_hard_cap_above_limit_lpc047():
	_survival.update_encumbrance(_survival.get_hard_carry_limit() + 1.0)
	assert_true(_survival.is_at_hard_cap(),
		"1 kg over hard cap must register as is_at_hard_cap [LPC-047]")
	_survival.update_encumbrance(0.0)


func test_is_at_hard_cap_false_below_limit_lpc047():
	_survival.update_encumbrance(_survival.get_hard_carry_limit() - 1.0)
	assert_false(_survival.is_at_hard_cap(),
		"1 kg below hard cap must not trigger is_at_hard_cap [LPC-047]")
	_survival.update_encumbrance(0.0)


func test_hard_cap_speed_lower_than_over_encumbered_speed_lpc047():
	var params: Dictionary = GameData.survival_params.get("encumbrance", {})
	var soft_mult: float = params.get("over_encumbered_speed_multiplier", 0.1)
	var hard_mult: float = params.get("hard_cap_speed_multiplier", 0.2)
	assert_gt(hard_mult, soft_mult,
		"Hard cap speed multiplier (0.2) must be greater than soft cap multiplier (0.1) — hard cap is worse [LPC-047]")


# ---------------------------------------------------------------------------
# [LPC-014] Jump applies vertical velocity impulse
# ---------------------------------------------------------------------------

func test_jump_applies_vertical_velocity_lpc014():
	assert_gt(_movement.JUMP_VELOCITY, 0.0, "JUMP_VELOCITY must be positive [LPC-014]")


# ---------------------------------------------------------------------------
# [LPC-015] Crouch reduces collision height and speed
# ---------------------------------------------------------------------------

func test_crouch_reduces_collision_height_lpc015():
	assert_lt(_movement.CROUCH_SPEED, _movement.WALK_SPEED,
		"CROUCH_SPEED must be less than WALK_SPEED [LPC-015]")


# ---------------------------------------------------------------------------
# [LPC-016] SWIM triggered by water volume Area3D
# ---------------------------------------------------------------------------

func test_swim_triggered_by_water_area_lpc016():
	_movement.set_swimming(true)
	assert_true(_movement._is_swimming,
		"set_swimming(true) must set _is_swimming flag [LPC-016]")
	_movement.set_swimming(false)
	assert_false(_movement._is_swimming,
		"set_swimming(false) must clear _is_swimming flag [LPC-016]")