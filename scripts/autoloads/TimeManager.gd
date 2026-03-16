## TimeManager
## Autoload singleton. Manages in-game clock (LMAP-020..025).
## 30 real minutes = 24 in-game hours at default time_scale of 48.
## Drives dawn/dusk signals and optional DirectionalLight3D sun rotation.
extends Node

signal dawn
signal dusk
signal hour_changed(hour: int)

## Current in-game hour (0.0–24.0). Wraps at 24.
var time_of_day: float = 6.0

## Ratio of in-game hours per real second.
## Default 48.0 means 1 real second = 48 in-game seconds → 30 min real = 24 hr game.
var time_scale: float = 48.0

## While true the clock does not advance.
var is_paused: bool = false

# Tracks the last whole hour to fire hour_changed only once per in-game hour.
var _last_hour: int = 6

# Tracks day/night crossings to fire dawn/dusk once per transition.
var _was_daytime: bool = true

# Optional sun light — set via set_sun_light().
var _sun_light: DirectionalLight3D = null


func _ready() -> void:
	_last_hour = int(time_of_day)
	_was_daytime = is_daytime()


func _process(delta: float) -> void:
	if is_paused:
		return

	# Advance time: time_scale is in-game hours per real hour, so per-second = /3600.
	time_of_day += delta * time_scale / 3600.0

	if time_of_day >= 24.0:
		time_of_day -= 24.0

	_check_hour_signal()
	_check_day_night_signals()
	_rotate_sun()


func _check_hour_signal() -> void:
	var current_hour := int(time_of_day)
	if current_hour != _last_hour:
		_last_hour = current_hour
		hour_changed.emit(current_hour)


func _check_day_night_signals() -> void:
	var now_day := is_daytime()
	if now_day and not _was_daytime:
		dawn.emit()
	elif not now_day and _was_daytime:
		dusk.emit()
	_was_daytime = now_day


func _rotate_sun() -> void:
	if _sun_light == null:
		return
	# Map 0–24 hours to 0–360 degrees around the X axis.
	# Noon (12 h) is straight overhead (pitch = 90°).
	var angle_deg := (time_of_day / 24.0) * 360.0 - 90.0
	_sun_light.rotation_degrees.x = angle_deg


# --- Public API ---

## Register the scene's DirectionalLight3D so TimeManager can rotate it.
func set_sun_light(light: DirectionalLight3D) -> void:
	_sun_light = light


## Returns a zero-padded "HH:MM" label for the current time.
func get_time_label() -> String:
	var hours := int(time_of_day)
	var minutes := int((time_of_day - hours) * 60.0)
	return "%02d:%02d" % [hours, minutes]


## Returns true during standard daylight hours (06:00–20:00 default).
## SeasonManager provides the actual daylight window when available.
func is_daytime() -> bool:
	var sunrise := 6.0
	var sunset := 20.0
	# Pull daylight hours from SeasonManager if it is loaded.
	if Engine.has_singleton("SeasonManager"):
		var sm := Engine.get_singleton("SeasonManager") as Node
		if sm != null:
			var day_h: float = sm.get_daylight_hours()
			sunset = sunrise + day_h
	return time_of_day >= sunrise and time_of_day < sunset


## Jump the clock forward to 06:00 (dawn).
func advance_to_morning() -> void:
	time_of_day = 6.0
	_last_hour = 6
	_was_daytime = true
	dawn.emit()
