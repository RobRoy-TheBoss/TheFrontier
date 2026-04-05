## PlayerAnimations
## Drives idle / walk / sprint / jump / crouch / swim / attack state on the
## AnimationPlayer inside CharacterModel (PlayerModel.tscn). Uses UAL library.
class_name PlayerAnimations
extends Node

# Map our state names to UAL animation paths (library "ual")
# Note: Godot strips _Loop suffix on animation_library import
const ANIM_MAP := {
	"idle":         "ual/Idle",
	"run":          "ual/Walk",
	"sprint":       "ual/Sprint",
	"jump":         "ual/Jump",
	"crouch_idle":  "ual/Crouch_Idle",
	"crouch_walk":  "ual/Crouch_Fwd",
	"swim":         "ual/Swim_Fwd",
	"swim_idle":    "ual/Swim_Idle",
	"attack":       "ual/Sword_Attack",
	"hit":          "ual/Hit_Chest",
	"death":        "ual/Death01",
}

var _player: CharacterBody3D
var _anim_player: AnimationPlayer
var _current: String = ""


func _ready() -> void:
	_player = get_parent()
	await _player.ready
	_setup()


func _setup() -> void:
	_anim_player = _player.character_model.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if _anim_player == null:
		push_warning("PlayerAnimations: no AnimationPlayer found in CharacterModel")
		return

	# Point root at Armature so UAL tracks can find Skeleton3D beneath it.
	# The editor resets root_node to ".." on save, so we set it here instead.
	var armature: Node = _player.character_model.get_node_or_null("Armature")
	if armature:
		_anim_player.root_node = _anim_player.get_path_to(armature)

	# UAL loop animations should loop; one-shots (attack, hit, death) stay as-is
	const LOOP_KEYS := ["idle", "run", "sprint", "jump", "crouch_idle", "crouch_walk", "swim", "swim_idle"]
	for anim_key in LOOP_KEYS:
		var full_name: String = ANIM_MAP[anim_key]
		if _anim_player.has_animation(full_name):
			var anim: Animation = _anim_player.get_animation(full_name)
			anim.loop_mode = Animation.LOOP_LINEAR
		else:
			push_warning("PlayerAnimations: animation not found: %s" % full_name)

	_play("idle")


func _play(key: String) -> void:
	if not ANIM_MAP.has(key):
		return
	var full_name: String = ANIM_MAP[key]
	if _anim_player.has_animation(full_name):
		_anim_player.play(full_name)
		_current = key


func play_once(key: String) -> void:
	if _anim_player == null:
		return
	if not ANIM_MAP.has(key):
		return
	var full_name: String = ANIM_MAP[key]
	if _anim_player.has_animation(full_name):
		_anim_player.play(full_name)
		_current = key
		# Return to idle when done
		await _anim_player.animation_finished
		if _current == key:
			_play("idle")


func _process(_delta: float) -> void:
	if _anim_player == null or not _anim_player.is_inside_tree():
		return

	# Don't override one-shot animations in progress
	if _current in ["attack", "hit", "death"]:
		return

	var movement: PlayerMovement = _player.get_node_or_null("PlayerMovement")
	var on_floor := _player.is_on_floor()
	var hspeed := Vector2(_player.velocity.x, _player.velocity.z).length()
	var is_crouching: bool = movement != null and movement.is_crouching()
	var is_sprinting: bool = hspeed > 6.0

	var target: String
	if not on_floor:
		target = "jump"
	elif is_crouching:
		target = "crouch_walk" if hspeed > 0.3 else "crouch_idle"
	elif hspeed > 0.5:
		target = "sprint" if is_sprinting else "run"
	else:
		target = "idle"

	if target != _current:
		_play(target)
