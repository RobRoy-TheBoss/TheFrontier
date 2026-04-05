## PlayerArmorDisplay
## Attaches outfit mesh parts to the player's Skeleton3D when armor is equipped.
## Outfit GLTFs (Modular Character Outfits - Fantasy) use the same UE skeleton
## as the UBC base character, so meshes bind directly without retargeting.
class_name PlayerArmorDisplay
extends Node

var _player: CharacterBody3D
var _skeleton: Skeleton3D
# slot -> { item_id, nodes }
var _slot_meshes: Dictionary = {}



func _ready() -> void:
	_player = get_parent()
	await _player.ready
	_skeleton = _player.character_model.get_node_or_null("Armature/Skeleton3D") as Skeleton3D
	if _skeleton == null:
		push_warning("PlayerArmorDisplay: Skeleton3D not found at Armature/Skeleton3D")
		return

	_player.inventory.inventory_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var equipped: Dictionary = _player.inventory.equipped

	# Remove meshes for slots that are now empty or changed
	for slot in _slot_meshes.keys():
		var current_id: String = ""
		if equipped.has(slot) and not equipped[slot].is_empty():
			current_id = equipped[slot].get("item_id", "")
		if current_id != _slot_meshes[slot].get("item_id", ""):
			_clear_slot(slot)

	# Add meshes for newly equipped armor
	for slot in equipped.keys():
		var item: Dictionary = equipped[slot]
		if item.is_empty() or _slot_meshes.has(slot):
			continue
		var item_id: String = item.get("item_id", "")
		var def: Dictionary = GameData.get_armor(item_id)
		var mesh_path: String = def.get("mesh_path", "")
		if mesh_path.is_empty():
			continue
		_attach_slot(slot, item_id, mesh_path)

	_update_base_mesh_visibility(equipped)


func _attach_slot(slot: String, item_id: String, mesh_path: String) -> void:
	var packed: PackedScene = load(mesh_path) as PackedScene
	if packed == null:
		push_warning("PlayerArmorDisplay: could not load %s" % mesh_path)
		return

	var outfit_root: Node = packed.instantiate()
	var meshes: Array = []
	_collect_skinned_meshes(outfit_root, meshes)

	if meshes.is_empty():
		outfit_root.free()
		push_warning("PlayerArmorDisplay: no skinned meshes in %s" % mesh_path)
		return

	var attached: Array = []
	for mi: MeshInstance3D in meshes:
		var parent := mi.get_parent()
		if parent:
			parent.remove_child(mi)
		mi.name = "ArmorMesh_%s" % slot
		mi.scale = Vector3(1.05, 1.05, 1.05)
		_skeleton.add_child(mi)
		mi.skeleton = NodePath("..")
		attached.append(mi)

	outfit_root.free()
	_slot_meshes[slot] = { "item_id": item_id, "nodes": attached }


func _clear_slot(slot: String) -> void:
	if not _slot_meshes.has(slot):
		return
	for node in _slot_meshes[slot].get("nodes", []):
		if is_instance_valid(node):
			node.queue_free()
	_slot_meshes.erase(slot)


func _update_base_mesh_visibility(_equipped: Dictionary) -> void:
	pass


func _collect_skinned_meshes(node: Node, result: Array) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.skin != null or mi.mesh != null:
			result.append(mi)
	for child in node.get_children():
		_collect_skinned_meshes(child, result)
