## StorageUI
## Two-panel transfer interface: player inventory <-> global home storage.
## No capacity limit on storage side (LINV-008, LINV-009).
extends Control

@onready var inventory_list: VBoxContainer = $Panel/OuterVBox/Main/InventoryPanel/Scroll/InventoryList
@onready var storage_list: VBoxContainer = $Panel/OuterVBox/Main/StoragePanel/Scroll/StorageList
@onready var store_button: Button = $Panel/OuterVBox/Main/InventoryPanel/StoreButton
@onready var take_button: Button = $Panel/OuterVBox/Main/StoragePanel/TakeButton
@onready var close_button: Button = $Panel/OuterVBox/CloseButton
@onready var weight_label: Label = $Panel/OuterVBox/WeightLabel

var _storage: Array = []
var _inventory = null
var _selected_inv_index: int = -1
var _selected_stor_index: int = -1
var _active_panel: String = "inventory"  # "inventory" or "storage"


func _ready() -> void:
	add_to_group("storage_ui")
	visible = false
	close_button.pressed.connect(close)
	store_button.pressed.connect(_store_selected)
	take_button.pressed.connect(_take_selected)
	store_button.disabled = true
	take_button.disabled = true


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_forward"):
		_navigate(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_backward"):
		_navigate(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_left"):
		_active_panel = "inventory"
		if _selected_stor_index >= 0:
			_selected_stor_index = -1
			if _inventory and not _inventory.items.is_empty():
				_selected_inv_index = 0
		_refresh()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_right"):
		_active_panel = "storage"
		if _selected_inv_index >= 0:
			_selected_inv_index = -1
			if not _storage.is_empty():
				_selected_stor_index = 0
		_refresh()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		if _active_panel == "inventory" and _selected_inv_index >= 0:
			_store_selected()
		elif _active_panel == "storage" and _selected_stor_index >= 0:
			_take_selected()
		get_viewport().set_input_as_handled()


func _navigate(direction: int) -> void:
	if _active_panel == "inventory":
		if _inventory == null or _inventory.items.is_empty():
			return
		_selected_inv_index = wrapi(_selected_inv_index + direction, 0, _inventory.items.size())
	else:
		if _storage.is_empty():
			return
		_selected_stor_index = wrapi(_selected_stor_index + direction, 0, _storage.size())
	_refresh()


func open(storage: Array, inventory) -> void:
	_storage = storage
	_inventory = inventory
	_selected_stor_index = -1
	_active_panel = "inventory"
	_selected_inv_index = 0 if (inventory and not inventory.items.is_empty()) else -1
	if _inventory and not _inventory.weight_changed.is_connected(_on_weight_changed):
		_inventory.weight_changed.connect(_on_weight_changed)
	visible = true
	GameState.is_paused_for_ui = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_refresh()
	_update_weight_label()


func close() -> void:
	if _inventory and _inventory.weight_changed.is_connected(_on_weight_changed):
		_inventory.weight_changed.disconnect(_on_weight_changed)
	visible = false
	_storage = []
	_inventory = null
	GameState.is_paused_for_ui = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


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
				_active_panel = "inventory"
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
				_active_panel = "storage"
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
	_inventory.remove_item(entry["item_id"], entry.get("count", 1))
	_storage.append(entry)
	_selected_inv_index = mini(_selected_inv_index, _inventory.items.size() - 1)
	_refresh()


func _take_selected() -> void:
	if _selected_stor_index < 0 or _inventory == null:
		return
	var entry: Dictionary = _storage[_selected_stor_index]
	_storage.remove_at(_selected_stor_index)
	_inventory.add_item(entry["item_id"], entry.get("count", 1))
	_selected_stor_index = mini(_selected_stor_index, _storage.size() - 1)
	_refresh()


func _update_weight_label() -> void:
	if _inventory == null:
		return
	var current: float = _inventory.get_total_weight()
	var player: Node = _inventory.get_parent()
	var maximum: float = player.survival.get_max_carry_weight() if player and player.survival else 50.0
	weight_label.text = "Carrying: %.1f / %.1f kg" % [current, maximum]


func _on_weight_changed(current: float, maximum: float) -> void:
	weight_label.text = "Carrying: %.1f / %.1f kg" % [current, maximum]
