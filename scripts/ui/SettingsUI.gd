## SettingsUI
## In-game settings: audio volumes, display mode, graphics quality, keybindings.
## Opened from PauseMenuUI. Changes apply immediately; audio via AudioServer.
extends Control

@onready var master_slider: HSlider = $Panel/VBox/Audio/MasterSlider
@onready var music_slider: HSlider = $Panel/VBox/Audio/MusicSlider
@onready var sfx_slider: HSlider = $Panel/VBox/Audio/SFXSlider
@onready var window_option: OptionButton = $Panel/VBox/Display/WindowOption
@onready var graphics_option: OptionButton = $Panel/VBox/Display/GraphicsOption
@onready var keybindings_list: VBoxContainer = $Panel/VBox/KeybindingsScroll/KeybindingsList
@onready var reset_keys_button: Button = $Panel/VBox/ResetKeysButton
@onready var close_button: Button = $Panel/VBox/CloseButton

# Bus indices — matches project.godot AudioServer bus order
const BUS_MASTER := 0
const BUS_MUSIC  := 1
const BUS_SFX    := 2


func _ready() -> void:
	add_to_group("settings_ui")
	visible = false
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	window_option.item_selected.connect(_on_window_changed)
	graphics_option.item_selected.connect(_on_graphics_changed)
	reset_keys_button.pressed.connect(_on_reset_keys)
	close_button.pressed.connect(_close)


func open() -> void:
	_populate_sliders()
	_populate_window_option()
	_populate_graphics_option()
	_populate_keybindings()
	visible = true


func _populate_sliders() -> void:
	master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(BUS_MASTER))
	music_slider.value  = db_to_linear(AudioServer.get_bus_volume_db(BUS_MUSIC))
	sfx_slider.value    = db_to_linear(AudioServer.get_bus_volume_db(BUS_SFX))


func _populate_window_option() -> void:
	window_option.clear()
	window_option.add_item("Windowed")
	window_option.add_item("Fullscreen")
	window_option.add_item("Borderless")
	var mode := DisplayServer.window_get_mode()
	match mode:
		DisplayServer.WINDOW_MODE_WINDOWED:
			window_option.selected = 0
		DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			window_option.selected = 1
		_:
			window_option.selected = 2


func _populate_graphics_option() -> void:
	graphics_option.clear()
	graphics_option.add_item("Low")
	graphics_option.add_item("Medium")
	graphics_option.add_item("High")
	# Default to medium; could be persisted in a user config later
	graphics_option.selected = 1


func _populate_keybindings() -> void:
	for child in keybindings_list.get_children():
		child.queue_free()

	var actions := [
		"move_forward", "move_backward", "move_left", "move_right",
		"jump", "sprint", "interact", "attack", "block",
		"open_inventory", "open_map", "open_journal",
		"use_ability_1", "use_ability_2", "use_ability_3", "use_ability_4",
		"sleep", "deploy_camp", "scan"
	]
	for action in actions:
		var key_label: String = InputManager.get_action_key(action)
		if key_label == "":
			key_label = "(unbound)"
		var row := HBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = action.replace("_", " ").capitalize()
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var key_lbl := Label.new()
		key_lbl.text = key_label
		row.add_child(name_lbl)
		row.add_child(key_lbl)
		keybindings_list.add_child(row)


func _on_master_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(BUS_MASTER, linear_to_db(value))


func _on_music_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(BUS_MUSIC, linear_to_db(value))


func _on_sfx_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(BUS_SFX, linear_to_db(value))


func _on_window_changed(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_graphics_changed(_index: int) -> void:
	# Placeholder — hook into renderer quality settings when terrain is added
	pass


func _on_reset_keys() -> void:
	InputManager.reset_to_defaults()
	_populate_keybindings()


func _close() -> void:
	visible = false
