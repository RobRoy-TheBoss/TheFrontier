## AttunementUI
## Shown when player is at a Place of Power. Displays discipline info and attunement prompt.
extends Control

@onready var discipline_name_label: Label = $Panel/DisciplineName
@onready var discipline_desc_label: Label = $Panel/DisciplineDesc
@onready var ability_preview_list: VBoxContainer = $Panel/AbilityPreview
@onready var attune_button: Button = $Panel/AttuneButton
@onready var already_label: Label = $Panel/AlreadyLabel
@onready var full_label: Label = $Panel/FullLabel

var _site_node: Node = null
var _site_id: String = ""
var _discipline_id: String = ""


func _ready() -> void:
	add_to_group("attunement_ui")
	visible = false
	if attune_button:
		attune_button.pressed.connect(_on_attune_pressed)


func show_prompt(site_id: String, discipline_id: String, site_node: Node) -> void:
	_site_id = site_id
	_discipline_id = discipline_id
	_site_node = site_node
	visible = true
	GameState.is_paused_for_ui = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_populate()


func _populate() -> void:
	var disc := GameData.get_discipline(_discipline_id)
	if disc.is_empty():
		return
	if discipline_name_label:
		discipline_name_label.text = disc.get("name", _discipline_id)
	if discipline_desc_label:
		discipline_desc_label.text = disc.get("description", "")
	if ability_preview_list:
		for child in ability_preview_list.get_children():
			child.queue_free()
		for ab in disc.get("abilities", []):
			var lbl := Label.new()
			lbl.text = "[%d] %s — %s" % [ab.get("index", 0), ab.get("name", ""), ab.get("type", "")]
			ability_preview_list.add_child(lbl)

	var already_attuned := DisciplineManager.is_attuned(_discipline_id)
	var can_attune := DisciplineManager.can_attune()

	if attune_button:
		attune_button.visible = not already_attuned and can_attune
	if already_label:
		already_label.visible = already_attuned
		already_label.text = "Already attuned. Bonus XP granted."
	if full_label:
		full_label.visible = not can_attune and not already_attuned
		full_label.text = "Attunement slots full (3/3)."


func _on_attune_pressed() -> void:
	if _site_node and _site_node.has_method("attempt_attunement"):
		var player := get_tree().get_first_node_in_group("player")
		_site_node.attempt_attunement(player)
	_close()


func _close() -> void:
	visible = false
	GameState.is_paused_for_ui = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_close()
