## PlayerHome
## Purchasable player home at Village+.
## Provides persistent storage, alchemy workshop, and free bed (HOME-112).
extends Node3D

@export var settlement_id: String = ""

var is_owned: bool = false
var storage_items: Array = []

@onready var bed: Node3D = $Bed
@onready var workshop: Node3D = $AlchemyWorkshop
@onready var chest: Node3D = $StorageChest


func _ready() -> void:
	add_to_group("player_home")


func purchase(player: Node) -> bool:
	var s := SettlementManager.get_settlement(settlement_id)
	if s == null or s.tier_index < 1:
		return false
	var cost := 500  # Base cost; could be data-driven
	if player.inventory.currency < cost:
		return false
	player.inventory.currency -= cost
	is_owned = true
	s.is_player_home = true
	return true


func interact(player: Node) -> void:
	if not is_owned:
		_offer_purchase(player)
		return
	_show_home_menu(player)


func _offer_purchase(player: Node) -> void:
	var ui := get_tree().get_first_node_in_group("shop_ui")
	# Show a simple purchase prompt
	pass


func _show_home_menu(player: Node) -> void:
	var ui := get_tree().get_first_node_in_group("home_ui")
	if ui and ui.has_method("open"):
		ui.open(self)


func sleep_here(player: Node) -> void:
	for sid in SettlementManager.settlements:
		var s: SettlementManager.SettlementData = SettlementManager.settlements[sid]
		s.last_rested_here = (sid == settlement_id)
	player._do_sleep()


func open_storage(player: Node) -> void:
	var ui := get_tree().get_first_node_in_group("storage_ui")
	if ui and ui.has_method("open"):
		ui.open(storage_items, player.inventory)


func open_workshop(player: Node) -> void:
	var crafting_ui := get_tree().get_first_node_in_group("crafting_ui")
	if crafting_ui and crafting_ui.has_method("open"):
		crafting_ui.open(AlchemySystem.Station.HOME_WORKSHOP)


func get_save_data() -> Dictionary:
	return {
		"settlement_id": settlement_id,
		"is_owned": is_owned,
		"storage_items": storage_items.duplicate(true)
	}


func apply_save_data(data: Dictionary) -> void:
	is_owned = data.get("is_owned", false)
	storage_items = data.get("storage_items", [])
