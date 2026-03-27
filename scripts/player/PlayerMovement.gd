## PlayerMovement
## Handles first-person movement: walk, sprint, jump, crouch, swim.
## Consumes stamina from PlayerHealth on sprint/jump.
class_name PlayerMovement
extends Node

const WALK_SPEED := 4.5
const SPRINT_SPEED := 8.0
const CROUCH_SPEED := 2.5
const SWIM_SPEED := 3.0
const JUMP_VELOCITY := 5.0
const GRAVITY := 9.8

var _player: CharacterBody3D
var _health: PlayerHealth
var _survival: PlayerSurvival
var _camera_pivot: Node3D
var _body_mesh: Node3D
var _is_crouching: bool = false
var _is_swimming: bool = false
var _is_sprinting: bool = false
var _road_speed_bonus: float = 0.0

# Double-tap sprint detection
const DOUBLE_TAP_WINDOW := 0.3
var _last_tap_time: Dictionary = {
	"move_forward": -1.0, "move_backward": -1.0,
	"move_left": -1.0, "move_right": -1.0
}
var _sprint_actions: Array[String] = ["move_forward", "move_backward", "move_left", "move_right"]


func _ready() -> void:
	_player = get_parent()
	await _player.ready
	_health = _player.health
	_survival = _player.survival
	_camera_pivot = _player.camera_pivot
	_body_mesh = _player.character_model


func _physics_process(delta: float) -> void:
	if GameState.is_paused_for_ui or GameState.is_sleeping:
		return
	_handle_movement(delta)


func _handle_movement(delta: float) -> void:
	var on_floor := _player.is_on_floor()

	# Gravity
	if not on_floor and not _is_swimming:
		_player.velocity.y -= GRAVITY * delta

	# Jump
	if Input.is_action_just_pressed("jump") and on_floor and not _is_crouching:
		if _health.try_consume_stamina(10.0):
			_player.velocity.y = JUMP_VELOCITY

	# Crouch toggle (Shift)
	if Input.is_action_just_pressed("crouch"):
		_is_crouching = not _is_crouching
		if _is_crouching:
			_is_sprinting = false

	# Double-tap sprint detection
	_update_double_tap_sprint()

	# Direction — camera-relative
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := Vector3.ZERO
	if input_dir != Vector2.ZERO:
		var cb := _camera_pivot.global_transform.basis
		var fwd := Vector3(-cb.z.x, 0, -cb.z.z).normalized()
		var right := Vector3(cb.x.x, 0, cb.x.z).normalized()
		direction = (right * input_dir.x - fwd * input_dir.y).normalized()

	# Stop sprint if no movement input
	if Input.get_vector("move_left", "move_right", "move_forward", "move_backward") == Vector2.ZERO:
		_is_sprinting = false

	# Speed selection
	var over_enc := _survival.is_over_encumbered()

	var enc_params: Dictionary = GameData.survival_params.get("encumbrance", {})
	var at_hard_cap := _survival.is_at_hard_cap()

	var speed: float
	if _is_swimming:
		speed = SWIM_SPEED
	elif _is_crouching:
		speed = CROUCH_SPEED
	elif at_hard_cap:
		speed = WALK_SPEED * enc_params.get("hard_cap_speed_multiplier", 0.2)
	elif _is_sprinting and not over_enc and _health.stamina > 5.0:
		speed = SPRINT_SPEED
		_health.drain_stamina(enc_params.get("stamina", {}).get("sprint_drain_per_second", 12.0) * delta)
		DisciplineManager.add_xp("survivalist", "off_road_travel_km")
	elif over_enc:
		speed = WALK_SPEED * enc_params.get("over_encumbered_speed_multiplier", 0.1)
	else:
		speed = WALK_SPEED

	# Apply road speed bonus
	speed *= (1.0 + _road_speed_bonus)

	# Weatherskin passive: no gameplay effect on movement, handled in survival

	if direction != Vector3.ZERO:
		_player.velocity.x = direction.x * speed
		_player.velocity.z = direction.z * speed
		# Rotate body mesh to face movement direction (player node stays unrotated)
		var target_y := atan2(-direction.x, -direction.z) + PI
		_body_mesh.rotation.y = lerp_angle(_body_mesh.rotation.y, target_y, min(1.0, 10.0 * delta))
		# Fatigue gain from movement
		_survival.accumulate_fatigue(GameData.survival_params.get("fatigue", {}).get("gain_per_second_active", 0.003) * delta)
	else:
		_player.velocity.x = move_toward(_player.velocity.x, 0, speed)
		_player.velocity.z = move_toward(_player.velocity.z, 0, speed)
		_survival.accumulate_fatigue(GameData.survival_params.get("fatigue", {}).get("gain_per_second_idle", 0.001) * delta)

	_player.move_and_slide()


func _update_double_tap_sprint() -> void:
	if _is_crouching:
		return
	var now := Time.get_ticks_msec() / 1000.0
	for action in _sprint_actions:
		if Input.is_action_just_pressed(action):
			var last: float = _last_tap_time[action]
			if last >= 0.0 and (now - last) <= DOUBLE_TAP_WINDOW:
				_is_sprinting = true
			_last_tap_time[action] = now


func set_road_speed_bonus(bonus: float) -> void:
	_road_speed_bonus = bonus


func set_swimming(swimming: bool) -> void:
	_is_swimming = swimming


func is_crouching() -> bool:
	return _is_crouching
