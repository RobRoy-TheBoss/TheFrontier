## GameState
## Autoload singleton. Tracks runtime game state: current season, day, time,
## weather, active area, and game-wide flags.
extends Node

signal day_changed(new_day: int)
signal season_changed(new_season: String)
signal weather_changed(new_weather: String)
signal time_of_day_changed(hour: float)
signal export_value_changed(new_value: int)

# Time
var current_day: int = 1
var current_season_index: int = 0
var time_of_day: float = 6.0  # 0-24 hours
var time_speed_multiplier: float = 60.0  # 1 real second = 1 game minute
var is_paused_for_ui: bool = false

# Weather
var current_weather: String = "clear"
var weather_transition_timer: float = 0.0
var weather_duration: float = 600.0  # seconds

# World
var current_area_id: String = ""
var current_region_id: String = ""
var player_position: Vector3 = Vector3.ZERO

# Economy
var global_export_value: int = 0
var manufactured_goods_tier: String = "low"

# Flags
var is_sleeping: bool = false
var batch_processing: bool = false

# Precursor randomization seed
var world_seed: int = 0
var precursor_assignments: Dictionary = {}  # site_id -> discipline_id

# Named landmarks
var named_landmarks: Dictionary = {}  # landmark_id -> player-given name

# Home Storage — single global dict accessible at any owned home (LINV-008)
# No capacity limit (LINV-009). Items stored as Array[{item_id, count, ...}].
var home_storage: Array = []

const EXPORT_THRESHOLDS := {
	"low": 0,
	"moderate": 500,
	"high": 2000,
	"very_high": 6000
}


func _ready() -> void:
	world_seed = randi()


func _process(delta: float) -> void:
	if is_paused_for_ui or is_sleeping or batch_processing:
		return
	_advance_time(delta)
	_update_weather(delta)


func _advance_time(delta: float) -> void:
	var prev_day := current_day
	time_of_day += (delta * time_speed_multiplier) / 3600.0  # convert seconds to hours

	if time_of_day >= 24.0:
		time_of_day -= 24.0
		current_day += 1
		_check_season_advance()
		day_changed.emit(current_day)

	time_of_day_changed.emit(time_of_day)


func _check_season_advance() -> void:
	var season_data := GameData.get_season(current_season_index)
	if season_data.is_empty():
		return
	var days_into_season := (current_day - 1) % _total_season_duration()
	if days_into_season == 0 and current_day > 1:
		current_season_index = (current_season_index + 1) % GameData.seasons.size()
		season_changed.emit(get_current_season_id())
		_roll_weather()


func _update_weather(delta: float) -> void:
	weather_transition_timer -= delta
	if weather_transition_timer <= 0.0:
		_roll_weather()


func _roll_weather() -> void:
	var season := GameData.get_season(current_season_index)
	if season.is_empty():
		return
	var table: Array = season.get("weather_table", [])
	var total_weight := 0
	for entry in table:
		total_weight += entry["weight"]
	var roll := randi() % total_weight
	var cumulative := 0
	for entry in table:
		cumulative += entry["weight"]
		if roll < cumulative:
			if current_weather != entry["type"]:
				current_weather = entry["type"]
				weather_changed.emit(current_weather)
			break
	weather_duration = randf_range(300.0, 1200.0)
	weather_transition_timer = weather_duration


func _total_season_duration() -> int:
	var total := 0
	for s in GameData.seasons:
		total += s.get("duration_days", 20)
	return total


func get_current_season_id() -> String:
	var s := GameData.get_season(current_season_index)
	return s.get("id", "spring")


func get_current_season() -> Dictionary:
	return GameData.get_season(current_season_index)


func is_daytime() -> bool:
	var season := get_current_season()
	var day_length: float = season.get("day_length_hours", 12.0)
	var sunrise := 6.0
	var sunset := sunrise + day_length
	return time_of_day >= sunrise and time_of_day < sunset


func add_export_value(amount: int) -> void:
	global_export_value += amount
	_update_goods_tier()
	export_value_changed.emit(global_export_value)


func _update_goods_tier() -> void:
	var new_tier := "low"
	for tier_name in ["very_high", "high", "moderate"]:
		if global_export_value >= EXPORT_THRESHOLDS[tier_name]:
			new_tier = tier_name
			break
	manufactured_goods_tier = new_tier


func name_landmark(landmark_id: String, name: String) -> void:
	named_landmarks[landmark_id] = name


func get_landmark_name(landmark_id: String) -> String:
	return named_landmarks.get(landmark_id, "")


func set_precursor_assignment(site_id: String, discipline_id: String) -> void:
	precursor_assignments[site_id] = discipline_id


func get_precursor_assignment(site_id: String) -> String:
	return precursor_assignments.get(site_id, "")
