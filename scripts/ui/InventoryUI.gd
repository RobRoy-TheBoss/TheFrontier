## InventoryUI
## Weight-based inventory display with rune socketing interface.
extends Control

@onready var item_list: VBoxContainer = $Panel/ScrollContainer/ItemList
@onready var weight_label: Label = $Panel/WeightLabel
@onready var currency_label: Label = $Panel/CurrencyLabel
@onready var equipment_slots: GridContainer = $Panel/EquipmentSlots
@onready var rune_panel: Control = $Panel/RunePanel

var _player: Node = null
var _inventory: PlayerInventory = null
var _selected_slot: String = ""


func _ready() -> void:
	add_to_group("inventory_ui")
	visible = false
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")
	if _player:
		_inventory = _player.inventory
		_inventory.inventory_changed.connect(_refresh)
		_inventory.weight_changed.connect(_update_weight)


func toggle() -> void:
	visible = not visible
	if visible:
		_refresh()


func _refresh() -> void:
	if not visible or _inventory == null:
		return
	_populate_item_list()
	_populate_equipment_slots()
	_update_weight(_inventory.get_total_weight(), _player.survival.get_max_carry_weight())
	if currency_label:
		currency_label.text = "Silver: %d" % _inventory.currency


func _populate_item_list() -> void:
	if item_list == null:
		return
	for child in item_list.get_children():
		child.queue_free()

	for entry in _inventory.items:
		var item_id: String = entry["item_id"]
		var def := GameData.get_item(item_id)
		if def.is_empty():
			def = GameData.get_weapon(item_id)
		if def.is_empty():
			def = GameData.get_armor(item_id)

		var row := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = def.get("name", item_id)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var count_label := Label.new()
		count_label.text = "x%d" % entry["count"]

		var weight_val: float = def.get("weight", 0.0) * entry["count"]
		var weight_label_node := Label.new()
		weight_label_node.text = "%.1fkg" % weight_val

		row.add_child(name_label)
		row.add_child(count_label)
		row.add_child(weight_label_node)
		item_list.add_child(row)


func _populate_equipment_slots() -> void:
	if equipment_slots == null:
		return
	for child in equipment_slots.get_children():
		child.queue_free()

	var slot_names := ["weapon", "offhand", "head", "chest", "hands", "legs", "feet"]
	for slot in slot_names:
		var slot_container := VBoxContainer.new()
		var slot_label := Label.new()
		slot_label.text = slot.capitalize()

		var equipped := _inventory.equipped.get(slot, {})
		var item_label := Label.new()
		if equipped.is_empty():
			item_label.text = "—"
		else:
			var def := GameData.get_weapon(equipped.get("item_id", ""))
			if def.is_empty():
				def = GameData.get_armor(equipped.get("item_id", ""))
			item_label.text = def.get("name", equipped.get("item_id", ""))

		# Rune slots display
		if not equipped.is_empty():
			var any_def := GameData.get_weapon(equipped.get("item_id", ""))
			if any_def.is_empty():
				any_def = GameData.get_armor(equipped.get("item_id", ""))
			var max_rune_slots: int = any_def.get("rune_slots", 0)
			var runes: Array = equipped.get("runes", [])
			var rune_label := Label.new()
			rune_label.text = "Runes: %d/%d" % [runes.size(), max_rune_slots]
			slot_container.add_child(rune_label)

		slot_container.add_child(slot_label)
		slot_container.add_child(item_label)
		equipment_slots.add_child(slot_container)


func _update_weight(current: float, maximum: float) -> void:
	if weight_label:
		weight_label.text = "Weight: %.1f / %.1f kg" % [current, maximum]
		if current > maximum:
			weight_label.add_theme_color_override("font_color", Color.RED)
		else:
			weight_label.remove_theme_color_override("font_color")
