## PlayerStats
## Autoload singleton. Central player statistics hub (LHP-001..015, LSHOP-001).
## Owns health, stamina, gold, and a modifier system so equipment / buffs / debuffs
## can add or remove stat bonuses without coupling to each other.
extends Node

signal health_changed(new_val: float, max_val: float)
signal stamina_changed(new_val: float, max_val: float)
signal player_died

# --- Base stats ---
var max_health: float   = 100.0
var max_stamina: float  = 100.0
var gold: int           = 0

# Current values — initialised in _ready so max values can be tweaked before first frame.
var health: float  = 100.0
var stamina: float = 100.0

# Regen rates (units per second of real time while the clock is running).
const HEALTH_REGEN_PER_SEC: float  = 0.5
const STAMINA_REGEN_PER_SEC: float = 2.0

# --- Modifier system ---
# modifier_id -> { "stat": String, "value": float }
var _modifiers: Dictionary = {}

# Guard to prevent player_died being emitted multiple times.
var _is_dead: bool = false


func _ready() -> void:
	health  = max_health
	stamina = max_stamina


func _process(delta: float) -> void:
	if _is_dead:
		return
	_regen(delta)


func _regen(delta: float) -> void:
	var changed := false

	if health < get_stat("max_health"):
		health = minf(health + HEALTH_REGEN_PER_SEC * delta, get_stat("max_health"))
		changed = true

	if stamina < get_stat("max_stamina"):
		stamina = minf(stamina + STAMINA_REGEN_PER_SEC * delta, get_stat("max_stamina"))

	# Emit signals after both values are updated to avoid unnecessary double-emit.
	if changed:
		health_changed.emit(health, get_stat("max_health"))
	stamina_changed.emit(stamina, get_stat("max_stamina"))


# --- Modifier API ---

## Add (or replace) a named modifier affecting stat_name by value (can be negative).
func add_modifier(id: String, stat: String, value: float) -> void:
	_modifiers[id] = { "stat": stat, "value": value }


## Remove a named modifier.
func remove_modifier(id: String) -> void:
	_modifiers.erase(id)


## Return the effective value of a stat after applying all active modifiers.
## Recognised stat names: "max_health", "max_stamina".
## Unknown names fall back to 0.0 plus modifiers.
func get_stat(stat_name: String) -> float:
	var base := 0.0
	match stat_name:
		"max_health":  base = max_health
		"max_stamina": base = max_stamina
		_:             base = 0.0

	var bonus := 0.0
	for mid in _modifiers:
		var m: Dictionary = _modifiers[mid]
		if m.get("stat", "") == stat_name:
			bonus += float(m.get("value", 0.0))
	return base + bonus


# --- Damage / Healing ---

## Apply damage from a source. source can be a String tag or null.
func take_damage(amount: float, source = null) -> void:
	if _is_dead:
		return
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, get_stat("max_health"))
	if health <= 0.0:
		_on_death()


## Restore health up to the current max_health (with modifiers).
func heal(amount: float) -> void:
	if _is_dead:
		return
	health = minf(health + amount, get_stat("max_health"))
	health_changed.emit(health, get_stat("max_health"))


## Spend stamina. Returns false and does nothing if insufficient stamina.
func drain_stamina(amount: float) -> bool:
	if stamina < amount:
		return false
	stamina -= amount
	stamina_changed.emit(stamina, get_stat("max_stamina"))
	return true


## Restore stamina up to max_stamina (with modifiers).
func restore_stamina(amount: float) -> void:
	stamina = minf(stamina + amount, get_stat("max_stamina"))
	stamina_changed.emit(stamina, get_stat("max_stamina"))


# --- Private helpers ---

func _on_death() -> void:
	if _is_dead:
		return
	_is_dead = true
	player_died.emit()
	print("[PlayerStats] Player has died.")


# --- Save / Load helpers ---

func get_save_data() -> Dictionary:
	return {
		"health":     health,
		"stamina":    stamina,
		"gold":       gold,
		"max_health": max_health,
		"max_stamina":max_stamina
	}


func apply_save_data(data: Dictionary) -> void:
	max_health  = data.get("max_health",  100.0)
	max_stamina = data.get("max_stamina", 100.0)
	health      = data.get("health",      max_health)
	stamina     = data.get("stamina",     max_stamina)
	gold        = data.get("gold",        0)
	_is_dead    = false
