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

# Settlement site (designer-placed)
@export var settlement_site_position: Vector3 = Vector3.ZERO
@export var settlement_site_rotation: float = 0.0

@onready var spawn_manager: SpawnManager = $SpawnManager
@onready var resource_zones: Node3D = $ResourceZones

var _discovered_resources: Dictionary = {}


func _ready() -> void:
	WorldManager.register_area_node(area_id, self)
	_setup_spawn_manager()


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
	var t := Transform3D()
	t.origin = settlement_site_position
	t = t.rotated(Vector3.UP, deg_to_rad(settlement_site_rotation))
	return t
