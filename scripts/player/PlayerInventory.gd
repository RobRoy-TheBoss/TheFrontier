## PlayerInventory
## Weight-based inventory with rune socketing support.
## Items stored as { item_id: String, count: int, runes: Array, instance_id: String }
class_name PlayerInventory
extends Node

signal inventory_changed()
signal weight_changed(current: float, maximum: float)
signal item_added(item_id: String, count: int)
signal item_removed(item_id: String, count: int)

# List of inventory entries
var items: Array = []

# Equipment slots: slot_name -> { item_id, runes: [] }
var equipped: Dictionary = {
	"weapon": {},
	"offhand": {},
	"head": {},
	"chest": {},
	"hands": {},
	"legs": {},
	"feet": {}
}

# Two main-hand weapon slots (LPC-020). No off-hand at launch (LPC-045).
var weapon_slots: Array = [{}, {}]
var active_weapon_slot: int = 0

var currency: int = 50  # Starting silver


func _ready() -> void:
	pass


func add_item(item_id: String, count: int) -> bool:
	var item_def := DataLoader.get_item(item_id)
	if item_def.is_empty():
		item_def = DataLoader.get_weapon(item_id)
	if item_def.is_empty():
		push_warning("[PlayerInventory] Unknown item: " + item_id)
		return false

	var stackable: bool = item_def.get("stackable", true)
	if stackable:
		# Find existing stack
		for entry in items:
			if entry["item_id"] == item_id:
				var stack_max: int = item_def.get("stack_size", 99)
				var can_add: int = mini(count, stack_max - int(entry["count"]))
				entry["count"] += can_add
				count -= can_add
				if count <= 0:
					break
		while count > 0:
			var stack_max: int = item_def.get("stack_size", 99)
			var to_add: int = mini(count, stack_max)
			items.append({ "item_id": item_id, "count": to_add, "runes": [] })
			count -= to_add
	else:
		for i in range(count):
			items.append({ "item_id": item_id, "count": 1, "runes": [] })

	item_added.emit(item_id, count)
	_recalculate_weight()
	inventory_changed.emit()
	return true


func remove_item(item_id: String, count: int) -> bool:
	var remaining := count
	for entry in items.duplicate():
		if entry["item_id"] == item_id:
			var remove_count: int = mini(remaining, int(entry["count"]))
			entry["count"] -= remove_count
			remaining -= remove_count
			if entry["count"] <= 0:
				items.erase(entry)
			if remaining <= 0:
				break
	if remaining > 0:
		return false
	item_removed.emit(item_id, count)
	_recalculate_weight()
	inventory_changed.emit()
	return true


func has_item(item_id: String) -> bool:
	return get_item_count(item_id) > 0


func get_item_count(item_id: String) -> int:
	var total := 0
	for entry in items:
		if entry["item_id"] == item_id:
			total += entry["count"]
	return total


func get_total_weight() -> float:
	var total := 0.0
	for entry in items:
		var def := _get_any_item_def(entry["item_id"])
		var w: float = def.get("weight", 0.0)
		# Alchemist Light Load
		if DisciplineManager.has_passive("light_load"):
			var eff := DisciplineManager.get_passive_effect("light_load")
			var subtype: String = def.get("subtype", def.get("type", ""))
			if subtype in ["potion", "plant", "ingredient"]:
				w *= eff.get("potion_weight_multiplier", 0.50)
		total += w * entry["count"]
	return total


func equip(item_id: String, slot: String) -> bool:
	if not has_item(item_id):
		return false
	var def := _get_any_item_def(item_id)
	if def.is_empty():
		return false

	# Validate slot compatibility
	var valid_slot := _get_valid_slot(def, item_id)
	if valid_slot != slot and slot != "auto":
		return false

	# Check heavy armor unlock
	if def.get("armor_class", "") == "heavy" and not DisciplineManager.has_passive("ironclad"):
		return false

	var actual_slot := valid_slot if slot == "auto" else slot
	if not equipped[actual_slot].is_empty():
		_unequip_slot(actual_slot)

	# Transfer from inventory to equipped
	remove_item(item_id, 1)
	equipped[actual_slot] = { "item_id": item_id, "runes": [] }
	_apply_equipment_bonuses(def, true)
	inventory_changed.emit()
	return true


func unequip(slot: String) -> void:
	_unequip_slot(slot)
	inventory_changed.emit()


func _unequip_slot(slot: String) -> void:
	if equipped[slot].is_empty():
		return
	var item_id: String = equipped[slot]["item_id"]
	var def := _get_any_item_def(item_id)
	_apply_equipment_bonuses(def, false)
	add_item(item_id, 1)
	equipped[slot] = {}


func _apply_equipment_bonuses(def: Dictionary, equipping: bool) -> void:
	var mult := 1.0 if equipping else -1.0
	var player: CharacterBody3D = get_parent()
	if def.has("temperature_modifier"):
		pass  # Handled in PlayerSurvival._get_clothing_temp_bonus


func socket_rune(slot: String, rune_id: String) -> bool:
	if equipped[slot].is_empty():
		return false
	var item_id: String = equipped[slot]["item_id"]
	var def := _get_any_item_def(item_id)
	var max_slots: int = def.get("rune_slots", 0)
	var current_runes: Array = equipped[slot]["runes"]
	if current_runes.size() >= max_slots:
		return false
	# Slot-type validation (LPC-RUNE-004): check rune's allowed_slot_types against equipped weapon type
	var rune_def := DataLoader.get_rune(rune_id)
	var allowed: Array = rune_def.get("allowed_slot_types", [])
	if allowed.size() > 0:
		var item_type: String = def.get("type", "")
		if item_type not in allowed:
			return false
	if not has_item(rune_id):
		return false
	remove_item(rune_id, 1)
	current_runes.append(rune_id)
	inventory_changed.emit()
	return true


func get_equipped_runes(slot: String) -> Array:
	if equipped[slot].is_empty():
		return []
	return equipped[slot].get("runes", [])


func get_all_equipped_rune_effects() -> Array:
	var effects := []
	for slot in equipped:
		for rune_id in get_equipped_runes(slot):
			var rune := DataLoader.get_rune(rune_id)
			if not rune.is_empty():
				effects.append(rune.get("effect_data", {}))
	return effects


func _get_valid_slot(def: Dictionary, item_id: String) -> String:
	var item_type: String = def.get("type", "")
	var slot: String = def.get("slot", "")
	if slot != "":
		return slot  # Armor has explicit slot
	match item_type:
		"one_handed_blade", "blunt", "bow", "pistol":
			return "weapon"
		"two_handed_blade", "musket":
			return "weapon"
		_:
			return ""


func _recalculate_weight() -> void:
	var total := get_total_weight()
	var player: CharacterBody3D = get_parent()
	if player and player.survival:
		player.survival.update_encumbrance(total)
	weight_changed.emit(total, player.survival.get_max_carry_weight() if player else 50.0)


func _get_any_item_def(item_id: String) -> Dictionary:
	var def := DataLoader.get_item(item_id)
	if def.is_empty():
		def = DataLoader.get_weapon(item_id)
	if def.is_empty():
		def = DataLoader.get_rune(item_id)
	return def


func equip_to_weapon_slot(item_id: String, slot: int) -> bool:
	if slot < 0 or slot >= weapon_slots.size():
		return false
	if not has_item(item_id):
		return false
	var def := _get_any_item_def(item_id)
	if def.is_empty():
		return false
	# Return existing item in that slot to inventory
	if not weapon_slots[slot].is_empty():
		add_item(weapon_slots[slot]["item_id"], 1)
	remove_item(item_id, 1)
	weapon_slots[slot] = { "item_id": item_id, "runes": [] }
	inventory_changed.emit()
	return true


func swap_weapon_slot() -> void:
	active_weapon_slot = 1 - active_weapon_slot
	inventory_changed.emit()


func get_active_weapon() -> Dictionary:
	return weapon_slots[active_weapon_slot]


func get_save_data() -> Dictionary:
	return {
		"items": items.duplicate(true),
		"equipped": equipped.duplicate(true),
		"currency": currency
	}


func apply_save_data(data: Dictionary) -> void:
	items = data.get("items", [])
	equipped = data.get("equipped", {
		"weapon": {}, "offhand": {}, "head": {}, "chest": {}, "hands": {}, "legs": {}, "feet": {}
	})
	currency = data.get("currency", 0)
	_recalculate_weight()
	inventory_changed.emit()
