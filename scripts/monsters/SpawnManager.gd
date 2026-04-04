## AreaSpawnManager
## Per-area monster spawning component. Reads spawn table from area data,
## applies east-west difficulty scalar, respects settlement suppression and safe zones.
class_name AreaSpawnManager
extends Node3D

@export var area_id: String = ""
@export var east_west_scalar: float = 1.0  # 0 = east (easy), 1 = west (hardest)
@export var spawn_table: Array = []  # Override from area data, else loaded from data
@export var max_monsters: int = 40
@export var despawn_distance: float = 150.0

const SPAWN_INTERVAL := 30.0
const MIN_SPAWN_DIST_FROM_PLAYER := 30.0
const WATER_LEVEL := 8.5  # must match HexAssetScatterer.WATER_LEVEL

var _active_monsters: Array = []
var _spawn_timer: float = 0.0
var _suppression_percent: float = 0.0
var _settlement_in_area: String = ""

const MONSTER_SCENE := preload("res://scenes/monsters/MonsterBase.tscn")


func _ready() -> void:
	_load_area_spawn_data()
	recalculate_suppression()


func _physics_process(delta: float) -> void:
	if GameState.is_sleeping or GameState.batch_processing:
		return
	_cleanup_dead_monsters()
	_despawn_distant_monsters()
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_try_spawn()
		_spawn_timer = SPAWN_INTERVAL


func _load_area_spawn_data() -> void:
	# Placeholder: real area data loaded from map JSON
	# spawn_table already set by Area node or exported
	pass


func recalculate_suppression() -> void:
	_suppression_percent = 0.0
	_settlement_in_area = ""
	for sid in SettlementManager.settlements:
		var s: SettlementManager.SettlementData = SettlementManager.settlements[sid]
		if s.area_id == area_id:
			_settlement_in_area = sid
			var tier := DataLoader.get_tier_by_index(s.tier_index)
			_suppression_percent = tier.get("area_suppression_percent", 25) / 100.0
			return


func _try_spawn() -> void:
	if _active_monsters.size() >= max_monsters:
		return
	if randf() < _suppression_percent:
		return

	# Batch fill on first spawn (timer was 0.0); trickle after that
	var batch := max_monsters if _active_monsters.is_empty() else 1
	for i in range(batch):
		if _active_monsters.size() >= max_monsters:
			break
		var monster_id := "prowler" if randf() < 0.6 else "bog_lurker"  # DEBUG
		if monster_id == "":
			break
		var monster_data: Dictionary = DataLoader.get_monster(monster_id)
		var territory: String = monster_data.get("territory", "")
		var spawn_pos := _find_spawn_position(territory)
		if spawn_pos == Vector3.ZERO:
			continue
		var monster_instance := MONSTER_SCENE.instantiate()
		monster_instance.monster_id = monster_id
		get_tree().root.add_child(monster_instance)
		monster_instance.global_position = spawn_pos
		monster_instance.connect("died", _on_monster_died)
		_active_monsters.append(monster_instance)


func _pick_monster_from_table() -> String:
	if spawn_table.is_empty():
		return ""
	var season := GameState.get_current_season()
	var season_modifier: float = season.get("spawn_rate_modifier", 1.0)

	var total_weight := 0.0
	var weighted_table := []
	for entry in spawn_table:
		var mid: String = entry.get("monster_id", entry.get("id", ""))
		var monster_data: Dictionary = DataLoader.get_monster(mid)
		if monster_data.is_empty():
			continue
		# Difficulty filter: east-west scalar
		var difficulty: int = monster_data.get("difficulty", 1)
		var min_scalar := (difficulty - 1) / 10.0
		if east_west_scalar < min_scalar:
			continue
		var weight: float = entry.get("weight", 1.0) * season_modifier
		weighted_table.append({ "id": mid, "weight": weight })
		total_weight += weight

	if weighted_table.is_empty():
		return ""
	var roll := randf() * total_weight
	var cumulative := 0.0
	for entry in weighted_table:
		cumulative += entry["weight"]
		if roll <= cumulative:
			return entry["id"]
	return ""


func _find_spawn_position(territory: String = "") -> Vector3:
	var player := get_tree().get_first_node_in_group("player")
	var space := get_world_3d().direct_space_state
	var attempts := 10
	while attempts > 0:
		var offset := Vector3(randf_range(-160, 160), 0, randf_range(-160, 160))
		var xz := global_position + offset
		# Raycast straight down from above to find terrain surface
		var ray := PhysicsRayQueryParameters3D.create(
			Vector3(xz.x, xz.y + 200.0, xz.z),
			Vector3(xz.x, xz.y - 50.0,  xz.z)
		)
		ray.collision_mask = 1  # terrain layer
		var hit := space.intersect_ray(ray)
		if hit.is_empty():
			attempts -= 1
			continue
		var pos: Vector3 = hit["position"] + Vector3(0.0, 0.1, 0.0)
		match territory:
			"terrestrial":
				if pos.y <= WATER_LEVEL:
					attempts -= 1
					continue
			"aquatic":
				if pos.y > WATER_LEVEL:
					attempts -= 1
					continue
			"amphibious":
				if pos.y > WATER_LEVEL + 3.0 or pos.y < WATER_LEVEL - 6.0:
					attempts -= 1
					continue
		if player and pos.distance_to(player.global_position) < MIN_SPAWN_DIST_FROM_PLAYER:
			attempts -= 1
			continue
		if _in_safe_zone(pos):
			attempts -= 1
			continue
		return pos
	return Vector3.ZERO


func _in_safe_zone(pos: Vector3) -> bool:
	for sid in SettlementManager.settlements:
		var s: SettlementManager.SettlementData = SettlementManager.settlements[sid]
		var tier := DataLoader.get_tier_by_index(s.tier_index)
		var safe_radius: float = tier.get("safe_zone_radius", 40.0)
		if pos.distance_to(s.position) < safe_radius:
			return true
	return false


func _cleanup_dead_monsters() -> void:
	_active_monsters = _active_monsters.filter(func(m): return is_instance_valid(m))


func _despawn_distant_monsters() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	for m in _active_monsters.duplicate():
		if not is_instance_valid(m):
			continue
		if m.global_position.distance_to(player.global_position) > despawn_distance:
			m.queue_free()
			_active_monsters.erase(m)


func _on_monster_died(monster_id: String, pos: Vector3) -> void:
	pass  # Future: drop items at pos, update kill counts
