## DisciplineManager
## Autoload singleton. Manages player attunements, discipline XP, and ability unlocks.
extends Node

signal attuned(discipline_id: String)
signal ability_unlocked(discipline_id: String, ability_id: String)
signal xp_gained(discipline_id: String, amount: int, new_total: int)

const MAX_ATTUNEMENTS := 3

# discipline_id -> { "xp": int, "unlocked_abilities": [ability_id, ...] }
var player_disciplines: Dictionary = {}


func is_attuned(discipline_id: String) -> bool:
	return player_disciplines.has(discipline_id)


func get_attunement_count() -> int:
	return player_disciplines.size()


func can_attune() -> bool:
	return player_disciplines.size() < MAX_ATTUNEMENTS


func attune(discipline_id: String) -> bool:
	if not can_attune():
		push_warning("[DisciplineManager] Max attunements reached.")
		return false
	if is_attuned(discipline_id):
		push_warning("[DisciplineManager] Already attuned to: " + discipline_id)
		return false
	var disc := GameData.get_discipline(discipline_id)
	if disc.is_empty():
		push_error("[DisciplineManager] Unknown discipline: " + discipline_id)
		return false

	player_disciplines[discipline_id] = {
		"xp": 0,
		"unlocked_abilities": []
	}

	# Grant ability 1 automatically
	var abilities: Array = disc.get("abilities", [])
	for ab in abilities:
		if ab.get("granted_on_attunement", false):
			player_disciplines[discipline_id]["unlocked_abilities"].append(ab["id"])
			ability_unlocked.emit(discipline_id, ab["id"])

	attuned.emit(discipline_id)
	return true


func add_xp(discipline_id: String, trigger: String) -> void:
	if not is_attuned(discipline_id):
		return
	var disc := GameData.get_discipline(discipline_id)
	var triggers: Array = disc.get("xp_triggers", [])
	var xp_amount := 0
	for t in triggers:
		if t["trigger"] == trigger:
			xp_amount = t["xp"]
			break
	if xp_amount == 0:
		return
	player_disciplines[discipline_id]["xp"] += xp_amount
	xp_gained.emit(discipline_id, xp_amount, player_disciplines[discipline_id]["xp"])


func add_xp_direct(discipline_id: String, amount: int) -> void:
	if not is_attuned(discipline_id):
		return
	player_disciplines[discipline_id]["xp"] += amount
	xp_gained.emit(discipline_id, amount, player_disciplines[discipline_id]["xp"])


func can_unlock_ability(discipline_id: String, ability_id: String) -> bool:
	if not is_attuned(discipline_id):
		return false
	var ab := _get_ability(discipline_id, ability_id)
	if ab.is_empty():
		return false
	if is_ability_unlocked(discipline_id, ability_id):
		return false
	# Must unlock in sequence
	var ab_index: int = ab.get("index", 999)
	if ab_index > 1:
		var prev_ab := _get_ability_by_index(discipline_id, ab_index - 1)
		if prev_ab.is_empty() or not is_ability_unlocked(discipline_id, prev_ab["id"]):
			return false
	var cost_xp: int = ab.get("unlock_cost_xp", 0)
	var current_xp: int = player_disciplines[discipline_id].get("xp", 0)
	return current_xp >= cost_xp


func unlock_ability(discipline_id: String, ability_id: String, gold_cost: int) -> bool:
	if not can_unlock_ability(discipline_id, ability_id):
		return false
	var ab := _get_ability(discipline_id, ability_id)
	var xp_cost: int = ab.get("unlock_cost_xp", 0)
	player_disciplines[discipline_id]["xp"] -= xp_cost
	player_disciplines[discipline_id]["unlocked_abilities"].append(ability_id)
	ability_unlocked.emit(discipline_id, ability_id)
	return true


func is_ability_unlocked(discipline_id: String, ability_id: String) -> bool:
	if not is_attuned(discipline_id):
		return false
	return ability_id in player_disciplines[discipline_id].get("unlocked_abilities", [])


func has_passive(ability_id: String) -> bool:
	for disc_id in player_disciplines:
		if is_ability_unlocked(disc_id, ability_id):
			var ab := _get_ability(disc_id, ability_id)
			if ab.get("type", "") == "passive":
				return true
	return false


func get_passive_effect(ability_id: String) -> Dictionary:
	for disc_id in player_disciplines:
		if is_ability_unlocked(disc_id, ability_id):
			var ab := _get_ability(disc_id, ability_id)
			if ab.get("type", "") == "passive":
				return ab.get("effect_data", {})
	return {}


func get_unlocked_abilities(discipline_id: String) -> Array:
	if not is_attuned(discipline_id):
		return []
	return player_disciplines[discipline_id].get("unlocked_abilities", [])


func get_xp(discipline_id: String) -> int:
	if not is_attuned(discipline_id):
		return 0
	return player_disciplines[discipline_id].get("xp", 0)


func _get_ability(discipline_id: String, ability_id: String) -> Dictionary:
	var disc := GameData.get_discipline(discipline_id)
	for ab in disc.get("abilities", []):
		if ab["id"] == ability_id:
			return ab
	return {}


func _get_ability_by_index(discipline_id: String, index: int) -> Dictionary:
	var disc := GameData.get_discipline(discipline_id)
	for ab in disc.get("abilities", []):
		if ab.get("index", -1) == index:
			return ab
	return {}


func get_save_data() -> Dictionary:
	return player_disciplines.duplicate(true)


func apply_save_data(data: Dictionary) -> void:
	player_disciplines = data.duplicate(true)
