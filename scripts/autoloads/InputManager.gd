## InputManager
## Autoload singleton. Manages keybindings loaded from JSON (LCORE-006..007).
## On startup loads user://input_config.json; falls back to res://data/default_input.json.
## Callers use get_action_key() to read bindings and remap_action() to change them.
extends Node

const USER_CONFIG_PATH    := "user://input_config.json"
const DEFAULT_CONFIG_PATH := "res://data/default_input.json"

## action -> human-readable key string (e.g. "W", "Space", "Left Shift")
var _bindings: Dictionary = {}

## Raw default bindings loaded at startup (used for reset_to_defaults).
var _default_bindings: Dictionary = {}


func _ready() -> void:
	_load_defaults()
	_load_user_config()


# --- Public API ---

## Return the display string for the key currently mapped to action.
func get_action_key(action: String) -> String:
	return _bindings.get(action, "")


## Remap an action to a new InputEvent. Also updates the Godot InputMap at runtime.
func remap_action(action: String, event: InputEvent) -> void:
	if not InputMap.has_action(action):
		push_warning("[InputManager] remap_action: unknown action '%s'" % action)
		return
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	_bindings[action] = _event_to_label(event)
	save_config()


## Persist current bindings to user://input_config.json.
func save_config() -> void:
	var file := FileAccess.open(USER_CONFIG_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[InputManager] Could not open user config for writing: " + USER_CONFIG_PATH)
		return
	file.store_string(JSON.stringify(_bindings, "\t"))
	file.close()


## Discard user overrides and restore factory defaults.
func reset_to_defaults() -> void:
	_bindings = _default_bindings.duplicate()
	_apply_bindings_to_inputmap()
	save_config()


# --- Private helpers ---

func _load_defaults() -> void:
	var file := FileAccess.open(DEFAULT_CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_warning("[InputManager] No default input config at: " + DEFAULT_CONFIG_PATH)
		return
	var text := file.get_as_text()
	file.close()
	var parsed := JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		push_error("[InputManager] Failed to parse default input config.")
		return
	_default_bindings = parsed
	_bindings = _default_bindings.duplicate()
	_apply_bindings_to_inputmap()


func _load_user_config() -> void:
	if not FileAccess.file_exists(USER_CONFIG_PATH):
		return
	var file := FileAccess.open(USER_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var parsed := JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		push_warning("[InputManager] User config parse failed — using defaults.")
		return
	# Merge: user overrides shadow defaults, unknown actions are ignored.
	for action in parsed:
		if _default_bindings.has(action):
			_bindings[action] = parsed[action]
	_apply_bindings_to_inputmap()
	print("[InputManager] User input config loaded.")


## Sync _bindings label strings back to the Godot InputMap.
## This only re-applies keyboard bindings stored as plain key names.
func _apply_bindings_to_inputmap() -> void:
	for action in _bindings:
		if not InputMap.has_action(action):
			continue
		var key_name: String = _bindings[action]
		var keycode := OS.find_keycode_from_string(key_name)
		if keycode == KEY_NONE:
			continue
		var event := InputEventKey.new()
		event.keycode = keycode
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, event)


## Produce a human-readable label from an InputEvent (keyboard only for now).
func _event_to_label(event: InputEvent) -> String:
	if event is InputEventKey:
		return OS.get_keycode_string((event as InputEventKey).keycode)
	return "?"
