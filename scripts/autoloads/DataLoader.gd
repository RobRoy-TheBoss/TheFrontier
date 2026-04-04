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
var hex_templates: Dictionary = {}          # template_id → template
var hex_template_by_mesh: Dictionary = {}   # mesh filename (lowercase) → template
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
	# Monsters (array root)
	for m in _load_json_array("monsters.json"):
		monsters[m["id"]] = m

	# Spawn tables (array root)
	for s in _load_json_array("spawn_tables.json"):
		spawn_tables[s["id"]] = s

	# Hex templates — also build mesh-name → template lookup
	for t in _load_json_array("hex_templates.json"):
		hex_templates[t["template_id"]] = t
		for mesh_name in t.get("meshes", []):
			hex_template_by_mesh[mesh_name.to_lower()] = t

	# Resources (array root)
	for r in _load_json_array("resources.json"):
		resources[r["id"]] = r

	# Areas (sparse overlay keyed by "col_row")
	for a in _load_json_array("areas.json"):
		var key: String = "%d_%d" % [int(a["col"]), int(a["row"])]
		a["_key"] = key
		areas[key] = a
		# Also index by human id if present, for settlement lookups
		if a.has("id"):
			areas[a["id"]] = a

	# Settlement tiers (array root — store as {"tiers": [...]} for compatibility)
	var tiers_array: Array = _load_json_array("settlement_tiers.json")
	settlement_tiers = {"tiers": tiers_array}

	# Trade weights (dict root)
	trade_weights = _load_json("trade_weights.json")

	# Export thresholds (dict root — JSON stores flat numerics; expand to rich objects at load)
	var _raw_thresholds: Dictionary = _load_json("export_thresholds.json")
	for _thresh_key in _raw_thresholds:
		var _val: Variant = _raw_thresholds[_thresh_key]
		if _val is float or _val is int:
			export_thresholds[_thresh_key] = {"threshold": float(_val), "goods_tier": _thresh_key}
		else:
			export_thresholds[_thresh_key] = _val

	# Disciplines (array root OR dict with "disciplines"/"extended_disciplines" keys)
	var _disc_text := FileAccess.get_file_as_string(DATA_PATH + "disciplines.json")
	var _disc_raw: Variant = JSON.parse_string(_disc_text)
	var _launch_discs: Array = []
	var _ext_discs: Array = []
	if _disc_raw is Array:
		_launch_discs = _disc_raw
	elif _disc_raw is Dictionary:
		_launch_discs = _disc_raw.get("disciplines", [])
		_ext_discs = _disc_raw.get("extended_disciplines", [])
	for d in _launch_discs:
		disciplines[d["id"]] = d
	for d in _ext_discs:
		if disciplines.has(d["id"]):
			disciplines[d["id"]]["abilities"].append_array(d.get("abilities", []))
		else:
			disciplines[d["id"]] = d

	# Reagents (array root)
	for r in _load_json_array("reagents.json"):
		reagents[r["id"]] = r

	# Runes (array root)
	for r in _load_json_array("runes.json"):
		runes[r["id"]] = r

	# Items (array root)
	for i in _load_json_array("items.json"):
		items[i["id"]] = i

	# Injuries (array root)
	for i in _load_json_array("injuries.json"):
		injuries[i["id"]] = i

	# Weapons (array root)
	for w in _load_json_array("weapons.json"):
		weapons[w["id"]] = w

	# Seasons (array root)
	_seasons_ordered = _load_json_array("seasons.json")
	for s in _seasons_ordered:
		seasons[s["id"]] = s

	# Survival params (dict root)
	survival = _load_json("survival.json")

	# Recipes (array root)
	for r in _load_json_array("recipes.json"):
		recipes[r["id"]] = r

	# Manufactured goods (array root)
	for g in _load_json_array("manufactured_goods.json"):
		manufactured_goods[g["id"]] = g

	# Hirelings (array root)
	for h in _load_json_array("hirelings.json"):
		hirelings[h["id"]] = h

	# Roads (array root — keyed by quality int)
	for r in _load_json_array("roads.json"):
		roads[r["quality"]] = r
	roads["road_budget"] = 9
	roads["speed_multiplier"] = 1.3  # baseline paved road speed multiplier

	# Landmarks (array root)
	for l in _load_json_array("landmarks.json"):
		landmarks[l["id"]] = l


func _load_json(filename: String) -> Dictionary:
	var full_path: String = DATA_PATH + filename
	var file: FileAccess = FileAccess.open(full_path, FileAccess.READ)
	if file == null:
		push_error("[DataLoader] Failed to open: " + full_path)
		return {}
	var text: String = file.get_as_text()
	file.close()
	var result: Variant = JSON.parse_string(text)
	if result == null:
		push_error("[DataLoader] Failed to parse JSON: " + full_path)
		return {}
	if not result is Dictionary:
		push_error("[DataLoader] JSON root is not a Dictionary: " + full_path)
		return {}
	return result as Dictionary


func _load_json_array(filename: String) -> Array:
	var full_path: String = DATA_PATH + filename
	var file: FileAccess = FileAccess.open(full_path, FileAccess.READ)
	if file == null:
		push_error("[DataLoader] Failed to open: " + full_path)
		return []
	var text: String = file.get_as_text()
	file.close()
	var result: Variant = JSON.parse_string(text)
	if result == null:
		push_error("[DataLoader] Failed to parse JSON: " + full_path)
		return []
	if not result is Array:
		push_error("[DataLoader] JSON root is not an Array: " + full_path)
		return []
	return result as Array


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


## Returns the settlement tier Dictionary by string id (e.g. "hamlet").
func get_tier(id: String) -> Dictionary:
	var tiers: Array = settlement_tiers.get("tiers", [])
	for t in tiers:
		if (t as Dictionary).get("id", "") == id:
			return t as Dictionary
	return {}


## Returns the settlement tier Dictionary for the given integer index (0-based).
func get_tier_by_index(tier_int: int) -> Dictionary:
	var tiers: Array = settlement_tiers.get("tiers", [])
	if tier_int < 0 or tier_int >= tiers.size():
		return {}
	return tiers[tier_int] as Dictionary


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
	return _seasons_ordered[index] as Dictionary


func get_spawn_table(id: String) -> Dictionary:
	return spawn_tables.get(id, {})


func get_hex_template_for_mesh(mesh_filename: String) -> Dictionary:
	return hex_template_by_mesh.get(mesh_filename.to_lower(), {})


func get_resource(id: String) -> Dictionary:
	return resources.get(id, {})


## Returns any top-level survival value by key. May be float, int, Array, or Dictionary.
func get_survival_param(key: String) -> Variant:
	return survival.get(key, null)
