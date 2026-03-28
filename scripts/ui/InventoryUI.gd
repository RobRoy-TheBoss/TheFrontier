## InventoryUI
## Weight-based inventory display with rune socketing interface.
## Equipment slots have moved to HeroUI (H key).
extends Control

@onready var item_list: VBoxContainer = $Panel/VBox/ScrollContainer/ItemList
@onready var weight_label: Label = $Panel/VBox/WeightLabel
@onready var currency_label: Label = $Panel/VBox/CurrencyLabel
@onready var rune_panel: Control = $Panel/VBox/RunePanel

var _player: Node = null
var _inventory: PlayerInventory = null
var _selected_item_index: int = -1
var _survival: PlayerSurvival = null


func _ready() -> void:
	add_to_group("inventory_ui")
	visible = false
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")
	if _player:
		_inventory = _player.inventory
		_survival = _player.survival
		_inventory.inventory_changed.connect(_refresh)
		_inventory.weight_changed.connect(_update_weight)


func toggle() -> void:
	visible = not visible
	if visible:
		_selected_item_index = 0 if (_inventory and not _inventory.items.is_empty()) else -1
		_refresh()
	else:
		_selected_item_index = -1


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_forward"):
		_navigate(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_backward"):
		_navigate(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		_try_consume_selected()
		get_viewport().set_input_as_handled()


func _navigate(direction: int) -> void:
	if _inventory == null or _inventory.items.is_empty():
		return
	_selected_item_index = wrapi(_selected_item_index + direction, 0, _inventory.items.size())
	_refresh()


func _try_consume_selected() -> void:
	if _selected_item_index < 0 or _inventory == null or _survival == null:
		return
	if _selected_item_index >= _inventory.items.size():
		return
	var entry: Dictionary = _inventory.items[_selected_item_index]
	var item_id: String = entry["item_id"]
	var def := GameData.get_item(item_id)
	if def.is_empty():
		return

	var hunger_restore: float = def.get("hunger_restore", 0.0)
	var thirst_restore: float = def.get("thirst_restore",
		def.get("use_effect", {}).get("thirst_restore", 0.0))

	if hunger_restore > 0.0:
		if _survival.hunger >= 100.0:
			return
		_survival.restore_hunger(hunger_restore)
		_inventory.remove_item(item_id, 1)
		_selected_item_index = mini(_selected_item_index, _inventory.items.size() - 1)
		_refresh()
	elif thirst_restore > 0.0:
		if _survival.thirst >= 100.0:
			return
		_survival.restore_thirst(thirst_restore)
		_inventory.remove_item(item_id, 1)
		_selected_item_index = mini(_selected_item_index, _inventory.items.size() - 1)
		_refresh()


func _refresh() -> void:
	if not visible or _inventory == null:
		return
	_populate_item_list()
	_update_weight(_inventory.get_total_weight(), _player.survival.get_max_carry_weight())
	if currency_label:
		currency_label.text = "Silver: %d" % _inventory.currency


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
		panel.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_selected_item_index = idx
				_refresh()
		)
		item_list.add_child(panel)


func _update_weight(current: float, maximum: float) -> void:
	if weight_label:
		weight_label.text = "Weight: %.1f / %.1f kg" % [current, maximum]
		if current > maximum:
			weight_label.add_theme_color_override("font_color", Color.RED)
		else:
			weight_label.remove_theme_color_override("font_color")
