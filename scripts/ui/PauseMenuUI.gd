## PauseMenuUI
## Pause overlay triggered by ESC. Entry point for save/load and settings.
## Pauses the scene tree while open (except UI).
extends Control

@onready var resume_button: Button = $Panel/VBox/ResumeButton
@onready var save_load_button: Button = $Panel/VBox/SaveLoadButton
@onready var settings_button: Button = $Panel/VBox/SettingsButton
@onready var quit_button: Button = $Panel/VBox/QuitButton


func _ready() -> void:
	add_to_group("pause_menu_ui")
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(_resume)
	save_load_button.pressed.connect(_open_save_slot)
	settings_button.pressed.connect(_open_settings)
	quit_button.pressed.connect(_quit)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_resume()
		elif _close_any_open_ui():
			pass
		else:
			_pause()
		get_viewport().set_input_as_handled()


func _close_any_open_ui() -> bool:
	var groups: Array[String] = [
		"inventory_ui", "hero_ui", "journal_ui", "discipline_ui", "map_ui", "storage_ui"
	]
	for group in groups:
		var ui := get_tree().get_first_node_in_group(group)
		if ui and ui.visible:
			if ui.has_method("close"):
				ui.close()
			elif ui.has_method("toggle"):
				ui.toggle()
			return true
	return false


func _pause() -> void:
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	GameState.is_paused_for_ui = true


func _resume() -> void:
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	GameState.is_paused_for_ui = false


func _open_save_slot() -> void:
	var ui = get_tree().get_first_node_in_group("save_slot_ui")
	if ui:
		visible = false
		ui.open(self)


func _open_settings() -> void:
	var ui = get_tree().get_first_node_in_group("settings_ui")
	if ui:
		ui.open()


func _quit() -> void:
	get_tree().paused = false
	get_tree().quit()
