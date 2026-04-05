## AbilityBarUI
## Displays active abilities for all attuned disciplines with cooldown overlays.
## Player assigns abilities to hotkeys 1-8 from their unlocked pool.
extends Control

@onready var slot_container: HBoxContainer = $Slots
@onready var channel_bar: ProgressBar = $ChannelBar
@onready var channel_label: Label = $ChannelLabel

const MAX_SLOTS := 8

var _slots: Array = []  # Array of { discipline_id, ability_id }
var _ability_system: AbilitySystem = null
var _player_combat: PlayerCombat = null
var _attack_overlay: ColorRect = null
var _attack_weapon_label: Label = null

# Input actions for ability slots
const SLOT_ACTIONS := [
	"ability_slot_1", "ability_slot_2", "ability_slot_3", "ability_slot_4",
	"ability_slot_5", "ability_slot_6", "ability_slot_7", "ability_slot_8"
]


func _ready() -> void:
	add_to_group("ability_bar_ui")
	for i in range(MAX_SLOTS):
		_slots.append({})
	if channel_bar:
		channel_bar.visible = false
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player")
	if player:
		if player.has_node("AbilitySystem"):
			_ability_system = player.get_node("AbilitySystem")
		if player.has_node("PlayerCombat"):
			_player_combat = player.get_node("PlayerCombat")
			player.inventory.inventory_changed.connect(_update_attack_slot_label)
		_ability_system.ability_channel_started.connect(_on_channel_started)
		_ability_system.ability_channel_completed.connect(_on_channel_complete)
		_ability_system.ability_channel_interrupted.connect(_on_channel_interrupted)
		_ability_system.ability_activated.connect(_on_ability_activated)
	DisciplineManager.ability_unlocked.connect(_on_ability_unlocked)
	DisciplineManager.attuned.connect(_on_attuned)
	_rebuild_slots()


func _unhandled_input(event: InputEvent) -> void:
	if GameState.is_paused_for_ui or GameState.is_sleeping:
		return
	for i in range(MAX_SLOTS):
		if i < SLOT_ACTIONS.size() and event.is_action_pressed(SLOT_ACTIONS[i]):
			_activate_slot(i)


func _process(_delta: float) -> void:
	_update_cooldown_overlays()
	_update_attack_slot_cooldown()


func _activate_slot(index: int) -> void:
	if index >= _slots.size():
		return
	var slot: Dictionary = _slots[index]
	if slot.is_empty():
		return
	if _ability_system:
		_ability_system.activate_ability(slot["discipline_id"], slot["ability_id"])


func assign_ability_to_slot(index: int, discipline_id: String, ability_id: String) -> void:
	if index < 0 or index >= MAX_SLOTS:
		return
	_slots[index] = { "discipline_id": discipline_id, "ability_id": ability_id }
	_rebuild_slots()


func _rebuild_slots() -> void:
	if slot_container == null:
		return
	for child in slot_container.get_children():
		child.queue_free()
	_attack_overlay = null
	_attack_weapon_label = null
	_build_attack_slot()

	for i in range(MAX_SLOTS):
		var slot_panel := PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(60, 60)
		var vbox := VBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.name = "AbilityName"
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.add_theme_font_size_override("font_size", 9)
		var key_lbl := Label.new()
		key_lbl.text = str(i + 1)
		key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_lbl.add_theme_color_override("font_color", Color.GRAY)
		key_lbl.add_theme_font_size_override("font_size", 8)
		var cd_overlay := ColorRect.new()
		cd_overlay.name = "CooldownOverlay"
		cd_overlay.color = Color(0, 0, 0, 0.6)
		cd_overlay.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cd_overlay.visible = false

		vbox.add_child(key_lbl)
		vbox.add_child(name_lbl)
		slot_panel.add_child(vbox)
		slot_panel.add_child(cd_overlay)
		slot_container.add_child(slot_panel)

		var slot: Dictionary = _slots[i]
		if not slot.is_empty():
			var ab := _get_ability_display_name(slot["discipline_id"], slot["ability_id"])
			name_lbl.text = ab
		else:
			name_lbl.text = "—"


func _update_cooldown_overlays() -> void:
	if slot_container == null or _ability_system == null:
		return
	for i in range(mini(_slots.size(), slot_container.get_child_count())):
		var slot: Dictionary = _slots[i]
		var panel := slot_container.get_child(i)
		if panel == null:
			continue
		var overlay := panel.get_node_or_null("CooldownOverlay")
		if overlay == null:
			continue
		if slot.is_empty():
			overlay.visible = false
			continue
		var on_cd := _ability_system.is_on_cooldown(slot["discipline_id"], slot["ability_id"])
		overlay.visible = on_cd


func _on_channel_started(disc_id: String, ability_id: String, duration: float) -> void:
	if channel_bar:
		channel_bar.visible = true
		channel_bar.max_value = duration
		channel_bar.value = 0.0
		# Tween the bar
		var tween := create_tween()
		tween.tween_property(channel_bar, "value", duration, duration)
	if channel_label:
		channel_label.text = _get_ability_display_name(disc_id, ability_id) + "..."


func _on_channel_complete(_disc_id: String, _ability_id: String) -> void:
	if channel_bar:
		channel_bar.visible = false
	if channel_label:
		channel_label.text = ""


func _on_channel_interrupted(_disc_id: String, _ability_id: String) -> void:
	if channel_bar:
		channel_bar.visible = false
	if channel_label:
		channel_label.text = "Interrupted"
		await get_tree().create_timer(1.0).timeout
		channel_label.text = ""


func _on_ability_activated(disc_id: String, ability_id: String) -> void:
	pass


func _on_ability_unlocked(_disc_id: String, _ability_id: String) -> void:
	_auto_assign_new_ability(_disc_id, _ability_id)


func _on_attuned(_disc_id: String) -> void:
	pass


func _auto_assign_new_ability(disc_id: String, ability_id: String) -> void:
	# Find first empty slot and assign
	for i in range(MAX_SLOTS):
		if _slots[i].is_empty():
			assign_ability_to_slot(i, disc_id, ability_id)
			return


func _build_attack_slot() -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(60, 60)
	var vbox := VBoxContainer.new()
	var key_lbl := Label.new()
	key_lbl.text = "LMB"
	key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_lbl.add_theme_color_override("font_color", Color.GRAY)
	key_lbl.add_theme_font_size_override("font_size", 8)
	_attack_weapon_label = Label.new()
	_attack_weapon_label.name = "WeaponLabel"
	_attack_weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_attack_weapon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_attack_weapon_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_attack_weapon_label.add_theme_font_size_override("font_size", 9)
	vbox.add_child(key_lbl)
	vbox.add_child(_attack_weapon_label)
	panel.add_child(vbox)
	_attack_overlay = ColorRect.new()
	_attack_overlay.name = "AttackCooldownOverlay"
	_attack_overlay.color = Color(0, 0, 0, 0.6)
	_attack_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_attack_overlay.visible = false
	panel.add_child(_attack_overlay)
	slot_container.add_child(panel)
	_update_attack_slot_label()


func _update_attack_slot_label() -> void:
	if _attack_weapon_label == null:
		return
	if _player_combat == null:
		_attack_weapon_label.text = "Attack"
		return
	var weapon: Dictionary = _player_combat.get_equipped_weapon()
	_attack_weapon_label.text = weapon.get("name", "Unarmed") if not weapon.is_empty() else "Unarmed"


func _update_attack_slot_cooldown() -> void:
	if _attack_overlay == null or _player_combat == null:
		return
	var frac: float = _player_combat.get_attack_cooldown_frac()
	if frac <= 0.0:
		_attack_overlay.visible = false
		return
	_attack_overlay.visible = true
	# Scale from top — frac=1 fully covered, frac=0 gone
	_attack_overlay.scale = Vector2(1.0, frac)


func _get_ability_display_name(disc_id: String, ability_id: String) -> String:
	var disc := GameData.get_discipline(disc_id)
	for ab in disc.get("abilities", []):
		if ab["id"] == ability_id:
			return ab.get("name", ability_id)
	return ability_id
