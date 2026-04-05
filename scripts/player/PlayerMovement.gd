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
var _god_mode: bool = false
var god_mode: bool:
	get: return _god_mode

# Double-tap dodge detection
const DOUBLE_TAP_WINDOW := 0.3
const DODGE_SPEED := 10.0
const DODGE_DURATION := 0.5  # Matches PlayerCombat.DODGE_DURATION
var _last_tap_time: Dictionary = {
	"move_forward": -1.0, "move_backward": -1.0,
	"move_left": -1.0, "move_right": -1.0
}
var _dodge_actions: Array[String] = ["move_forward", "move_backward", "move_left", "move_right"]
var _dodge_timer: float = 0.0
var _dodge_direction: Vector3 = Vector3.ZERO


func _ready() -> void:
	_player = get_parent()
	await _player.ready
	_health = _player.health
	_survival = _player.survival
	_camera_pivot = _player.camera_pivot
	_body_mesh = _player.character_model
	_attach_weapon_to_hand()


func _attach_weapon_to_hand() -> void:
	var skeleton: Skeleton3D = _body_mesh.get_node_or_null("Armature/Skeleton3D") as Skeleton3D
	var wh: Node3D = _player.weapon_holder
	if skeleton == null or skeleton.find_bone("hand_r") < 0:
		# Fallback: parent to body mesh
		var saved := wh.global_transform
		wh.reparent(_body_mesh)
		wh.global_transform = saved
		return
	var attach := BoneAttachment3D.new()
	attach.name = "WeaponBoneAttach"
	attach.bone_name = "hand_r"
	skeleton.add_child(attach)
	wh.reparent(attach)
	wh.transform = Transform3D.IDENTITY
	wh.rotation_degrees = Vector3(-90.0, 0.0, 0)
	wh.position = Vector3(-0.05, 0.1, 0.2)


func _physics_process(delta: float) -> void:
	if GameState.is_paused_for_ui or GameState.is_sleeping:
		return
	if Input.is_action_just_pressed("god_mode"):
		_god_mode = not _god_mode
		print("GOD MODE: ", "ON" if _god_mode else "OFF")
	if _god_mode:
		_handle_god_movement(delta)
	else:
		_handle_movement(delta)


func _handle_god_movement(delta: float) -> void:
	const GOD_SPEED := WALK_SPEED * 5.0
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := Vector3.ZERO
	if input_dir != Vector2.ZERO:
		var cb: Basis = _camera_pivot.global_transform.basis
		var fwd := Vector3(-cb.z.x, 0, -cb.z.z).normalized()
		var right := Vector3(cb.x.x, 0, cb.x.z).normalized()
		direction = (right * input_dir.x - fwd * input_dir.y).normalized()
		_body_mesh.rotation.y = _camera_pivot.rotation.y + PI
	_player.velocity.x = direction.x * GOD_SPEED
	_player.velocity.z = direction.z * GOD_SPEED
	_player.velocity.y = 0.0
	if Input.is_action_pressed("jump"):
		_player.velocity.y = GOD_SPEED
	elif Input.is_action_pressed("crouch"):
		_player.velocity.y = -GOD_SPEED
	_player.move_and_slide()


func _handle_movement(delta: float) -> void:
	var on_floor := _player.is_on_floor()

	# Gravity
	if not on_floor and not _is_swimming:
		_player.velocity.y -= GRAVITY * delta

	# Tick dodge timer
	if _dodge_timer > 0.0:
		_dodge_timer -= delta
		var floor_normal := _player.get_floor_normal() if _player.is_on_floor() else Vector3.UP
		var slide_dir := _dodge_direction.slide(floor_normal).normalized()
		_player.velocity.x = slide_dir.x * DODGE_SPEED
		_player.velocity.z = slide_dir.z * DODGE_SPEED
		if not _player.is_on_floor():
			_player.velocity.y -= GRAVITY * delta
		_body_mesh.rotation.y = atan2(_dodge_direction.x, _dodge_direction.z)
		_player.move_and_slide()
		return

	# Jump
	if Input.is_action_just_pressed("jump") and on_floor and not _is_crouching:
		if _health.try_consume_stamina(10.0):
			_player.velocity.y = JUMP_VELOCITY

	# Crouch toggle
	if Input.is_action_just_pressed("crouch"):
		_is_crouching = not _is_crouching
		if _is_crouching:
			_is_sprinting = false

	# Double-tap sprint
	_update_double_tap_sprint()

	# Spacebar dodge
	if Input.is_action_just_pressed("dodge") and not _is_crouching:
		_trigger_dodge_from_input()

	if _dodge_timer > 0.0:
		_player.move_and_slide()
		return

	# Direction — camera-relative
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := Vector3.ZERO
	if input_dir != Vector2.ZERO:
		var cb: Basis = _camera_pivot.global_transform.basis
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

	# Injury movement speed
	speed *= _health.get_movement_speed_multiplier()

	var combat: PlayerCombat = _player.get_node_or_null("PlayerCombat") as PlayerCombat
	var is_attacking: bool = combat != null and combat.attack_cooldown > 0.0

	if is_attacking:
		_body_mesh.rotation.y = _camera_pivot.rotation.y + PI
		_player.velocity.x = move_toward(_player.velocity.x, 0, speed)
		_player.velocity.z = move_toward(_player.velocity.z, 0, speed)
	elif direction != Vector3.ZERO:
		_body_mesh.rotation.y = atan2(direction.x, direction.z)
		_player.velocity.x = direction.x * speed
		_player.velocity.z = direction.z * speed
		# Fatigue drain from movement
		_survival.accumulate_fatigue(GameData.survival_params.get("fatigue", {}).get("drain_per_second_active", 0.003) * delta)
	else:
		_player.velocity.x = move_toward(_player.velocity.x, 0, speed)
		_player.velocity.z = move_toward(_player.velocity.z, 0, speed)
		_survival.accumulate_fatigue(GameData.survival_params.get("fatigue", {}).get("drain_per_second_idle", 0.001) * delta)

	_player.move_and_slide()


func _update_double_tap_sprint() -> void:
	if _is_crouching:
		_is_sprinting = false
		return
	var now := Time.get_ticks_msec() / 1000.0
	for action in _dodge_actions:
		if Input.is_action_just_pressed(action):
			var last: float = _last_tap_time[action]
			if last >= 0.0 and (now - last) <= DOUBLE_TAP_WINDOW:
				_is_sprinting = true
			_last_tap_time[action] = now
	# Stop sprinting when no movement input
	if Input.get_vector("move_left", "move_right", "move_forward", "move_backward") == Vector2.ZERO:
		_is_sprinting = false


func _trigger_dodge_from_input() -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var cb: Basis = _camera_pivot.global_transform.basis
	var fwd := Vector3(-cb.z.x, 0, -cb.z.z).normalized()
	var right := Vector3(cb.x.x, 0, cb.x.z).normalized()
	var impulse: Vector3
	if input_dir != Vector2.ZERO:
		impulse = (right * input_dir.x - fwd * input_dir.y).normalized()
	else:
		impulse = -fwd  # Default: dodge backward
	_trigger_dodge_direction(impulse)


func _trigger_dodge_direction(impulse: Vector3) -> void:
	if not _player.is_on_floor() or _dodge_timer > 0.0:
		return
	var combat: Node = _player.get_node_or_null("PlayerCombat")
	if combat == null or not combat._try_dodge():
		return
	_dodge_direction = impulse
	_body_mesh.rotation.y = atan2(impulse.x, impulse.z)
	_player.velocity.x = impulse.x * DODGE_SPEED
	_player.velocity.z = impulse.z * DODGE_SPEED
	# No vertical hop — ground roll stays grounded
	_dodge_timer = DODGE_DURATION
	var anim: Node = _player.get_node_or_null("PlayerAnimations")
	if anim:
		anim.play_once("roll")


func set_road_speed_bonus(bonus: float) -> void:
	_road_speed_bonus = bonus


func set_swimming(swimming: bool) -> void:
	_is_swimming = swimming


func is_crouching() -> bool:
	return _is_crouching
