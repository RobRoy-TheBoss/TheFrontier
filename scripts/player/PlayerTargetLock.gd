## PlayerTargetLock
## L-Tab cycles through nearby monsters: press to lock, press to release,
## press again for the next closest. Camera tracks the locked target.
class_name PlayerTargetLock
extends Node

const LOCK_RADIUS  := 10.0
const TRACK_SPEED  := 8.0   # rad/s camera snap toward target

var locked_target: Node = null

var _player: CharacterBody3D
var _cycle_index: int = 0


func _ready() -> void:
	_player = get_parent()


func _process(delta: float) -> void:
	if GameState.is_paused_for_ui or GameState.is_sleeping:
		return
	if Input.is_action_just_pressed("lock_target"):
		_handle_press()
	if locked_target != null:
		_track_camera(delta)


func is_locked() -> bool:
	return locked_target != null and is_instance_valid(locked_target)


func _handle_press() -> void:
	if locked_target != null:
		# Release and advance cycle index so next press gets the next monster
		_cycle_index += 1
		locked_target = null
		return
	var candidates := _sorted_candidates()
	if candidates.is_empty():
		_cycle_index = 0
		return
	_cycle_index = _cycle_index % candidates.size()
	locked_target = candidates[_cycle_index]


func _sorted_candidates() -> Array:
	var result: Array = []
	for m in get_tree().get_nodes_in_group("monster"):
		if not is_instance_valid(m):
			continue
		if m.global_position.distance_to(_player.global_position) <= LOCK_RADIUS:
			result.append(m)
	var pp := _player.global_position
	result.sort_custom(func(a, b): return a.global_position.distance_to(pp) < b.global_position.distance_to(pp))
	return result


func _track_camera(delta: float) -> void:
	if not is_instance_valid(locked_target):
		locked_target = null
		return
	var to_target: Vector3 = (locked_target as Node3D).global_position - _player.global_position

	# Yaw: rotate camera pivot to face target horizontally
	var target_yaw := atan2(-to_target.x, -to_target.z)
	_player.camera_pivot.rotation.y = lerp_angle(
		_player.camera_pivot.rotation.y, target_yaw, TRACK_SPEED * delta)

	# Pitch: tilt spring arm to keep target vertically centred
	var flat_dist := Vector2(to_target.x, to_target.z).length()
	var mid_y     := (locked_target as Node3D).global_position.y + 1.0  # ~chest height
	var target_pitch := atan2(mid_y - _player.camera.global_position.y, flat_dist)
	_player.spring_arm.rotation.x = lerp_angle(
		_player.spring_arm.rotation.x, -target_pitch, TRACK_SPEED * delta)
	_player.spring_arm.rotation.x = clamp(
		_player.spring_arm.rotation.x, deg_to_rad(-60), deg_to_rad(20))
