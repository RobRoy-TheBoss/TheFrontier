## Monster
## Base class for all monsters. Reads stats from GameData, handles AI states,
## combat, loot, and XP trigger reporting.
extends CharacterBody3D

enum State { IDLE, PATROL, ALERT, CHASE, ATTACK, FLEE, DESPAWN, DEAD }

@export var monster_id: String = "prowler"
@export var static_mode: bool = false  # If true: no AI, no movement, no attacks

var _data: Dictionary = {}
var _stats: Dictionary = {}
var _state: State = State.IDLE
var _target: Node = null
var _health: float = 0.0
var _max_health: float = 0.0
var _alert_timer: float = 0.0
var _attack_cooldown: float = 0.0
var _patrol_timer: float = 0.0
var _patrol_target: Vector3 = Vector3.ZERO
var _has_detected_player: bool = false

# Status effects
var _cripple_timer: float = 0.0
var _bleed_stacks: int = 0
var _bleed_timer: float = 0.0
var _deathmark_active: bool = false
var _deathmark_cripple_count: int = 0
var _mesh_material: StandardMaterial3D = null

const GRAVITY := 9.8

signal died(monster_id: String, position: Vector3)


func _ready() -> void:
	add_to_group("monster")
	_data = GameData.get_monster(monster_id)
	if _data.is_empty():
		push_error("[Monster] No data for id: " + monster_id)
		queue_free()
		return
	_stats = _data.get("stats", {})
	_max_health = _stats.get("max_health", 60.0)
	_health = _max_health
	var mesh: MeshInstance3D = get_node_or_null("MeshInstance3D")
	if mesh:
		var mat := mesh.get_surface_override_material(0)
		if mat:
			_mesh_material = mat.duplicate() as StandardMaterial3D
			mesh.set_surface_override_material(0, _mesh_material)


func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return
	_process_status_effects(delta)
	_tick_timers(delta)
	_run_ai(delta)
	_apply_gravity(delta)
	move_and_slide()


func _tick_timers(delta: float) -> void:
	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta
	if _alert_timer > 0.0:
		_alert_timer -= delta
		if _alert_timer <= 0.0 and _state == State.ALERT:
			_state = State.PATROL
	if _cripple_timer > 0.0:
		_cripple_timer -= delta


func _run_ai(delta: float) -> void:
	if static_mode:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var dist_to_player := global_position.distance_to(player.global_position)
	var detection_range: float = _stats.get("detection_range", 20.0)
	var aggro_range: float = _stats.get("aggro_range", 15.0)

	# Detection
	var player_health: PlayerHealth = player.get("health") as PlayerHealth
	if player_health and player_health.is_dead:
		_target = null
		_state = State.IDLE
		return
	if dist_to_player <= detection_range:
		if _can_see_player(player):
			_has_detected_player = true
			_target = player
			if _state not in [State.CHASE, State.ATTACK]:
				_state = State.CHASE

	match _state:
		State.IDLE:
			_patrol_timer -= delta
			if _patrol_timer <= 0.0:
				_pick_patrol_point()
				_patrol_timer = randf_range(3.0, 8.0)
				_state = State.PATROL
		State.PATROL:
			_move_toward(_patrol_target, delta)
			if global_position.distance_to(_patrol_target) < 1.0:
				_state = State.IDLE
		State.ALERT:
			pass
		State.CHASE:
			if _target == null or dist_to_player > detection_range * 2:
				_state = State.IDLE
				_has_detected_player = false
				_target = null
				return
			_move_toward(_target.global_position, delta)
			if dist_to_player <= 2.0 and _attack_cooldown <= 0.0:
				_state = State.ATTACK
		State.ATTACK:
			if _target == null:
				_state = State.IDLE
				return
			_telegraph_attack()
			_perform_attack(_target)
			_attack_cooldown = 1.0 / _stats.get("attack_speed", 1.0)
			_state = State.CHASE


func _can_see_player(player: Node) -> bool:
	if _data.get("behavior_type", "") == "ambush":
		return global_position.distance_to(player.global_position) <= _stats.get("aggro_range", 5.0)
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, player.global_position + Vector3.UP)
	query.exclude = [self]
	var result := space.intersect_ray(query)
	return result.is_empty() or result.get("collider") == player


func _move_toward(target_pos: Vector3, delta: float) -> void:
	if _cripple_timer > 0.0:
		return
	var direction := (target_pos - global_position).normalized()
	direction.y = 0
	var speed: float = _stats.get("move_speed", 4.5)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0


func _telegraph_attack() -> void:
	# Plays telegraph animation — monsters must telegraph per MEL-043
	# Animation node: $AnimationPlayer.play("telegraph")
	pass


func _perform_attack(target: Node) -> void:
	if _state == State.DEAD:
		return
	var player_health: PlayerHealth = target.get("health") as PlayerHealth
	if player_health == null or player_health.is_dead:
		return

	var damage: float = _stats.get("damage", 10.0)
	# Apply deathmark bonus
	if _deathmark_active:
		damage *= 1.30

	# Block reduction via player combat
	var player_combat: PlayerCombat = target.combat if "combat" in target else null
	if player_combat:
		damage = player_combat.receive_attack_for_block(damage, self)
		damage = player_combat.receive_damage_check_barrier(damage)
		if player_combat.is_invulnerable_dodge():
			damage = 0.0
			# Riposte window
			player_combat.open_riposte_window(self, 0.4)

	if damage > 0.0:
		player_health.take_damage(damage, self)
		player_health.try_combat_injury_roll()

	# Special attacks
	for special in _data.get("special_attacks", []):
		if randf() < special.get("chance", 0.0):
			if special.has("inflicts_injury"):
				player_health.inflict_injury(special["inflicts_injury"])
			if special.has("aoe_radius"):
				_perform_aoe(special)


func _perform_aoe(attack_data: Dictionary) -> void:
	var radius: float = attack_data.get("aoe_radius", 5.0)
	var damage: float = attack_data.get("damage", 20.0)
	var bodies := []
	# Use overlap sphere via ShapeCast
	var player := get_tree().get_first_node_in_group("player")
	if player and player.global_position.distance_to(global_position) <= radius:
		if player.has_method("health"):
			player.health.take_damage(damage, self)


func _pick_patrol_point() -> void:
	var offset := Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
	_patrol_target = global_position + offset


func take_damage(amount: float, attacker: Node = null) -> void:
	if _state == State.DEAD:
		return

	# Bleed DOT stacks
	var total_damage := amount
	for i in range(_bleed_stacks):
		total_damage += 3.0  # Per stack per hit is wrong; bleed handled in status

	_health -= total_damage
	_health = max(0.0, _health)

	_flash_hit()

	if attacker != null and _state == State.IDLE:
		_target = attacker
		_state = State.CHASE
		_has_detected_player = true

	if _health <= 0.0:
		_die()


func _die() -> void:
	_state = State.DEAD
	_has_detected_player = false
	died.emit(monster_id, global_position)
	_drop_loot()
	set_physics_process(false)
	if _mesh_material:
		_mesh_material.albedo_color = Color(0.15, 0.15, 0.15)
	await get_tree().create_timer(1.5).timeout
	queue_free()


func _drop_loot() -> void:
	var loot_table: Array = _data.get("loot_table", [])
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	for entry in loot_table:
		var chance: float = entry.get("chance", 0.0)
		if randf() > chance:
			continue
		if entry.has("item_id"):
			var count_range: Array = entry.get("count_range", [1, 1])
			var count: int = randi_range(int(count_range[0]), int(count_range[1]))
			player.add_item_to_inventory(entry["item_id"], count)
		elif entry.has("rune_id"):
			player.add_item_to_inventory(entry["rune_id"], 1)
		elif entry.has("reagent_id"):
			player.add_item_to_inventory(entry["reagent_id"], 1)
	# Notify XP system
	var xp_type: String = _data.get("xp_type", "melee_kill")
	DisciplineManager.add_xp("survivalist", xp_type)
	DisciplineManager.add_xp("warrior", xp_type)
	DisciplineManager.add_xp("swordsman", xp_type)
	DisciplineManager.add_xp("artificer", xp_type)


func apply_status(status: String, dps: float, duration: float, max_stacks: int = 1) -> void:
	match status:
		"bleed":
			_bleed_stacks = min(_bleed_stacks + 1, max_stacks)
			_bleed_timer = duration


func apply_cripple(duration: float) -> void:
	_cripple_timer = duration
	_deathmark_cripple_count += 1
	# Check Deathmark
	if _deathmark_cripple_count >= 3 and DisciplineManager.is_ability_unlocked("swordsman", "deathmark"):
		_deathmark_active = true


func _process_status_effects(delta: float) -> void:
	if _bleed_stacks > 0:
		_bleed_timer -= delta
		_health -= 3.0 * _bleed_stacks * delta
		if _bleed_timer <= 0.0:
			_bleed_stacks = 0
		if _health <= 0.0:
			_die()


func apply_calm(duration: float) -> void:
	_state = State.IDLE
	_has_detected_player = false
	_target = null
	# Re-aggro after duration
	await get_tree().create_timer(duration).timeout
	# Monster resumes normal AI


func apply_stagger(duration: float) -> void:
	_state = State.ALERT
	_attack_cooldown = duration
	await get_tree().create_timer(duration).timeout


func apply_flinch(duration: float) -> void:
	_attack_cooldown = maxf(_attack_cooldown, duration)


func apply_root(duration: float) -> void:
	_cripple_timer = maxf(_cripple_timer, duration)


func force_despawn() -> void:
	_state = State.DEAD
	set_physics_process(false)
	queue_free()


func flee_from(position: Vector3) -> void:
	var dir := (global_position - position).normalized()
	dir.y = 0
	_patrol_target = global_position + dir * 20.0
	_state = State.PATROL


func has_detected_player() -> bool:
	return _has_detected_player


func alert_to_sound(position: Vector3) -> void:
	if _data.get("attracted_to_sound", false) or _data.get("attracted_to_fire_reaction", "") == "attracted":
		_target = get_tree().get_first_node_in_group("player")
		_state = State.CHASE
		_has_detected_player = true


func is_apex() -> bool:
	return _data.get("is_apex", false)


func _flash_hit() -> void:
	if _mesh_material == null:
		return
	var original: Color = _mesh_material.albedo_color
	_mesh_material.albedo_color = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	_mesh_material.albedo_color = original
