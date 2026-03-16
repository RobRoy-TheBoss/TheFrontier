## ItemCache
## A loot cache in the world — used for death item drops, hidden caches, and rune locations.
extends Node3D

var cached_items: Array = []  # [{ item_id, count, runes }]

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var interact_area: Area3D = $InteractArea


func _ready() -> void:
	add_to_group("item_cache")
	if has_meta("items"):
		cached_items = get_meta("items")
	if cached_items.is_empty():
		queue_free()


func interact(player: Node) -> void:
	_loot_all(player)


func _loot_all(player: Node) -> void:
	for entry in cached_items:
		player.add_item_to_inventory(entry["item_id"], entry.get("count", 1))
	cached_items.clear()
	queue_free()


func add_item(item_id: String, count: int = 1) -> void:
	for entry in cached_items:
		if entry["item_id"] == item_id:
			entry["count"] += count
			return
	cached_items.append({ "item_id": item_id, "count": count, "runes": [] })
