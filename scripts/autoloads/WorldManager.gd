## WorldManager
## Autoload singleton. Tracks area discovery, resource logging, player's current area,
## and precursor site randomization.
extends Node

signal area_entered(area_id: String)
signal area_resource_discovered(area_id: String, resource_id: String)
signal precursor_site_discovered(site_id: String, discipline_id: String)
signal landmark_named(landmark_id: String, name: String)

# area_id -> { "discovered_resources": {res_id: richness}, "fully_explored": bool }
var area_data: Dictionary = {}

# site_id -> { "discipline_id": str, "discovered": bool, "attuned": bool }
var precursor_sites: Dictionary = {}

# All spawned areas (Area nodes register here)
var active_areas: Dictionary = {}  # area_id -> Area node ref

# Current map
var current_map_id: String = "eastern_frontier"

func load_map(map_id: String) -> void:
	current_map_id = map_id
	active_areas.clear()
	get_tree().reload_current_scene()


func _ready() -> void:
	_randomize_precursor_sites()


func _randomize_precursor_sites() -> void:
	# Uses GameState.world_seed. 27 sites total, 12 are Places of Power.
	# Assign discipline_ids to 12 of them (min 2 per discipline = 14, distribute 12 among 7 disciplines).
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.world_seed

	var disciplines := ["survivalist", "ritualist", "warrior", "swordsman", "artificer", "alchemist", "wizard"]
	var power_site_ids: Array = []
	for i in range(27):
		var site_id := "precursor_site_%02d" % i
		precursor_sites[site_id] = { "discovered": false, "attuned": false }
		if i < 12:
			power_site_ids.append(site_id)

	# Guarantee at least 1 per discipline for first 7, then random for remaining 5
	var assignments := []
	for d in disciplines:
		assignments.append(d)
	# Add 5 more random
	for i in range(5):
		assignments.append(disciplines[rng.randi() % disciplines.size()])
	# Shuffle
	for i in range(assignments.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var temp = assignments[i]
		assignments[i] = assignments[j]
		assignments[j] = temp

	for i in range(power_site_ids.size()):
		var sid: String = power_site_ids[i]
		var disc_id: String = assignments[i]
		precursor_sites[sid]["discipline_id"] = disc_id
		GameState.set_precursor_assignment(sid, disc_id)


func enter_area(area_id: String) -> void:
	GameState.current_area_id = area_id
	if not area_data.has(area_id):
		area_data[area_id] = { "discovered_resources": {}, "fully_explored": false }
	area_entered.emit(area_id)


func log_resource_discovery(area_id: String, resource_id: String, richness: float) -> void:
	if not area_data.has(area_id):
		area_data[area_id] = { "discovered_resources": {}, "fully_explored": false }
	if not area_data[area_id]["discovered_resources"].has(resource_id):
		area_data[area_id]["discovered_resources"][resource_id] = richness
		area_resource_discovered.emit(area_id, resource_id)
		# Sync to settlement if one exists in this area
		_sync_resource_to_settlement(area_id, resource_id, richness)


func _sync_resource_to_settlement(area_id: String, resource_id: String, richness: float) -> void:
	for sid in SettlementManager.settlements:
		var s: SettlementManager.SettlementData = SettlementManager.settlements[sid]
		if s.area_id == area_id:
			s.discovered_resources[resource_id] = richness
			return


func discover_precursor_site(site_id: String) -> void:
	if not precursor_sites.has(site_id):
		return
	precursor_sites[site_id]["discovered"] = true
	var disc_id: String = precursor_sites[site_id].get("discipline_id", "")
	precursor_site_discovered.emit(site_id, disc_id)


func attune_to_site(site_id: String) -> bool:
	if not precursor_sites.has(site_id):
		return false
	var site: Dictionary = precursor_sites[site_id]
	if not site.get("discovered", false):
		return false
	var disc_id: String = site.get("discipline_id", "")
	if disc_id == "":
		return false  # Not a Place of Power

	if DisciplineManager.is_attuned(disc_id):
		# Second site of same discipline: bonus XP
		DisciplineManager.add_xp_direct(disc_id, 200)
		return true

	if DisciplineManager.attune(disc_id):
		site["attuned"] = true
		DisciplineManager.add_xp(disc_id, "precursor_site_visited")
		return true
	return false


func is_place_of_power(site_id: String) -> bool:
	return precursor_sites.get(site_id, {}).has("discipline_id")


func get_area_resources(area_id: String) -> Dictionary:
	return area_data.get(area_id, {}).get("discovered_resources", {})


func mark_area_fully_explored(area_id: String) -> void:
	if area_data.has(area_id):
		area_data[area_id]["fully_explored"] = true


func name_landmark(landmark_id: String, player_name: String) -> void:
	GameState.name_landmark(landmark_id, player_name)
	landmark_named.emit(landmark_id, player_name)


func register_area_node(area_id: String, node: Node) -> void:
	active_areas[area_id] = node


func unregister_area_node(area_id: String) -> void:
	active_areas.erase(area_id)
