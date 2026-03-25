## RepairUI
## Shows equipped items and their durability. Artificer field_repair ability
## calls show() when at camp — player selects item to repair.
extends Control

@onready var item_list: VBoxContainer = $Panel/ItemList
@onready var repair_button: Button = $Panel/RepairButton
@onready var close_button: Button = $Panel/CloseButton
@onready var title_label: Label = $Panel/TitleLabel

var _player: Node = null
var _selected_slot: String = ""


func _ready() -> void:
	add_to_group("repair_ui")
	visible = false
	repair_button.pressed.connect(_repair_selected)
	close_button.pressed.connect(_close)
	repair_button.disabled = true


func open() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_selected_slot = ""
	visible = true
	_refresh()


func _close() -> void:
	visible = false
	_player = null


func _refresh() -> void:
	for child in item_list.get_children():
		child.queue_free()
	repair_button.disabled = _selected_slot == ""
	if _player == null:
		return

	var slots := ["weapon", "offhand", "chest", "head", "hands", "legs", "feet"]
	for slot in slots:
		var equipped: Dictionary = _player.inventory.equipped.get(slot, {})
		if equipped.is_empty():
			continue
		var item_id: String = equipped.get("item_id", "")
		var def := DataLoader.get_weapon(item_id)
		if def.is_empty():
			def = DataLoader.get_item(item_id)
		var max_dur: float = def.get("durability", 100.0)
		var cur_dur: float = equipped.get("durability", max_dur)

		var row := HBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = def.get("name", item_id)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var dur_lbl := Label.new()
		dur_lbl.text = "%d / %d" % [int(cur_dur), int(max_dur)]
		if cur_dur / max_dur < 0.3:
			dur_lbl.add_theme_color_override("font_color", Color.RED)
		elif cur_dur / max_dur < 0.6:
			dur_lbl.add_theme_color_override("font_color", Color.YELLOW)

		row.add_child(name_lbl)
		row.add_child(dur_lbl)

		var s: String = slot
		row.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed:
				_selected_slot = s
				_refresh()
		)
		if slot == _selected_slot:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.3, 0.6, 1.0, 0.3)
			var panel := PanelContainer.new()
			panel.add_theme_stylebox_override("panel", sb)
			panel.mouse_filter = Control.MOUSE_FILTER_STOP
			var inner := row
			panel.add_child(inner)
			item_list.add_child(panel)
		else:
			row.mouse_filter = Control.MOUSE_FILTER_STOP
			item_list.add_child(row)

	repair_button.disabled = _selected_slot == ""


func _repair_selected() -> void:
	if _player == null or _selected_slot == "":
		return
	var equipped: Dictionary = _player.inventory.equipped.get(_selected_slot, {})
	if equipped.is_empty():
		return
	var item_id: String = equipped.get("item_id", "")
	var def := DataLoader.get_weapon(item_id)
	if def.is_empty():
		def = DataLoader.get_item(item_id)
	var max_dur: float = def.get("durability", 100.0)
	equipped["durability"] = max_dur
	_player.inventory.inventory_changed.emit()
	_selected_slot = ""
	_refresh()
