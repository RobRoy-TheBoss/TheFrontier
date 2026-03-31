## Area
## Represents a single gameplay Area. Manages resource discovery trigger zones,
## registers with WorldManager, and owns a SpawnManager.
extends Node3D

@export var area_id: String = "area_default"
@export var region_id: String = "region_01"
@export var east_west_position: float = 0.5  # 0 = east, 1 = west
@export var is_deep_water_port: bool = false
@export var area_resources: Array = []  # [{ "resource_id": str, "richness": float, "hidden": bool }]
@export var spawn_table: Array = []
@export var difficulty: float = 1.0
## Biome string matched to AudioManager.BIOME_AMBIENCE keys.
## Auto-populated from DataLoader.areas at ready if left empty.
@export var biome: String = ""
## Half-extents of the AreaTrigger BoxShape3D in world units.
@export var area_bounds: Vector3 = Vector3(200.0, 20.0, 200.0)

# Settlement site (designer-placed)
@export var settlement_site_position: Vector3 = Vector3.ZERO
@export var settlement_site_rotation: float = 0.0

@onready var spawn_manager: AreaSpawnManager = $SpawnManager
@onready var resource_zones: Node3D = $ResourceZones
@onready var _area_trigger: Area3D = $AreaTrigger

var _discovered_resources: Dictionary = {}
## Populated at runtime by BiomeEdge nodes. Maps neighbor area_id → biome string.
var neighbor_biomes: Dictionary = {}


func register_neighbor_biome(neighbor_id: String, biome_type: String) -> void:
	if neighbor_id != "":
		neighbor_biomes[neighbor_id] = biome_type


func _ready() -> void:
	WorldManager.register_area_node(area_id, self)
	_populate_from_data()
	_setup_spawn_manager()
	_setup_trigger()
	# If this is the player's starting area, fire on_player_enter after all
	# _ready() calls complete (player must be in scene tree first).
	if area_id == GameState.current_area_id:
		call_deferred("on_player_enter")


func _exit_tree() -> void:
	WorldManager.unregister_area_node(area_id)


func _setup_spawn_manager() -> void:
	if spawn_manager:
		spawn_manager.area_id = area_id
		spawn_manager.east_west_scalar = east_west_position
		spawn_manager.spawn_table = spawn_table


func on_player_enter() -> void:
	WorldManager.enter_area(area_id)
	# Discover non-hidden surface resources on entry
	for res in area_resources:
		if not res.get("hidden", false):
			_discover_resource(res["resource_id"], res["richness"])
	# Update ambient audio biome
	if biome != "":
		var audio_mgr = get_tree().get_first_node_in_group("audio_manager")
		if audio_mgr:
			audio_mgr.set_biome(biome)


func _discover_resource(resource_id: String, richness: float) -> void:
	if _discovered_resources.has(resource_id):
		return
	_discovered_resources[resource_id] = richness
	WorldManager.log_resource_discovery(area_id, resource_id, richness)


func survey_all_resources() -> void:
	# Called by Surveyor hireling or Ritualist Reveal
	for res in area_resources:
		_discover_resource(res["resource_id"], res["richness"])
	WorldManager.mark_area_fully_explored(area_id)


func get_settlement_site_transform() -> Transform3D:
	var t: Transform3D = Transform3D()
	t.origin = settlement_site_position
	t = t.rotated(Vector3.UP, deg_to_rad(settlement_site_rotation))
	return t


func _populate_from_data() -> void:
	var data: Dictionary = DataLoader.get_area(area_id)
	if data.is_empty():
		return
	if biome == "":
		biome = data.get("biome", "")
	if area_resources.is_empty():
		area_resources = data.get("area_resources", [])
	if spawn_table.is_empty():
		var table_id: String = data.get("spawn_table_id", "")
		if table_id != "":
			spawn_table = DataLoader.get_spawn_table(table_id).get("entries", [])
	if difficulty == 1.0:
		difficulty = float(data.get("difficulty", 1.0))


func _setup_trigger() -> void:
	if _area_trigger == null:
		return
	# Assign a box shape sized to area_bounds if the CollisionShape3D has none
	var col: CollisionShape3D = _area_trigger.get_node_or_null("CollisionShape3D")
	if col and col.shape == null:
		var box := BoxShape3D.new()
		box.size = area_bounds
		col.shape = box
	# Connect body_entered once
	if not _area_trigger.body_entered.is_connected(_on_trigger_body_entered):
		_area_trigger.body_entered.connect(_on_trigger_body_entered)


func _on_trigger_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		on_player_enter()
