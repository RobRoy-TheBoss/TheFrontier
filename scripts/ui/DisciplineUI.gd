## DisciplineUI
## Shows player attunements, ability unlock tree, XP progress, and next unlock cost.
extends Control

@onready var discipline_tabs: TabContainer = $Panel/DisciplineTabs
@onready var attunement_slots_label: Label = $Panel/AttunementSlots

var _player: Node = null


func _ready() -> void:
	add_to_group("discipline_ui")
	visible = false
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")
	DisciplineManager.xp_gained.connect(_on_xp_gained)
	DisciplineManager.ability_unlocked.connect(_on_ability_unlocked)
	DisciplineManager.attuned.connect(_on_attuned)


func toggle() -> void:
	visible = not visible
	if visible:
		_refresh()


func _refresh() -> void:
	if not visible:
		return
	if attunement_slots_label:
		attunement_slots_label.text = "Attunements: %d / %d" % [
			DisciplineManager.get_attunement_count(),
			DisciplineManager.MAX_ATTUNEMENTS
		]
	_populate_tabs()


func _populate_tabs() -> void:
	if discipline_tabs == null:
		return
	for child in discipline_tabs.get_children():
		child.queue_free()

	for disc_id in DisciplineManager.player_disciplines:
		var disc := GameData.get_discipline(disc_id)
		if disc.is_empty():
			continue
		var tab := VBoxContainer.new()
		tab.name = disc.get("name", disc_id)

		var xp_label := Label.new()
		xp_label.text = "XP: %d" % DisciplineManager.get_xp(disc_id)
		tab.add_child(xp_label)

		var abilities: Array = disc.get("abilities", [])
		for ab in abilities:
			var ab_row := HBoxContainer.new()
			var ab_name := Label.new()
			ab_name.text = "[%d] %s" % [ab.get("index", 0), ab.get("name", "")]
			ab_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var status_label := Label.new()
			if DisciplineManager.is_ability_unlocked(disc_id, ab["id"]):
				status_label.text = "UNLOCKED"
				status_label.add_theme_color_override("font_color", Color.GREEN)
			else:
				var xp_cost: int = ab.get("unlock_cost_xp", 0)
				var gold_cost: int = ab.get("unlock_cost_gold", 0)
				status_label.text = "%d XP / %d gold" % [xp_cost, gold_cost]
				if DisciplineManager.can_unlock_ability(disc_id, ab["id"]):
					status_label.add_theme_color_override("font_color", Color.YELLOW)

			ab_row.add_child(ab_name)
			ab_row.add_child(status_label)
			tab.add_child(ab_row)

			# Description
			var desc := Label.new()
			desc.text = "  " + ab.get("description", "")
			desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			tab.add_child(desc)

		discipline_tabs.add_child(tab)


func _on_xp_gained(disc_id: String, _amount: int, _total: int) -> void:
	if visible:
		_refresh()


func _on_ability_unlocked(_disc_id: String, _ability_id: String) -> void:
	if visible:
		_refresh()


func _on_attuned(_disc_id: String) -> void:
	if visible:
		_refresh()
