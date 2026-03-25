## CampDeployer
## Handles the player deploying camp equipment (tent, campfire, alchemy set).
## Attached to Player node.
class_name CampDeployer
extends Node

const CAMP_SCENE := "res://scenes/camp/PlayerCamp.tscn"

var _player: Node = null
var _current_camp: Node = null


func _ready() -> void:
	_player = get_parent()


func _unhandled_input(event: InputEvent) -> void:
	if GameState.is_paused_for_ui or GameState.is_sleeping:
		return
	if event.is_action_pressed("deploy_camp"):
		_toggle_camp()
	if event.is_action_pressed("pack_up_camp"):
		_pack_up()


func _toggle_camp() -> void:
	if _current_camp != null:
		_pack_up()
		return
	_deploy_camp()


func _deploy_camp() -> void:
	var has_tent: bool = _player.inventory.has_item("tent")
	var has_campfire: bool = _player.inventory.has_item("campfire_kit")
	var has_alchemy: bool = _player.inventory.has_item("alchemy_set")

	if not has_tent and not has_campfire:
		# Nothing to deploy
		var hud: Node = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_message"):
			hud.show_message("You need a tent or campfire kit to make camp.")
		return

	# Remove from inventory
	if has_tent:
		_player.inventory.remove_item("tent", 1)
	if has_campfire:
		_player.inventory.remove_item("campfire_kit", 1)
	if has_alchemy:
		_player.inventory.remove_item("alchemy_set", 1)

	var camp_res: PackedScene = load(CAMP_SCENE) as PackedScene
	var camp: Node
	if camp_res:
		camp = camp_res.instantiate()
	else:
		# Fallback: create from script
		camp = Node3D.new()
		camp.set_script(load("res://scripts/world/PlayerCamp.gd"))

	camp.global_position = _player.global_position
	get_tree().root.add_child(camp)

	if camp.has_method("setup"):
		camp.setup(has_tent, has_campfire, has_alchemy)

	_current_camp = camp

	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_message"):
		var msg: String = "Camp established."
		if has_campfire:
			msg += " Campfire lit."
		if has_alchemy:
			msg += " Alchemy set ready."
		hud.show_message(msg)


func _pack_up() -> void:
	if _current_camp == null:
		return
	if _current_camp.has_method("pack_up"):
		_current_camp.pack_up()
	_current_camp = null


func get_current_camp() -> Node:
	return _current_camp
