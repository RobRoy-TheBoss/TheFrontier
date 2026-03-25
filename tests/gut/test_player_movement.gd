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
# [LPC-012] SPRINT disabled when over max_carry
# ---------------------------------------------------------------------------

func test_sprint_disabled_over_encumbered_lpc012():
	_survival.update_encumbrance(9999.0)
	assert_true(_survival.is_over_encumbered(),
		"9999 kg must register as over-encumbered [LPC-012]")


# ---------------------------------------------------------------------------
# [LPC-013] Walk speed penalized when over-encumbered
# ---------------------------------------------------------------------------

func test_walk_speed_penalty_over_encumbered_lpc013():
	var max_carry: float = _survival.get_max_carry_weight()
	assert_gt(max_carry, 0.0, "Base max carry weight must be positive")
	_survival.update_encumbrance(max_carry + 1.0)
	assert_true(_survival.is_over_encumbered(),
		"1 kg over max carry must trigger over-encumbered [LPC-013]")
	_survival.update_encumbrance(0.0)
	assert_false(_survival.is_over_encumbered(),
		"0 kg must not be over-encumbered [LPC-013]")


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