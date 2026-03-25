## StorageUI
## Two-panel transfer interface: player inventory <-> global home storage.
## No capacity limit on storage side (LINV-008, LINV-009).
extends Control

@onready var inventory_list: VBoxContainer = $Panel/OuterVBox/Main/InventoryPanel/Scroll/InventoryList
@onready var storage_list: VBoxContainer = $Panel/OuterVBox/Main/StoragePanel/Scroll/StorageList
@onready var store_button: Button = $Panel/OuterVBox/Main/InventoryPanel/StoreButton
@onready var take_button: Button = $Panel/OuterVBox/Main/StoragePanel/TakeButton
@onready var close_button: Button = $Panel/OuterVBox/CloseButton

var _storage: Array = []
var _inventory = null
var _selected_inv_index: int = -1
var _selected_stor_index: int = -1


func _ready() -> void:
	add_to_group("storage_ui")
	visible = false
	close_button.pressed.connect(close)
	store_button.pressed.connect(_store_selected)
	take_button.pressed.connect(_take_selected)
	store_button.disabled = true
	take_button.disabled = true


func open(storage: Array, inventory) -> void:
	_storage = storage
	_inventory = inventory
	_selected_inv_index = -1
	_selected_stor_index = -1
	visible = true
	_refresh()


func close() -> void:
	visible = false
	_storage = []
	_inventory = null


func _refresh() -> void:
	_populate_inventory()
	_populate_storage()
	store_button.disabled = _selected_inv_index < 0
	take_button.disabled = _selected_stor_index < 0


func _populate_inventory() -> void:
	for child in inventory_list.get_children():
		child.queue_free()
	if _inventory == null:
		return
	for i in range(_inventory.items.size()):
		var entry: Dictionary = _inventory.items[i]
		var def := DataLoader.get_item(entry["item_id"])
		if def.is_empty():
			def = DataLoader.get_weapon(entry["item_id"])
		var row := _make_row(
			def.get("name", entry["item_id"]),
			entry["count"],
			def.get("weight", 0.0) * entry["count"],
			i == _selected_inv_index
		)
		var idx := i
		row.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed:
				_selected_inv_index = idx
				_selected_stor_index = -1
				_refresh()
		)
		inventory_list.add_child(row)


func _populate_storage() -> void:
	for child in storage_list.get_children():
		child.queue_free()
	for i in range(_storage.size()):
		var entry: Dictionary = _storage[i]
		var def := DataLoader.get_item(entry.get("item_id", ""))
		if def.is_empty():
			def = DataLoader.get_weapon(entry.get("item_id", ""))
		var row := _make_row(
			def.get("name", entry.get("item_id", "?")),
			entry.get("count", 1),
			def.get("weight", 0.0) * entry.get("count", 1),
			i == _selected_stor_index
		)
		var idx := i
		row.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed:
				_selected_stor_index = idx
				_selected_inv_index = -1
				_refresh()
		)
		storage_list.add_child(row)


func _make_row(item_name: String, count: int, weight: float, selected: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	if selected:
		panel.add_theme_stylebox_override("panel", _selected_style())
	var hbox := HBoxContainer.new()
	var name_lbl := Label.new()
	name_lbl.text = item_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var count_lbl := Label.new()
	count_lbl.text = "x%d" % count
	var weight_lbl := Label.new()
	weight_lbl.text = "%.1fkg" % weight
	hbox.add_child(name_lbl)
	hbox.add_child(count_lbl)
	hbox.add_child(weight_lbl)
	panel.add_child(hbox)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	return panel


func _selected_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.3, 0.6, 1.0, 0.3)
	return sb


func _store_selected() -> void:
	if _selected_inv_index < 0 or _inventory == null:
		return
	var entry: Dictionary = _inventory.items[_selected_inv_index].duplicate()
	_inventory.items.remove_at(_selected_inv_index)
	_inventory.inventory_changed.emit()
	_storage.append(entry)
	_selected_inv_index = -1
	_refresh()


func _take_selected() -> void:
	if _selected_stor_index < 0 or _inventory == null:
		return
	var entry: Dictionary = _storage[_selected_stor_index]
	_storage.remove_at(_selected_stor_index)
	_inventory.add_item(entry["item_id"], entry.get("count", 1))
	_selected_stor_index = -1
	_refresh()
