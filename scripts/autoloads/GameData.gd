## GameData
## Autoload singleton. Loads and caches all JSON data definitions at startup.
## All systems read game definitions through this singleton.
extends Node

# Raw loaded data
var weapons: Dictionary = {}
var ammo: Dictionary = {}
var armor: Dictionary = {}
var runes: Dictionary = {}
var disciplines: Dictionary = {}
var reagents: Dictionary = {}
var monsters: Dictionary = {}
var items: Dictionary = {}
var recipes: Dictionary = {}
var injuries: Dictionary = {}
var seasons: Array = []
var settlement_tiers: Dictionary = {}
var hirelings: Dictionary = {}
var survival_params: Dictionary = {}

const DATA_PATH := "res://data/"

func _ready() -> void:
	_load_all()


func _load_all() -> void:
	survival_params = _load_json("survival/survival_params.json")

	var weapons_data := _load_json("weapons/weapons.json")
	for w in weapons_data.get("weapons", []):
		weapons[w["id"]] = w

	var ammo_data := _load_json("weapons/ammo.json")
	for a in ammo_data.get("ammo", []):
		ammo[a["id"]] = a

	var armor_data := _load_json("armor/armor.json")
	for a in armor_data.get("armor_pieces", []):
		armor[a["id"]] = a

	var rune_data := _load_json("runes/runes.json")
	for r in rune_data.get("runes", []):
		runes[r["id"]] = r

	var discipline_data := _load_json("disciplines/disciplines.json")
	for d in discipline_data.get("disciplines", []):
		disciplines[d["id"]] = d

	var reagent_data := _load_json("reagents/reagents.json")
	for r in reagent_data.get("reagents", []):
		reagents[r["id"]] = r

	var monster_data := _load_json("monsters/monsters.json")
	for m in monster_data.get("monsters", []):
		monsters[m["id"]] = m

	var item_data := _load_json("items/items.json")
	for i in item_data.get("items", []):
		items[i["id"]] = i

	var recipe_data := _load_json("recipes/recipes.json")
	for r in recipe_data.get("recipes", []):
		recipes[r["id"]] = r

	var injury_data := _load_json("injuries/injuries.json")
	for i in injury_data.get("injuries", []):
		injuries[i["id"]] = i

	var season_data := _load_json("seasons/seasons.json")
	seasons = season_data.get("seasons", [])

	var tier_data := _load_json("settlements/settlement_tiers.json")
	settlement_tiers = tier_data

	var hireling_data := _load_json("hirelings/hirelings.json")
	for h in hireling_data.get("hirelings", []):
		hirelings[h["id"]] = h

	print("[GameData] All data loaded.")


func _load_json(relative_path: String) -> Dictionary:
	var full_path := DATA_PATH + relative_path
	var file := FileAccess.open(full_path, FileAccess.READ)
	if file == null:
		push_error("[GameData] Failed to open: " + full_path)
		return {}
	var text := file.get_as_text()
	file.close()
	var result := JSON.parse_string(text)
	if result == null:
		push_error("[GameData] Failed to parse JSON: " + full_path)
		return {}
	return result


func get_weapon(id: String) -> Dictionary:
	return weapons.get(id, {})


func get_armor(id: String) -> Dictionary:
	return armor.get(id, {})


func get_rune(id: String) -> Dictionary:
	return runes.get(id, {})


func get_discipline(id: String) -> Dictionary:
	return disciplines.get(id, {})


func get_monster(id: String) -> Dictionary:
	return monsters.get(id, {})


func get_item(id: String) -> Dictionary:
	return items.get(id, {})


func get_recipe(id: String) -> Dictionary:
	return recipes.get(id, {})


func get_injury(id: String) -> Dictionary:
	return injuries.get(id, {})


func get_season(index: int) -> Dictionary:
	if index < 0 or index >= seasons.size():
		return {}
	return seasons[index]


func get_hireling(id: String) -> Dictionary:
	return hirelings.get(id, {})


func get_tier(id: String) -> Dictionary:
	for t in settlement_tiers.get("tiers", []):
		if t["id"] == id:
			return t
	return {}


func get_tier_by_index(index: int) -> Dictionary:
	var tiers: Array = settlement_tiers.get("tiers", [])
	if index < 0 or index >= tiers.size():
		return {}
	return tiers[index]


func get_survival_param(key: String) -> Variant:
	return survival_params.get(key, null)
