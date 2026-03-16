## SettlementUI
## Shows settlement tier, resources, trade score, connections, and growth progress.
## Also provides access to shop, hirelings, discipline enhancement, and sleep.
extends Control

@onready var title_label: Label = $Panel/TitleLabel
@onready var tier_label: Label = $Panel/TierLabel
@onready var trade_score_bar: ProgressBar = $Panel/TradeScoreBar
@onready var resources_list: VBoxContainer = $Panel/ResourcesList
@onready var connections_label: Label = $Panel/ConnectionsLabel
@onready var services_list: VBoxContainer = $Panel/ServicesList

var _current_settlement_id: String = ""


func _ready() -> void:
	add_to_group("settlement_ui")
	visible = false
	SettlementManager.settlement_tier_changed.connect(_on_tier_changed)


func show_settlement(settlement_id: String) -> void:
	_current_settlement_id = settlement_id
	visible = true
	GameState.is_paused_for_ui = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_refresh()


func hide_settlement() -> void:
	visible = false
	GameState.is_paused_for_ui = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _refresh() -> void:
	if not visible or _current_settlement_id == "":
		return
	var s := SettlementManager.get_settlement(_current_settlement_id)
	if s == null:
		return
	var tier := GameData.get_tier_by_index(s.tier_index)
	var next_tier := GameData.get_tier_by_index(s.tier_index + 1)

	if title_label:
		title_label.text = _current_settlement_id.capitalize().replace("_", " ")
	if tier_label:
		tier_label.text = tier.get("name", "Unknown Tier")

	# Trade score progress
	if trade_score_bar and not next_tier.is_empty():
		trade_score_bar.max_value = next_tier.get("trade_score_threshold", 1)
		trade_score_bar.value = s.trade_score
	elif trade_score_bar:
		trade_score_bar.value = trade_score_bar.max_value  # Max tier

	# Resources
	if resources_list:
		for child in resources_list.get_children():
			child.queue_free()
		for res_id in s.discovered_resources:
			var lbl := Label.new()
			lbl.text = "%s (richness: %.1f)" % [res_id, s.discovered_resources[res_id]]
			resources_list.add_child(lbl)

	# Connections
	if connections_label:
		var connections: Array = SettlementManager.road_network.get(_current_settlement_id, [])
		connections_label.text = "Connections: %d" % connections.size()

	# Services
	if services_list:
		for child in services_list.get_children():
			child.queue_free()
		for service in tier.get("services", []):
			var lbl := Label.new()
			lbl.text = "• " + service.replace("_", " ").capitalize()
			services_list.add_child(lbl)


func _on_tier_changed(sid: String, _new_tier: String) -> void:
	if sid == _current_settlement_id and visible:
		_refresh()
