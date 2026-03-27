## test_camera_zoom.gd
## GUT Runtime Tests — Third-Person Adjustable Camera Zoom
## Traces to: PC-001
##
## RUNTIME ONLY: Requires Godot 4 + GUT. Run via Godot editor → GUT panel.

extends GutTest

var _player: CharacterBody3D
var _spring_arm: SpringArm3D
var _ray: RayCast3D


func before_all() -> void:
	_player = preload("res://scenes/player/Player.tscn").instantiate()
	add_child(_player)
	await get_tree().process_frame
	_spring_arm = _player.get_node("CameraPivot/SpringArm3D")
	_ray = _player.get_node("CameraPivot/SpringArm3D/Camera3D/InteractionRay")


func after_all() -> void:
	_player.queue_free()


# ---------------------------------------------------------------------------
# [PC-001] SpringArm3D present and at default length
# ---------------------------------------------------------------------------

func test_spring_arm_exists_pc001():
	assert_not_null(_spring_arm,
		"Player must have a SpringArm3D for third-person camera [PC-001]")


func test_default_zoom_within_bounds_pc001():
	var length: float = _spring_arm.spring_length
	assert_gte(length, _player.ZOOM_MIN,
		"Default spring_length must be >= ZOOM_MIN [PC-001]")
	assert_lte(length, _player.ZOOM_MAX,
		"Default spring_length must be <= ZOOM_MAX [PC-001]")


# ---------------------------------------------------------------------------
# [PC-001] Zoom constants are defined and sane
# ---------------------------------------------------------------------------

func test_zoom_min_defined_pc001():
	assert_gt(_player.ZOOM_MIN, 0.0,
		"ZOOM_MIN must be positive [PC-001]")


func test_zoom_max_greater_than_min_pc001():
	assert_gt(_player.ZOOM_MAX, _player.ZOOM_MIN,
		"ZOOM_MAX must exceed ZOOM_MIN [PC-001]")


func test_zoom_step_positive_pc001():
	assert_gt(_player.ZOOM_STEP, 0.0,
		"ZOOM_STEP must be positive [PC-001]")


# ---------------------------------------------------------------------------
# [PC-001] _adjust_zoom clamps spring_length within [ZOOM_MIN, ZOOM_MAX]
# ---------------------------------------------------------------------------

func test_zoom_in_decreases_spring_length_pc001():
	var before: float = _spring_arm.spring_length
	_player._adjust_zoom(-_player.ZOOM_STEP)
	assert_lt(_spring_arm.spring_length, before,
		"Zooming in must decrease spring_length [PC-001]")


func test_zoom_out_increases_spring_length_pc001():
	_spring_arm.spring_length = _player.ZOOM_MIN + _player.ZOOM_STEP
	var before: float = _spring_arm.spring_length
	_player._adjust_zoom(_player.ZOOM_STEP)
	assert_gt(_spring_arm.spring_length, before,
		"Zooming out must increase spring_length [PC-001]")


func test_zoom_cannot_exceed_max_pc001():
	_spring_arm.spring_length = _player.ZOOM_MAX
	_player._adjust_zoom(_player.ZOOM_STEP)
	assert_lte(_spring_arm.spring_length, _player.ZOOM_MAX,
		"spring_length must not exceed ZOOM_MAX [PC-001]")


func test_zoom_cannot_go_below_min_pc001():
	_spring_arm.spring_length = _player.ZOOM_MIN
	_player._adjust_zoom(-_player.ZOOM_STEP)
	assert_gte(_spring_arm.spring_length, _player.ZOOM_MIN,
		"spring_length must not go below ZOOM_MIN [PC-001]")


# ---------------------------------------------------------------------------
# [PC-001] Interaction ray stays in sync with zoom level
# ---------------------------------------------------------------------------

func test_ray_synced_after_zoom_in_pc001():
	_player._adjust_zoom(-_player.ZOOM_STEP)
	var expected_z: float = -(_spring_arm.spring_length + _player.INTERACTION_DISTANCE)
	assert_eq(_ray.target_position.z, expected_z,
		"InteractionRay target_position.z must equal -(spring_length + INTERACTION_DISTANCE) after zoom in [PC-001]")


func test_ray_synced_after_zoom_out_pc001():
	_spring_arm.spring_length = _player.ZOOM_MIN + _player.ZOOM_STEP
	_player._adjust_zoom(_player.ZOOM_STEP)
	var expected_z: float = -(_spring_arm.spring_length + _player.INTERACTION_DISTANCE)
	assert_almost_eq(_ray.target_position.z, expected_z, 0.001,
		"InteractionRay target_position.z must equal -(spring_length + INTERACTION_DISTANCE) after zoom out [PC-001]")


func test_ray_synced_at_max_zoom_pc001():
	_spring_arm.spring_length = _player.ZOOM_MAX
	_player._adjust_zoom(0.0)
	var expected_z: float = -(_player.ZOOM_MAX + _player.INTERACTION_DISTANCE)
	assert_eq(_ray.target_position.z, expected_z,
		"InteractionRay must remain synced at ZOOM_MAX [PC-001]")


func test_ray_synced_at_min_zoom_pc001():
	_spring_arm.spring_length = _player.ZOOM_MIN
	_player._adjust_zoom(0.0)
	var expected_z: float = -(_player.ZOOM_MIN + _player.INTERACTION_DISTANCE)
	assert_eq(_ray.target_position.z, expected_z,
		"InteractionRay must remain synced at ZOOM_MIN [PC-001]")
