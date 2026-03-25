## HirelingUI
## Interface for hiring and managing hirelings at settlements.
extends Control

@onready var hireling_list: VBoxContainer = $Panel/HirelingList
@onready var active_hirelings_list: VBoxContainer = $Panel/ActiveHirelings
@onready var close_button: Button = $Panel/CloseButton
@onready var currency_label: Label = $Panel/CurrencyLabel

var _settlement_id: String = ""
var _player: Node = null


func _ready() -> void:
	add_to_group("hireling_ui")
	visible = false
	if close_button:
		close_button.pressed.connect(_close)
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")


func open(settlement_id: String) -> void:
	_settlement_id = settlement_id
	visible = true
	GameState.is_paused_for_ui = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_refresh()


func _refresh() -> void:
	var s := SettlementManager.get_settlement(_settlement_id)
	if s == null or _player == null:
		return
	if currency_label:
		currency_label.text = "Silver: %d" % _player.inventory.currency
	_populate_available(s)
	_populate_active()


func _populate_available(s: SettlementManager.SettlementData) -> void:
	if hireling_list == null:
		return
	for child in hireling_list.get_children():
		child.queue_free()
	var camp := get_tree().get_first_node_in_group("player_camp")
	var active_ids: Array = camp.get_hireling_ids() if camp else []

	for hid in GameData.hirelings:
		var h: Dictionary = GameData.hirelings[hid]
		var min_tier: String = h.get("min_settlement_tier", "village")
		var tier_order := ["trading_post", "village", "town", "city"]
		if tier_order.find(min_tier) > s.tier_index:
			continue
		var row := HBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = h.get("name", hid)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cost_lbl := Label.new()
		cost_lbl.text = "%d hire / %d/day" % [h.get("hire_cost", 100), h.get("daily_wage", 5)]
		var hire_btn := Button.new()
		var is_hired: bool = hid in active_ids
		hire_btn.text = "Hired" if is_hired else "Hire"
		hire_btn.disabled = is_hired
		var captured_id: String = hid
		hire_btn.pressed.connect(func(): _hire(captured_id))
		var desc_lbl := Label.new()
		desc_lbl.text = h.get("description", "")
		desc_lbl.add_theme_font_size_override("font_size", 10)
		var vbox := VBoxContainer.new()
		var top_row := HBoxContainer.new()
		top_row.add_child(name_lbl)
		top_row.add_child(cost_lbl)
		top_row.add_child(hire_btn)
		vbox.add_child(top_row)
		vbox.add_child(desc_lbl)
		hireling_list.add_child(vbox)


func _populate_active() -> void:
	if active_hirelings_list == null:
		return
	for child in active_hirelings_list.get_children():
		child.queue_free()
	var camp := get_tree().get_first_node_in_group("player_camp")
	if camp == null:
		var lbl := Label.new()
		lbl.text = "No camp established."
		active_hirelings_list.add_child(lbl)
		return
	for hid in camp.get_hireling_ids():
		var h: Dictionary = GameData.get_hireling(hid)
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = h.get("name", hid)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var dismiss_btn := Button.new()
		dismiss_btn.text = "Dismiss"
		var captured_id: String = hid
		dismiss_btn.pressed.connect(func(): _dismiss(captured_id))
		row.add_child(lbl)
		row.add_child(dismiss_btn)
		active_hirelings_list.add_child(row)


func _hire(hireling_id: String) -> void:
	var h := GameData.get_hireling(hireling_id)
	var cost: int = h.get("hire_cost", 100)
	if _player.inventory.currency < cost:
		return
	var camp := get_tree().get_first_node_in_group("player_camp")
	if camp == null:
		return
	if camp.hire(hireling_id):
		_player.inventory.currency -= cost
		_refresh()


func _dismiss(hireling_id: String) -> void:
	var camp := get_tree().get_first_node_in_group("player_camp")
	if camp:
		camp.dismiss(hireling_id)
	_refresh()


func _close() -> void:
	visible = false
	GameState.is_paused_for_ui = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
