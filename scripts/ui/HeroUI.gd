## HeroUI
## Character/Hero screen: equipment, vitals, disciplines, active conditions.
## Equipment section replaces the equipment panel in InventoryUI.
## Toggle with "hero" action (H key).
extends Control

@onready var equip_slots: VBoxContainer = $Panel/OuterVBox/MainHBox/EquipColumn/EquipSlots
@onready var backpack_list: VBoxContainer = $Panel/OuterVBox/MainHBox/EquipColumn/BackpackScroll/BackpackList
@onready var vitals_grid: GridContainer = $Panel/OuterVBox/MainHBox/StatsColumn/VitalsGrid
@onready var discs_panel: VBoxContainer = $Panel/OuterVBox/MainHBox/StatsColumn/DiscsPanel
@onready var cond_panel: VBoxContainer = $Panel/OuterVBox/MainHBox/StatsColumn/CondPanel
@onready var close_btn: Button = $Panel/OuterVBox/TitleRow/CloseButton

var _player: Node = null
var _inventory: PlayerInventory = null
var _health: PlayerHealth = null
var _survival: PlayerSurvival = null

# Gauge references (bar, value_label)
var _health_bar: ProgressBar
var _stamina_bar: ProgressBar
var _hunger_bar: ProgressBar
var _thirst_bar: ProgressBar
var _fatigue_bar: ProgressBar
var _enc_bar: ProgressBar
var _temp_label: Label

var _selected_item_id: String = ""

const WEAPON_TYPES := ["one_handed_blade", "two_handed_blade", "blunt", "bow", "pistol", "musket"]
const ARMOR_SLOTS := ["head", "chest", "hands", "legs", "feet"]


func _ready() -> void:
	add_to_group("hero_ui")
	visible = false
	close_btn.pressed.connect(func(): toggle())
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")
	if _player:
		_inventory = _player.inventory
		_health = _player.health
		_survival = _player.survival
		_health.health_changed.connect(_on_health_changed)
		_health.stamina_changed.connect(_on_stamina_changed)
		_health.injury_inflicted.connect(func(_id): _refresh_conditions())
		_health.injury_resolved.connect(func(_id): _refresh_conditions())
		_inventory.inventory_changed.connect(_refresh_equipment)
		_survival.hunger_changed.connect(func(v, m): _set_bar(_hunger_bar, v, m))
		_survival.thirst_changed.connect(func(v, m): _set_bar(_thirst_bar, v, m))
		_survival.fatigue_changed.connect(func(v, m): _set_bar(_fatigue_bar, v, m))
		_survival.encumbrance_changed.connect(func(v, m): _set_bar(_enc_bar, v, m))
		_survival.temperature_changed.connect(_on_temperature_changed)
	DisciplineManager.xp_gained.connect(func(_d, _x, _t): _refresh_disciplines())
	DisciplineManager.attuned.connect(func(_d): _refresh_disciplines())
	DisciplineManager.ability_unlocked.connect(func(_d, _a): _refresh_disciplines())
	_build_vitals_grid()


func toggle() -> void:
	visible = not visible
	if visible:
		_refresh_equipment()
		_refresh_disciplines()
		_refresh_conditions()
		_refresh_vitals()
		_selected_item_id = ""
	else:
		_selected_item_id = ""


# ---------------------------------------------------------------------------
# Vitals grid (built once in _ready, updated via signals)
# ---------------------------------------------------------------------------

func _build_vitals_grid() -> void:
	if vitals_grid == null:
		return
	for c in vitals_grid.get_children():
		c.queue_free()

	_health_bar  = _add_gauge_row("Health",       0.0, 100.0, Color(0.9, 0.2, 0.2))
	_stamina_bar = _add_gauge_row("Stamina",      0.0, 100.0, Color(0.2, 0.7, 1.0))
	_hunger_bar  = _add_gauge_row("Hunger",       0.0, 100.0, Color(0.9, 0.7, 0.2))
	_thirst_bar  = _add_gauge_row("Thirst",       0.0, 100.0, Color(0.3, 0.6, 1.0))
	_fatigue_bar = _add_gauge_row("Fatigue",      0.0, 100.0, Color(0.6, 0.4, 0.8))
	_enc_bar     = _add_gauge_row("Encumbrance",  0.0, 100.0, Color(0.8, 0.5, 0.2))

	# Temperature: special text row (no ProgressBar)
	var t_name := Label.new()
	t_name.text = "Temp"
	vitals_grid.add_child(t_name)
	_temp_label = Label.new()
	_temp_label.text = "18 °C"
	_temp_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vitals_grid.add_child(_temp_label)
	var t_pad := Label.new()  # empty third column
	vitals_grid.add_child(t_pad)


func _add_gauge_row(label_text: String, min_v: float, max_v: float, color: Color) -> ProgressBar:
	var name_lbl := Label.new()
	name_lbl.text = label_text
	vitals_grid.add_child(name_lbl)

	var bar := ProgressBar.new()
	bar.min_value = min_v
	bar.max_value = max_v
	bar.value = max_v
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size.x = 180.0
	bar.add_theme_color_override("fill", color)
	bar.show_percentage = false
	vitals_grid.add_child(bar)

	var val_lbl := Label.new()
	val_lbl.text = "100 / 100"
	val_lbl.custom_minimum_size.x = 80.0
	vitals_grid.add_child(val_lbl)

	# Store value label on bar's metadata for updates
	bar.set_meta("val_label", val_lbl)
	return bar


func _set_bar(bar: ProgressBar, current: float, maximum: float) -> void:
	if bar == null:
		return
	bar.max_value = maximum
	bar.value = current
	var lbl: Label = bar.get_meta("val_label", null)
	if lbl:
		lbl.text = "%d / %d" % [int(current), int(maximum)]


func _refresh_vitals() -> void:
	if _health == null:
		return
	_set_bar(_health_bar,  _health.current_health, _health.max_health)
	_set_bar(_stamina_bar, _health.stamina,         _health.max_stamina)
	_set_bar(_hunger_bar,  _survival.hunger,        100.0)
	_set_bar(_thirst_bar,  _survival.thirst,        100.0)
	_set_bar(_fatigue_bar, _survival.fatigue,       100.0)
	_set_bar(_enc_bar,     _survival.current_weight, _survival.get_max_carry_weight())
	_on_temperature_changed(_survival.temperature)


func _on_health_changed(current: float, maximum: float) -> void:
	_set_bar(_health_bar, current, maximum)


func _on_stamina_changed(current: float, maximum: float) -> void:
	_set_bar(_stamina_bar, current, maximum)


func _on_temperature_changed(value: float) -> void:
	if _temp_label == null:
		return
	_temp_label.text = "%.0f °C" % value
	if value < 0.0:
		_temp_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	elif value > 35.0:
		_temp_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.2))
	else:
		_temp_label.remove_theme_color_override("font_color")


# ---------------------------------------------------------------------------
# Equipment panel (weapon slots + armor slots + equippable backpack list)
# ---------------------------------------------------------------------------

func _refresh_equipment() -> void:
	if not visible or _inventory == null:
		return
	_build_equip_slots()
	_build_backpack_list()


func _build_equip_slots() -> void:
	if equip_slots == null:
		return
	for c in equip_slots.get_children():
		c.queue_free()

	var selected_def: Dictionary = {}
	if _selected_item_id != "":
		selected_def = GameData.get_weapon(_selected_item_id)
		if selected_def.is_empty():
			selected_def = GameData.get_armor(_selected_item_id)
	var selected_is_weapon: bool = selected_def.get("type", "") in WEAPON_TYPES
	var selected_armor_slot: String = selected_def.get("slot", "") if not selected_is_weapon else ""

	# -- Weapon slots --
	var wsec := Label.new()
	wsec.text = "Weapons"
	wsec.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5))
	equip_slots.add_child(wsec)

	var weapon_labels := ["Main Weapon", "Backup Weapon"]
	for i in range(2):
		var ws: Dictionary = _inventory.weapon_slots[i]
		var highlighted: bool = selected_is_weapon and _selected_item_id != ""

		var panel := PanelContainer.new()
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		if highlighted:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.2, 0.8, 0.3, 0.35)
			panel.add_theme_stylebox_override("panel", sb)

		var row := HBoxContainer.new()
		var slot_lbl := Label.new()
		slot_lbl.text = weapon_labels[i]
		slot_lbl.custom_minimum_size.x = 110.0
		if i == _inventory.active_weapon_slot:
			slot_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		var item_lbl := Label.new()
		item_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if ws.is_empty():
			item_lbl.text = "—"
		else:
			var def: Dictionary = GameData.get_weapon(ws.get("item_id", ""))
			item_lbl.text = def.get("name", ws.get("item_id", ""))
		row.add_child(slot_lbl)
		row.add_child(item_lbl)

		if not ws.is_empty():
			var btn := Button.new()
			btn.text = "Unequip"
			var wi: int = i
			btn.pressed.connect(func(): _inventory.unequip_weapon_slot(wi))
			row.add_child(btn)

		panel.add_child(row)

		if highlighted:
			var wi: int = i
			var sid: String = _selected_item_id
			panel.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					_inventory.equip_to_weapon_slot(sid, wi)
					_selected_item_id = ""
					_refresh_equipment()
			)
		equip_slots.add_child(panel)

	# -- Armor slots --
	var asec := Label.new()
	asec.text = "Armour"
	asec.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5))
	equip_slots.add_child(asec)

	for slot in ARMOR_SLOTS:
		var equipped_item: Dictionary = _inventory.equipped.get(slot, {})
		var highlighted: bool = selected_armor_slot == slot and slot != ""

		var panel := PanelContainer.new()
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		if highlighted:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.2, 0.8, 0.3, 0.35)
			panel.add_theme_stylebox_override("panel", sb)

		var row := HBoxContainer.new()
		var slot_lbl := Label.new()
		slot_lbl.text = slot.capitalize()
		slot_lbl.custom_minimum_size.x = 110.0
		var item_lbl := Label.new()
		item_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if equipped_item.is_empty():
			item_lbl.text = "—"
		else:
			var def: Dictionary = GameData.get_armor(equipped_item.get("item_id", ""))
			item_lbl.text = def.get("name", equipped_item.get("item_id", ""))
		row.add_child(slot_lbl)
		row.add_child(item_lbl)

		if not equipped_item.is_empty():
			var btn := Button.new()
			btn.text = "Unequip"
			var sl: String = slot
			btn.pressed.connect(func(): _inventory.unequip(sl))
			row.add_child(btn)

		panel.add_child(row)

		if highlighted:
			var sl: String = slot
			var sid: String = _selected_item_id
			panel.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					_inventory.equip(sid, sl)
					_selected_item_id = ""
					_refresh_equipment()
			)
		equip_slots.add_child(panel)


func _build_backpack_list() -> void:
	if backpack_list == null:
		return
	for c in backpack_list.get_children():
		c.queue_free()

	# Show only equippable items (weapons + armor)
	for entry in _inventory.items:
		var item_id: String = entry["item_id"]
		var def: Dictionary = GameData.get_weapon(item_id)
		if def.is_empty():
			def = GameData.get_armor(item_id)
		if def.is_empty():
			continue

		var panel := PanelContainer.new()
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		if item_id == _selected_item_id:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.3, 0.6, 1.0, 0.35)
			panel.add_theme_stylebox_override("panel", sb)

		var lbl := Label.new()
		lbl.text = def.get("name", item_id)
		panel.add_child(lbl)

		var iid: String = item_id
		panel.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_selected_item_id = iid if _selected_item_id != iid else ""
				_refresh_equipment()
		)
		backpack_list.add_child(panel)


# ---------------------------------------------------------------------------
# Disciplines
# ---------------------------------------------------------------------------

func _refresh_disciplines() -> void:
	if not visible or discs_panel == null:
		return
	for c in discs_panel.get_children():
		c.queue_free()

	if DisciplineManager.player_disciplines.is_empty():
		var lbl := Label.new()
		lbl.text = "No disciplines attuned."
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		discs_panel.add_child(lbl)
		return

	for disc_id in DisciplineManager.player_disciplines:
		var disc: Dictionary = GameData.get_discipline(disc_id)
		var xp: int = DisciplineManager.get_xp(disc_id)
		var unlocked: Array = DisciplineManager.get_unlocked_abilities(disc_id)

		var row := HBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = disc.get("name", disc_id)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var xp_lbl := Label.new()
		xp_lbl.text = "%d XP" % xp
		xp_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
		row.add_child(name_lbl)
		row.add_child(xp_lbl)
		discs_panel.add_child(row)

		# List unlocked abilities
		for ab_id in unlocked:
			var ab: Dictionary = _find_ability(disc, ab_id)
			var ab_lbl := Label.new()
			ab_lbl.text = "  • %s" % ab.get("name", ab_id)
			ab_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
			discs_panel.add_child(ab_lbl)


func _find_ability(disc: Dictionary, ability_id: String) -> Dictionary:
	for ab in disc.get("abilities", []):
		if ab.get("id", "") == ability_id:
			return ab
	return {}


# ---------------------------------------------------------------------------
# Conditions (injuries, survival warnings)
# ---------------------------------------------------------------------------

func _refresh_conditions() -> void:
	if not visible or cond_panel == null:
		return
	for c in cond_panel.get_children():
		c.queue_free()

	if _health == null or _health.active_injuries.is_empty():
		var lbl := Label.new()
		lbl.text = "No active conditions."
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		cond_panel.add_child(lbl)
		return

	for inj_id in _health.active_injuries:
		var inj: Dictionary = GameData.get_injury(inj_id)
		var panel := PanelContainer.new()
		var col := VBoxContainer.new()

		var name_lbl := Label.new()
		name_lbl.text = inj.get("name", inj_id)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.2))
		col.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = inj.get("description", "")
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		col.add_child(desc_lbl)

		var dur_lbl := Label.new()
		dur_lbl.text = "Duration: Until treated"
		dur_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		col.add_child(dur_lbl)

		panel.add_child(col)
		cond_panel.add_child(panel)
