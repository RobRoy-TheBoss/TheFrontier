## DeathUI
## Shown on player death. Handles respawn flow.
extends Control

@onready var death_label: Label = $Panel/DeathLabel
@onready var respawn_label: Label = $Panel/RespawnLabel
@onready var respawn_button: Button = $Panel/RespawnButton

var _respawn_settlement_id: String = ""


func _ready() -> void:
	add_to_group("death_ui")
	visible = false
	if respawn_button:
		respawn_button.pressed.connect(_on_respawn_pressed)
	await get_tree().process_frame
	var player_health := get_tree().get_first_node_in_group("player")
	if player_health and player_health.has_node("PlayerHealth"):
		player_health.get_node("PlayerHealth").player_died.connect(_on_player_died)


func _on_player_died() -> void:
	_handle_death()


## Called directly by Player._on_player_died() as an alternative entry point.
func show_death() -> void:
	_handle_death()


func _handle_death() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	# Drop all items at death location
	_drop_items_at_death(player)

	# Destroy any planted flags
	var flags := get_tree().get_nodes_in_group("settlement_flag")
	for flag in flags:
		if flag.has_method("destroy_on_player_death"):
			flag.destroy_on_player_death()

	# Find last rested settlement
	_respawn_settlement_id = _find_last_rested_settlement()

	# Show UI
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	GameState.is_paused_for_ui = true
	if death_label:
		death_label.text = "You have fallen."
	if respawn_label:
		var s := SettlementManager.get_settlement(_respawn_settlement_id)
		var name := _respawn_settlement_id.capitalize().replace("_", " ") if s else "The Starting Point"
		respawn_label.text = "Respawn at: %s" % name


func _drop_items_at_death(player: Node) -> void:
	var death_pos := player.global_position
	# Spawn a loot cache at death position with all inventory items
	var cache_scene := load("res://scenes/items/ItemCache.tscn")
	if cache_scene == null:
		return
	var cache := cache_scene.instantiate()
	cache.global_position = death_pos
	# Transfer inventory to cache
	var items_to_drop := player.inventory.items.duplicate(true)
	cache.set_meta("items", items_to_drop)
	player.inventory.items.clear()
	player.inventory.inventory_changed.emit()
	get_tree().root.add_child(cache)


func _find_last_rested_settlement() -> String:
	for sid in SettlementManager.settlements:
		var s: SettlementManager.SettlementData = SettlementManager.settlements[sid]
		if s.last_rested_here:
			return sid
	return "crestport"


func _on_respawn_pressed() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var s := SettlementManager.get_settlement(_respawn_settlement_id)
	if s:
		player.global_position = s.position + Vector3(2, 1, 2)
	# Restore minimal health
	player.health.current_health = player.health.max_health * 0.3
	player.health.health_changed.emit(player.health.current_health, player.health.max_health)
	visible = false
	GameState.is_paused_for_ui = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
