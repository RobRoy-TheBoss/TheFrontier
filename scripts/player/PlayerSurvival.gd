## PlayerSurvival
## Tracks and processes Hunger, Thirst, Temperature, Fatigue, Encumbrance.
extends Node

signal hunger_changed(value: float, max_value: float)
signal thirst_changed(value: float, max_value: float)
signal temperature_changed(value: float)
signal fatigue_changed(value: float, max_value: float)
signal encumbrance_changed(current_weight: float, max_weight: float)
signal survival_warning(need: String, level: String)  # "hunger", "low" / "critical"

var hunger: float = 100.0
var thirst: float = 100.0
var temperature: float = 18.0  # Celsius
var fatigue: float = 0.0
var current_weight: float = 0.0

var _params: Dictionary = {}
var _player: CharacterBody3D


func _ready() -> void:
	_params = GameData.survival_params
	_player = get_parent()


func _process(delta: float) -> void:
	if GameState.is_sleeping or GameState.is_paused_for_ui:
		return
	_process_hunger(delta)
	_process_thirst(delta)
	_process_temperature(delta)
	_process_fatigue(delta)


func _process_hunger(delta: float) -> void:
	var h_params: Dictionary = _params.get("hunger", {})
	hunger -= h_params.get("drain_per_second", 0.002) * delta
	hunger = max(0.0, hunger)
	hunger_changed.emit(hunger, h_params.get("max", 100.0))

	if hunger <= h_params.get("critical_threshold", 10.0):
		_player.health.take_damage(h_params.get("critical_health_drain_per_second", 0.5) * delta)
		if fmod(delta, 30.0) < delta:
			survival_warning.emit("hunger", "critical")
	elif hunger <= h_params.get("low_threshold", 30.0):
		survival_warning.emit("hunger", "low")


func _process_thirst(delta: float) -> void:
	var t_params: Dictionary = _params.get("thirst", {})
	thirst -= t_params.get("drain_per_second", 0.004) * delta
	thirst = max(0.0, thirst)
	thirst_changed.emit(thirst, t_params.get("max", 100.0))

	if thirst <= t_params.get("low_threshold", 30.0):
		survival_warning.emit("thirst", "low")


func _process_temperature(delta: float) -> void:
	var t_params: Dictionary = _params.get("temperature", {})
	var season := GameState.get_current_season()
	var biome_temp := season.get("temperature_modifier", 0.0)
	# Altitude cooling: placeholder
	# Weather modifier
	var weather_temp_mod := _get_weather_temp_mod()
	# Clothing bonus: sum from equipped armor
	var clothing_bonus := _get_clothing_temp_bonus()

	temperature = biome_temp + weather_temp_mod + clothing_bonus

	var comfort_min: float = t_params.get("comfortable_min", 10.0)
	var comfort_max: float = t_params.get("comfortable_max", 30.0)

	# Weatherskin passive widens comfort range
	if DisciplineManager.has_passive("weatherskin"):
		var eff := DisciplineManager.get_passive_effect("weatherskin")
		comfort_min -= eff.get("cold_threshold_bonus", 8.0)
		comfort_max += eff.get("heat_threshold_bonus", 8.0)

	# Injury temp sensitivity
	if "temperature_sensitivity" in _player.health.active_injuries:
		comfort_min += 10.0
		comfort_max -= 10.0

	temperature_changed.emit(temperature)

	if temperature < t_params.get("danger_cold", -5.0) or temperature > t_params.get("danger_hot", 40.0):
		if randf() < t_params.get("injury_risk_per_second_outside_danger", 0.001) * delta:
			_player.health._try_inflict_random_injury()


func _process_fatigue(delta: float) -> void:
	var f_params: Dictionary = _params.get("fatigue", {})
	# Base gain handled by PlayerMovement, here we process penalties
	fatigue_changed.emit(fatigue, f_params.get("max", 100.0))

	var critical: float = f_params.get("critical_threshold", 90.0)
	if fatigue >= critical:
		if randf() < f_params.get("critical_passout_risk_per_second", 0.005) * delta:
			# Pass out: forced sleep
			_player._do_sleep()
		survival_warning.emit("fatigue", "critical")


func accumulate_fatigue(amount: float) -> void:
	var f_params: Dictionary = _params.get("fatigue", {})
	# Endurance passive halves fatigue gain
	if DisciplineManager.has_passive("endurance"):
		var eff := DisciplineManager.get_passive_effect("endurance")
		amount *= eff.get("fatigue_penalty_multiplier", 0.5)
	fatigue = min(fatigue + amount, f_params.get("max", 100.0))


func consume_hunger(amount: float) -> void:
	hunger = min(hunger + amount, _params.get("hunger", {}).get("max", 100.0))
	hunger_changed.emit(hunger, 100.0)


func consume_thirst(amount: float) -> void:
	thirst = min(thirst + amount, _params.get("thirst", {}).get("max", 100.0))
	thirst_changed.emit(thirst, 100.0)


func update_encumbrance(weight: float) -> void:
	current_weight = weight
	var enc_params: Dictionary = _params.get("encumbrance", {})
	var max_weight := get_max_carry_weight()
	encumbrance_changed.emit(current_weight, max_weight)


func get_max_carry_weight() -> float:
	var enc_params: Dictionary = _params.get("encumbrance", {})
	var base: float = enc_params.get("base_carry_weight", 50.0)
	# Warrior Pack Mule
	if DisciplineManager.has_passive("pack_mule"):
		var eff := DisciplineManager.get_passive_effect("pack_mule")
		base *= eff.get("carry_weight_multiplier", 1.30)
	# Porter hireling
	var camp := get_tree().get_first_node_in_group("player_camp")
	if camp and "porter" in camp.get_meta("hireling_ids", []):
		var porter := GameData.get_hireling("porter")
		base += porter.get("capabilities", {}).get("carry_weight_bonus", 30.0)
	return base


func is_over_encumbered() -> bool:
	return current_weight > get_max_carry_weight()


func get_stamina_regen_multiplier() -> float:
	var mult := 1.0
	var h_params: Dictionary = _params.get("hunger", {})
	if hunger <= h_params.get("low_threshold", 30.0):
		mult *= h_params.get("low_stamina_regen_multiplier", 0.5)
	var f_params: Dictionary = _params.get("fatigue", {})
	if fatigue >= f_params.get("high_threshold", 70.0):
		mult *= f_params.get("high_stamina_regen_multiplier", 0.6)
	return mult


func _get_weather_temp_mod() -> float:
	match GameState.current_weather:
		"snow", "blizzard":
			return -10.0
		"clear_cold":
			return -5.0
		"rain":
			return -3.0
		"heat_haze":
			return 8.0
		_:
			return 0.0


func _get_clothing_temp_bonus() -> float:
	# Placeholder: sum temperature_modifier from equipped armor
	return 0.0


func on_sleep_start() -> void:
	# Consume hunger/thirst for elapsed sleep time (approx 8 hours)
	var h_params: Dictionary = _params.get("hunger", {})
	var t_params: Dictionary = _params.get("thirst", {})
	hunger -= h_params.get("drain_per_second", 0.002) * 28800.0
	thirst -= t_params.get("drain_per_second", 0.004) * 28800.0
	hunger = max(0.0, hunger)
	thirst = max(0.0, thirst)


func on_sleep_end() -> void:
	var f_params: Dictionary = _params.get("fatigue", {})
	fatigue = max(0.0, fatigue - f_params.get("sleep_recovery_per_second", 10.0) * 28800.0)
	fatigue_changed.emit(fatigue, f_params.get("max", 100.0))


func get_save_data() -> Dictionary:
	return {
		"hunger": hunger,
		"thirst": thirst,
		"temperature": temperature,
		"fatigue": fatigue,
		"current_weight": current_weight
	}


func apply_save_data(data: Dictionary) -> void:
	hunger = data.get("hunger", 100.0)
	thirst = data.get("thirst", 100.0)
	temperature = data.get("temperature", 18.0)
	fatigue = data.get("fatigue", 0.0)
	current_weight = data.get("current_weight", 0.0)
