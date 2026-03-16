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


func _ready() -> void:
	add_to_group("hud")
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


func _process(delta: float) -> void:
	_update_compass()


func _on_health_changed(current: float, maximum: float) -> void:
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current
		health_bar.modulate = Color.RED if current / maximum < 0.3 else Color.WHITE


func _on_stamina_changed(current: float, maximum: float) -> void:
	if stamina_bar:
		stamina_bar.max_value = maximum
		stamina_bar.value = current


func _update_compass() -> void:
	if _player == null or compass_needle == null:
		return
	var player_rot_y := _player.rotation.y
	compass_needle.rotation = -player_rot_y


func _update_weapon_display() -> void:
	if _player == null or weapon_label == null:
		return
	var equipped := _player.inventory.equipped.get("weapon", {})
	if equipped.is_empty():
		weapon_label.text = "Unarmed"
		return
	var weapon := GameData.get_weapon(equipped.get("item_id", ""))
	weapon_label.text = weapon.get("name", "Unknown")


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
