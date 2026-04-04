## HUD
## Main HUD: compass, health/stamina bars, status effects, equipped weapon display.
## Survival needs communicated via audio/visual cues, not persistent bars (per GDD intent).
extends Control

@onready var health_bar: ProgressBar = $HealthBar
@onready var stamina_bar: ProgressBar = $StaminaBar
@onready var compass_needle: Control = $Compass/Needle
@onready var weapon_label: Label = $WeaponDisplay/WeaponName
@onready var status_container: HBoxContainer = $StatusEffects
@onready var reload_indicator: Control = $ReloadIndicator
@onready var reload_bar: ProgressBar = $ReloadIndicator/ReloadBar
@onready var crosshair: Control = $Crosshair

var _player: Node = null
var _player_health: PlayerHealth = null
var _player_combat: PlayerCombat = null
var _compass_bar: Control = null


func _ready() -> void:
	add_to_group("hud")
	_setup_heading_label()
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")
	if _player:
		_player_health = _player.health
		_player_combat = _player.combat
		_player_health.health_changed.connect(_on_health_changed)
		_player_health.stamina_changed.connect(_on_stamina_changed)
		_player_health.injury_inflicted.connect(_on_injury_inflicted)
		_player_health.injury_resolved.connect(_on_injury_resolved)
		_player_combat.reload_step_completed.connect(_on_reload_step)
		_player_combat.reload_completed.connect(_on_reload_complete)
		_player.inventory.inventory_changed.connect(_update_weapon_display)
		_player.inventory.inventory_changed.connect(_update_compass_visibility)
		_update_compass_visibility()
	SaveManager.save_completed.connect(_on_save_completed)
	SaveManager.save_failed.connect(_on_save_failed)
	_debug_setup()  # DEBUG — remove with the block below


func _process(delta: float) -> void:
	_update_compass()
	if _debug_area_label:
		_debug_area_label.text = "[AREA] %s" % GameState.current_area_id
	if _debug_pos_label and _player:
		var p: Vector3 = _player.global_position
		_debug_pos_label.text = "[POS] %.1f, %.1f, %.1f" % [p.x, p.y, p.z]
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var col := Color(1.0, 1.0, 1.0, 0.85)
	var gap  := 4.0
	var arm  := 10.0
	var thick := 2.0
	draw_rect(Rect2(c.x - gap - arm, c.y - thick * 0.5, arm, thick), col)
	draw_rect(Rect2(c.x + gap,       c.y - thick * 0.5, arm, thick), col)
	draw_rect(Rect2(c.x - thick * 0.5, c.y - gap - arm, thick, arm), col)
	draw_rect(Rect2(c.x - thick * 0.5, c.y + gap,       thick, arm), col)


func _on_health_changed(current: float, maximum: float) -> void:
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current
		health_bar.modulate = Color.RED if current / maximum < 0.3 else Color.WHITE


func _on_stamina_changed(current: float, maximum: float) -> void:
	if stamina_bar:
		stamina_bar.max_value = maximum
		stamina_bar.value = current


func _setup_heading_label() -> void:
	_compass_bar = Control.new()
	_compass_bar.name = "CompassBar"
	_compass_bar.set_script(load("res://scripts/ui/CompassBar.gd"))
	_compass_bar.anchor_left   = 1.0 / 3.0
	_compass_bar.anchor_right  = 2.0 / 3.0
	_compass_bar.anchor_top    = 0.0
	_compass_bar.anchor_bottom = 0.0
	_compass_bar.offset_left   = 0.0
	_compass_bar.offset_right  = 0.0
	_compass_bar.offset_top    = 0.0
	_compass_bar.offset_bottom = 48.0
	_compass_bar.visible = false
	add_child(_compass_bar)


func _update_compass() -> void:
	if _player == null or compass_needle == null:
		return
	var rot_y: float = _player.camera_pivot.rotation.y
	compass_needle.rotation = -rot_y
	_update_heading()


func _update_heading() -> void:
	if _compass_bar == null or not _compass_bar.visible:
		return
	_compass_bar.heading_deg = fposmod(rad_to_deg(-_player.camera_pivot.rotation.y), 360.0)
	_compass_bar.queue_redraw()


func _update_compass_visibility() -> void:
	if _compass_bar == null or _player == null:
		return
	_compass_bar.visible = _player.inventory.has_item("compass")


func _update_weapon_display() -> void:
	if _player == null or weapon_label == null:
		return
	var active: Dictionary = _player.inventory.get_active_weapon()
	if active.is_empty():
		weapon_label.text = "Unarmed"
	else:
		var weapon: Dictionary = GameData.get_weapon(active.get("item_id", ""))
		weapon_label.text = weapon.get("name", "Unknown")
	_debug_update_weapon()


func _on_injury_inflicted(injury_id: String) -> void:
	var inj := GameData.get_injury(injury_id)
	_add_status_icon(injury_id, inj.get("name", injury_id))


func _on_injury_resolved(injury_id: String) -> void:
	_remove_status_icon(injury_id)


func _add_status_icon(id: String, display_name: String) -> void:
	if status_container == null:
		return
	# Remove existing if any
	_remove_status_icon(id)
	var label := Label.new()
	label.name = "status_" + id
	label.text = display_name
	label.add_theme_color_override("font_color", Color.ORANGE_RED)
	status_container.add_child(label)


func _remove_status_icon(id: String) -> void:
	if status_container == null:
		return
	var existing := status_container.get_node_or_null("status_" + id)
	if existing:
		existing.queue_free()


func _on_reload_step(steps_remaining: int) -> void:
	if reload_indicator:
		reload_indicator.visible = true


func _on_reload_complete() -> void:
	if reload_indicator:
		reload_indicator.visible = false


func show_message(text: String, duration: float = 3.0) -> void:
	var msg_label := get_node_or_null("MessageLabel")
	if msg_label:
		msg_label.text = text
		msg_label.visible = true
		await get_tree().create_timer(duration).timeout
		msg_label.visible = false


func _on_save_completed(slot: String) -> void:
	show_message("Game saved. [%s]" % slot, 3.0)


func _on_save_failed(reason: String) -> void:
	show_message("Save FAILED: %s" % reason, 5.0)


# ---------------------------------------------------------------------------
# DEBUG OVERLAY — weapon damage readout. Delete this entire block to remove.
# ---------------------------------------------------------------------------
var _debug_label: Label = null
var _debug_last_hit: float = 0.0
var _debug_area_label: Label = null
var _debug_pos_label: Label = null

func _debug_setup() -> void:
	_debug_pos_label = Label.new()
	_debug_pos_label.name = "DebugPosLabel"
	_debug_pos_label.position = Vector2(12, -64)
	_debug_pos_label.anchor_bottom = 1.0
	_debug_pos_label.anchor_top = 1.0
	_debug_pos_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_debug_pos_label.add_theme_color_override("font_color", Color(0.4, 1.0, 1.0))
	_debug_pos_label.add_theme_font_size_override("font_size", 14)
	add_child(_debug_pos_label)

	_debug_area_label = Label.new()
	_debug_area_label.name = "DebugAreaLabel"
	_debug_area_label.position = Vector2(12, -48)
	_debug_area_label.anchor_bottom = 1.0
	_debug_area_label.anchor_top = 1.0
	_debug_area_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_debug_area_label.add_theme_color_override("font_color", Color(0.4, 1.0, 1.0))
	_debug_area_label.add_theme_font_size_override("font_size", 14)
	add_child(_debug_area_label)

	_debug_label = Label.new()
	_debug_label.name = "DebugWeaponLabel"
	_debug_label.position = Vector2(12, -12)
	_debug_label.anchor_bottom = 1.0
	_debug_label.anchor_top = 1.0
	_debug_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_debug_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.4))
	_debug_label.add_theme_font_size_override("font_size", 14)
	add_child(_debug_label)
	if _player_combat:
		_player_combat.attack_landed.connect(_debug_on_hit)
	_debug_update_weapon()

func _debug_update_weapon() -> void:
	if _debug_label == null or _player == null:
		return
	var active: Dictionary = _player.inventory.get_active_weapon()
	if active.is_empty():
		_debug_label.text = "[DEBUG] Weapon: Unarmed\nLast hit: %.1f dmg" % _debug_last_hit
		return
	var wdef: Dictionary = GameData.get_weapon(active.get("item_id", ""))
	var dmg: int = wdef.get("damage", 0)
	var slot_name := "Main" if _player.inventory.active_weapon_slot == 0 else "Backup"
	_debug_label.text = "[DEBUG] %s (%s) — %d dmg\nLast hit: %.1f dmg" % [
		wdef.get("name", "?"), slot_name, dmg, _debug_last_hit
	]

func _debug_on_hit(target: Node, damage: float) -> void:
	_debug_last_hit = damage
	_debug_update_weapon()
# ---------------------------------------------------------------------------
# END DEBUG OVERLAY
# ---------------------------------------------------------------------------
