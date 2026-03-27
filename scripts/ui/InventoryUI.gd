## InventoryUI
## Weight-based inventory display with rune socketing interface.
extends Control

@onready var item_list: VBoxContainer = $Panel/VBox/ScrollContainer/ItemList
@onready var weight_label: Label = $Panel/VBox/WeightLabel
@onready var currency_label: Label = $Panel/VBox/CurrencyLabel
@onready var equipment_slots: GridContainer = $Panel/VBox/EquipmentSlots
@onready var rune_panel: Control = $Panel/VBox/RunePanel

var _player: Node = null
var _inventory: PlayerInventory = null
var _selected_slot: String = ""
var _selected_item_index: int = -1
var _selected_item_id: String = ""


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
	else:
		_selected_item_index = -1
		_selected_item_id = ""


func _refresh() -> void:
	if not visible or _inventory == null:
		return
	_populate_item_list()
	_populate_equipment_slots()
	_update_weight(_inventory.get_total_weight(), _player.survival.get_max_carry_weight())
	if currency_label:
		currency_label.text = "Silver: %d" % _inventory.currency


const WEAPON_TYPES := ["one_handed_blade", "two_handed_blade", "blunt", "bow", "pistol", "musket"]


func _populate_item_list() -> void:
	if item_list == null:
		return
	for child in item_list.get_children():
		child.queue_free()

	for i in range(_inventory.items.size()):
		var entry: Dictionary = _inventory.items[i]
		var item_id: String = entry["item_id"]
		var def := GameData.get_item(item_id)
		if def.is_empty():
			def = GameData.get_weapon(item_id)
		if def.is_empty():
			def = GameData.get_armor(item_id)

		var panel := PanelContainer.new()
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		if i == _selected_item_index:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.3, 0.6, 1.0, 0.35)
			panel.add_theme_stylebox_override("panel", sb)

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
		panel.add_child(row)

		var idx := i
		var iid := item_id
		panel.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_selected_item_index = idx
				_selected_item_id = iid
				_refresh()
		)
		item_list.add_child(panel)


func _populate_equipment_slots() -> void:
	if equipment_slots == null:
		return
	for child in equipment_slots.get_children():
		child.queue_free()

	# Determine what the selected item is compatible with
	var selected_def := Dictionary()
	if _selected_item_id != "":
		selected_def = GameData.get_weapon(_selected_item_id)
		if selected_def.is_empty():
			selected_def = GameData.get_armor(_selected_item_id)
	var selected_is_weapon := selected_def.get("type", "") in WEAPON_TYPES
	var selected_armor_slot: String = selected_def.get("slot", "") if not selected_is_weapon else ""

	# Weapon slots (LPC-020)
	var weapon_slot_labels := ["Main Weapon", "Backup Weapon"]
	for i in range(2):
		var ws: Dictionary = _inventory.weapon_slots[i]
		var highlighted := selected_is_weapon and _selected_item_id != ""

		var panel := PanelContainer.new()
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		if highlighted:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.2, 0.8, 0.3, 0.35)
			panel.add_theme_stylebox_override("panel", sb)

		var col := VBoxContainer.new()
		var slot_label := Label.new()
		slot_label.text = weapon_slot_labels[i]
		if i == _inventory.active_weapon_slot:
			slot_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		var item_label := Label.new()
		if ws.is_empty():
			item_label.text = "—"
		else:
			var def: Dictionary = GameData.get_weapon(ws.get("item_id", ""))
			item_label.text = def.get("name", ws.get("item_id", ""))
		col.add_child(slot_label)
		col.add_child(item_label)
		if not ws.is_empty():
			var unequip_btn := Button.new()
			unequip_btn.text = "Unequip"
			var wi := i
			unequip_btn.pressed.connect(func(): _inventory.unequip_weapon_slot(wi))
			col.add_child(unequip_btn)
		panel.add_child(col)

		if highlighted:
			var wi := i
			var sid := _selected_item_id
			panel.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					_inventory.equip_to_weapon_slot(sid, wi)
					_selected_item_index = -1
					_selected_item_id = ""
					_refresh()
			)
		equipment_slots.add_child(panel)

	# Armour slots
	var armour_slots := ["head", "chest", "hands", "legs", "feet"]
	for slot in armour_slots:
		var equipped: Dictionary = _inventory.equipped.get(slot, {})
		var highlighted := selected_armor_slot == slot and slot != ""

		var panel := PanelContainer.new()
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		if highlighted:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.2, 0.8, 0.3, 0.35)
			panel.add_theme_stylebox_override("panel", sb)

		var col := VBoxContainer.new()
		var slot_label := Label.new()
		slot_label.text = slot.capitalize()
		var item_label := Label.new()
		if equipped.is_empty():
			item_label.text = "—"
		else:
			var def: Dictionary = GameData.get_armor(equipped.get("item_id", ""))
			item_label.text = def.get("name", equipped.get("item_id", ""))
		col.add_child(slot_label)
		col.add_child(item_label)
		if not equipped.is_empty():
			var unequip_btn := Button.new()
			unequip_btn.text = "Unequip"
			unequip_btn.pressed.connect(func(): _inventory.unequip(slot))
			col.add_child(unequip_btn)
		panel.add_child(col)

		if highlighted:
			var sl := slot
			var sid := _selected_item_id
			panel.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					_inventory.equip(sid, sl)
					_selected_item_index = -1
					_selected_item_id = ""
					_refresh()
			)
		equipment_slots.add_child(panel)


func _update_weight(current: float, maximum: float) -> void:
	if weight_label:
		weight_label.text = "Weight: %.1f / %.1f kg" % [current, maximum]
		if current > maximum:
			weight_label.add_theme_color_override("font_color", Color.RED)
		else:
			weight_label.remove_theme_color_override("font_color")
