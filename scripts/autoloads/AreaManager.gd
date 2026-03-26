## AreaManager
## Autoload singleton. Manages area runtime state (LMAP-010..018).
## Replaces WorldManager.gd. Reads area definitions from DataLoader on ready,
## then tracks per-area discovered resources, settlement links, suppression, and
## map reveal status at runtime.
extends Node

signal resource_discovered(area_id: String, resource_id: String)

# area_id -> {
#   "discovered_resources": Array[String],
#   "settlement_id":        String,
#   "suppression_pct":      float,   # 0.0 – 1.0
#   "map_revealed":         bool
# }
var _area_states: Dictionary = {}

# Passability rule constants (checked against area edge feature tags)
const IMPASSABLE_EDGE_FEATURES: Array = ["cliff"]
const WATER_EDGE_FEATURES: Array     = ["river"]
const FORD_TAG: String               = "ford"
# Tier index at which a river edge becomes passable without a ford tag
const TOWN_TIER_INDEX: int           = 3


func _ready() -> void:
	_load_areas()


func _load_areas() -> void:
	# DataLoader must be earlier in the autoload order.
	for area_id in DataLoader.areas:
		_area_states[area_id] = {
			"discovered_resources": [],
			"settlement_id":        "",
			"suppression_pct":      0.0,
			"map_revealed":         false
		}
	print("[AreaManager] Initialised %d area states." % _area_states.size())


# --- Coordinate lookup ---

## Return the area_id whose axial position is nearest to world_pos.
## O(n) scan — cache results on the caller side for hot paths.
func get_area(world_pos: Vector3) -> String:
	var axial := HexGrid.world_to_axial(world_pos)
	# Areas store their axial coords as {"q": int, "r": int} in the data
	for area_id in DataLoader.areas:
		var data: Dictionary = DataLoader.areas[area_id]
		var aq: int = data.get("q", 0)
		var ar: int = data.get("r", 0)
		if aq == axial.x and ar == axial.y:
			return area_id
	return ""


## Return the merged static+runtime data for an area.
func get_area_data(area_id: String) -> Dictionary:
	var static_data: Dictionary = DataLoader.get_area(area_id)
	var runtime: Dictionary = _area_states.get(area_id, {})
	# Shallow merge: runtime keys shadow static keys where they exist
	var merged := static_data.duplicate()
	for key in runtime:
		merged[key] = runtime[key]
	return merged


# --- Resource discovery ---

## Mark a single resource as discovered in the area.
func discover_resource(area_id: String, resource_id: String) -> void:
	if not _area_states.has(area_id):
		push_warning("[AreaManager] discover_resource: unknown area '%s'" % area_id)
		return
	var state: Dictionary = _area_states[area_id]
	var discovered: Array = state["discovered_resources"]
	if resource_id in discovered:
		return
	discovered.append(resource_id)
	resource_discovered.emit(area_id, resource_id)


## Discover every resource listed in the area's static data at once.
func discover_all(area_id: String) -> void:
	var static_data := DataLoader.get_area(area_id)
	var all_resources: Array = static_data.get("resources", [])
	for rid in all_resources:
		discover_resource(area_id, rid)


# --- Edge passability ---

## Returns true if moving between two adjacent areas is allowed.
## Rules (LMAP-015):
##   - cliff edges are never passable.
##   - river edges require a ford tag OR the destination area has a Town-tier (>=2) settlement.
func is_edge_passable(area_a: String, area_b: String) -> bool:
	var data_a := DataLoader.get_area(area_a)
	var data_b := DataLoader.get_area(area_b)
	var q_a: int = data_a.get("q", 0)
	var r_a: int = data_a.get("r", 0)
	var q_b: int = data_b.get("q", 0)
	var r_b: int = data_b.get("r", 0)

	var edge_index := HexGrid.get_shared_edge_index(q_a, r_a, q_b, r_b)
	if edge_index == -1:
		push_warning("[AreaManager] is_edge_passable: areas '%s' and '%s' are not adjacent." % [area_a, area_b])
		return false

	# Each area can define per-edge features as edges[0..5] = [tag, ...]
	var edges_a: Array = data_a.get("edges", [])
	var features_a: Array = edges_a[edge_index] if edge_index < edges_a.size() else []

	for feat in IMPASSABLE_EDGE_FEATURES:
		if feat in features_a:
			return false

	for feat in WATER_EDGE_FEATURES:
		if feat in features_a:
			# Passable if ford tag is present OR destination has a Town+ settlement
			if FORD_TAG in features_a:
				return true
			var state_b: Dictionary = _area_states.get(area_b, {})
			var sid: String = state_b.get("settlement_id", "")
			if sid != "":
				var settlement = SettlementManager.get_settlement(sid)
				if settlement != null and settlement.tier_index >= TOWN_TIER_INDEX:
					return true
			return false

	return true


# --- Settlement link ---

## Associate a settlement with an area (called by SettlementManager / FoundingManager).
func set_area_settlement(area_id: String, settlement_id: String) -> void:
	if not _area_states.has(area_id):
		push_warning("[AreaManager] set_area_settlement: unknown area '%s'" % area_id)
		return
	_area_states[area_id]["settlement_id"] = settlement_id


# --- Suppression ---

## Return the current suppression percentage (0.0–1.0) for an area.
func get_suppression(area_id: String) -> float:
	if not _area_states.has(area_id):
		return 0.0
	return _area_states[area_id].get("suppression_pct", 0.0)


## Directly set suppression. Clamped to [0.0, 1.0].
func set_suppression(area_id: String, value: float) -> void:
	if not _area_states.has(area_id):
		push_warning("[AreaManager] set_suppression: unknown area '%s'" % area_id)
		return
	_area_states[area_id]["suppression_pct"] = clampf(value, 0.0, 1.0)


# --- Map reveal ---

func reveal_area(area_id: String) -> void:
	if _area_states.has(area_id):
		_area_states[area_id]["map_revealed"] = true


func is_area_revealed(area_id: String) -> bool:
	return _area_states.get(area_id, {}).get("map_revealed", false)
