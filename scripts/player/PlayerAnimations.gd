## PlayerAnimations
## Drives idle / run / jump state on the AnimationPlayer that lives inside
## the CharacterModel (Player2.tscn). Animation libraries are named "idle",
## "run", "jump"; the actual animations inside are "Root|Idle", "Root|Run",
## "Root|Jump" — accessed as "idle/Root|Idle" etc. in Godot's library syntax.
class_name PlayerAnimations
extends Node

# Map our state names to the full library/animation path inside the player
const ANIM_MAP := {
	"idle": "idle/Root|Idle",
	"run":  "run/Root|Run",
	"jump": "jump/Root|Jump",
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

	for anim_key in ANIM_MAP:
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


func _process(_delta: float) -> void:
	if _anim_player == null or not _anim_player.is_inside_tree():
		return

	var on_floor := _player.is_on_floor()
	var hspeed := Vector2(_player.velocity.x, _player.velocity.z).length()

	var target: String
	if not on_floor:
		target = "jump"
	elif hspeed > 0.5:
		target = "run"
	else:
		target = "idle"

	if target != _current:
		_play(target)
