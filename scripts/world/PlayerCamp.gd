## PlayerCamp
## Represents the player's temporary basecamp. Spawned when a campfire is lit.
## Not a settlement — no trade network, no suppression.
## Tracks placed camp equipment and active hirelings.
extends Node3D

var hireling_ids: Array = []
var has_tent: bool = false
var has_campfire: bool = false
var has_alchemy_set: bool = false

@onready var campfire_light: OmniLight3D = $CampfireLight
@onready var campfire_mesh: MeshInstance3D = $CampfireMesh


func _ready() -> void:
	add_to_group("player_camp")
	set_meta("hireling_ids", hireling_ids)
	_notify_nearby_monsters()


func setup(in_has_tent: bool, in_has_campfire: bool, in_has_alchemy: bool) -> void:
	has_tent = in_has_tent
	has_campfire = in_has_campfire
	has_alchemy_set = in_has_alchemy

	if campfire_light:
		campfire_light.visible = has_campfire
	if campfire_mesh:
		campfire_mesh.visible = has_campfire

	if has_campfire:
		_notify_nearby_monsters()


func _notify_nearby_monsters() -> void:
	if not has_campfire:
		return
	var monsters := get_tree().get_nodes_in_group("monster")
	for m in monsters:
		if not is_instance_valid(m):
			continue
		var dist: float = m.global_position.distance_to(global_position)
		if dist > 30.0:
			continue
		var data: Dictionary = GameData.get_monster(m.monster_id)
		match data.get("fire_reaction", "neutral"):
			"avoids", "strongly_avoids":
				# Drive monster away
				if m.has_method("flee_from"):
					m.flee_from(global_position)
			"attracted":
				if m.has_method("alert_to_sound"):
					m.alert_to_sound(global_position)


func hire(hireling_id: String) -> bool:
	var hireling := GameData.get_hireling(hireling_id)
	if hireling.is_empty():
		return false
	if hireling_id in hireling_ids:
		return false
	hireling_ids.append(hireling_id)
	set_meta("hireling_ids", hireling_ids)
	return true


func dismiss(hireling_id: String) -> void:
	hireling_ids.erase(hireling_id)
	set_meta("hireling_ids", hireling_ids)


func get_hireling_ids() -> Array:
	return hireling_ids


func can_sleep() -> bool:
	return has_tent


func can_brew() -> bool:
	return has_alchemy_set


func pack_up() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		if has_tent:
			player.inventory.add_item("tent", 1)
		if has_campfire:
			player.inventory.add_item("campfire_kit", 1)
		if has_alchemy_set:
			player.inventory.add_item("alchemy_set", 1)
	queue_free()
