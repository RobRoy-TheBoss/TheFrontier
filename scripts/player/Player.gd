## Player
## Root script for the player character. Coordinates all player subsystems.
extends CharacterBody3D

const INTERACTION_DISTANCE := 2.5

@onready var camera: Camera3D = $Head/Camera3D
@onready var head: Node3D = $Head
@onready var movement: PlayerMovement = $PlayerMovement
@onready var health: PlayerHealth = $PlayerHealth
@onready var survival: PlayerSurvival = $PlayerSurvival
@onready var inventory: PlayerInventory = $PlayerInventory
@onready var combat: PlayerCombat = $PlayerCombat
@onready var interaction_ray: RayCast3D = $Head/Camera3D/InteractionRay
@onready var ability_system: AbilitySystem = $AbilitySystem
@onready var camp_deployer: CampDeployer = $CampDeployer
@onready var surveying_tool: SurveyingTool = $SurveyingTool

# Mouse sensitivity
var mouse_sensitivity: float = 0.002


func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_give_starting_items()
	health.player_died.connect(_on_player_died)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85), deg_to_rad(85))

	if event.is_action_pressed("interact"):
		_try_interact()

	if event.is_action_pressed("inventory"):
		_toggle_inventory()

	if event.is_action_pressed("journal"):
		_toggle_journal()

	if event.is_action_pressed("map"):
		_toggle_map()

	if event.is_action_pressed("sleep"):
		_try_sleep()

	if event.is_action_pressed("plant_flag"):
		_try_plant_flag()

	if event.is_action_pressed("disciplines"):
		_toggle_disciplines()

	if event.is_action_pressed("scan"):
		_perform_scan()


func _process(delta: float) -> void:
	pass


func _try_interact() -> void:
	if not interaction_ray.is_colliding():
		return
	var collider := interaction_ray.get_collider()
	if collider == null:
		return
	var dist := global_position.distance_to(interaction_ray.get_collision_point())
	if dist > INTERACTION_DISTANCE:
		return
	if collider.has_method("interact"):
		collider.interact(self)


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


func _give_starting_items() -> void:
	inventory.add_item("compass", 1)
	inventory.add_item("field_journal", 1)
	inventory.add_item("hardtack", 5)
	inventory.add_item("waterskin", 1)
	inventory.add_item("hunting_knife", 1)
	inventory.add_item("bandage", 3)


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
	var collider := result.get("collider")
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
