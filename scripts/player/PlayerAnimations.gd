## PlayerAnimations
## Drives idle / walk / sprint / jump / crouch / swim / attack state on the
## AnimationPlayer inside CharacterModel (PlayerModel.tscn). Uses UAL library.
class_name PlayerAnimations
extends Node

# Map our state names to UAL/UAL2 animation paths.
# Note: Godot strips _Loop suffix on animation_library import.
const ANIM_MAP := {
	# UAL1 — locomotion
	"idle":         "ual/Idle",
	"run":          "ual/Walk",
	"sprint":       "ual/Sprint",
	"jump":         "ual/Jump",
	"crouch_idle":  "ual/Crouch_Idle",
	"crouch_walk":  "ual/Crouch_Fwd",
	"swim":         "ual/Swim_Fwd",
	"swim_idle":    "ual/Swim_Idle",
	"carry":        "ual2/Walk_Carry",
	"slide":        "ual2/Slide_Start",
	"roll":         "ual/Roll",
	# UAL1 — combat
	"attack":       "ual/Sword_Attack",
	"sword_idle":   "ual/Sword_Idle",
	"hit":          "ual/Hit_Chest",
	"death":        "ual/Death01",
	# UAL2 — combat
	"block":        "ual2/Sword_Block",
	"attack_a":     "ual2/Sword_Regular_A",
	"attack_b":     "ual2/Sword_Regular_B",
	"attack_c":     "ual2/Sword_Regular_C",
	"attack_combo": "ual2/Sword_Regular_Combo",
	"hit_knockback":"ual2/Hit_Knockback",
	"punch":        "ual2/Melee_Hook",
	# UAL2 — interaction
	"consume":      "ual2/Consume",
	"chop":         "ual2/TreeChopping",
	"chest_open":   "ual2/Chest_Open",
	"climb":        "ual2/ClimbUp_1m_RM",
}

var _player: CharacterBody3D
var _anim_player: AnimationPlayer
var _current: String = ""
var _one_shot_playing: bool = false


func _ready() -> void:
	_player = get_parent()
	await _player.ready
	_setup()


func _setup() -> void:
	_anim_player = _player.character_model.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if _anim_player == null:
		push_warning("PlayerAnimations: no AnimationPlayer found in CharacterModel")
		return

	# UAL loop animations should loop; one-shots stay as-is
	const LOOP_KEYS := ["idle", "run", "sprint", "jump", "crouch_idle", "crouch_walk",
		"swim", "swim_idle", "carry", "sword_idle", "chop"]
	for anim_key in LOOP_KEYS:
		var full_name: String = ANIM_MAP[anim_key]
		if _anim_player.has_animation(full_name):
			var anim: Animation = _anim_player.get_animation(full_name)
			anim.loop_mode = Animation.LOOP_LINEAR
		else:
			push_warning("PlayerAnimations: animation not found: %s" % full_name)

	_play("idle")


const ANIM_SPEED := {
	"run": 1.8,
	"sprint": 1.6,
	"crouch_walk": 1.4,
	"swim": 1.2,
	"carry": 1.4,
}

func _play(key: String) -> void:
	if not ANIM_MAP.has(key):
		return
	var full_name: String = ANIM_MAP[key]
	if _anim_player.has_animation(full_name):
		_anim_player.speed_scale = ANIM_SPEED.get(key, 1.0)
		_anim_player.play(full_name)
		_current = key


func play_once(key: String) -> void:
	if _anim_player == null:
		return
	if not ANIM_MAP.has(key):
		push_warning("PlayerAnimations: unknown key '%s'" % key)
		return
	var full_name: String = ANIM_MAP[key]
	if not _anim_player.has_animation(full_name):
		push_warning("PlayerAnimations: animation not found '%s'" % full_name)
		return
	_one_shot_playing = true
	_anim_player.speed_scale = ANIM_SPEED.get(key, 1.0)
	_anim_player.play(full_name)
	_current = key
	await _anim_player.animation_finished
	_one_shot_playing = false
	if _current == key:
		_play("idle")


func _process(_delta: float) -> void:
	if _anim_player == null or not _anim_player.is_inside_tree():
		return

	# Don't override one-shot animations in progress
	if _one_shot_playing:
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
