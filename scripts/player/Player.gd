## Player
## Root script for the player character. Coordinates all player subsystems.
extends CharacterBody3D

const INTERACTION_DISTANCE := 2.5
const ZOOM_MIN := 1.5
const ZOOM_MAX := 8.0
const ZOOM_STEP := 0.4

@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var character_model: Node3D = $CharacterModel
@onready var weapon_holder: Node3D = $WeaponHolder
@onready var movement: PlayerMovement = $PlayerMovement
@onready var health: PlayerHealth = $PlayerHealth
@onready var survival: PlayerSurvival = $PlayerSurvival
@onready var inventory: PlayerInventory = $PlayerInventory
@onready var combat: PlayerCombat = $PlayerCombat
@onready var interaction_ray: RayCast3D = $CameraPivot/SpringArm3D/Camera3D/InteractionRay
@onready var ability_system: AbilitySystem = $AbilitySystem
@onready var camp_deployer: CampDeployer = $CampDeployer
@onready var surveying_tool: SurveyingTool = $SurveyingTool

# Mouse sensitivity
var mouse_sensitivity: float = 0.002
# Keyboard look speed (radians per second)
const KEY_TURN_SPEED := 1.8


func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	interaction_ray.add_exception(self)
	_give_starting_items()
	health.player_died.connect(_on_player_died)
	inventory.inventory_changed.connect(_update_weapon_display)
	_update_weapon_display()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not GameState.is_paused_for_ui:
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-60), deg_to_rad(20))

	if event is InputEventMouseButton and not GameState.is_paused_for_ui:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_adjust_zoom(-ZOOM_STEP)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_adjust_zoom(ZOOM_STEP)

	# UI toggles work in both directions regardless of paused state
	if event.is_action_pressed("inventory"):
		_toggle_inventory()
		return
	if event.is_action_pressed("journal"):
		_toggle_journal()
		return
	if event.is_action_pressed("disciplines"):
		_toggle_disciplines()
		return
	if event.is_action_pressed("map"):
		_toggle_map()
		return

	if GameState.is_paused_for_ui:
		return

	if event.is_action_pressed("interact"):
		_try_interact()

	if event.is_action_pressed("sleep"):
		_try_sleep()

	if event.is_action_pressed("plant_flag"):
		_try_plant_flag()

	if event.is_action_pressed("scan"):
		_perform_scan()

	if event.is_action_pressed("weapon_swap"):
		inventory.swap_weapon_slot()
		_update_weapon_display()


func _process(delta: float) -> void:
	if GameState.is_paused_for_ui or GameState.is_sleeping:
		return
	var turn := Input.get_axis("turn_left", "turn_right")
	var look := Input.get_axis("look_up", "look_down")
	if turn != 0.0:
		camera_pivot.rotate_y(-turn * KEY_TURN_SPEED * delta)
	if look != 0.0:
		spring_arm.rotate_x(-look * KEY_TURN_SPEED * delta)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-60), deg_to_rad(20))
	# Keep weapon aligned with character body (not camera)
	weapon_holder.rotation.y = character_model.rotation.y


func _try_interact() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if not interaction_ray.is_colliding():
		if hud: hud.show_message("interact: no collision", 2.0)
		return
	var collider := interaction_ray.get_collider()
	if collider == null:
		if hud: hud.show_message("interact: collider null", 2.0)
		return
	var dist := global_position.distance_to(interaction_ray.get_collision_point())
	if dist > INTERACTION_DISTANCE:
		if hud: hud.show_message("interact: too far (%.1f)" % dist, 2.0)
		return
	var target: Node = collider if collider.has_method("interact") else collider.get_parent()
	if target and target.has_method("interact"):
		if hud: hud.show_message("interact: calling %s" % target.name, 2.0)
		target.interact(self)
	else:
		if hud: hud.show_message("interact: no interact on %s" % collider.name, 2.0)


func _toggle_inventory() -> void:
	var ui := get_tree().get_first_node_in_group("inventory_ui")
	if ui and ui.has_method("toggle"):
		ui.toggle()
		_set_ui_mouse_mode(ui.visible)


func _toggle_journal() -> void:
	var ui := get_tree().get_first_node_in_group("journal_ui")
	if ui and ui.has_method("toggle"):
		ui.toggle()
		_set_ui_mouse_mode(ui.visible)


func _toggle_disciplines() -> void:
	var ui := get_tree().get_first_node_in_group("discipline_ui")
	if ui and ui.has_method("toggle"):
		ui.toggle()
		_set_ui_mouse_mode(ui.visible)


func _toggle_map() -> void:
	if not inventory.has_item("map_item"):
		return
	var ui := get_tree().get_first_node_in_group("map_ui")
	if ui and ui.has_method("toggle"):
		ui.toggle()
		_set_ui_mouse_mode(ui.visible)


func _set_ui_mouse_mode(ui_open: bool) -> void:
	if ui_open:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		GameState.is_paused_for_ui = true
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		GameState.is_paused_for_ui = false


func _try_sleep() -> void:
	# Check: must be in settlement or have tent at camp
	var in_settlement := _is_near_settlement()
	var has_tent := inventory.has_item("tent")
	var at_camp := get_tree().get_first_node_in_group("player_camp") != null

	if not in_settlement and not (has_tent and at_camp):
		# Push UI message: cannot sleep here
		return

	_do_sleep()


func _do_sleep() -> void:
	# BatchProcessor.run_sleep_batch() manages GameState.is_sleeping internally.
	# survival and health steps are handled by the batch (steps 11–13).
	await BatchProcessor.run_sleep_batch()


func _try_plant_flag() -> void:
	if not inventory.has_item("settlement_flag"):
		return
	var area_id := GameState.current_area_id
	if area_id == "" or SettlementManager.settlements.has("settlement_" + area_id):
		return
	# Show resource summary UI and confirm
	var resources := WorldManager.get_area_resources(area_id)
	inventory.remove_item("settlement_flag", 1)
	# Flag is planted; player must return to purchasing settlement to report
	var ui := get_tree().get_first_node_in_group("flag_confirm_ui")
	if ui and ui.has_method("show_flag_planted"):
		ui.show_flag_planted(area_id, resources)


func _is_near_settlement() -> bool:
	for sid in SettlementManager.settlements:
		var s: SettlementManager.SettlementData = SettlementManager.settlements[sid]
		if global_position.distance_to(s.position) < 50.0:
			return true
	return false


func in_settlement() -> bool:
	return _is_near_settlement()


const _FT := "res://assets/models/kenney_fantasy-town-kit/Models/GLB format/"
const _RM := "res://assets/models/kenney_retro-medieval-kit/Models/GLB format/"

# Native GLB sizes (measured):
#   blade.glb          X=0.111  Y=2.000  Z=0.430  (upright — Y is blade length)
#   planks-half.glb    X=0.500  Y=0.060  Z=1.000  (flat — rotate 90°X to stand up)
#   planks.glb         X=1.000  Y=0.060  Z=1.000  (flat — rotate 90°X to stand up)
#   column-wood.glb    X=0.300  Y=1.000  Z=0.300  (upright column)
#   structure-pole.glb X=0.100  Y=1.000  Z=0.100  (single thin pole, upright)
#   poles-horizontal   X=0.100  Y=1.000  Z=1.000  (use Z as barrel axis)
#
# planks rot(90,0,0) remaps: world-Y = native-Z, world-Z = native-Y (thin)
# Scale is applied before rotation in Godot, so scale against native axes.

const WEAPON_MESH_CONFIG := {
	# blade.glb — scale Y for length, X for width, Z ultra-thin
	"hunting_knife":   { "mesh": "blade.glb",            "pack": "FT", "scale": Vector3(0.18, 0.125, 0.012), "rot": Vector3.ZERO },
	"shortsword":      { "mesh": "blade.glb",            "pack": "FT", "scale": Vector3(0.23, 0.300, 0.014), "rot": Vector3.ZERO },
	"arming_sword":    { "mesh": "blade.glb",            "pack": "FT", "scale": Vector3(0.27, 0.430, 0.016), "rot": Vector3.ZERO },
	"cavalry_saber":   { "mesh": "blade.glb",            "pack": "FT", "scale": Vector3(0.32, 0.450, 0.016), "rot": Vector3.ZERO },
	"greatsword":      { "mesh": "blade.glb",            "pack": "FT", "scale": Vector3(0.36, 0.600, 0.018), "rot": Vector3.ZERO },
	"zweihander":      { "mesh": "blade.glb",            "pack": "FT", "scale": Vector3(0.40, 0.750, 0.020), "rot": Vector3.ZERO },
	# planks-half rot90X → world: X=native-X*s, Y=native-Z*s, Z=native-Y*s (6cm thin)
	# axe head ~30cm wide × 40cm tall × 6cm deep
	"woodcutters_axe": { "mesh": "planks-half.glb",      "pack": "FT", "scale": Vector3(0.60, 1.00, 0.40),  "rot": Vector3(90, 0, 0) },
	# pistol block ~15cm wide × 25cm tall × 6cm deep
	"pistol":          { "mesh": "planks-half.glb",      "pack": "FT", "scale": Vector3(0.30, 1.00, 0.25),  "rot": Vector3(90, 0, 0) },
	# buckler ~40cm × 40cm × 6cm
	"buckler":         { "mesh": "planks-half.glb",      "pack": "FT", "scale": Vector3(0.80, 1.00, 0.40),  "rot": Vector3(90, 0, 0) },
	# column-wood — scale Y for handle length, X/Z for head girth
	"warhammer":       { "mesh": "column-wood.glb",      "pack": "RM", "scale": Vector3(0.50, 0.55, 0.50),  "rot": Vector3.ZERO },
	# structure-pole — single thin pole, perfect for bows
	"hunting_bow":     { "mesh": "structure-pole.glb",   "pack": "RM", "scale": Vector3(0.40, 1.20, 0.40),  "rot": Vector3.ZERO },
	"longbow":         { "mesh": "structure-pole.glb",   "pack": "RM", "scale": Vector3(0.40, 1.50, 0.40),  "rot": Vector3.ZERO },
	# poles-horizontal — use Z as barrel axis, squash Y to barrel height
	"musket":          { "mesh": "poles-horizontal.glb", "pack": "FT", "scale": Vector3(0.40, 0.06, 1.20),  "rot": Vector3.ZERO },
	# planks rot90X → kite shield ~45cm wide × 70cm tall × 6cm deep
	"kite_shield":     { "mesh": "planks.glb",           "pack": "FT", "scale": Vector3(0.45, 1.00, 0.70),  "rot": Vector3(90, 0, 0) },
}


func _update_weapon_display() -> void:
	for child in weapon_holder.get_children():
		child.queue_free()

	var active: Dictionary = inventory.get_active_weapon()
	if active.is_empty():
		weapon_holder.visible = false
		return

	var weapon_id: String = active.get("item_id", "")
	var cfg: Dictionary = WEAPON_MESH_CONFIG.get(weapon_id, {})
	if cfg.is_empty():
		weapon_holder.visible = false
		return

	var base_path: String = _FT if cfg["pack"] == "FT" else _RM
	var packed: PackedScene = load(base_path + cfg["mesh"])
	if packed == null:
		weapon_holder.visible = false
		return

	var mesh_instance: Node3D = packed.instantiate()
	mesh_instance.scale = cfg["scale"]
	mesh_instance.rotation_degrees = cfg["rot"]
	weapon_holder.add_child(mesh_instance)
	weapon_holder.visible = true


func _give_starting_items() -> void:
	inventory.add_item("compass", 1)
	inventory.add_item("field_journal", 1)
	inventory.add_item("hardtack", 5)
	inventory.add_item("waterskin", 1)
	inventory.add_item("bandage", 3)
	inventory.add_item("zweihander", 1)
	inventory.add_item("hunting_knife", 1)
	inventory.equip_to_weapon_slot("zweihander", 0)
	inventory.equip_to_weapon_slot("hunting_knife", 1)


func add_item_to_inventory(item_id: String, count: int) -> void:
	inventory.add_item(item_id, count)


func spend_gold(amount: int) -> bool:
	if inventory.currency < amount:
		return false
	inventory.currency -= amount
	return true


## Raycast scan for journal entries (LNAV-040..044).
## Hits objects in the "scannable" group and records them in the field journal.
func _perform_scan() -> void:
	var space := get_world_3d().direct_space_state
	var origin := camera.global_position
	var end := origin + (-camera.global_transform.basis.z * 30.0)
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [self]
	var result := space.intersect_ray(query)
	if result.is_empty():
		return
	var collider: Variant = result.get("collider")
	if collider == null or not collider.is_in_group("scannable"):
		return
	var journal_node := get_node_or_null("FieldJournal")
	if journal_node == null:
		journal_node = get_tree().get_first_node_in_group("field_journal")
	if journal_node == null:
		return
	# Determine category and record
	if collider.is_in_group("monster"):
		journal_node.record_creature(collider.monster_id)
	elif collider.is_in_group("resource_node") and collider.has_method("get"):
		journal_node.record_ingredient(collider.resource_id)
	elif collider.is_in_group("landmark"):
		collider.interact(self)  # Landmark naming UI
	# Visual + audio feedback (LNAV-043)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_message"):
		hud.show_message("Scanned.")
	AudioManager.play_sfx("scan_beep")


func _on_player_died() -> void:
	# Cancel founding if pending (LFOUND-011)
	FoundingManager.cancel_founding()
	# Destroy any planted flags
	var flags := get_tree().get_nodes_in_group("settlement_flag")
	for flag in flags:
		if flag.has_method("destroy_on_player_death"):
			flag.destroy_on_player_death()
	# Show death UI
	var death_ui := get_tree().get_first_node_in_group("death_ui")
	if death_ui and death_ui.has_method("show_death"):
		death_ui.show_death()
	else:
		var ui := get_tree().get_first_node_in_group("hud")
		if ui and ui.has_method("show_message"):
			ui.show_message("You have fallen.")


func get_save_data() -> Dictionary:
	return {
		"position": { "x": global_position.x, "y": global_position.y, "z": global_position.z },
		"rotation_y": rotation.y,
		"health": health.get_save_data(),
		"survival": survival.get_save_data(),
		"inventory": inventory.get_save_data(),
		"combat": combat.get_save_data()
	}


func apply_save_data(data: Dictionary) -> void:
	var pos: Dictionary = data.get("position", {})
	global_position = Vector3(pos.get("x", 0), pos.get("y", 0), pos.get("z", 0))
	rotation.y = data.get("rotation_y", 0.0)
	health.apply_save_data(data.get("health", {}))
	survival.apply_save_data(data.get("survival", {}))
	inventory.apply_save_data(data.get("inventory", {}))
	combat.apply_save_data(data.get("combat", {}))


func _adjust_zoom(delta: float) -> void:
	spring_arm.spring_length = clamp(spring_arm.spring_length + delta, ZOOM_MIN, ZOOM_MAX)
	interaction_ray.target_position.z = -(spring_arm.spring_length + INTERACTION_DISTANCE)
