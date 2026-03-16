## ResourceNode
## A gatherable resource node in the world (plant, ore vein, timber, etc.)
## Triggers resource discovery logging when player is in proximity.
extends Area3D

@export var resource_id: String = "fire_herb"
@export var richness: float = 1.0
@export var is_hidden: bool = false  # Only revealed by Alchemist Keen Eye
@export var respawn_days: int = 3
@export var gather_time: float = 2.0

var _gathered: bool = false
var _respawn_day: int = 0

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var interact_label: Label3D = $InteractLabel


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if is_hidden:
		visible = false


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if _gathered:
		return
	# Log discovery
	WorldManager.log_resource_discovery(GameState.current_area_id, resource_id, richness)
	# Show gather prompt
	if interact_label:
		interact_label.visible = true


func interact(player: Node) -> bool:
	if _gathered:
		return false
	if is_hidden and not DisciplineManager.has_passive("keen_eye"):
		return false

	# Gather
	_gathered = true
	_respawn_day = GameState.current_day + respawn_days
	if mesh:
		mesh.visible = false
	if interact_label:
		interact_label.visible = false

	# Add to inventory
	player.add_item_to_inventory(resource_id, 1)
	DisciplineManager.add_xp("alchemist", "ingredient_gathered")
	DisciplineManager.add_xp("survivalist", "off_road_travel_km")
	return true


func reveal_hidden() -> void:
	if is_hidden:
		visible = true


func check_respawn() -> void:
	if _gathered and GameState.current_day >= _respawn_day:
		_gathered = false
		if mesh:
			mesh.visible = true
