## SaveManager
## Autoload singleton. Handles serializing and deserializing complete game state to/from JSON.
extends Node

const SAVE_DIR := "user://saves/"
const AUTO_SAVE_SLOT := "autosave"

signal save_completed(slot: String)
signal load_completed(slot: String)
signal save_failed(reason: String)
signal load_failed(reason: String)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func save_game(slot: String = AUTO_SAVE_SLOT) -> void:
	var data := _build_save_data()
	var json_text := JSON.stringify(data, "\t")
	var path := SAVE_DIR + slot + ".json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		save_failed.emit("Cannot open file for writing: " + path)
		return
	file.store_string(json_text)
	file.close()
	print("[SaveManager] Game saved to: " + path)
	save_completed.emit(slot)


func load_game(slot: String = AUTO_SAVE_SLOT) -> bool:
	var path := SAVE_DIR + slot + ".json"
	if not FileAccess.file_exists(path):
		load_failed.emit("Save file not found: " + path)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		load_failed.emit("Cannot open file: " + path)
		return false
	var text := file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if data == null:
		load_failed.emit("Corrupt save file: " + path)
		return false
	_apply_save_data(data)
	load_completed.emit(slot)
	return true


func get_save_slots() -> Array:
	var slots := []
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return slots
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".json"):
			slots.append(fname.replace(".json", ""))
		fname = dir.get_next()
	return slots


func delete_save(slot: String) -> void:
	var path := SAVE_DIR + slot + ".json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _build_save_data() -> Dictionary:
	var player_node = get_tree().get_first_node_in_group("player")
	var player_data := {}
	if player_node and player_node.has_method("get_save_data"):
		player_data = player_node.get_save_data()

	return {
		"version": 1,
		"timestamp": Time.get_unix_time_from_system(),
		"world_seed": GameState.world_seed,
		"precursor_assignments": GameState.precursor_assignments,
		"current_day": GameState.current_day,
		"current_season_index": GameState.current_season_index,
		"time_of_day": GameState.time_of_day,
		"current_weather": GameState.current_weather,
		"global_export_value": GameState.global_export_value,
		"named_landmarks": GameState.named_landmarks,
		"home_storage": GameState.home_storage.duplicate(true),
		"player": player_data,
		"settlements": SettlementManager.get_save_data(),
		"disciplines": DisciplineManager.get_save_data(),
	}


func _apply_save_data(data: Dictionary) -> void:
	GameState.world_seed = data.get("world_seed", randi())
	GameState.precursor_assignments = data.get("precursor_assignments", {})
	GameState.current_day = data.get("current_day", 1)
	GameState.current_season_index = data.get("current_season_index", 0)
	GameState.time_of_day = data.get("time_of_day", 6.0)
	GameState.current_weather = data.get("current_weather", "clear")
	GameState.global_export_value = data.get("global_export_value", 0)
	GameState.named_landmarks = data.get("named_landmarks", {})
	GameState.home_storage = data.get("home_storage", [])

	SettlementManager.apply_save_data(data.get("settlements", {}))
	DisciplineManager.apply_save_data(data.get("disciplines", {}))

	var player_node = get_tree().get_first_node_in_group("player")
	if player_node and player_node.has_method("apply_save_data"):
		player_node.apply_save_data(data.get("player", {}))
