## PlayerCombat
## Handles melee, bow, and firearm combat logic, dodge, block, and discipline integration.
class_name PlayerCombat
extends Node

signal attack_landed(target: Node, damage: float)
signal riposte_available(window_duration: float)
signal riposte_executed(target: Node, damage: float)
signal firearm_discharged(weapon_id: String)
signal reload_step_completed(steps_remaining: int)
signal reload_completed()

const SPRING_ARM_LENGTH := 4.0  # Camera offset behind player
const UNARMED_REACH := 0.8
const BOW_RANGE := 60.0

# Cooldowns and state
var attack_cooldown: float = 0.0
var is_blocking: bool = false
var is_drawing_bow: bool = false
var draw_time: float = 0.0
var reload_steps_remaining: int = 0
var reload_step_timer: float = 0.0
var is_reloading: bool = false
var is_dodging: bool = false
var dodge_timer: float = 0.0
const DODGE_DURATION := 0.5
const DODGE_INVULN_WINDOW := 0.3

# Riposte tracking
var riposte_window_open: bool = false
var riposte_window_timer: float = 0.0
var _riposte_target: Node = null

# Second Wind tracking
var second_wind_used_this_rest: bool = false

# Weapon condition (degrades with use, affects misfire chance)
var _weapon_condition: float = 1.0

# Stone Shield
var barrier_hp: float = 0.0
var barrier_timer: float = 0.0

var _player: CharacterBody3D
var _health: PlayerHealth
var _inventory: PlayerInventory


func _ready() -> void:
	_player = get_parent()
	await _player.ready
	_health = _player.health
	_inventory = _player.inventory


func _process(delta: float) -> void:
	if GameState.is_paused_for_ui or GameState.is_sleeping:
		return
	_tick_timers(delta)
	_handle_input(delta)


func _tick_timers(delta: float) -> void:
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	if dodge_timer > 0.0:
		dodge_timer -= delta
		if dodge_timer <= 0.0:
			is_dodging = false
	if riposte_window_timer > 0.0:
		riposte_window_timer -= delta
		if riposte_window_timer <= 0.0:
			riposte_window_open = false
	if is_reloading:
		reload_step_timer -= delta
		if reload_step_timer <= 0.0:
			_complete_reload_step()
	if barrier_timer > 0.0:
		barrier_timer -= delta
		if barrier_timer <= 0.0:
			barrier_hp = 0.0
	if is_drawing_bow and Input.is_action_pressed("attack"):
		draw_time += delta
		_health.drain_stamina(_get_bow_held_stamina_drain() * delta)


func _handle_input(delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		_try_attack()
	if Input.is_action_just_released("attack"):
		if is_drawing_bow:
			_release_bow()
	if Input.is_action_pressed("block"):
		if not is_blocking:
			is_blocking = true
		_health.drain_stamina(GameData.survival_params.get("stamina", {}).get("block_drain_per_second", 8.0) * delta)
	else:
		is_blocking = false
	if Input.is_action_just_pressed("dodge"):
		_try_dodge()


func _try_attack() -> void:
	if attack_cooldown > 0.0 or is_dodging:
		return
	var anim: PlayerAnimations = _player.get_node_or_null("PlayerAnimations")
	if anim:
		anim.play_once("attack")
	var weapon: Dictionary = get_equipped_weapon()
	if weapon.is_empty():
		_melee_unarmed()
		return
	match weapon.get("type", ""):
		"one_handed_blade", "two_handed_blade", "blunt":
			_melee_attack(weapon)
		"bow":
			_start_bow_draw(weapon)
		"pistol", "musket":
			_try_fire(weapon)


func _melee_unarmed() -> void:
	if not _health.try_consume_stamina(10.0):
		return
	_set_attack_cooldown(1.0)
	var target: Node = _get_melee_target(UNARMED_REACH)
	if target == null:
		return
	_deal_damage(target, 10.0)


func _melee_attack(weapon: Dictionary) -> void:
	var stamina_cost: float = weapon.get("stamina_cost", 15.0)
	if not _health.try_consume_stamina(stamina_cost):
		return
	_set_attack_cooldown(1.0 / weapon.get("attack_speed", 1.0))
	var target: Node = _get_melee_target(weapon.get("melee_range", 1.0))
	if target == null:
		return

	var damage: float = _calculate_melee_damage(weapon)
	_deal_damage(target, damage)

	# Swordsman Bleed on crit
	if randf() < 0.1 and DisciplineManager.is_ability_unlocked("swordsman", "bleed"):
		if target.has_method("apply_status"):
			target.apply_status("bleed", 3.0, 10.0, 3)


func _calculate_melee_damage(weapon: Dictionary) -> float:
	var base: float = weapon.get("damage", 10.0)
	# Warrior Heavy Hand
	if DisciplineManager.has_passive("heavy_hand"):
		var eff: Dictionary = DisciplineManager.get_passive_effect("heavy_hand")
		base *= eff.get("melee_damage_multiplier", 1.20)
	# Rune effects
	for rune_eff in _inventory.get_all_equipped_rune_effects():
		if rune_eff.has("melee_damage_multiplier"):
			base *= rune_eff["melee_damage_multiplier"]
	return base


func _get_melee_target(weapon_reach: float) -> Node:
	var space := _player.get_world_3d().direct_space_state
	var fwd   := _player_forward()
	var end   := _player.global_position + Vector3.UP * 1.0 + fwd * weapon_reach

	var sphere := SphereShape3D.new()
	sphere.radius = 0.4
	var sq := PhysicsShapeQueryParameters3D.new()
	sq.shape = sphere
	sq.transform = Transform3D(Basis.IDENTITY, end)
	sq.exclude = [_player.get_rid()]
	sq.collision_mask = 0b10
	var hits: Array = space.intersect_shape(sq, 1)
	if not hits.is_empty():
		return hits[0].get("collider")
	return null


## Horizontal forward direction from the camera pivot (what the player is facing),
## independent of camera elevation or spring-arm offset.
func _player_forward() -> Vector3:
	var cb: Basis = _player.camera_pivot.global_transform.basis
	return Vector3(-cb.z.x, 0.0, -cb.z.z).normalized()


func _deal_damage(target: Node, damage: float) -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage, _player)
		attack_landed.emit(target, damage)
		# XP triggers
		DisciplineManager.add_xp("warrior", "melee_kill")  # On kill tracked by monster


func _start_bow_draw(weapon: Dictionary) -> void:
	is_drawing_bow = true
	draw_time = 0.0


func _release_bow() -> void:
	is_drawing_bow = false
	var weapon: Dictionary = get_equipped_weapon()
	if weapon.is_empty():
		return
	var arrow_id: String = "arrow"
	if not _inventory.has_item(arrow_id):
		return
	_inventory.remove_item(arrow_id, 1)

	var draw_speed: float = weapon.get("draw_speed", 1.5)
	# Steady Draw passive
	if DisciplineManager.has_passive("steady_draw"):
		var eff: Dictionary = DisciplineManager.get_passive_effect("steady_draw")
		draw_speed /= eff.get("draw_speed_multiplier", 1.30)

	var charge: float = clamp(draw_time / draw_speed, 0.0, 1.0)
	var damage: float = weapon.get("damage", 35.0) * charge
	# Light Foot stealth bonus
	if DisciplineManager.has_passive("light_foot") and _is_undetected():
		var eff: Dictionary = DisciplineManager.get_passive_effect("light_foot")
		damage *= eff.get("stealth_bow_damage_multiplier", 1.40)

	var target: Node = _get_ranged_target(BOW_RANGE)
	if target != null:
		_deal_damage(target, damage)
		DisciplineManager.add_xp("survivalist", "bow_kill")

	# Arrow recovery (Survivalist)
	if DisciplineManager.has_passive("arrow_recovery"):
		var eff: Dictionary = DisciplineManager.get_passive_effect("arrow_recovery")
		if randf() < eff.get("recovery_chance", 0.60):
			_inventory.add_item("arrow", 1)

	_set_attack_cooldown(1.0)


func _try_fire(weapon: Dictionary) -> void:
	if is_reloading:
		return
	if reload_steps_remaining > 0:
		return

	var ammo_id: String = "pistol_ball" if weapon["type"] == "pistol" else "musket_ball"
	if not _inventory.has_item(ammo_id):
		return
	_inventory.remove_item(ammo_id, 1)

	# Degrade weapon condition
	_weapon_condition -= weapon.get("condition_loss_per_shot", 0.0)
	_weapon_condition = clamp(_weapon_condition, 0.0, 1.0)

	# Calculate misfire chance based on condition below threshold
	var misfire_threshold: float = weapon.get("misfire_threshold", 0.2)
	var misfire_chance: float = 0.0
	if _weapon_condition < misfire_threshold:
		misfire_chance = (misfire_threshold - _weapon_condition) / misfire_threshold

	# Hangfire delay
	var hangfire_delay := randf_range(0.3, 0.8)
	await get_tree().create_timer(hangfire_delay).timeout

	# Roll for misfire
	if randf() < misfire_chance:
		var player: Node = get_parent()
		player.health.take_damage(20.0)
		player.health.inflict_injury("bleeding_gash")
		return

	var damage: float = weapon.get("damage", 80.0)
	var sway: float = _calculate_aim_sway(weapon)
	var target: Node = _get_ranged_target(weapon.get("range", 20.0))
	if target != null:
		var accuracy_roll: float = randf()
		if accuracy_roll > sway:
			_deal_damage(target, damage)
		DisciplineManager.add_xp("artificer", "firearm_kill")

	firearm_discharged.emit(weapon.get("id", ""))
	_attract_monsters(weapon.get("monster_aggro_radius", 80.0))

	# Start reload
	var total_steps: int = weapon.get("reload_steps", 4)
	var step_time: float = weapon.get("reload_time_per_step", 1.2)
	# Quick Load
	if DisciplineManager.has_passive("quick_load"):
		var eff: Dictionary = DisciplineManager.get_passive_effect("quick_load")
		step_time *= eff.get("reload_time_multiplier", 0.70)
	reload_steps_remaining = total_steps
	reload_step_timer = step_time
	is_reloading = true


func _complete_reload_step() -> void:
	reload_steps_remaining -= 1
	var weapon: Dictionary = get_equipped_weapon()
	var step_time: float = weapon.get("reload_time_per_step", 1.2)
	if DisciplineManager.has_passive("quick_load"):
		var eff: Dictionary = DisciplineManager.get_passive_effect("quick_load")
		step_time *= eff.get("reload_time_multiplier", 0.70)

	if reload_steps_remaining <= 0:
		is_reloading = false
		reload_step_timer = 0.0
		reload_completed.emit()
	else:
		reload_step_timer = step_time
		reload_step_completed.emit(reload_steps_remaining)


func _calculate_aim_sway(weapon: Dictionary) -> float:
	var base_sway: float = weapon.get("aim_sway_base", 0.05)
	var f_params: Dictionary = GameData.survival_params.get("fatigue", {})
	var fatigue: float = _player.survival.fatigue
	var aim_threshold: float = f_params.get("aim_impairment_threshold", 60.0)
	if fatigue > aim_threshold:
		var fatigue_sway: float = (fatigue - aim_threshold) / 40.0 * 0.15
		# Steady Hands
		if DisciplineManager.has_passive("steady_hands"):
			var eff: Dictionary = DisciplineManager.get_passive_effect("steady_hands")
			fatigue_sway *= eff.get("fatigue_sway_multiplier", 0.50)
		base_sway += fatigue_sway
	return base_sway


func _try_dodge() -> bool:
	if is_dodging or attack_cooldown > 0.0:
		return false
	if not _health.try_consume_stamina(GameData.survival_params.get("stamina", {}).get("dodge_cost", 20.0)):
		return false

	is_dodging = true
	var dodge_duration: float = DODGE_DURATION
	# Swordsman Read widens window
	if DisciplineManager.has_passive("read"):
		var eff: Dictionary = DisciplineManager.get_passive_effect("read")
		# Handled in open_riposte_window
		pass
	dodge_timer = dodge_duration

	# Check if riposte window is open
	if riposte_window_open and _riposte_target != null:
		_execute_riposte(_riposte_target)
	DisciplineManager.add_xp("swordsman", "dodge_successful")
	return true


func open_riposte_window(attacker: Node, base_window: float) -> void:
	var window: float = base_window
	if DisciplineManager.has_passive("read"):
		var eff: Dictionary = DisciplineManager.get_passive_effect("read")
		window += eff.get("dodge_window_bonus", 0.3)
	riposte_window_open = true
	riposte_window_timer = window
	_riposte_target = attacker
	riposte_available.emit(window)


func _execute_riposte(target: Node) -> void:
	if not DisciplineManager.is_ability_unlocked("swordsman", "riposte"):
		return
	var weapon: Dictionary = get_equipped_weapon()
	var base_damage: float = weapon.get("damage", 10.0) if not weapon.is_empty() else 10.0
	var eff: Dictionary = DisciplineManager.get_passive_effect("riposte") if DisciplineManager.has_passive("riposte") else {}
	var damage: float = base_damage * eff.get("damage_multiplier", 2.0)
	# Warrior Heavy Hand applies to riposte
	if DisciplineManager.has_passive("heavy_hand"):
		var warrior_eff: Dictionary = DisciplineManager.get_passive_effect("heavy_hand")
		damage *= warrior_eff.get("melee_damage_multiplier", 1.20)

	if target.has_method("take_damage"):
		target.take_damage(damage, _player)
	riposte_executed.emit(target, damage)
	riposte_window_open = false
	DisciplineManager.add_xp("swordsman", "riposte_landed")

	# Cripple
	if DisciplineManager.is_ability_unlocked("swordsman", "cripple"):
		var cripple_eff: Dictionary = DisciplineManager.get_passive_effect("cripple")
		if target.has_method("apply_cripple"):
			target.apply_cripple(cripple_eff.get("cripple_duration", 15.0))
		DisciplineManager.add_xp("swordsman", "cripple_applied")

	# Flurry follow-up
	if DisciplineManager.is_ability_unlocked("swordsman", "flurry"):
		_execute_flurry(target)


func _execute_flurry(target: Node) -> void:
	if not _health.try_consume_stamina(45.0):
		return
	var weapon: Dictionary = get_equipped_weapon()
	var base_damage: float = weapon.get("damage", 10.0) if not weapon.is_empty() else 10.0
	for i in range(3):
		if target.has_method("take_damage"):
			target.take_damage(base_damage * 0.9, _player)


func receive_attack_for_block(damage: float, attacker: Node) -> float:
	var blocked_pct: float = 0.6
	var stamina_cost: float = damage * 0.3
	_health.drain_stamina(stamina_cost)
	if not is_blocking:
		return damage
	return damage * (1.0 - blocked_pct)


func receive_damage_check_barrier(damage: float) -> float:
	if barrier_hp <= 0.0:
		return damage
	var absorbed: float = min(damage, barrier_hp)
	barrier_hp -= absorbed
	return damage - absorbed


func is_invulnerable_dodge() -> bool:
	return is_dodging and dodge_timer > (DODGE_DURATION - DODGE_INVULN_WINDOW)


var _attack_cooldown_max: float = 0.0

func get_attack_cooldown_frac() -> float:
	if _attack_cooldown_max <= 0.0:
		return 0.0
	return attack_cooldown / _attack_cooldown_max

func _set_attack_cooldown(base_cooldown: float) -> void:
	var mult: float = _health.get_attack_cooldown_multiplier()
	attack_cooldown = base_cooldown * mult
	_attack_cooldown_max = attack_cooldown


func get_equipped_weapon() -> Dictionary:
	var active: Dictionary = _inventory.get_active_weapon()
	if active.is_empty():
		return {}
	return GameData.get_weapon(active.get("item_id", ""))


func _get_ranged_target(max_range: float) -> Node:
	var camera: Camera3D = _player.camera
	var space: PhysicsDirectSpaceState3D = _player.get_world_3d().direct_space_state
	var origin: Vector3 = camera.global_position
	var end: Vector3 = origin + (-camera.global_transform.basis.z * max_range)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [_player]
	query.collision_mask = 0b10
	var result: Dictionary = space.intersect_ray(query)
	if result.is_empty():
		return null
	return result.get("collider")


func _attract_monsters(radius: float) -> void:
	var monsters: Array = get_tree().get_nodes_in_group("monster")
	for m in monsters:
		if m.global_position.distance_to(_player.global_position) <= radius:
			if m.has_method("alert_to_sound"):
				m.alert_to_sound(_player.global_position)


func _is_undetected() -> bool:
	# Check if any nearby monster has detected the player
	var monsters: Array = get_tree().get_nodes_in_group("monster")
	for m in monsters:
		if m.has_method("has_detected_player") and m.has_detected_player():
			return false
	return true


func _get_bow_held_stamina_drain() -> float:
	var base: float = 5.0
	if DisciplineManager.has_passive("steady_draw"):
		var eff: Dictionary = DisciplineManager.get_passive_effect("steady_draw")
		base *= eff.get("held_stamina_drain_multiplier", 0.50)
	return base


func on_rest() -> void:
	second_wind_used_this_rest = false


func get_save_data() -> Dictionary:
	return {
		"reload_steps_remaining": reload_steps_remaining,
		"second_wind_used": second_wind_used_this_rest
	}


func apply_save_data(data: Dictionary) -> void:
	reload_steps_remaining = data.get("reload_steps_remaining", 0)
	second_wind_used_this_rest = data.get("second_wind_used", false)
