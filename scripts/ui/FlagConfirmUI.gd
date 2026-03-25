## FlagConfirmUI
## Shown when player plants a settlement flag. Displays area resources summary
## and reminds player they must return to report.
extends Control

const _SettlementFlag := preload("res://scripts/settlement/SettlementFlag.gd")

@onready var area_label: Label = $Panel/AreaLabel
@onready var resources_list: VBoxContainer = $Panel/ResourcesList
@onready var instruction_label: Label = $Panel/InstructionLabel
@onready var confirm_button: Button = $Panel/ConfirmButton

var _area_id: String = ""
var _pending_flag: _SettlementFlag = null


func _ready() -> void:
	add_to_group("flag_confirm_ui")
	visible = false
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_pressed)


func show_flag_planted(area_id: String, resources: Dictionary) -> void:
	_area_id = area_id
	visible = true
	GameState.is_paused_for_ui = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if area_label:
		area_label.text = "Flag planted in: %s" % area_id.replace("_", " ").capitalize()

	if resources_list:
		for child in resources_list.get_children():
			child.queue_free()
		if resources.is_empty():
			var lbl := Label.new()
			lbl.text = "No resources surveyed in this area."
			resources_list.add_child(lbl)
		else:
			for res_id in resources:
				var lbl := Label.new()
				lbl.text = "• %s (richness: %.1f)" % [res_id.replace("_", " ").capitalize(), resources[res_id]]
				resources_list.add_child(lbl)

	if instruction_label:
		instruction_label.text = "Return to the settlement where you purchased this flag and report to found the settlement.\n\nWARNING: If you die before reporting, the flag is destroyed."

	# Spawn the flag object in the world
	_spawn_flag()


func _spawn_flag() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var flag_scene: PackedScene = load("res://scenes/items/SettlementFlag.tscn") as PackedScene
	if flag_scene == null:
		return
	var flag: Node = flag_scene.instantiate()
	flag.initialize(_area_id, _find_purchase_settlement())
	flag.global_position = player.global_position
	get_tree().root.add_child(flag)
	_pending_flag = flag


func _find_purchase_settlement() -> String:
	# The flag was purchased from somewhere — track via player meta or find nearest
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_meta("last_settlement_visited"):
		return player.get_meta("last_settlement_visited")
	return "crestport"


func _on_confirm_pressed() -> void:
	visible = false
	GameState.is_paused_for_ui = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
