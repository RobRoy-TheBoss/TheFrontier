## SleepSummaryUI
## Optional post-sleep summary screen (SLEEP-180 SHOULD).
## Shows what happened during the batch: tier changes, resources found, trade changes.
extends Control

@onready var summary_list: VBoxContainer = $Panel/SummaryList
@onready var continue_button: Button = $Panel/ContinueButton
@onready var day_label: Label = $Panel/DayLabel

var _entries: Array = []


func _ready() -> void:
	add_to_group("sleep_summary_ui")
	visible = false
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	BatchProcessor.batch_step_completed.connect(_on_batch_step)
	BatchProcessor.batch_completed.connect(_on_batch_complete)
	SettlementManager.settlement_tier_changed.connect(_on_tier_changed)


func _on_batch_step(step: int, step_name: String) -> void:
	pass  # Could add step-by-step display


func _on_batch_complete() -> void:
	if _entries.is_empty():
		return
	_show()


func _on_tier_changed(settlement_id: String, new_tier: String) -> void:
	_entries.append("⚑ %s advanced to %s!" % [
		settlement_id.capitalize().replace("_", " "),
		new_tier.capitalize()
	])


func _show() -> void:
	visible = true
	GameState.is_paused_for_ui = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if day_label:
		day_label.text = "Day %d — Morning" % GameState.current_day
	if summary_list:
		for child in summary_list.get_children():
			child.queue_free()
		for entry in _entries:
			var lbl := Label.new()
			lbl.text = entry
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			summary_list.add_child(lbl)
		if _entries.is_empty():
			var lbl := Label.new()
			lbl.text = "A quiet night."
			summary_list.add_child(lbl)


func _on_continue_pressed() -> void:
	visible = false
	GameState.is_paused_for_ui = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_entries.clear()


func add_entry(text: String) -> void:
	_entries.append(text)
