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
var _quantity_mode: bool = false
var _pending_quantity: int = 0

# Hold-to-scroll state for quantity adjustment
const _HOLD_INITIAL_DELAY := 0.4   # seconds before auto-repeat begins
const _HOLD_FAST_THRESHOLD := 1.2  # seconds held before switching to 10x
const _HOLD_SLOW_INTERVAL := 0.08  # repeat interval at 1x
const _HOLD_FAST_INTERVAL := 0.05  # repeat interval at 10x
var _hold_dir: int = 0             # -1 = A held, +1 = D held
var _hold_time: float = 0.0
var _hold_repeat_timer: float = 0.0


func _ready() -> void:
	add_to_group("storage_ui")
	visible = false
	close_button.pressed.connect(close)
	store_button.pressed.connect(_store_selected)
	take_button.pressed.connect(_take_selected)
	store_button.disabled = true
	take_button.disabled = true


func _process(delta: float) -> void:
	if not visible or not _quantity_mode or _hold_dir == 0:
		return
	var action := "move_left" if _hold_dir == -1 else "move_right"
	if not Input.is_action_pressed(action):
		_hold_dir = 0
		return
	_hold_time += delta
	if _hold_time < _HOLD_INITIAL_DELAY:
		return
	_hold_repeat_timer += delta
	var interval := _HOLD_FAST_INTERVAL if _hold_time >= _HOLD_FAST_THRESHOLD else _HOLD_SLOW_INTERVAL
	var step := 10 if _hold_time >= _HOLD_FAST_THRESHOLD else 1
	if _hold_repeat_timer >= interval:
		_hold_repeat_timer = 0.0
		_adjust_quantity(_hold_dir * step)


func _adjust_quantity(delta_qty: int) -> void:
	_pending_quantity = clamp(_pending_quantity + delta_qty, 1, _get_selected_max_count())
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if _quantity_mode:
		_handle_quantity_input(event)
	else:
		_handle_navigate_input(event)


func _handle_navigate_input(event: InputEvent) -> void:
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
		_begin_transfer()
		get_viewport().set_input_as_handled()


func _handle_quantity_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_forward"):
		_quantity_mode = false
		_navigate(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_backward"):
		_quantity_mode = false
		_navigate(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_left"):
		_hold_dir = -1
		_hold_time = 0.0
		_hold_repeat_timer = 0.0
		_adjust_quantity(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_right"):
		_hold_dir = 1
		_hold_time = 0.0
		_hold_repeat_timer = 0.0
		_adjust_quantity(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_released("move_left") or event.is_action_released("move_right"):
		_hold_dir = 0
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		_confirm_transfer()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_quantity_mode = false
		_refresh()
		get_viewport().set_input_as_handled()


func _begin_transfer() -> void:
	var count := _get_selected_max_count()
	if count <= 0:
		return
	if count == 1:
		# Single item — transfer immediately
		if _active_panel == "inventory":
			_store_selected()
		else:
			_take_selected()
		return
	# Multi-item stack — enter quantity picker
	_quantity_mode = true
	_pending_quantity = count
	_refresh()


func _confirm_transfer() -> void:
	if _active_panel == "inventory":
		_store_selected()
	else:
		_take_selected()


func _get_selected_max_count() -> int:
	if _active_panel == "inventory":
		if _inventory == null or _selected_inv_index < 0 or _selected_inv_index >= _inventory.items.size():
			return 0
		return _inventory.items[_selected_inv_index].get("count", 1)
	else:
		if _selected_stor_index < 0 or _selected_stor_index >= _storage.size():
			return 0
		return _storage[_selected_stor_index].get("count", 1)


func _navigate(direction: int) -> void:
	_quantity_mode = false
	_hold_dir = 0
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
	_quantity_mode = false
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
			i == _selected_inv_index and not _quantity_mode
		)
		var idx := i
		row.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed:
				_selected_inv_index = idx
				_selected_stor_index = -1
				_active_panel = "inventory"
				_quantity_mode = false
				_refresh()
		)
		inventory_list.add_child(row)
		if i == _selected_inv_index and _quantity_mode:
			inventory_list.add_child(_make_quantity_row(entry.get("count", 1)))


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
			i == _selected_stor_index and not _quantity_mode
		)
		var idx := i
		row.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed:
				_selected_stor_index = idx
				_selected_inv_index = -1
				_active_panel = "storage"
				_quantity_mode = false
				_refresh()
		)
		storage_list.add_child(row)
		if i == _selected_stor_index and _quantity_mode:
			storage_list.add_child(_make_quantity_row(entry.get("count", 1)))


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


func _make_quantity_row(max_count: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _selected_style())
	var hbox := HBoxContainer.new()
	var hint := Label.new()
	hint.text = "A / D to adjust,  E to confirm"
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	var qty_lbl := Label.new()
	qty_lbl.text = "%d / %d" % [_pending_quantity, max_count]
	hbox.add_child(hint)
	hbox.add_child(qty_lbl)
	panel.add_child(hbox)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


func _store_selected() -> void:
	if _selected_inv_index < 0 or _inventory == null:
		return
	var entry: Dictionary = _inventory.items[_selected_inv_index]
	var qty: int = _pending_quantity if _quantity_mode else entry.get("count", 1)
	_quantity_mode = false
	_inventory.remove_item(entry["item_id"], qty)
	# Add to storage (merge into existing stack if present)
	var merged := false
	for s in _storage:
		if s["item_id"] == entry["item_id"]:
			s["count"] += qty
			merged = true
			break
	if not merged:
		_storage.append({ "item_id": entry["item_id"], "count": qty, "runes": entry.get("runes", []) })
	_selected_inv_index = mini(_selected_inv_index, _inventory.items.size() - 1)
	_refresh()


func _take_selected() -> void:
	if _selected_stor_index < 0 or _inventory == null:
		return
	var entry: Dictionary = _storage[_selected_stor_index]
	var qty: int = _pending_quantity if _quantity_mode else entry.get("count", 1)
	_quantity_mode = false
	if qty >= entry.get("count", 1):
		_storage.remove_at(_selected_stor_index)
	else:
		_storage[_selected_stor_index]["count"] -= qty
	_inventory.add_item(entry["item_id"], qty)
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
