## AbilitySystem
## Manages active ability execution, cooldowns, channeling, and reagent consumption.
## Attached to the Player node.
extends Node

signal ability_activated(discipline_id: String, ability_id: String)
signal ability_channel_started(discipline_id: String, ability_id: String, duration: float)
signal ability_channel_completed(discipline_id: String, ability_id: String)
signal ability_channel_interrupted(discipline_id: String, ability_id: String)
signal ability_on_cooldown(discipline_id: String, ability_id: String, remaining: float)
signal ward_placed(position: Vector3, radius: float, duration: float)
signal anchor_set(position: Vector3)
signal anchor_teleport_used()

# Cooldown tracking: "discipline_id.ability_id" -> seconds_remaining
var _cooldowns: Dictionary = {}

# Per-rest tracking
var _once_per_rest: Dictionary = {}

# Channeling state
var _channeling: bool = false
var _channel_discipline: String = ""
var _channel_ability: String = ""
var _channel_timer: float = 0.0
var _channel_duration: float = 0.0

# Anchor position for Ritualist Anchor ability
var _anchor_position: Vector3 = Vector3.ZERO
var _anchor_set: bool = false

# Ward instances
var _active_wards: Array = []

# Stone Shield
var _shield_active: bool = false

var _player: Node = null


func _ready() -> void:
	_player = get_parent()


func _process(delta: float) -> void:
	if GameState.is_paused_for_ui or GameState.is_sleeping:
		return
	_tick_cooldowns(delta)
	_tick_channel(delta)


func _tick_cooldowns(delta: float) -> void:
	for key in _cooldowns.keys():
		_cooldowns[key] -= delta
		if _cooldowns[key] <= 0.0:
			_cooldowns.erase(key)


func _tick_channel(delta: float) -> void:
	if not _channeling:
		return
	# Interrupt if player moved significantly
	if _player.velocity.length() > 0.5:
		_interrupt_channel()
		return
	_channel_timer += delta
	if _channel_timer >= _channel_duration:
		_complete_channel()


func activate_ability(discipline_id: String, ability_id: String) -> bool:
	if not DisciplineManager.is_ability_unlocked(discipline_id, ability_id):
		return false
	if is_on_cooldown(discipline_id, ability_id):
		ability_on_cooldown.emit(discipline_id, ability_id, get_cooldown_remaining(discipline_id, ability_id))
		return false
	if _channeling:
		return false

	var disc := GameData.get_discipline(discipline_id)
	var ab := _get_ability_def(disc, ability_id)
	if ab.is_empty():
		return false

	# Check once-per-rest
	var once_key := discipline_id + "." + ability_id
	if ab.get("cooldown", 0) == -1:
		if _once_per_rest.get(once_key, false):
			return false

	# Check reagent for Wizard
	if discipline_id == "wizard":
		if not _consume_reagent(ab):
			return false

	var channel_time: float = ab.get("channel_time", ab.get("cast_time", 0.0))
	if channel_time > 0.0:
		_start_channel(discipline_id, ability_id, channel_time)
	else:
		_execute_ability(discipline_id, ability_id, ab)

	return true


func _start_channel(discipline_id: String, ability_id: String, duration: float) -> void:
	_channeling = true
	_channel_discipline = discipline_id
	_channel_ability = ability_id
	_channel_timer = 0.0
	_channel_duration = duration
	DisciplineManager.add_xp(discipline_id, "ritual_channel_completed")
	ability_channel_started.emit(discipline_id, ability_id, duration)


func _complete_channel() -> void:
	_channeling = false
	var disc := GameData.get_discipline(_channel_discipline)
	var ab := _get_ability_def(disc, _channel_ability)
	if not ab.is_empty():
		_execute_ability(_channel_discipline, _channel_ability, ab)
	ability_channel_completed.emit(_channel_discipline, _channel_ability)
	_channel_discipline = ""
	_channel_ability = ""


func _interrupt_channel() -> void:
	ability_channel_interrupted.emit(_channel_discipline, _channel_ability)
	_channeling = false
	_channel_discipline = ""
	_channel_ability = ""
	_channel_timer = 0.0


func _execute_ability(discipline_id: String, ability_id: String, ab: Dictionary) -> void:
	var effect_data: Dictionary = ab.get("effect_data", {})
	var cooldown: float = ab.get("cooldown", 0.0)
	var once_key := discipline_id + "." + ability_id

	match ability_id:
		# ---- SURVIVALIST ----
		"trapper":
			_place_trap(effect_data)
		"night_eyes":
			_toggle_night_eyes(effect_data)
		"ghost_walk":
			_activate_ghost_walk(effect_data)

		# ---- RITUALIST ----
		"ward":
			_place_ward(effect_data)
		"reveal":
			_execute_reveal(effect_data)
		"calm":
			_execute_calm(effect_data)
		"mending":
			_execute_mending(effect_data)
		"banish":
			_execute_banish(effect_data)
			if ab.get("cooldown", 0) == 86400:
				_once_per_rest[once_key] = true
		"anchor":
			_execute_anchor(effect_data)

		# ---- WARRIOR ----
		"stagger":
			_execute_stagger(effect_data)
		"second_wind":
			_execute_second_wind(effect_data)
			_once_per_rest[once_key] = true
		"warcry":
			_execute_warcry(effect_data)

		# ---- SWORDSMAN ----
		"riposte":
			pass  # Handled reactively in PlayerCombat
		"flurry":
			pass  # Handled reactively in PlayerCombat

		# ---- ARTIFICER ----
		"field_repair":
			_execute_field_repair(effect_data)
		"ammo_smith":
			_open_crafting_ui(["ammo_pistol_ball", "ammo_musket_ball"])
		"spike_trap":
			_place_spike_trap(effect_data)
		"reinforce":
			_execute_reinforce(effect_data)
		"jury_rig":
			_execute_jury_rig(effect_data)

		# ---- ALCHEMIST ----
		"master_brewer":
			_open_crafting_ui(effect_data.get("unlocks_recipes", []))
		"identify":
			_execute_identify(effect_data)

		# ---- WIZARD ----
		"firebolt":
			_cast_firebolt(effect_data)
		"frost_snap":
			_cast_frost_snap(effect_data)
		"force_push":
			_cast_force_push(effect_data)
		"lightning_arc":
			_cast_lightning_arc(effect_data)
		"stone_shield":
			_cast_stone_shield(effect_data)
		"ruin":
			_cast_ruin(effect_data)

	if cooldown > 0.0 and cooldown != -1.0:
		_set_cooldown(discipline_id, ability_id, cooldown)

	ability_activated.emit(discipline_id, ability_id)
	DisciplineManager.add_xp(discipline_id, "spell_cast")


# ---- SURVIVALIST ----

func _place_trap(data: Dictionary) -> void:
	var item_id: String = data.get("trap_item_id", "snare_trap")
	if not _player.inventory.has_item(item_id):
		return
	_player.inventory.remove_item(item_id, 1)
	var trap_scene := load("res://scenes/items/SnareTrap.tscn")
	if trap_scene == null:
		return
	var trap := trap_scene.instantiate()
	trap.global_position = _player.global_position
	get_tree().root.add_child(trap)
	DisciplineManager.add_xp("survivalist", "trap_check")


func _toggle_night_eyes(data: Dictionary) -> void:
	var cam: Camera3D = _player.camera
	if cam == null:
		return
	var env := cam.get_world_3d().environment
	if env == null:
		return
	# Toggle night vision via environment brightness
	# Full implementation uses shader; placeholder toggles ambient
	pass


func _activate_ghost_walk(data: Dictionary) -> void:
	var duration: float = data.get("duration", 10.0)
	# Set player fully undetectable for duration
	_player.set_meta("ghost_walk_active", true)
	await get_tree().create_timer(duration).timeout
	_player.set_meta("ghost_walk_active", false)


# ---- RITUALIST ----

func _place_ward(data: Dictionary) -> void:
	var radius: float = data.get("radius", 3.0)
	var duration: float = data.get("duration", 60.0)
	var target_pos := _get_target_position(8.0)
	var ward_scene := load("res://scenes/combat/Ward.tscn")
	if ward_scene:
		var ward := ward_scene.instantiate()
		ward.global_position = target_pos
		ward.setup(radius, duration)
		get_tree().root.add_child(ward)
		_active_wards.append(ward)
	ward_placed.emit(target_pos, radius, duration)
	DisciplineManager.add_xp("ritualist", "survived_warded_night")


func _execute_reveal(data: Dictionary) -> void:
	var area_node = WorldManager.active_areas.get(GameState.current_area_id)
	if area_node and area_node.has_method("survey_all_resources"):
		area_node.survey_all_resources()


func _execute_calm(data: Dictionary) -> void:
	var target := _get_closest_monster(20.0)
	if target == null:
		return
	var is_aoe: bool = data.get("is_aoe", false)
	var aoe_radius: float = data.get("aoe_radius", 8.0)
	var duration: float = data.get("duration", 60.0)
	if is_aoe:
		var monsters := get_tree().get_nodes_in_group("monster")
		for m in monsters:
			if m.global_position.distance_to(_player.global_position) <= aoe_radius:
				if m.has_method("apply_calm"):
					m.apply_calm(duration)
	else:
		if target.has_method("apply_calm"):
			target.apply_calm(duration)
	DisciplineManager.add_xp("ritualist", "ritual_channel_completed")


func _execute_mending(data: Dictionary) -> void:
	# Treat injury as one tier higher
	var bonus: int = data.get("treatment_tier_bonus", 1)
	_player.set_meta("mending_tier_bonus", bonus)
	# Player's on_sleep will check this meta


func _execute_banish(data: Dictionary) -> void:
	var target := _get_closest_monster(15.0)
	if target == null:
		return
	if target.is_apex():
		return
	if target.has_method("force_despawn"):
		target.force_despawn()
	else:
		target.queue_free()


func _execute_anchor(data: Dictionary) -> void:
	if not _anchor_set:
		_anchor_position = _player.global_position
		_anchor_set = true
		anchor_set.emit(_anchor_position)
	else:
		# Teleport
		_player.global_position = _anchor_position
		_anchor_set = false
		anchor_teleport_used.emit()
		DisciplineManager.add_xp("ritualist", "ritual_channel_completed")


# ---- WARRIOR ----

func _execute_stagger(data: Dictionary) -> void:
	var target := _get_closest_monster(3.0)
	if target == null:
		return
	if target.is_apex():
		return
	var stagger_duration: float = data.get("stagger_duration", 2.5)
	if target.has_method("apply_stagger"):
		target.apply_stagger(stagger_duration)
	_player.health.drain_stamina(data.get("stamina_cost", 40.0))


func _execute_second_wind(data: Dictionary) -> void:
	if _once_per_rest.get("warrior.second_wind", false):
		return
	var hp_threshold: float = data.get("hp_threshold", 0.25)
	if _player.health.current_health / _player.health.max_health > hp_threshold:
		return
	var stamina_restore: float = data.get("stamina_restore_percent", 0.30) * _player.health.max_stamina
	_player.health.restore_stamina(stamina_restore)
	var resist_duration: float = data.get("duration", 8.0)
	_player.set_meta("damage_resist_active", true)
	_player.set_meta("damage_resist_value", data.get("damage_resist_percent", 0.35))
	await get_tree().create_timer(resist_duration).timeout
	_player.set_meta("damage_resist_active", false)


func _execute_warcry(data: Dictionary) -> void:
	var radius: float = data.get("radius", 15.0)
	var flinch: float = data.get("flinch_duration", 1.5)
	var monsters := get_tree().get_nodes_in_group("monster")
	for m in monsters:
		if m.global_position.distance_to(_player.global_position) > radius:
			continue
		if m.is_apex():
			continue
		if m.has_method("apply_flinch"):
			m.apply_flinch(flinch)


# ---- ARTIFICER ----

func _execute_field_repair(data: Dictionary) -> void:
	if get_tree().get_first_node_in_group("player_camp") == null:
		return
	var ui := get_tree().get_first_node_in_group("repair_ui")
	if ui and ui.has_method("show"):
		ui.show()


func _open_crafting_ui(recipe_ids: Array) -> void:
	var ui := get_tree().get_first_node_in_group("crafting_ui")
	if ui and ui.has_method("show_recipes"):
		ui.show_recipes(recipe_ids)


func _place_spike_trap(data: Dictionary) -> void:
	var recipe_id := "spike_trap"
	var alchemy := AlchemySystem.new()
	if not alchemy.can_brew(recipe_id, AlchemySystem.Station.HOME_WORKSHOP, _player.inventory):
		return
	alchemy.brew(recipe_id, AlchemySystem.Station.HOME_WORKSHOP, _player.inventory)
	var trap_scene := load("res://scenes/items/SpikeTrap.tscn")
	if trap_scene == null:
		return
	var trap := trap_scene.instantiate()
	trap.global_position = _get_target_position(3.0)
	trap.damage = data.get("damage", 80.0)
	get_tree().root.add_child(trap)
	DisciplineManager.add_xp("artificer", "trap_triggered")


func _execute_reinforce(data: Dictionary) -> void:
	_player.set_meta("reinforced_until_sleep", true)
	_player.set_meta("reinforce_damage_bonus", data.get("damage_bonus_percent", 20) / 100.0)
	_player.set_meta("reinforce_dr_bonus", data.get("dr_bonus", 10))


func _execute_jury_rig(data: Dictionary) -> void:
	var uses_key := "jury_rig_uses"
	var uses_remaining: int = _player.get_meta(uses_key, data.get("uses", 10))
	if uses_remaining <= 0:
		return
	_player.set_meta(uses_key, uses_remaining - 1)
	var repair_pct: float = data.get("repair_amount_percent", 0.40)
	# Repair equipped weapon and armor by repair_pct of max durability
	# Full impl: iterate equipped items and restore durability
	DisciplineManager.add_xp("artificer", "repair_performed")


# ---- ALCHEMIST ----

func _execute_identify(data: Dictionary) -> void:
	var ui := get_tree().get_first_node_in_group("identify_ui")
	if ui and ui.has_method("show"):
		ui.show()
	DisciplineManager.add_xp("alchemist", "recipe_experimented")


# ---- WIZARD ----

func _cast_firebolt(data: Dictionary) -> void:
	var target := _get_ranged_target(40.0)
	if target == null:
		return
	var damage: float = _apply_arcane_rune_bonus(data.get("damage", 35.0))
	if target.has_method("take_damage"):
		target.take_damage(damage, _player)
	if target.has_method("apply_status"):
		target.apply_status("burn", data.get("burn_dps", 5.0), data.get("burn_duration", 6.0))
	DisciplineManager.add_xp("wizard", "spell_kill")
	_spawn_projectile_effect("firebolt", target.global_position)


func _cast_frost_snap(data: Dictionary) -> void:
	var target := _get_ranged_target(30.0)
	if target == null:
		return
	var root_duration: float = data.get("root_duration", 5.0)
	if target.has_method("apply_root"):
		target.apply_root(root_duration)
	_spawn_projectile_effect("frost_snap", target.global_position)


func _cast_force_push(data: Dictionary) -> void:
	var cone_angle: float = data.get("cone_angle", 60.0)
	var knockback: float = data.get("knockback_force", 15.0)
	var stagger: float = data.get("stagger_duration", 1.5)
	var monsters := get_tree().get_nodes_in_group("monster")
	var forward := -_player.global_transform.basis.z
	for m in monsters:
		var to_monster := (m.global_position - _player.global_position).normalized()
		var angle := rad_to_deg(forward.angle_to(to_monster))
		if angle > cone_angle / 2.0:
			continue
		if m.global_position.distance_to(_player.global_position) > 10.0:
			continue
		var push_dir := to_monster
		push_dir.y = 0.3
		m.velocity += push_dir * knockback
		if m.has_method("apply_stagger"):
			m.apply_stagger(stagger)


func _cast_lightning_arc(data: Dictionary) -> void:
	var damage: float = _apply_arcane_rune_bonus(data.get("damage", 70.0))
	var max_targets: int = data.get("max_chain_targets", 3)
	var chain_range: float = data.get("chain_range", 6.0)
	var first_target := _get_ranged_target(30.0)
	if first_target == null:
		return
	var targets_hit := [first_target]
	first_target.take_damage(damage, _player) if first_target.has_method("take_damage") else null
	# Chain to nearby monsters
	var all_monsters := get_tree().get_nodes_in_group("monster")
	var last_pos := first_target.global_position
	while targets_hit.size() < max_targets:
		var next: Node = null
		var next_dist := INF
		for m in all_monsters:
			if m in targets_hit:
				continue
			var d := m.global_position.distance_to(last_pos)
			if d < chain_range and d < next_dist:
				next_dist = d
				next = m
		if next == null:
			break
		next.take_damage(damage * 0.7, _player) if next.has_method("take_damage") else null
		targets_hit.append(next)
		last_pos = next.global_position
	DisciplineManager.add_xp("wizard", "spell_kill")


func _cast_stone_shield(data: Dictionary) -> void:
	var barrier_hp: float = data.get("barrier_hp", 80.0)
	var duration: float = data.get("duration", 15.0)
	_player.combat.barrier_hp = barrier_hp
	_player.combat.barrier_timer = duration
	_shield_active = true


func _cast_ruin(data: Dictionary) -> void:
	var target := _get_ranged_target(50.0)
	if target == null:
		return
	var damage: float = _apply_arcane_rune_bonus(data.get("damage", 250.0))
	if target.has_method("take_damage"):
		target.take_damage(damage, _player)
	DisciplineManager.add_xp("wizard", "spell_kill")
	_spawn_projectile_effect("ruin", target.global_position)


func _apply_arcane_rune_bonus(base_damage: float) -> float:
	for rune_eff in _player.inventory.get_all_equipped_rune_effects():
		if rune_eff.has("wizard_spell_damage_multiplier"):
			base_damage *= rune_eff["wizard_spell_damage_multiplier"]
	return base_damage


func _consume_reagent(ab: Dictionary) -> bool:
	var reagent_id: String = ab.get("reagent", "")
	if reagent_id == "":
		return true
	var count: int = ab.get("reagent_count", 1)
	if not _player.inventory.has_item(reagent_id):
		return false
	_player.inventory.remove_item(reagent_id, count)
	return true


func _get_target_position(max_dist: float) -> Vector3:
	var cam: Camera3D = _player.camera
	var space := _player.get_world_3d().direct_space_state
	var origin := cam.global_position
	var end := origin + (-cam.global_transform.basis.z * max_dist)
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [_player]
	var result := space.intersect_ray(query)
	if result.is_empty():
		return end
	return result["position"]


func _get_closest_monster(max_dist: float) -> Node:
	var monsters := get_tree().get_nodes_in_group("monster")
	var closest: Node = null
	var closest_dist := max_dist
	for m in monsters:
		var d := m.global_position.distance_to(_player.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = m
	return closest


func _get_ranged_target(max_range: float) -> Node:
	var cam: Camera3D = _player.camera
	var space := _player.get_world_3d().direct_space_state
	var origin := cam.global_position
	var end := origin + (-cam.global_transform.basis.z * max_range)
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [_player]
	query.collision_mask = 0b10
	var result := space.intersect_ray(query)
	if result.is_empty():
		return null
	return result.get("collider")


func _spawn_projectile_effect(effect_type: String, target_pos: Vector3) -> void:
	# Placeholder: spawn visual effect
	pass


func is_on_cooldown(discipline_id: String, ability_id: String) -> bool:
	var key := discipline_id + "." + ability_id
	return _cooldowns.has(key) and _cooldowns[key] > 0.0


func get_cooldown_remaining(discipline_id: String, ability_id: String) -> float:
	var key := discipline_id + "." + ability_id
	return _cooldowns.get(key, 0.0)


func _set_cooldown(discipline_id: String, ability_id: String, duration: float) -> void:
	_cooldowns[discipline_id + "." + ability_id] = duration


func _get_ability_def(disc: Dictionary, ability_id: String) -> Dictionary:
	for ab in disc.get("abilities", []):
		if ab["id"] == ability_id:
			return ab
	return {}


func on_rest() -> void:
	_once_per_rest.clear()
	_player.combat.on_rest()


func get_save_data() -> Dictionary:
	return { "cooldowns": _cooldowns.duplicate(), "once_per_rest": _once_per_rest.duplicate() }


func apply_save_data(data: Dictionary) -> void:
	_cooldowns = data.get("cooldowns", {})
	_once_per_rest = data.get("once_per_rest", {})
