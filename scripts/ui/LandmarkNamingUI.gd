## LandmarkNamingUI
## Text input for naming a discovered landmark.
## Landmark.interact() calls show_for_landmark(self).
extends Control

@onready var name_input: LineEdit = $Panel/NameInput
@onready var current_label: Label = $Panel/CurrentLabel
@onready var confirm_button: Button = $Panel/ConfirmButton
@onready var cancel_button: Button = $Panel/CancelButton

var _landmark = null


func _ready() -> void:
	add_to_group("landmark_naming_ui")
	visible = false
	confirm_button.pressed.connect(_confirm)
	cancel_button.pressed.connect(_cancel)
	name_input.text_submitted.connect(func(_t): _confirm())


func show_for_landmark(landmark: Node) -> void:
	_landmark = landmark
	var existing: String = landmark.get_display_name()
	current_label.text = "Current name: %s" % existing
	name_input.text = ""
	name_input.placeholder_text = existing
	visible = true
	name_input.grab_focus()


func _confirm() -> void:
	if _landmark == null:
		return
	var new_name: String = name_input.text.strip_edges()
	if new_name == "":
		return
	_landmark.set_name_by_player(new_name)
	visible = false
	_landmark = null


func _cancel() -> void:
	visible = false
	_landmark = null
