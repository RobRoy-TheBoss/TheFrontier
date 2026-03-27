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
