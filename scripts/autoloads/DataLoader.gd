## DataLoader
## Autoload singleton. Replaces GameData.gd for LLR v0.5.1 (LPROJ-003).
## Loads ALL JSON data files from the flat res://data/ layout at startup.
## All game systems should read definitions through this singleton.
extends Node

signal data_loaded

const DATA_PATH := "res://data/"

# --- Raw data stores (id -> Dictionary for O(1) lookup) ---
var monsters: Dictionary = {}
var spawn_tables: Dictionary = {}
var resources: Dictionary = {}
var areas: Dictionary = {}
var settlement_tiers: Dictionary = {}
var trade_weights: Dictionary = {}
var export_thresholds: Dictionary = {}
var disciplines: Dictionary = {}
var reagents: Dictionary = {}
var runes: Dictionary = {}
var items: Dictionary = {}
var injuries: Dictionary = {}
var weapons: Dictionary = {}
var seasons: Dictionary = {}       # keyed by "id" string
var _seasons_ordered: Array = []   # preserves original array order for index lookup
var survival: Dictionary = {}
var recipes: Dictionary = {}
var manufactured_goods: Dictionary = {}
var hirelings: Dictionary = {}
var roads: Dictionary = {}
var landmarks: Dictionary = {}


func _ready() -> void:
	_load_all()
	data_loaded.emit()
	print("[DataLoader] All data loaded.")


func _load_all() -> void:
	# Monsters
	var monster_data := _load_json("monsters.json")
	for m in monster_data.get("monsters", []):
		monsters[m["id"]] = m

	# Spawn tables
	var spawn_data := _load_json("spawn_tables.json")
	for s in spawn_data.get("spawn_tables", []):
		spawn_tables[s["id"]] = s

	# Resources
	var resource_data := _load_json("resources.json")
	for r in resource_data.get("resources", []):
		resources[r["id"]] = r

	# Areas
	var area_data := _load_json("areas.json")
	for a in area_data.get("areas", []):
		areas[a["id"]] = a

	# Settlement tiers (also keep raw dict for road_quality etc.)
	var tier_data := _load_json("settlement_tiers.json")
	settlement_tiers = tier_data

	# Trade weights
	trade_weights = _load_json("trade_weights.json")

	# Export thresholds
	export_thresholds = _load_json("export_thresholds.json")

	# Disciplines
	var discipline_data := _load_json("disciplines.json")
	for d in discipline_data.get("disciplines", []):
		disciplines[d["id"]] = d

	# Reagents
	var reagent_data := _load_json("reagents.json")
	for r in reagent_data.get("reagents", []):
		reagents[r["id"]] = r

	# Runes
	var rune_data := _load_json("runes.json")
	for r in rune_data.get("runes", []):
		runes[r["id"]] = r

	# Items
	var item_data := _load_json("items.json")
	for i in item_data.get("items", []):
		items[i["id"]] = i

	# Injuries
	var injury_data := _load_json("injuries.json")
	for i in injury_data.get("injuries", []):
		injuries[i["id"]] = i

	# Weapons
	var weapon_data := _load_json("weapons.json")
	for w in weapon_data.get("weapons", []):
		weapons[w["id"]] = w

	# Seasons (ordered array kept for index-based lookup)
	var season_data := _load_json("seasons.json")
	_seasons_ordered = season_data.get("seasons", [])
	for s in _seasons_ordered:
		seasons[s["id"]] = s

	# Survival params
	survival = _load_json("survival.json")

	# Recipes
	var recipe_data := _load_json("recipes.json")
	for r in recipe_data.get("recipes", []):
		recipes[r["id"]] = r

	# Manufactured goods
	var mg_data := _load_json("manufactured_goods.json")
	for g in mg_data.get("manufactured_goods", []):
		manufactured_goods[g["id"]] = g

	# Hirelings
	var hireling_data := _load_json("hirelings.json")
	for h in hireling_data.get("hirelings", []):
		hirelings[h["id"]] = h

	# Roads
	var road_data := _load_json("roads.json")
	for r in road_data.get("roads", []):
		roads[r["id"]] = r

	# Landmarks
	var landmark_data := _load_json("landmarks.json")
	for l in landmark_data.get("landmarks", []):
		landmarks[l["id"]] = l


func _load_json(filename: String) -> Dictionary:
	var full_path := DATA_PATH + filename
	var file := FileAccess.open(full_path, FileAccess.READ)
	if file == null:
		push_error("[DataLoader] Failed to open: " + full_path)
		return {}
	var text := file.get_as_text()
	file.close()
	var result := JSON.parse_string(text)
	if result == null:
		push_error("[DataLoader] Failed to parse JSON: " + full_path)
		return {}
	return result


# --- Typed getters ---

func get_monster(id: String) -> Dictionary:
	return monsters.get(id, {})


func get_item(id: String) -> Dictionary:
	return items.get(id, {})


func get_weapon(id: String) -> Dictionary:
	return weapons.get(id, {})


func get_rune(id: String) -> Dictionary:
	return runes.get(id, {})


func get_discipline(id: String) -> Dictionary:
	return disciplines.get(id, {})


func get_reagent(id: String) -> Dictionary:
	return reagents.get(id, {})


func get_injury(id: String) -> Dictionary:
	return injuries.get(id, {})


func get_area(id: String) -> Dictionary:
	return areas.get(id, {})


## Returns the settlement tier Dictionary for the given integer index (0-based).
func get_tier(tier_int: int) -> Dictionary:
	var tiers: Array = settlement_tiers.get("tiers", [])
	if tier_int < 0 or tier_int >= tiers.size():
		return {}
	return tiers[tier_int]


func get_hireling(id: String) -> Dictionary:
	return hirelings.get(id, {})


func get_recipe(id: String) -> Dictionary:
	return recipes.get(id, {})


## Returns a season by its string id. Use get_season_by_index() for ordered access.
func get_season(id: String) -> Dictionary:
	return seasons.get(id, {})


## Returns a season Dictionary by its array index (e.g. 0=spring, 1=summer …).
func get_season_by_index(index: int) -> Dictionary:
	if index < 0 or index >= _seasons_ordered.size():
		return {}
	return _seasons_ordered[index]


func get_spawn_table(id: String) -> Dictionary:
	return spawn_tables.get(id, {})


func get_resource(id: String) -> Dictionary:
	return resources.get(id, {})
