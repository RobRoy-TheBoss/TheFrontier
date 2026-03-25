## IdentifyUI
## Shows unidentified items in inventory. Alchemist identify ability calls show().
## Identifying reveals material properties and unlocks experimental recipes.
extends Control

@onready var item_list: VBoxContainer = $Panel/ItemList
@onready var identify_button: Button = $Panel/IdentifyButton
@onready var info_label: Label = $Panel/InfoLabel
@onready var close_button: Button = $Panel/CloseButton

var _player: Node = null
var _selected_index: int = -122


func _ready() -> void:
	add_to_group("identify_ui")
	visible = false
	identify_button.pressed.connect(_identify_selected)
	close_button.pressed.connect(_close)
	identify_button.disabled = true


func open() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_selected_index = -1
	visible = true
	_refresh()


func _close() -> void:
	visible = false
	_player = null


func _refresh() -> void:
	for child in item_list.get_children():
		child.queue_free()
	identify_button.disabled = _selected_index < 0
	info_label.text = ""
	if _player == null:
		return

	var unidentified := _get_unidentified_items()
	if unidentified.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No unidentified items."
		item_list.add_child(empty_lbl)
		return

	for i in range(unidentified.size()):
		var entry: Dictionary = unidentified[i]
		var def := DataLoader.get_item(entry["item_id"])
		if def.is_empty():
			def = DataLoader.get_weapon(entry["item_id"])

		var row := PanelContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		if i == _selected_index:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.3, 0.6, 1.0, 0.3)
			row.add_theme_stylebox_override("panel", sb)

		var hbox := HBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = def.get("name", entry["item_id"]) + " [?]"
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_lbl)
		row.add_child(hbox)

		var idx := i
		row.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed:
				_selected_index = idx
				_refresh()
		)
		item_list.add_child(row)

	if _selected_index >= 0 and _selected_index < unidentified.size():
		var entry: Dictionary = unidentified[_selected_index]
		var def := DataLoader.get_item(entry["item_id"])
		if def.is_empty():
			def = DataLoader.get_weapon(entry["item_id"])
		info_label.text = def.get("description", "No additional information.")


func _get_unidentified_items() -> Array:
	if _player == null:
		return []
	return _player.inventory.items.filter(func(e): return e.get("unidentified", false))


func _identify_selected() -> void:
	if _player == null or _selected_index < 0:
		return
	var unidentified := _get_unidentified_items()
	if _selected_index >= unidentified.size():
		return
	var entry: Dictionary = unidentified[_selected_index]
	entry["unidentified"] = false
	# Unlock experimental recipes tied to this material
	var def := DataLoader.get_item(entry["item_id"])
	if def.is_empty():
		def = DataLoader.get_weapon(entry["item_id"])
	var unlocks: Array = def.get("unlocks_recipes", [])
	for recipe_id in unlocks:
		GameState.unlock_recipe(recipe_id)
	_player.inventory.inventory_changed.emit()
	DisciplineManager.add_xp("alchemist", "recipe_experimented")
	_selected_index = -1
	_refresh()
