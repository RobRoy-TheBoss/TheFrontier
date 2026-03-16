## SeasonManager
## Autoload singleton. Manages the in-game calendar — seasons and day count (LMAP-030..033).
## Reads season definitions from DataLoader. Season transitions are driven by advance_day()
## which is called by the sleep/rest system each time the player rests until morning.
extends Node

signal season_changed(new_index: int)
signal day_advanced(day: int)

## Current season (0=spring, 1=summer, 2=autumn, 3=winter by default JSON order).
var season_index: int = 0

## Cumulative day counter since the start of a new game.
var day_count: int = 1

# Ordered season definitions loaded from DataLoader.
var _season_data: Array = []

# Tracks how many days have elapsed in the current season.
var _days_in_current_season: int = 0


func _ready() -> void:
	# DataLoader must be earlier in the autoload order.
	_season_data = DataLoader._seasons_ordered.duplicate()
	if _season_data.is_empty():
		push_warning("[SeasonManager] No season data found in DataLoader.")


# --- Public API ---

## Return the Dictionary for the currently active season.
func get_current_season() -> Dictionary:
	if season_index < 0 or season_index >= _season_data.size():
		return {}
	return _season_data[season_index]


## Advance one in-game day. Checks whether the season should roll over.
func advance_day() -> void:
	day_count += 1
	_days_in_current_season += 1
	day_advanced.emit(day_count)
	_check_season_transition()


## Returns the number of daylight hours for the current season (used by TimeManager).
func get_daylight_hours() -> float:
	var season := get_current_season()
	return season.get("day_length_hours", 14.0)


# --- Private helpers ---

func _check_season_transition() -> void:
	var season := get_current_season()
	if season.is_empty():
		return
	var duration: int = season.get("duration_days", 20)
	if _days_in_current_season >= duration:
		_days_in_current_season = 0
		season_index = (season_index + 1) % _season_data.size()
		season_changed.emit(season_index)
		print("[SeasonManager] Season transitioned to index %d." % season_index)


# --- Save / Load helpers ---

func get_save_data() -> Dictionary:
	return {
		"season_index":           season_index,
		"day_count":              day_count,
		"days_in_current_season": _days_in_current_season
	}


func apply_save_data(data: Dictionary) -> void:
	season_index              = data.get("season_index",           0)
	day_count                 = data.get("day_count",              1)
	_days_in_current_season   = data.get("days_in_current_season", 0)
