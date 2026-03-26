## PlayerHealth
## Manages health pool, stamina pool, and the injury system.
class_name PlayerHealth
extends Node

signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal injury_inflicted(injury_id: String)
signal injury_resolved(injury_id: String)
signal player_died()

var max_health: float = 100.0
var current_health: float = 100.0
var max_stamina: float = 100.0
var stamina: float = 100.0
var active_injuries: Array = []  # List of injury_id strings
var is_dead: bool = false

# Passive buffs from runes/disciplines
var _health_bonus: float = 0.0
var _stamina_bonus: float = 0.0
var _health_regen_bonus: float = 0.0

var _params: Dictionary = {}
var _stamina_regen_timer: float = 0.0
const STAMINA_REGEN_DELAY := 0.5  # seconds after last stamina use before regen starts
var _stamina_regen_cooldown: float = 0.0


func _ready() -> void:
	_params = DataLoader.survival
	_apply_discipline_passives()
	_recalculate_max()


func _physics_process(delta: float) -> void:
	if GameState.is_sleeping:
		return
	_regen_health(delta)
	_regen_stamina(delta)
	_process_injury_effects(delta)


func _recalculate_max() -> void:
	var hp_params: Dictionary = _params.get("health", {})
	max_health = hp_params.get("base_max", 100.0) + _health_bonus
	# Apply injury reduction
	for inj_id in active_injuries:
		var inj := DataLoader.get_injury(inj_id)
		var debuffs: Dictionary = inj.get("debuffs", {})
		if debuffs.has("max_health_reduction_percent"):
			max_health *= (1.0 - debuffs["max_health_reduction_percent"] / 100.0)
	current_health = min(current_health, max_health)

	var st_params: Dictionary = _params.get("stamina", {})
	var base_stamina: float = st_params.get("base_max", 100.0) + _stamina_bonus
	# Endurance passive
	if DisciplineManager.has_passive("endurance"):
		var eff := DisciplineManager.get_passive_effect("endurance")
		base_stamina *= eff.get("stamina_max_multiplier", 1.25)
	max_stamina = base_stamina
	stamina = min(stamina, max_stamina)

	health_changed.emit(current_health, max_health)
	stamina_changed.emit(stamina, max_stamina)


func take_damage(amount: float, attacker: Node = null) -> void:
	current_health -= amount
	current_health = max(0.0, current_health)
	health_changed.emit(current_health, max_health)

	# Second Wind (Warrior) auto-trigger
	if current_health / max_health <= 0.25:
		_check_second_wind()

	if current_health <= 0.0 and not is_dead:
		is_dead = true
		player_died.emit()


## Called by combat sources (monsters, traps) after dealing damage to attempt
## a random injury roll. Separated from take_damage so non-combat callers
## (survival drains, test helpers) do not trigger injury rolls.
func try_combat_injury_roll() -> void:
	var hp_params: Dictionary = _params.get("health", {})
	var threshold: float = hp_params.get("injury_threshold_percent", 0.35) * max_health
	if current_health < threshold and randf() < 0.15:
		_try_inflict_random_injury()


func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)


func drain_stamina(amount: float) -> void:
	var cost_mult := _get_stamina_cost_multiplier()
	stamina -= amount * cost_mult
	stamina = max(0.0, stamina)
	_stamina_regen_cooldown = STAMINA_REGEN_DELAY
	stamina_changed.emit(stamina, max_stamina)


func try_consume_stamina(amount: float) -> bool:
	if stamina < amount:
		return false
	drain_stamina(amount)
	return true


func restore_stamina(amount: float) -> void:
	stamina = min(stamina + amount, max_stamina)
	stamina_changed.emit(stamina, max_stamina)


func _regen_health(delta: float) -> void:
	var hp_params: Dictionary = _params.get("health", {})
	var regen: float = hp_params.get("regen_rate_per_second", 0.5) + _health_regen_bonus
	if current_health < max_health:
		heal(regen * delta)


func _regen_stamina(delta: float) -> void:
	if _stamina_regen_cooldown > 0.0:
		_stamina_regen_cooldown -= delta
		return
	var st_params: Dictionary = _params.get("stamina", {})
	var player: CharacterBody3D = get_parent()
	var regen_rate: float
	if player and player.velocity.length() > 0.1:
		regen_rate = st_params.get("regen_rate_moving", 5.0)
	else:
		regen_rate = st_params.get("regen_rate_idle", 15.0)

	# Reduce regen based on hunger/fatigue
	var survival: PlayerSurvival = get_parent().survival
	regen_rate *= survival.get_stamina_regen_multiplier()

	restore_stamina(regen_rate * delta)


func _process_injury_effects(delta: float) -> void:
	for inj_id in active_injuries:
		var inj := DataLoader.get_injury(inj_id)
		var debuffs: Dictionary = inj.get("debuffs", {})
		if debuffs.has("health_drain_per_second"):
			current_health -= debuffs["health_drain_per_second"] * delta
			current_health = max(0.0, current_health)
			health_changed.emit(current_health, max_health)
			if current_health <= 0.0 and not is_dead:
				is_dead = true
				player_died.emit()


func _try_inflict_random_injury() -> void:
	# Weight-based random selection from injury definitions
	var available := []
	var total_weight := 0.0
	for inj_id in DataLoader.injuries:
		if inj_id in active_injuries:
			continue
		var inj := DataLoader.get_injury(inj_id)
		var w: float = inj.get("probability_weight", 1.0)
		# Resilience rune reduction
		if DisciplineManager.has_passive("rune_resilience"):
			var eff := DisciplineManager.get_passive_effect("rune_resilience")
			w *= (1.0 - eff.get("injury_chance_reduction", 0.0))
		available.append({ "id": inj_id, "weight": w })
		total_weight += w

	if available.is_empty() or total_weight <= 0:
		return

	var roll := randf() * total_weight
	var cumulative := 0.0
	for entry in available:
		cumulative += entry["weight"]
		if roll <= cumulative:
			inflict_injury(entry["id"])
			return


func inflict_injury(injury_id: String) -> void:
	if injury_id in active_injuries:
		return
	active_injuries.append(injury_id)
	_recalculate_max()
	injury_inflicted.emit(injury_id)


func resolve_injury(injury_id: String) -> void:
	active_injuries.erase(injury_id)
	_recalculate_max()
	injury_resolved.emit(injury_id)


func can_treat_injury(injury_id: String, location_tier: String) -> bool:
	var inj := DataLoader.get_injury(injury_id)
	var required: String = inj.get("treatment_tier", "city")
	var tier_order := ["field", "camp", "village", "town", "city"]
	# Ritualist Mending raises effective tier
	var tier_bonus := 0
	if DisciplineManager.is_ability_unlocked("ritualist", "mending"):
		tier_bonus = 1
	var location_idx: int = tier_order.find(location_tier) + tier_bonus
	var required_idx: int = tier_order.find(required)
	return location_idx >= required_idx


func get_movement_speed_multiplier() -> float:
	var mult := 1.0
	for inj_id in active_injuries:
		var inj := DataLoader.get_injury(inj_id)
		var debuffs: Dictionary = inj.get("debuffs", {})
		mult *= debuffs.get("movement_speed_multiplier", 1.0)
	return mult


func get_attack_cooldown_multiplier() -> float:
	var mult := 1.0
	for inj_id in active_injuries:
		var inj := DataLoader.get_injury(inj_id)
		mult *= inj.get("debuffs", {}).get("attack_cooldown_multiplier", 1.0)
	return mult


func _get_stamina_cost_multiplier() -> float:
	var mult := 1.0
	for inj_id in active_injuries:
		var inj := DataLoader.get_injury(inj_id)
		mult *= inj.get("debuffs", {}).get("stamina_cost_multiplier", 1.0)
	return mult


func _check_second_wind() -> void:
	if not DisciplineManager.is_ability_unlocked("warrior", "second_wind"):
		return
	# Handled by combat/active ability system

func add_health_bonus(amount: float) -> void:
	_health_bonus += amount
	_recalculate_max()


func add_stamina_bonus(amount: float) -> void:
	_stamina_bonus += amount
	_recalculate_max()


func on_sleep(in_settlement: bool) -> void:
	# Base field healing
	var treated := []
	var location_tier := "field"
	if in_settlement:
		var nearest := _get_nearest_settlement_tier()
		location_tier = nearest
	# Healer hireling
	var camp := get_tree().get_first_node_in_group("player_camp")
	if camp and "healer" in camp.get_meta("hireling_ids", []):
		location_tier = "town"

	for inj_id in active_injuries.duplicate():
		if can_treat_injury(inj_id, location_tier):
			resolve_injury(inj_id)
		else:
			var inj := DataLoader.get_injury(inj_id)
			var partial_tier: String = inj.get("partial_stabilization_tier", "")
			if partial_tier != "" and _tier_index(location_tier) >= _tier_index(partial_tier):
				# Partial: no resolution, just stop bleed etc.
				pass


func _get_nearest_settlement_tier() -> String:
	var player_pos: Vector3 = get_parent().global_position
	var best_tier := "field"
	var best_dist := INF
	for sid in SettlementManager.settlements:
		var s: SettlementManager.SettlementData = SettlementManager.settlements[sid]
		var d := player_pos.distance_to(s.position)
		if d < best_dist and d < 55.0:
			best_dist = d
			best_tier = s.get_tier_id()
	return best_tier


func _tier_index(tier_id: String) -> int:
	var order := ["field", "camp", "village", "town", "city"]
	return order.find(tier_id)


func _apply_discipline_passives() -> void:
	# Applied once on load; rune bonuses applied by equipment system
	pass


func get_save_data() -> Dictionary:
	return {
		"current_health": current_health,
		"max_health": max_health,
		"stamina": stamina,
		"max_stamina": max_stamina,
		"active_injuries": active_injuries.duplicate()
	}


func apply_save_data(data: Dictionary) -> void:
	current_health = data.get("current_health", 100.0)
	max_health = data.get("max_health", 100.0)
	stamina = data.get("stamina", 100.0)
	max_stamina = data.get("max_stamina", 100.0)
	active_injuries = data.get("active_injuries", [])
	health_changed.emit(current_health, max_health)
	stamina_changed.emit(stamina, max_stamina)
