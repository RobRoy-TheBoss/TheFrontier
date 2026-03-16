## Landmark
## A nameable world feature. Player can name it, name persists in save and appears on maps.
extends Node3D

@export var landmark_id: String = "landmark_default"
@export var default_description: String = "A distinctive feature."
@export var is_visible_from_distance: float = 100.0

var _player_given_name: String = ""
var _discovered: bool = false

@onready var label: Label3D = $Label3D


func _ready() -> void:
	add_to_group("landmark")
	# Restore name from save
	var saved_name := GameState.get_landmark_name(landmark_id)
	if saved_name != "":
		_player_given_name = saved_name
		_discovered = true
		_update_label()


func interact(player: Node) -> void:
	_show_naming_ui()


func _show_naming_ui() -> void:
	var ui := get_tree().get_first_node_in_group("landmark_naming_ui")
	if ui and ui.has_method("show_for_landmark"):
		ui.show_for_landmark(self)


func set_name_by_player(player_name: String) -> void:
	_player_given_name = player_name
	_discovered = true
	WorldManager.name_landmark(landmark_id, player_name)
	_update_label()
	# Add to journal
	var journal := get_tree().get_first_node_in_group("field_journal")
	if journal and journal.has_method("record_landmark"):
		journal.record_landmark(landmark_id, player_name, global_position)


func _update_label() -> void:
	if label:
		label.text = _player_given_name if _player_given_name != "" else default_description


func get_display_name() -> String:
	return _player_given_name if _player_given_name != "" else default_description
