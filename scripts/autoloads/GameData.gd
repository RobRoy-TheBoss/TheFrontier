## GameData
## Compatibility shim. Delegates all data access to DataLoader.
## DataLoader (flat res://data/ layout) is the authoritative source.
## Existing scripts call GameData; this shim forwards every call so nothing breaks.
## New code should call DataLoader directly.
extends Node

var weapons: Dictionary:
	get: return DataLoader.weapons

var ammo: Dictionary:
	get: return {}  # not in DataLoader; placeholder until ammo system is added

var armor: Dictionary:
	get: return {}  # not in DataLoader; placeholder until armor system is added

var runes: Dictionary:
	get: return DataLoader.runes

var disciplines: Dictionary:
	get: return DataLoader.disciplines

var reagents: Dictionary:
	get: return DataLoader.reagents

var monsters: Dictionary:
	get: return DataLoader.monsters

var items: Dictionary:
	get: return DataLoader.items

var recipes: Dictionary:
	get: return DataLoader.recipes

var injuries: Dictionary:
	get: return DataLoader.injuries

var seasons: Array:
	get: return DataLoader._seasons_ordered

var settlement_tiers: Dictionary:
	get: return DataLoader.settlement_tiers

var hirelings: Dictionary:
	get: return DataLoader.hirelings

var survival_params: Dictionary:
	get: return DataLoader.survival


func get_weapon(id: String) -> Dictionary:
	return DataLoader.get_weapon(id)


func get_armor(id: String) -> Dictionary:
	return {}


func get_rune(id: String) -> Dictionary:
	return DataLoader.get_rune(id)


func get_discipline(id: String) -> Dictionary:
	return DataLoader.get_discipline(id)


func get_monster(id: String) -> Dictionary:
	return DataLoader.get_monster(id)


func get_item(id: String) -> Dictionary:
	return DataLoader.get_item(id)


func get_recipe(id: String) -> Dictionary:
	return DataLoader.get_recipe(id)


func get_injury(id: String) -> Dictionary:
	return DataLoader.get_injury(id)


func get_season(index: int) -> Dictionary:
	return DataLoader.get_season_by_index(index)


func get_hireling(id: String) -> Dictionary:
	return DataLoader.get_hireling(id)


func get_tier(id: String) -> Dictionary:
	return DataLoader.get_tier(id)


func get_tier_by_index(index: int) -> Dictionary:
	return DataLoader.get_tier_by_index(index)


func get_survival_param(key: String) -> Variant:
	return DataLoader.survival.get(key, null)
