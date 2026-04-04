## Monster
## Base class for all monsters. Reads stats from GameData, handles AI states,
## combat, loot, and XP trigger reporting.
extends CharacterBody3D

enum State { IDLE, PATROL, ALERT, CHASE, WINDUP, ATTACK, RECOVER, SEEK_LAND, SEEK_WATER, FLEE, DESPAWN, DEAD }

@export var monster_id: String = "prowler"
@export var static_mode: bool = false  # If true: no AI, no movement, no attacks

var _data: Dictionary = {}
var _stats: Dictionary = {}
var _state: State = State.IDLE
var _target: Node = null
var _health: float = 0.0
var _max_health: float = 0.0
var _alert_timer: float = 0.0
var _attack_cooldown: float = 0.0   # global stagger/flinch blocker
var _attack_cooldowns: Dictionary = {}  # attack name → remaining cooldown
var _current_attack: Dictionary = {}    # attack selected at windup start
var _windup_timer: float = 0.0
var _recovery_timer: float = 0.0
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
var _mesh_albedo_original: Color = Color.WHITE
var _ind_fill_node: MeshInstance3D = null
var _ind_edge_node: MeshInstance3D = null
var _ind_fill_axis: String = "xz"  # "xz" = radius/arc/circle, "x" = line

const GRAVITY := 9.8
const DEFAULT_WINDUP := 0.6
const WATER_LEVEL := 8.5           # must match HexAssetScatterer.WATER_LEVEL
const SEEK_LAND_MARGIN := 2.0      # terrestrial: must be this far above water
const AMPHIBIOUS_PATROL_ABOVE := 5.0  # amphibious: patrol up to this many metres above waterline

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
	var facing_label := get_node_or_null("FacingLabel") as Label3D
	if facing_label:
		facing_label.text = ">:("
		var lo: Array = _data.get("label_offset", [])
		if lo.size() == 3:
			facing_label.position = Vector3(float(lo[0]), float(lo[1]), float(lo[2]))
		var lr: Array = _data.get("label_rotation_deg", [])
		if lr.size() == 3:
			facing_label.rotation_degrees = Vector3(float(lr[0]), float(lr[1]), float(lr[2]))
	var name_label := get_node_or_null("NameLabel") as Label3D
	if name_label:
		name_label.text = _data.get("name", monster_id)
	var mesh: MeshInstance3D = get_node_or_null("MeshInstance3D")
	if mesh:
		# Swap mesh geometry if specified in data
		var mesh_type: String = _data.get("mesh_type", "")
		match mesh_type:
			"cylinder":
				var cyl := CylinderMesh.new()
				cyl.top_radius    = float(_data.get("mesh_radius", 0.5))
				cyl.bottom_radius = cyl.top_radius
				cyl.height        = float(_data.get("mesh_height", 1.0))
				mesh.mesh = cyl
		var rot: Array = _data.get("mesh_rotation_deg", [])
		if rot.size() == 3:
			mesh.rotation_degrees = Vector3(float(rot[0]), float(rot[1]), float(rot[2]))
		var mpos: Array = _data.get("mesh_position", [])
		if mpos.size() == 3:
			mesh.position = Vector3(float(mpos[0]), float(mpos[1]), float(mpos[2]))
		# Build material — use mesh_color if provided, else fall back to scene default
		var mc: Array = _data.get("mesh_color", [])
		if mc.size() >= 3:
			_mesh_material = StandardMaterial3D.new()
			_mesh_material.albedo_color = Color(float(mc[0]), float(mc[1]), float(mc[2]),
					float(mc[3]) if mc.size() >= 4 else 1.0)
			mesh.set_surface_override_material(0, _mesh_material)
		else:
			var mat := mesh.get_surface_override_material(0)
			if mat:
				_mesh_material = mat.duplicate() as StandardMaterial3D
				mesh.set_surface_override_material(0, _mesh_material)
		if _mesh_material:
			_mesh_albedo_original = _mesh_material.albedo_color


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
	if _windup_timer > 0.0:
		_windup_timer -= delta
		_update_telegraph_visual()
		if _windup_timer <= 0.0:
			_finish_windup()
	if _recovery_timer > 0.0:
		_recovery_timer -= delta
		if _recovery_timer <= 0.0 and _state == State.RECOVER:
			_state = State.CHASE
	for atk_name in _attack_cooldowns:
		_attack_cooldowns[atk_name] = maxf(0.0, _attack_cooldowns[atk_name] - delta)


func _run_ai(delta: float) -> void:
	if static_mode:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var dist_to_player := global_position.distance_to(player.global_position)
	var detection_range: float = _stats.get("detection_range", 20.0)
	var aggro_range: float = _stats.get("aggro_range", 15.0)

	# Territory overrides
	var territory: String = _data.get("territory", "")
	var in_combat := _state in [State.CHASE, State.WINDUP, State.ATTACK, State.RECOVER]
	match territory:
		"terrestrial":
			# At full health: never enter water. Damaged: chase freely into water.
			var at_full_health: bool = _health >= _max_health
			if (at_full_health or not in_combat) and global_position.y < WATER_LEVEL + SEEK_LAND_MARGIN:
				_state = State.SEEK_LAND
				_seek_land(delta)
				return
		"aquatic":
			# Never leaves water, even when provoked
			if global_position.y > WATER_LEVEL:
				_state = State.SEEK_WATER
				_seek_water(delta)
				return
		"amphibious":
			# Chases freely on land when provoked; returns to waterline when idle
			if not in_combat and global_position.y > WATER_LEVEL + AMPHIBIOUS_PATROL_ABOVE:
				_state = State.SEEK_WATER
				_seek_water(delta)
				return

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
			if _state not in [State.CHASE, State.WINDUP, State.ATTACK, State.RECOVER]:
				# Terrestrial at full health won't initiate on a player in water
				var player_in_water: bool = player.global_position.y <= WATER_LEVEL
				var at_full_health: bool = _health >= _max_health
				if not (territory == "terrestrial" and player_in_water and at_full_health):
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
			if _attack_cooldown <= 0.0:
				var atk := _pick_attack(dist_to_player)
				if not atk.is_empty():
					_current_attack = atk
					_state = State.WINDUP
					_windup_timer = atk.get("windup_duration", DEFAULT_WINDUP)
					# Lock facing at windup start — won't track player during telegraph
					var dir: Vector3 = _target.global_position - global_position
					dir.y = 0.0
					if dir.length() > 0.01:
						look_at(global_position + dir.normalized(), Vector3.UP)
					_start_telegraph_visual()
		State.WINDUP:
			# Freeze movement and facing — committed to the attack angle
			velocity.x = 0.0
			velocity.z = 0.0
		State.ATTACK:
			pass  # Handled in _finish_windup
		State.RECOVER:
			# Post-attack freeze — can't move or start new attacks
			velocity.x = 0.0
			velocity.z = 0.0


func _can_see_player(player: Node) -> bool:
	if _data.get("behavior_type", "") == "ambush":
		return global_position.distance_to(player.global_position) <= _stats.get("aggro_range", 5.0)
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, player.global_position + Vector3.UP)
	query.exclude = [self]
	var result := space.intersect_ray(query)
	return result.is_empty() or result.get("collider") == player


func _seek_land(delta: float) -> void:
	# Sample terrain height in 8 directions and move toward the highest one.
	var space := get_world_3d().direct_space_state
	var best_dir := Vector3.ZERO
	var best_y := -INF
	var probe_dist := 8.0
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var dir := Vector3(sin(angle), 0.0, cos(angle))
		var probe_xz := global_position + dir * probe_dist
		var ray := PhysicsRayQueryParameters3D.create(
			Vector3(probe_xz.x, global_position.y + 60.0, probe_xz.z),
			Vector3(probe_xz.x, global_position.y - 20.0, probe_xz.z)
		)
		ray.collision_mask = 1
		ray.exclude = [self]
		var hit := space.intersect_ray(ray)
		var terrain_y: float = hit["position"].y if not hit.is_empty() else global_position.y
		if terrain_y > best_y:
			best_y = terrain_y
			best_dir = dir
	if best_dir != Vector3.ZERO:
		_move_toward(global_position + best_dir, delta)
	# Exit SEEK_LAND once safely above waterline
	if global_position.y >= WATER_LEVEL + SEEK_LAND_MARGIN:
		_state = State.IDLE


func _seek_water(delta: float) -> void:
	# Sample terrain height in 8 directions and move toward the lowest — toward water.
	var space := get_world_3d().direct_space_state
	var best_dir := Vector3.ZERO
	var best_y := INF
	var probe_dist := 8.0
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var dir := Vector3(sin(angle), 0.0, cos(angle))
		var probe_xz := global_position + dir * probe_dist
		var ray := PhysicsRayQueryParameters3D.create(
			Vector3(probe_xz.x, global_position.y + 60.0, probe_xz.z),
			Vector3(probe_xz.x, global_position.y - 20.0, probe_xz.z)
		)
		ray.collision_mask = 1
		ray.exclude = [self]
		var hit := space.intersect_ray(ray)
		var terrain_y: float = hit["position"].y if not hit.is_empty() else global_position.y
		if terrain_y < best_y:
			best_y = terrain_y
			best_dir = dir
	if best_dir != Vector3.ZERO:
		_move_toward(global_position + best_dir, delta)
	# Aquatic: exit when back in water. Amphibious: exit when within patrol zone.
	var territory: String = _data.get("territory", "")
	var at_water := global_position.y <= WATER_LEVEL
	var in_patrol_zone := global_position.y <= WATER_LEVEL + AMPHIBIOUS_PATROL_ABOVE
	if (territory == "aquatic" and at_water) or (territory == "amphibious" and in_patrol_zone):
		_state = State.IDLE


func _move_toward(target_pos: Vector3, delta: float) -> void:
	if _cripple_timer > 0.0:
		return
	var direction := (target_pos - global_position)
	direction.y = 0
	var dir_len := direction.length()
	if dir_len < 0.01:
		return
	direction = direction / dir_len
	var speed: float = _stats.get("move_speed", 4.5)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	look_at(global_position + direction, Vector3.UP)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0


func _start_telegraph_visual() -> void:
	_show_attack_indicator()


func _update_telegraph_visual() -> void:
	if _windup_timer <= 0.0 or _ind_fill_node == null:
		return
	var duration: float = _current_attack.get("windup_duration", DEFAULT_WINDUP)
	var t := clampf(1.0 - (_windup_timer / duration), 0.001, 1.0)
	if _ind_fill_axis == "x":
		_ind_fill_node.scale = Vector3(t, 1.0, 1.0)
	else:
		_ind_fill_node.scale = Vector3(t, 1.0, t)


func _finish_windup() -> void:
	_hide_attack_indicator()
	if _mesh_material:
		_mesh_material.albedo_color = _mesh_albedo_original
	if _state == State.WINDUP:
		_state = State.ATTACK
		if _target != null:
			if _check_attack_shape(_target):
				_perform_attack(_target)
		var atk_name: String = _current_attack.get("name", "attack")
		var cd: float = _current_attack.get("cooldown", 1.0 / _stats.get("attack_speed", 1.0))
		_attack_cooldowns[atk_name] = cd
		var recovery: float = _data.get("recovery_time", 0.4)
		_recovery_timer = recovery
		_state = State.RECOVER


func _show_attack_indicator() -> void:
	_hide_attack_indicator()
	var shape: Dictionary = _current_attack.get("shape", {})
	var type: String = shape.get("type", "radius")
	_ind_fill_axis = "x" if type == "line" else "xz"

	var fill_mesh := _build_fill_mesh(shape)
	if fill_mesh == null:
		return

	var fill_mat := StandardMaterial3D.new()
	fill_mat.albedo_color = Color(0.85, 0.0, 0.0, 0.65)
	fill_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fill_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	fill_mat.no_depth_test = true
	fill_mat.render_priority = 1

	_ind_fill_node = MeshInstance3D.new()
	_ind_fill_node.mesh = fill_mesh
	_ind_fill_node.set_surface_override_material(0, fill_mat)
	_ind_fill_node.position = Vector3(0.0, 0.05, 0.0)
	if _ind_fill_axis == "x":
		_ind_fill_node.scale = Vector3(0.001, 1.0, 1.0)
	else:
		_ind_fill_node.scale = Vector3(0.001, 1.0, 0.001)
	add_child(_ind_fill_node)

	var edge_mesh := _build_edge_mesh(shape)
	if edge_mesh != null:
		var edge_mat := StandardMaterial3D.new()
		edge_mat.albedo_color = Color(1.0, 0.5, 0.0, 1.0)
		edge_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		edge_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		edge_mat.no_depth_test = true
		edge_mat.render_priority = 2

		_ind_edge_node = MeshInstance3D.new()
		_ind_edge_node.mesh = edge_mesh
		_ind_edge_node.set_surface_override_material(0, edge_mat)
		_ind_edge_node.position = Vector3(0.0, 0.07, 0.0)
		add_child(_ind_edge_node)


func _hide_attack_indicator() -> void:
	if _ind_fill_node != null:
		_ind_fill_node.queue_free()
		_ind_fill_node = null
	if _ind_edge_node != null:
		_ind_edge_node.queue_free()
		_ind_edge_node = null


# Adds a flat quad (two triangles) along a line segment, raised slightly above fill.
func _add_edge_quad(verts: PackedVector3Array, a: Vector3, b: Vector3, width: float) -> void:
	var dir := b - a
	dir.y = 0.0
	if dir.length() < 0.001:
		return
	dir = dir.normalized()
	var perp := Vector3(-dir.z, 0.0, dir.x) * (width * 0.5)
	var lift := Vector3(0.0, 0.02, 0.0)
	verts.append(a - perp + lift); verts.append(b - perp + lift); verts.append(b + perp + lift)
	verts.append(a - perp + lift); verts.append(b + perp + lift); verts.append(a + perp + lift)


func _build_fill_mesh(shape: Dictionary) -> ArrayMesh:
	const SEG := 32
	var type: String = shape.get("type", "radius")
	var fill := PackedVector3Array()

	match type:
		"arc":
			var r: float = shape.get("range", 2.5)
			var half := deg_to_rad(shape.get("half_angle_deg", 60.0))
			for i in range(SEG):
				var a0: float = lerp(-half, half, float(i) / SEG)
				var a1: float = lerp(-half, half, float(i + 1) / SEG)
				var p0 := Vector3(sin(a0) * r, 0.0, -cos(a0) * r)
				var p1 := Vector3(sin(a1) * r, 0.0, -cos(a1) * r)
				fill.append(Vector3.ZERO); fill.append(p0); fill.append(p1)
		"radius":
			var r: float = shape.get("range", 2.5)
			for i in range(SEG):
				var a0 := TAU * float(i) / SEG
				var a1 := TAU * float(i + 1) / SEG
				var p0 := Vector3(sin(a0) * r, 0.0, cos(a0) * r)
				var p1 := Vector3(sin(a1) * r, 0.0, cos(a1) * r)
				fill.append(Vector3.ZERO); fill.append(p0); fill.append(p1)
		"line":
			# Full-size rect centered on forward axis. Scale animates X (widens from center).
			var length: float = shape.get("length", 3.0)
			var hw: float = shape.get("width", 0.8) * 0.5
			var c := [Vector3(-hw, 0, 0), Vector3(hw, 0, 0), Vector3(hw, 0, -length), Vector3(-hw, 0, -length)]
			fill.append(c[0]); fill.append(c[1]); fill.append(c[2])
			fill.append(c[0]); fill.append(c[2]); fill.append(c[3])
		"circle":
			var r: float = shape.get("radius", 1.5)
			for i in range(SEG):
				var a0 := TAU * float(i) / SEG
				var a1 := TAU * float(i + 1) / SEG
				var p0 := Vector3(sin(a0) * r, 0.0, cos(a0) * r)
				var p1 := Vector3(sin(a1) * r, 0.0, cos(a1) * r)
				fill.append(Vector3.ZERO); fill.append(p0); fill.append(p1)

	if fill.is_empty():
		return null
	var arr := Array(); arr.resize(Mesh.ARRAY_MAX); arr[Mesh.ARRAY_VERTEX] = fill
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh


func _build_edge_mesh(shape: Dictionary) -> ArrayMesh:
	const SEG := 32
	const EW  := 0.08
	var type: String = shape.get("type", "radius")
	var edge := PackedVector3Array()

	match type:
		"arc":
			var r: float = shape.get("range", 2.5)
			var half := deg_to_rad(shape.get("half_angle_deg", 60.0))
			for i in range(SEG):
				var a0: float = lerp(-half, half, float(i) / SEG)
				var a1: float = lerp(-half, half, float(i + 1) / SEG)
				var p0 := Vector3(sin(a0) * r, 0.0, -cos(a0) * r)
				var p1 := Vector3(sin(a1) * r, 0.0, -cos(a1) * r)
				_add_edge_quad(edge, p0, p1, EW)
			_add_edge_quad(edge, Vector3.ZERO, Vector3(sin(-half) * r, 0.0, -cos(-half) * r), EW)
			_add_edge_quad(edge, Vector3.ZERO, Vector3(sin( half) * r, 0.0, -cos( half) * r), EW)
		"radius":
			var r: float = shape.get("range", 2.5)
			for i in range(SEG):
				var a0 := TAU * float(i) / SEG
				var a1 := TAU * float(i + 1) / SEG
				var p0 := Vector3(sin(a0) * r, 0.0, cos(a0) * r)
				var p1 := Vector3(sin(a1) * r, 0.0, cos(a1) * r)
				_add_edge_quad(edge, p0, p1, EW)
		"line":
			var length: float = shape.get("length", 3.0)
			var hw: float = shape.get("width", 0.8) * 0.5
			var c := [Vector3(-hw, 0, 0), Vector3(hw, 0, 0), Vector3(hw, 0, -length), Vector3(-hw, 0, -length)]
			for i in range(4):
				_add_edge_quad(edge, c[i], c[(i + 1) % 4], EW)
		"circle":
			var r: float = shape.get("radius", 1.5)
			for i in range(SEG):
				var a0 := TAU * float(i) / SEG
				var a1 := TAU * float(i + 1) / SEG
				var p0 := Vector3(sin(a0) * r, 0.0, cos(a0) * r)
				var p1 := Vector3(sin(a1) * r, 0.0, cos(a1) * r)
				_add_edge_quad(edge, p0, p1, EW)

	if edge.is_empty():
		return null
	var arr := Array(); arr.resize(Mesh.ARRAY_MAX); arr[Mesh.ARRAY_VERTEX] = edge
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh


func _pick_attack(dist: float) -> Dictionary:
	var available: Array = []
	for atk in _data.get("attacks", []):
		var shape: Dictionary = atk.get("shape", {})
		var atk_range: float = shape.get("range", shape.get("length", 2.5))
		if dist > atk_range:
			continue
		var atk_name: String = atk.get("name", "attack")
		if _attack_cooldowns.get(atk_name, 0.0) > 0.0:
			continue
		available.append(atk)
	if available.is_empty():
		return {}
	return available[randi() % available.size()]


func _check_attack_shape(target: Node) -> bool:
	var to_target: Vector3 = target.global_position - global_position
	to_target.y = 0.0
	var dist := to_target.length()
	var shape: Dictionary = _current_attack.get("shape", {})
	var type: String = shape.get("type", "radius")

	match type:
		"radius":
			return dist <= shape.get("range", 2.5)
		"arc":
			if dist > shape.get("range", 2.5):
				return false
			if dist < 0.01:
				return true
			var forward := -global_transform.basis.z
			forward.y = 0.0
			forward = forward.normalized()
			var half_angle := deg_to_rad(shape.get("half_angle_deg", 60.0))
			return forward.dot(to_target.normalized()) >= cos(half_angle)
		"line":
			var forward := -global_transform.basis.z
			forward.y = 0.0
			forward = forward.normalized()
			var fwd_dist := forward.dot(to_target)
			if fwd_dist < 0.0 or fwd_dist > shape.get("length", 3.0):
				return false
			return (to_target - forward * fwd_dist).length() <= shape.get("width", 0.8)
		"circle":
			# Pounce: circle centered at a world position set by the special attack
			var center: Vector3 = shape.get("center", global_position)
			return target.global_position.distance_to(center) <= shape.get("radius", 1.5)
	return false


func _perform_attack(target: Node) -> void:
	if _state == State.DEAD:
		return
	var player_health: PlayerHealth = target.get("health") as PlayerHealth
	if player_health == null or player_health.is_dead:
		return

	var damage: float = _stats.get("damage", 10.0)
	damage *= _current_attack.get("damage_multiplier", 1.0)
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
		player_health.try_combat_injury_roll(monster_id)

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
	var territory: String = _data.get("territory", "")
	if territory == "aquatic" or territory == "amphibious":
		_pick_patrol_point_near_water()
		return
	var offset := Vector3(randf_range(-40, 40), 0, randf_range(-40, 40))
	_patrol_target = global_position + offset


func _pick_patrol_point_near_water() -> void:
	# Find a patrol point where terrain sits within the waterline band.
	var territory: String = _data.get("territory", "")
	var min_y := WATER_LEVEL - 6.0
	var max_y := WATER_LEVEL + (0.0 if territory == "aquatic" else AMPHIBIOUS_PATROL_ABOVE)
	var space := get_world_3d().direct_space_state
	for _attempt in range(12):
		var offset := Vector3(randf_range(-40, 40), 0, randf_range(-40, 40))
		var probe_xz := global_position + offset
		var ray := PhysicsRayQueryParameters3D.create(
			Vector3(probe_xz.x, global_position.y + 80.0, probe_xz.z),
			Vector3(probe_xz.x, global_position.y - 30.0, probe_xz.z)
		)
		ray.collision_mask = 1
		ray.exclude = [self]
		var hit := space.intersect_ray(ray)
		if hit.is_empty():
			continue
		var terrain_y: float = hit["position"].y
		if terrain_y >= min_y and terrain_y <= max_y:
			_patrol_target = hit["position"] + Vector3(0.0, 0.1, 0.0)
			return
	# Fallback: stay near current position
	_patrol_target = global_position + Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))


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

	var provokable := _state in [State.IDLE, State.PATROL, State.SEEK_LAND, State.SEEK_WATER]
	if attacker != null and provokable:
		_target = attacker
		_state = State.CHASE
		_has_detected_player = true

	if _health <= 0.0:
		_die()


func _die() -> void:
	_hide_attack_indicator()
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
	_mesh_material.albedo_color = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	# Restore telegraph color if still winding up, otherwise restore base color
	if _state == State.WINDUP and _windup_timer > 0.0:
		_update_telegraph_visual()
	else:
		_mesh_material.albedo_color = _mesh_albedo_original
