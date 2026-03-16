## PlayerMovement
## Handles first-person movement: walk, sprint, jump, crouch, swim.
## Consumes stamina from PlayerHealth on sprint/jump.
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
var _is_crouching: bool = false
var _is_swimming: bool = false
var _road_speed_bonus: float = 0.0


func _ready() -> void:
	_player = get_parent()
	await _player.ready
	_health = _player.health
	_survival = _player.survival


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

	# Crouch toggle
	if Input.is_action_just_pressed("crouch"):
		_is_crouching = not _is_crouching

	# Direction
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (_player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Speed selection
	var is_sprinting := Input.is_action_pressed("sprint") and not _is_crouching
	var over_enc := _survival.is_over_encumbered()

	var speed: float
	if _is_swimming:
		speed = SWIM_SPEED
	elif _is_crouching:
		speed = CROUCH_SPEED
	elif is_sprinting and not over_enc and _health.stamina > 5.0:
		speed = SPRINT_SPEED
		_health.drain_stamina(GameData.survival_params.get("stamina", {}).get("sprint_drain_per_second", 12.0) * delta)
		DisciplineManager.add_xp("survivalist", "off_road_travel_km")  # Incremental; tracked by distance
	elif over_enc:
		speed = WALK_SPEED * GameData.survival_params.get("encumbrance", {}).get("over_encumbered_speed_multiplier", 0.4)
	else:
		speed = WALK_SPEED

	# Apply road speed bonus
	speed *= (1.0 + _road_speed_bonus)

	# Weatherskin passive: no gameplay effect on movement, handled in survival

	if direction != Vector3.ZERO:
		_player.velocity.x = direction.x * speed
		_player.velocity.z = direction.z * speed
		# Fatigue gain from movement
		_survival.accumulate_fatigue(GameData.survival_params.get("fatigue", {}).get("gain_per_second_active", 0.003) * delta)
	else:
		_player.velocity.x = move_toward(_player.velocity.x, 0, speed)
		_player.velocity.z = move_toward(_player.velocity.z, 0, speed)
		_survival.accumulate_fatigue(GameData.survival_params.get("fatigue", {}).get("gain_per_second_idle", 0.001) * delta)

	_player.move_and_slide()


func set_road_speed_bonus(bonus: float) -> void:
	_road_speed_bonus = bonus


func set_swimming(swimming: bool) -> void:
	_is_swimming = swimming


func is_crouching() -> bool:
	return _is_crouching
