## SaveSlotUI
## Save slot browser: save, load, and delete named save files.
## Opened from PauseMenuUI. Uses SaveManager for all persistence.
extends Control

@onready var slot_list: VBoxContainer = $Panel/VBox/SlotList
@onready var slot_name_input: LineEdit = $Panel/VBox/SlotNameInput
@onready var save_button: Button = $Panel/VBox/Buttons/SaveButton
@onready var load_button: Button = $Panel/VBox/Buttons/LoadButton
@onready var delete_button: Button = $Panel/VBox/Buttons/DeleteButton
@onready var close_button: Button = $Panel/VBox/CloseButton
@onready var status_label: Label = $Panel/VBox/StatusLabel

var _selected_slot: String = ""


func _ready() -> void:
	add_to_group("save_slot_ui")
	visible = false
	save_button.pressed.connect(_on_save)
	load_button.pressed.connect(_on_load)
	delete_button.pressed.connect(_on_delete)
	close_button.pressed.connect(_close)
	_set_buttons_enabled(false)


func open() -> void:
	_refresh_slots()
	status_label.text = ""
	slot_name_input.text = ""
	_set_buttons_enabled(false)
	_selected_slot = ""
	visible = true


func _refresh_slots() -> void:
	for child in slot_list.get_children():
		child.queue_free()

	var slots: Array = SaveManager.get_save_slots()
	slots.sort()

	for slot in slots:
		var btn := Button.new()
		btn.text = slot
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(func(): _select_slot(slot))
		slot_list.add_child(btn)


func _select_slot(slot: String) -> void:
	_selected_slot = slot
	slot_name_input.text = slot
	_set_buttons_enabled(true)
	status_label.text = ""


func _on_save() -> void:
	var name_raw: String = slot_name_input.text.strip_edges()
	if name_raw == "":
		status_label.text = "Enter a slot name."
		return
	# Sanitize: alphanumerics, dashes, underscores only
	var safe_name: String = ""
	for ch in name_raw:
		if ch.is_valid_identifier() or ch == "-":
			safe_name += ch
		else:
			safe_name += "_"
	SaveManager.save_game(safe_name)
	status_label.text = "Saved: %s" % safe_name
	_refresh_slots()


func _on_load() -> void:
	if _selected_slot == "":
		return
	var ok: bool = SaveManager.load_game(_selected_slot)
	status_label.text = "Loaded: %s" % _selected_slot if ok else "Load failed."


func _on_delete() -> void:
	if _selected_slot == "":
		return
	SaveManager.delete_save(_selected_slot)
	status_label.text = "Deleted: %s" % _selected_slot
	_selected_slot = ""
	slot_name_input.text = ""
	_set_buttons_enabled(false)
	_refresh_slots()


func _set_buttons_enabled(on: bool) -> void:
	load_button.disabled = not on
	delete_button.disabled = not on


func _close() -> void:
	visible = false
