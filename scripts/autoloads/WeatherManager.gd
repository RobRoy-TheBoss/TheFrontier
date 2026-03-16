## WeatherManager
## Autoload singleton. Manages weather state (LMAP-034..038).
## Rolls new weather from the current season's weighted weather_table and
## applies environmental effects (fog density, particle visibility, temperature).
extends Node

signal weather_changed(new_weather: String)

## Current weather type string (e.g. "clear", "rain", "storm", "snow").
var current_weather: String = "clear"

## Additive temperature modifier applied by current weather (negative = cold).
var current_temp_modifier: float = 0.0

# Reference to the world environment node for fog updates — set by the scene.
var _environment: Environment = null

# Reference to precipitation particle node (GPUParticles3D or CPUParticles3D).
var _precipitation_particles: Node = null


func _ready() -> void:
	# Roll initial weather once SeasonManager is ready (called from GameBootstrap or similar).
	pass


# --- Public API ---

## Pick and apply a new weather state from the season's weather_table.
func roll_new_weather() -> void:
	var season := SeasonManager.get_current_season()
	if season.is_empty():
		push_warning("[WeatherManager] roll_new_weather: no season data available.")
		return
	var table: Array = season.get("weather_table", [])
	if table.is_empty():
		push_warning("[WeatherManager] roll_new_weather: empty weather_table in season.")
		return

	var total_weight := 0
	for entry in table:
		total_weight += int(entry.get("weight", 1))

	if total_weight == 0:
		return

	var roll := randi() % total_weight
	var cumulative := 0
	var chosen := current_weather
	for entry in table:
		cumulative += int(entry.get("weight", 1))
		if roll < cumulative:
			chosen = entry.get("type", "clear")
			break

	if chosen != current_weather:
		current_weather = chosen
		apply_weather_effects()
		weather_changed.emit(current_weather)


## Apply visual and gameplay effects for current_weather.
func apply_weather_effects() -> void:
	match current_weather:
		"clear":
			current_temp_modifier = 0.0
			_set_fog(false, 0.0)
			_set_precipitation(false)
		"overcast":
			current_temp_modifier = -2.0
			_set_fog(false, 0.0)
			_set_precipitation(false)
		"rain":
			current_temp_modifier = -5.0
			_set_fog(true, 0.01)
			_set_precipitation(true)
		"storm":
			current_temp_modifier = -8.0
			_set_fog(true, 0.02)
			_set_precipitation(true)
		"snow":
			current_temp_modifier = -15.0
			_set_fog(true, 0.015)
			_set_precipitation(true)
		_:
			# Unknown type — clear effects
			current_temp_modifier = 0.0
			_set_fog(false, 0.0)
			_set_precipitation(false)


## Returns true when current weather involves rain or storm.
func is_raining() -> bool:
	return current_weather in ["rain", "storm"]


## Returns a cold penalty (negative float) when raining or storming.
## Used by the survival system to increase hypothermia risk.
func get_rain_cold_bonus() -> float:
	if is_raining():
		return current_temp_modifier
	return 0.0


## Register the WorldEnvironment's Environment resource for fog control.
func set_environment(env: Environment) -> void:
	_environment = env


## Register a Particles node for precipitation visuals.
func set_precipitation_particles(particles: Node) -> void:
	_precipitation_particles = particles


# --- Private helpers ---

func _set_fog(enabled: bool, density: float) -> void:
	if _environment == null:
		return
	_environment.fog_enabled = enabled
	if enabled:
		_environment.fog_density = density


func _set_precipitation(visible: bool) -> void:
	if _precipitation_particles == null:
		return
	_precipitation_particles.emitting = visible
