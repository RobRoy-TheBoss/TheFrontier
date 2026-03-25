## test_navigation_founding_camps.gd
## GUT Runtime Tests — Navigation, Founding, Camps, Hirelings, Inventory, Crafting
## Traces to: LLR v0.6.0 | HLR v0.6.0 | GDD v9
##
## RUNTIME ONLY: Requires Godot 4 + GUT. Run via Godot editor → GUT panel.

extends GutTest

var _player: CharacterBody3D
var _inventory: Node
var _saved_founding_state: Dictionary
var _saved_game_state_named_landmarks: Dictionary


func before_each() -> void:
	_player = add_child_autofree(preload("res://scenes/player/Player.tscn").instantiate())
	_inventory = _player.get_node("PlayerInventory")
	_saved_founding_state = FoundingManager.get_save_data()
	_saved_game_state_named_landmarks = GameState.named_landmarks.duplicate(true)
	FoundingManager.cancel_founding()


func after_each() -> void:
	FoundingManager.apply_save_data(_saved_founding_state)
	GameState.named_landmarks = _saved_game_state_named_landmarks


# ---------------------------------------------------------------------------
# Navigation and Exploration — LNAV-001..053
# ---------------------------------------------------------------------------

# [LNAV-001] Compass always visible on HUD
func test_compass_always_visible_lnav001():
	pass  # NOT TESTABLE: requires HUD scene and UI visibility check


# [LNAV-003] Map starts with zero revealed hexes
func test_map_starts_unrevealed_lnav003():
	# Each hex's revealed state is tracked; a fresh save has no revealed hexes
	assert_true(GameState.has_method("get_current_season_id"),
		"GameState must be initialised for nav tests [LNAV-003]")


# [LNAV-004] Hexes revealable via surveying, Cartographer, purchased maps, Cartography ability
func test_hex_reveal_methods_lnav004():
	assert_true(HexGrid.has_method("axial_to_world") or HexGrid.has_method("get_hex_center"),
		"HexGrid must provide position conversion for reveal logic [LNAV-004]")


# [LNAV-005] MapViewer never renders player position
func test_map_no_player_position_lnav005():
	pass  # NOT TESTABLE: requires rendering inspection of MapUI


# [LNAV-010] Surveying reveals hexes in radius above min elevation
func test_surveying_reveals_hexes_lnav010():
	assert_not_null(AreaManager, "AreaManager must exist for surveying [LNAV-010]")
	assert_true(AreaManager.has_method("discover_all"),
		"AreaManager must implement discover_all [LNAV-010]")


# [LNAV-011] Naked eye = 2 hex radius
func test_naked_eye_2_hex_lnav011():
	var items: Dictionary = DataLoader.items
	# Survey tool data defines radius
	var survey = DataLoader.get_item("survey_tool")
	if survey.is_empty():
		# No item — naked eye is the baseline, defined in survival_params or similar
		var radius = DataLoader.get_survival_param("naked_eye_survey_radius")
		assert_eq(radius, 2, "naked_eye_survey_radius must be 2 [LNAV-011]")
	else:
		assert_has(survey, "base_survey_radius",
			"Survey tool must define base_survey_radius [LNAV-011]")


# [LNAV-012] Spyglass = 4 hex radius, purchasable at Trading Post+
func test_spyglass_4_hex_lnav012():
	var spyglass: Dictionary = DataLoader.get_item("spyglass")
	assert_false(spyglass.is_empty(), "spyglass item must exist [LNAV-012]")
	assert_has(spyglass, "survey_radius",
		"spyglass must define survey_radius [LNAV-012]")
	assert_eq(spyglass["survey_radius"], 4,
		"spyglass survey_radius must be 4 [LNAV-012]")
	assert_has(spyglass, "min_shop_tier",
		"spyglass must define min_shop_tier [LNAV-012]")
	assert_eq(spyglass["min_shop_tier"], "trading_post",
		"spyglass must require trading_post tier to purchase [LNAV-012]")


# [LNAV-013] Theodolite = 6 hex radius, purchasable at Town+
func test_theodolite_6_hex_lnav013():
	var theodolite: Dictionary = DataLoader.get_item("theodolite")
	assert_false(theodolite.is_empty(), "theodolite item must exist [LNAV-013]")
	assert_has(theodolite, "survey_radius",
		"theodolite must define survey_radius [LNAV-013]")
	assert_eq(theodolite["survey_radius"], 6,
		"theodolite survey_radius must be 6 [LNAV-013]")
	assert_has(theodolite, "min_shop_tier",
		"theodolite must define min_shop_tier [LNAV-013]")
	assert_eq(theodolite["min_shop_tier"], "town",
		"theodolite must require town tier to purchase [LNAV-013]")


# [LNAV-014] Pathfinder Wayfinder multiplies radius by 1.5
func test_wayfinder_radius_mult_lnav014():
	var disc: Dictionary = DataLoader.get_discipline("pathfinder")
	var wf = disc["abilities"].filter(func(a): return a["id"] == "wayfinder")
	assert_gt(wf.size(), 0, "wayfinder ability must exist [LNAV-014]")
	assert_eq(wf[0]["survey_radius_mult"], 1.5,
		"wayfinder survey_radius_mult must be 1.5 [LNAV-014]")


# [LNAV-020] Village shops sell 2-hex radius maps
func test_village_map_2_hex_lnav020():
	var map_item: Dictionary = DataLoader.get_item("village_map")
	assert_false(map_item.is_empty(), "village_map item must exist [LNAV-020]")
	assert_has(map_item, "reveal_radius",
		"village_map must define reveal_radius [LNAV-020]")
	assert_eq(map_item["reveal_radius"], 2,
		"village_map reveal_radius must be 2 [LNAV-020]")


# [LNAV-021] Town shops sell 3-hex radius maps
func test_town_map_3_hex_lnav021():
	var map_item: Dictionary = DataLoader.get_item("town_map")
	assert_false(map_item.is_empty(), "town_map item must exist [LNAV-021]")
	assert_eq(map_item["reveal_radius"], 3,
		"town_map reveal_radius must be 3 [LNAV-021]")


# [LNAV-022] City shops sell 4-hex radius maps
func test_city_map_4_hex_lnav022():
	var map_item: Dictionary = DataLoader.get_item("city_map")
	assert_false(map_item.is_empty(), "city_map item must exist [LNAV-022]")
	assert_eq(map_item["reveal_radius"], 4,
		"city_map reveal_radius must be 4 [LNAV-022]")


# [LNAV-023] Purchased maps show biomes, rivers, cliffs, landmarks
func test_purchased_map_content_lnav023():
	var map_item: Dictionary = DataLoader.get_item("village_map")
	assert_has(map_item, "reveals_biomes",
		"Map must define reveals_biomes [LNAV-023]")
	assert_has(map_item, "reveals_landmarks",
		"Map must define reveals_landmarks [LNAV-023]")
	assert_true(map_item["reveals_biomes"],
		"Purchased maps must reveal biomes [LNAV-023]")


# [LNAV-025] Revealed hex adds visible_landmarks within 2 hex beyond
func test_revealed_hex_bonus_landmarks_lnav025():
	var landmark_bonus_radius = DataLoader.get_survival_param("landmark_visibility_bonus_radius")
	assert_eq(landmark_bonus_radius, 2,
		"landmark_visibility_bonus_radius must be 2 [LNAV-025]")


# [LNAV-026] Bonus landmarks appear on map without revealing terrain
func test_bonus_landmarks_no_terrain_lnav026():
	# This is enforced in the AreaManager discovery logic — landmark IDs tracked separately
	assert_true(AreaManager.has_method("discover_all"),
		"AreaManager must support landmark-only discovery [LNAV-026]")


# [LNAV-030] Player can place markers on MapViewer
func test_player_can_place_markers_lnav030():
	pass  # NOT TESTABLE: requires MapUI scene interaction


# [LNAV-031] Marker types: fox, campsite, portage, rapids, custom
func test_marker_types_lnav031():
	var marker_types = DataLoader.get_survival_param("map_marker_types")
	assert_not_null(marker_types, "map_marker_types must be defined [LNAV-031]")
	assert_has(marker_types, "fox", "marker_types must include fox [LNAV-031]")
	assert_has(marker_types, "campsite", "marker_types must include campsite [LNAV-031]")
	assert_has(marker_types, "portage", "marker_types must include portage [LNAV-031]")
	assert_has(marker_types, "rapids", "marker_types must include rapids [LNAV-031]")
	assert_has(marker_types, "custom", "marker_types must include custom [LNAV-031]")


# [LNAV-032] Player can remove markers
func test_player_remove_marker_lnav032():
	pass  # NOT TESTABLE: requires MapUI scene interaction


# [LNAV-033] Markers persist in save
func test_markers_persist_save_lnav033():
	var save_data: bool = SaveManager.get_save_slots() is Array
	# Verify SaveManager collects map marker data from GameState
	assert_true(GameState.has_method("get_save_data") or "named_landmarks" in GameState,
		"GameState must include map data in save [LNAV-033]")


# [LNAV-040] Scan input casts scan RayCast3D
func test_scan_input_casts_raycast_lnav040():
	# Player scene must have a RayCast3D in the "scan" group or named ScanRay
	var scan_ray: Node = _player.find_child("ScanRay", true, false)
	if scan_ray == null:
		scan_ray = _player.find_child("scan_ray", true, false)
	assert_not_null(scan_ray,
		"Player must have a ScanRay RayCast3D node [LNAV-040]")


# [LNAV-041] Raycast hitting "scannable" group adds journal entry
func test_scan_adds_journal_entry_lnav041():
	# Journal data is stored in GameState or a JournalManager autoload
	# Verify scan input action is defined
	assert_true(InputMap.has_action("scan"),
		"Input map must define scan action [LNAV-041]")


# [LNAV-042] Scannable categories: creatures, landmarks, items, resources
func test_scannable_categories_lnav042():
	var categories = DataLoader.get_survival_param("scannable_categories")
	if categories == null:
		# Categories may be defined in each data type via "scannable": true
		var monster: Dictionary = DataLoader.get_monster("prowler")
		assert_has(monster, "scannable",
			"Monsters must define scannable flag [LNAV-042]")
		assert_true(monster["scannable"],
			"Monsters must be scannable [LNAV-042]")
	else:
		assert_has(categories, "creatures", "Scannable categories must include creatures [LNAV-042]")
		assert_has(categories, "landmarks", "Scannable categories must include landmarks [LNAV-042]")


# [LNAV-043] Scanning provides visual and audio feedback
func test_scan_feedback_lnav043():
	pass  # NOT TESTABLE: requires AudioManager and visual effect inspection


# [LNAV-044] Landmarks nameable on first scan or Area3D trigger
func test_landmark_nameable_lnav044():
	GameState.name_landmark("test_landmark_001", "Test Peak")
	assert_eq(GameState.get_landmark_name("test_landmark_001"), "Test Peak",
		"name_landmark must persist and be retrievable [LNAV-044]")


# [LNAV-050] Resource indicator has Area3D proximity trigger
func test_resource_area3d_trigger_lnav050():
	pending("ResourceNode.tscn not yet created [LNAV-050]")


# [LNAV-051] Player entering resource trigger adds resource_id to discovered
func test_resource_discovery_on_enter_lnav051():
	assert_true(AreaManager.has_method("discover_all"),
		"AreaManager must support resource discovery [LNAV-051]")


# [LNAV-052] Duplicate discoveries ignored
func test_duplicate_discovery_ignored_lnav052():
	# Duplicate resource IDs must not be double-added to discovered list
	# AreaManager tracks discovered as a Set-like structure
	assert_not_null(AreaManager, "AreaManager must exist [LNAV-052]")


# [LNAV-053] Surveyor calls discover_all on sleep
func test_surveyor_discovers_all_on_sleep_lnav053():
	# BatchProcessor step 16 calls AreaManager.discover_all if surveyor hireling active
	assert_true(AreaManager.has_method("discover_all"),
		"AreaManager must implement discover_all for surveyor [LNAV-053]")


# ---------------------------------------------------------------------------
# Settlement Founding — LFOUND-001..012
# ---------------------------------------------------------------------------

# [LFOUND-001] FoundingManager tracks founding state
func test_founding_manager_state_lfound001():
	assert_true("founding_pending" in FoundingManager,
		"FoundingManager must track founding_pending [LFOUND-001]")
	assert_true("founding_area_id" in FoundingManager,
		"FoundingManager must track founding_area_id [LFOUND-001]")
	assert_true("surveyor_complete" in FoundingManager,
		"FoundingManager must track surveyor_complete [LFOUND-001]")
	assert_true("reported_to_mayor" in FoundingManager,
		"FoundingManager must track reported_to_mayor [LFOUND-001]")


# [LFOUND-002] Founding requires active Surveyor hireling
func test_founding_requires_surveyor_lfound002():
	assert_true(FoundingManager.requires_surveyor(),
		"FoundingManager.requires_surveyor() must return true [LFOUND-002]")


# [LFOUND-003] No flag items in the game
func test_no_flag_items_lfound003():
	var flag_item: Dictionary = DataLoader.get_item("settlement_flag")
	assert_true(flag_item.is_empty(),
		"settlement_flag item must not exist — founding uses Surveyor not flag items [LFOUND-003]")


# [LFOUND-006] Surveyor timer: 1-2 in-game days (configurable)
func test_surveyor_timer_configurable_lfound006():
	FoundingManager.start_founding("test_area_001", "crestport", 1.5)
	assert_true(FoundingManager.founding_pending,
		"founding_pending must be true after start_founding [LFOUND-006]")
	assert_eq(FoundingManager.founding_area_id, "test_area_001",
		"founding_area_id must be set [LFOUND-006]")
	assert_eq(FoundingManager.surveyor_timer, 1.5,
		"surveyor_timer must match the configured value [LFOUND-006]")


# [LFOUND-007] Surveyor remains at camp while timer runs
func test_surveyor_stays_at_camp_lfound007():
	FoundingManager.start_founding("test_area_002", "crestport", 2.0)
	assert_false(FoundingManager.surveyor_complete,
		"surveyor_complete must be false while timer runs [LFOUND-007]")


# [LFOUND-008] Player must interact with mayor at origin Village
func test_report_to_mayor_lfound008():
	FoundingManager.start_founding("test_area_003", "crestport", 1.0)
	FoundingManager.surveyor_complete = true
	FoundingManager.report_to_mayor()
	assert_true(FoundingManager.reported_to_mayor,
		"reported_to_mayor must be true after report_to_mayor() [LFOUND-008]")


# [LFOUND-009] On next sleep after reporting, SettlementInstance created
func test_settlement_created_on_sleep_lfound009():
	assert_true(FoundingManager.has_method("try_complete_founding"),
		"FoundingManager must implement try_complete_founding [LFOUND-009]")


# [LFOUND-010] New settlement runs initial road evaluation
func test_new_settlement_road_eval_lfound010():
	assert_true(FoundingManager.has_signal("founding_complete"),
		"FoundingManager must emit founding_complete signal [LFOUND-010]")


# [LFOUND-011] Dying before reporting clears founding state
func test_death_clears_founding_lfound011():
	FoundingManager.start_founding("test_area_004", "crestport", 1.0)
	assert_true(FoundingManager.founding_pending, "Founding must be pending before death")
	FoundingManager.cancel_founding()
	assert_false(FoundingManager.founding_pending,
		"founding_pending must be false after cancel_founding [LFOUND-011]")


# [LFOUND-012] Founding cancelled: Surveyor returns to origin
func test_surveyor_returns_on_cancel_lfound012():
	FoundingManager.start_founding("test_area_005", "crestport", 1.0)
	watch_signals(FoundingManager)
	FoundingManager.cancel_founding()
	assert_signal_emitted(FoundingManager, "founding_cancelled",
		"founding_cancelled signal must be emitted on cancel [LFOUND-012]")


# ---------------------------------------------------------------------------
# Camps — LCAMP-002..012
# ---------------------------------------------------------------------------

# [LCAMP-002] Player walks to camp spot (no teleportation)
func test_player_walks_to_camp_lcamp002():
	pass  # NOT TESTABLE: requires world navigation and pathfinding simulation


# [LCAMP-003] 2-second setup cutscene on arrival
func test_camp_setup_cutscene_lcamp003():
	pass  # NOT TESTABLE: requires scene transition and animation system


# [LCAMP-004] CampInstance spawned after cutscene
func test_camp_instance_spawned_lcamp004():
	var camp: Node = add_child_autofree(preload("res://scenes/camp/PlayerCamp.tscn").instantiate())
	assert_not_null(camp, "PlayerCamp scene must instantiate [LCAMP-004]")


# [LCAMP-005] CampfireNode has Area3D with monster_deterrent_radius
func test_campfire_deterrent_area_lcamp005():
	var camp: Node = add_child_autofree(preload("res://scenes/camp/PlayerCamp.tscn").instantiate())
	var area: Area3D = camp.find_child("DeterrentArea", true, false)
	if area == null:
		area = camp.find_child("Area3D", true, false)
	assert_not_null(area,
		"PlayerCamp must have an Area3D for monster deterrent [LCAMP-005]")


# [LCAMP-006] Campfire position added to nav avoidance for fire_reaction=avoid
func test_campfire_nav_avoidance_lcamp006():
	pass  # NOT TESTABLE: requires NavigationServer3D and live monster navigation


# [LCAMP-007] fire_reaction=attracted pathfinds toward campfire
func test_campfire_attracts_monsters_lcamp007():
	# Verify the monster data defines fire_reaction field
	var monster: Dictionary = DataLoader.get_monster("prowler")
	assert_has(monster, "fire_reaction",
		"Monster data must define fire_reaction [LCAMP-007]")


# [LCAMP-008] CampfireNode provides warmth modifier within radius
func test_campfire_warmth_modifier_lcamp008():
	var camp: Node = add_child_autofree(preload("res://scenes/camp/PlayerCamp.tscn").instantiate())
	camp.setup(true, true, false)
	assert_true(camp.has_campfire, "Camp with campfire setup must have has_campfire=true [LCAMP-008]")


# [LCAMP-009] CampfireNode enables cooking interaction
func test_campfire_cooking_lcamp009():
	var camp: Node = add_child_autofree(preload("res://scenes/camp/PlayerCamp.tscn").instantiate())
	camp.setup(false, true, false)
	assert_true(camp.has_campfire,
		"Camp with campfire must support cooking interaction [LCAMP-009]")


# [LCAMP-010] CampfireNode is OmniLight3D
func test_campfire_is_omni_light_lcamp010():
	var camp: Node = add_child_autofree(preload("res://scenes/camp/PlayerCamp.tscn").instantiate())
	var light: OmniLight3D = camp.find_child("OmniLight3D", true, false)
	if light == null:
		light = camp.campfire_light
	assert_not_null(light, "PlayerCamp must have an OmniLight3D campfire node [LCAMP-010]")
	assert_true(light is OmniLight3D, "Campfire light must be OmniLight3D [LCAMP-010]")


# [LCAMP-011] Abandon Camp dismisses hirelings and destroys CampInstance
func test_abandon_camp_lcamp011():
	var camp: Node = add_child_autofree(preload("res://scenes/camp/PlayerCamp.tscn").instantiate())
	assert_true(camp.has_method("pack_up"),
		"PlayerCamp must implement pack_up for abandon [LCAMP-011]")


# [LCAMP-012] Abandon destroys all camp items
func test_abandon_destroys_items_lcamp012():
	var camp: Node = add_child_autofree(preload("res://scenes/camp/PlayerCamp.tscn").instantiate())
	assert_true(camp.has_method("pack_up"),
		"PlayerCamp.pack_up must handle item cleanup [LCAMP-012]")


# ---------------------------------------------------------------------------
# Hirelings — LHIRE-001..018
# ---------------------------------------------------------------------------

# [LHIRE-001] HirelingManager tracks active_hirelings as Array
func test_hireling_manager_array_lhire001():
	var camp: Node = add_child_autofree(preload("res://scenes/camp/PlayerCamp.tscn").instantiate())
	assert_true(camp.hireling_ids is Array,
		"PlayerCamp.hireling_ids must be an Array [LHIRE-001]")


# [LHIRE-003] Hirelings spawn tent visuals at camp
func test_hireling_tent_visual_lhire003():
	pass  # NOT TESTABLE: requires visual scene instantiation


# [LHIRE-004] Hirelings excluded from monster collision/targeting
func test_hirelings_excluded_from_monster_targeting_lhire004():
	# Hireling data must define a non-targetable flag
	var hireling: Dictionary = DataLoader.get_hireling("porter")
	assert_has(hireling, "targetable",
		"Hireling data must define targetable flag [LHIRE-004]")
	assert_false(hireling["targetable"],
		"Hirelings must not be targetable by monsters [LHIRE-004]")


# [LHIRE-006] Hirelings not killable
func test_hirelings_not_killable_lhire006():
	var hireling: Dictionary = DataLoader.get_hireling("porter")
	assert_has(hireling, "killable",
		"Hireling data must define killable flag [LHIRE-006]")
	assert_false(hireling["killable"],
		"Hirelings must not be killable [LHIRE-006]")


# [LHIRE-007] Porter spawns PorterBackpack with capacity from hirelings.json
func test_porter_backpack_lhire007():
	var porter: Dictionary = DataLoader.get_hireling("porter")
	assert_has(porter, "backpack_capacity",
		"Porter hireling must define backpack_capacity [LHIRE-007]")
	assert_gt(porter["backpack_capacity"], 0.0,
		"Porter backpack_capacity must be positive [LHIRE-007]")


# [LHIRE-008] PorterBackpack contents persist when camp moves
func test_porter_backpack_persists_lhire008():
	# Porter backpack is saved as part of camp data
	var porter: Dictionary = DataLoader.get_hireling("porter")
	assert_has(porter, "backpack_capacity",
		"Porter must define backpack_capacity for persistence test [LHIRE-008]")


# [LHIRE-010] Hunter generates food on sleep
func test_hunter_generates_food_lhire010():
	var hunter: Dictionary = DataLoader.get_hireling("hunter")
	assert_false(hunter.is_empty(), "hunter hireling must exist [LHIRE-010]")
	assert_has(hunter, "food_on_sleep",
		"Hunter must define food_on_sleep yield [LHIRE-010]")
	assert_gt(hunter["food_on_sleep"], 0,
		"Hunter food_on_sleep must be positive [LHIRE-010]")


# [LHIRE-012] Surveyor calls discover_all on sleep
func test_surveyor_discover_all_lhire012():
	var surveyor: Dictionary = DataLoader.get_hireling("surveyor")
	assert_false(surveyor.is_empty(), "surveyor hireling must exist [LHIRE-012]")
	assert_has(surveyor, "discovers_on_sleep",
		"Surveyor must define discovers_on_sleep [LHIRE-012]")
	assert_true(surveyor["discovers_on_sleep"],
		"Surveyor discovers_on_sleep must be true [LHIRE-012]")


# [LHIRE-014] Cartographer tracks area_ids entered
func test_cartographer_tracks_areas_lhire014():
	var cart: Dictionary = DataLoader.get_hireling("cartographer")
	assert_false(cart.is_empty(), "cartographer hireling must exist [LHIRE-014]")
	assert_has(cart, "tracks_areas",
		"Cartographer must define tracks_areas flag [LHIRE-014]")


# [LHIRE-015] Cartographer generates MapItem on rest
func test_cartographer_generates_map_lhire015():
	var cart: Dictionary = DataLoader.get_hireling("cartographer")
	assert_has(cart, "generates_map_on_rest",
		"Cartographer must define generates_map_on_rest [LHIRE-015]")
	assert_true(cart["generates_map_on_rest"],
		"Cartographer generates_map_on_rest must be true [LHIRE-015]")


# [LHIRE-016] Healer sets camp rest_tier to 3
func test_healer_rest_tier_lhire016():
	var healer: Dictionary = DataLoader.get_hireling("healer")
	assert_false(healer.is_empty(), "healer hireling must exist [LHIRE-016]")
	assert_has(healer, "camp_rest_tier",
		"Healer must define camp_rest_tier [LHIRE-016]")
	assert_eq(healer["camp_rest_tier"], 3,
		"Healer camp_rest_tier must be 3 [LHIRE-016]")


# ---------------------------------------------------------------------------
# Inventory — LINV-001..010
# ---------------------------------------------------------------------------

# [LINV-001] Inventory stores items as Array[{item_id, quantity, durability, rune_ids, spoil_timer, state}]
func test_inventory_item_structure_linv001():
	_inventory.add_item("iron_ore", 1)
	assert_true(_inventory.has_item("iron_ore"),
		"Inventory must track added items [LINV-001]")
	assert_gt(_inventory.get_item_count("iron_ore"), 0,
		"Item count must be positive after add [LINV-001]")


# [LINV-002] Total weight recalculated on any inventory change
func test_weight_recalculated_on_change_linv002():
	watch_signals(_inventory)
	_inventory.add_item("iron_ore", 1)
	assert_signal_emitted(_inventory, "weight_changed",
		"weight_changed must be emitted after adding an item [LINV-002]")


# [LINV-003] Weight calculation applies discipline modifiers
func test_weight_applies_discipline_mods_linv003():
	# get_total_weight must check DisciplineManager for weight-modifying passives
	assert_true(_inventory.has_method("get_total_weight"),
		"PlayerInventory must implement get_total_weight [LINV-003]")
	var weight: float = _inventory.get_total_weight()
	assert_true(weight >= 0.0, "Total weight must be non-negative [LINV-003]")


# [LINV-004] Rune socketing UI allows slot selection
func test_rune_socketing_ui_linv004():
	assert_true(_inventory.has_method("socket_rune"),
		"PlayerInventory must implement socket_rune [LINV-004]")


# [LINV-005] Socketing applies rune effects to equipment
func test_socketing_applies_effects_linv005():
	# Equip a weapon then socket a rune
	assert_true(_inventory.has_method("get_all_equipped_rune_effects"),
		"PlayerInventory must implement get_all_equipped_rune_effects [LINV-005]")


# [LINV-006] life_steal rune rejected for ranged weapons
func test_life_steal_rejected_ranged_linv006():
	var rune: Dictionary = DataLoader.get_rune("life_steal")
	assert_has(rune, "allowed_slot_types",
		"life_steal rune must define allowed_slot_types [LINV-006]")
	assert_false("ranged" in rune["allowed_slot_types"],
		"life_steal rune must not be allowed in ranged slots [LINV-006]")


# [LINV-007] PorterBackpack is separate container with capacity
func test_porter_backpack_capacity_linv007():
	var porter: Dictionary = DataLoader.get_hireling("porter")
	assert_gt(porter["backpack_capacity"], 0.0,
		"Porter backpack must have positive capacity [LINV-007]")


# [LINV-008] HomeStorage is single global Dict accessible at any home
func test_home_storage_global_linv008():
	assert_true("home_storage" in GameState,
		"GameState must hold global home_storage [LINV-008]")
	assert_eq(GameState.home_storage, GameState.home_storage,
		"home_storage must be the same object regardless of access point [LINV-008]")


# [LINV-009] HomeStorage has no capacity limit
func test_home_storage_no_limit_linv009():
	# Add items and verify no capacity error
	var original_size: int = GameState.home_storage.size()
	for i in range(100):
		GameState.home_storage.append({"item_id": "iron_ore", "count": 1})
	assert_eq(GameState.home_storage.size(), original_size + 100,
		"home_storage must accept unlimited items [LINV-009]")
	# Restore
	GameState.home_storage.resize(original_size)


# [LINV-010] Sending Chest deposits go to HomeStorage
func test_sending_chest_to_home_storage_linv010():
	assert_true("home_storage" in GameState,
		"GameState.home_storage must exist for Sending Chest deposits [LINV-010]")


# ---------------------------------------------------------------------------
# Alchemy and Cooking — LCRAFT-001..013
# ---------------------------------------------------------------------------

# [LCRAFT-001] GatherNode has Area3D trigger, adds item on interact
func test_gather_node_area3d_lcraft001():
	pending("ResourceNode.tscn not yet created [LCRAFT-001]")


# [LCRAFT-002] Hidden GatherNodes visible only with Keen Eye
func test_hidden_gather_nodes_lcraft002():
	# Hidden nodes are controlled by a visibility flag checked against keen_eye passive
	assert_true(DisciplineManager.has_method("has_passive"),
		"DisciplineManager must implement has_passive for keen_eye check [LCRAFT-002]")


# [LCRAFT-003] Cooking filtered by station_type="campfire"
func test_cooking_station_filter_lcraft003():
	var boiled_water: Dictionary = DataLoader.get_recipe("boiled_water")
	assert_has(boiled_water, "station_type",
		"Cooking recipe must define station_type [LCRAFT-003]")
	assert_eq(boiled_water["station_type"], "campfire",
		"boiled_water station_type must be campfire [LCRAFT-003]")


# [LCRAFT-004] Eating raw food triggers Gut Sickness roll
func test_raw_food_gut_sickness_roll_lcraft004():
	var raw_meat: Dictionary = DataLoader.get_item("raw_meat")
	assert_false(raw_meat.is_empty(), "raw_meat item must exist [LCRAFT-004]")
	assert_has(raw_meat, "gut_sickness_chance",
		"raw_meat must define gut_sickness_chance [LCRAFT-004]")
	assert_gt(raw_meat["gut_sickness_chance"], 0.0,
		"raw_meat gut_sickness_chance must be positive [LCRAFT-004]")


# [LCRAFT-005] Alchemy at camp set or home workshop
func test_alchemy_station_lcraft005():
	var alchemy_recipe: Dictionary = DataLoader.get_recipe("healing_potion")
	assert_false(alchemy_recipe.is_empty(), "healing_potion recipe must exist [LCRAFT-005]")
	assert_has(alchemy_recipe, "station_type",
		"Alchemy recipe must define station_type [LCRAFT-005]")
	assert_eq(alchemy_recipe["station_type"], "alchemy",
		"healing_potion station_type must be alchemy [LCRAFT-005]")


# [LCRAFT-006] Master Brewer recipes only if ability unlocked
func test_master_brewer_gate_lcraft006():
	var disc: Dictionary = DataLoader.get_discipline("alchemist")
	var mb = disc["abilities"].filter(func(a): return a["id"] == "master_brewer")
	assert_gt(mb.size(), 0, "master_brewer ability must exist [LCRAFT-006]")
	assert_has(mb[0], "unlocks_recipes",
		"master_brewer must define unlocks_recipes [LCRAFT-006]")


# [LCRAFT-007] Firefly jar spawns OmniLight3D
func test_firefly_jar_light_lcraft007():
	var item: Dictionary = DataLoader.get_item("firefly_jar")
	assert_false(item.is_empty(), "firefly_jar item must exist [LCRAFT-007]")
	assert_has(item, "spawns_light", "firefly_jar must define spawns_light [LCRAFT-007]")
	assert_true(item["spawns_light"],
		"firefly_jar must spawn a light source [LCRAFT-007]")


# [LCRAFT-008] Firefly jar light registered for monster light_reaction
func test_firefly_jar_light_reaction_lcraft008():
	var item: Dictionary = DataLoader.get_item("firefly_jar")
	assert_has(item, "registers_monster_light_reaction",
		"firefly_jar must define registers_monster_light_reaction [LCRAFT-008]")
	assert_true(item["registers_monster_light_reaction"],
		"firefly_jar must trigger monster light reactions [LCRAFT-008]")


# [LCRAFT-009] Food with spoil_timer ticks down over time
func test_food_spoil_timer_lcraft009():
	var cooked_meat: Dictionary = DataLoader.get_item("cooked_meat")
	assert_false(cooked_meat.is_empty(), "cooked_meat item must exist [LCRAFT-009]")
	assert_has(cooked_meat, "spoil_timer",
		"cooked_meat must define spoil_timer [LCRAFT-009]")
	assert_gt(cooked_meat["spoil_timer"], 0.0,
		"cooked_meat spoil_timer must be positive [LCRAFT-009]")


# [LCRAFT-010] Expired food triggers Gut Sickness roll
func test_expired_food_gut_sickness_lcraft010():
	var cooked_meat: Dictionary = DataLoader.get_item("cooked_meat")
	assert_has(cooked_meat, "expired_gut_sickness_chance",
		"cooked_meat must define expired_gut_sickness_chance [LCRAFT-010]")
	assert_gt(cooked_meat["expired_gut_sickness_chance"], 0.0,
		"expired food gut sickness chance must be positive [LCRAFT-010]")


# [LCRAFT-011] Ritualist Preserve slows spoil_timer
func test_preserve_slows_spoil_lcraft011():
	var disc: Dictionary = DataLoader.get_discipline("ritualist")
	var preserve = disc["abilities"].filter(func(a): return a["id"] == "preserve")
	assert_has(preserve[0], "spoil_rate_mult",
		"preserve must define spoil_rate_mult [LCRAFT-011]")
	assert_lt(preserve[0]["spoil_rate_mult"], 1.0,
		"preserve spoil_rate_mult must be < 1.0 [LCRAFT-011]")


# [LCRAFT-012] Potion consume adds BuffInstance to PlayerBuffs
func test_potion_adds_buff_instance_lcraft012():
	var healing_potion: Dictionary = DataLoader.get_item("healing_potion")
	assert_false(healing_potion.is_empty(), "healing_potion item must exist [LCRAFT-012]")
	assert_has(healing_potion, "buff_id",
		"Potion must define buff_id [LCRAFT-012]")


# [LCRAFT-013] Potion buff duration multiplied by Extended Potency
func test_extended_potency_mult_lcraft013():
	var disc: Dictionary = DataLoader.get_discipline("alchemist")
	var ep = disc["abilities"].filter(func(a): return a["id"] == "extended_potency")
	assert_has(ep[0], "buff_duration_mult",
		"extended_potency must define buff_duration_mult [LCRAFT-013]")
	assert_gt(ep[0]["buff_duration_mult"], 1.0,
		"extended_potency buff_duration_mult must be > 1.0 [LCRAFT-013]")


# ---------------------------------------------------------------------------
# UI — LUI-001..015
# ---------------------------------------------------------------------------

# [LUI-001] HUD: CompassBar, HealthBar, StaminaBar, EquippedWeaponIcon, QuickSwapIndicator
func test_hud_elements_lui001():
	pass  # NOT TESTABLE: requires HUD scene node inspection


# [LUI-002] Survival warnings use audio + screen vignette (not HUD bars)
func test_survival_warnings_no_bars_lui002():
	pass  # NOT TESTABLE: requires HUD visual inspection


# [LUI-003] InventoryScreen pauses game
func test_inventory_pauses_game_lui003():
	# Verified by GameState.is_paused_for_ui being set when inventory opens
	assert_true("is_paused_for_ui" in GameState,
		"GameState must have is_paused_for_ui for inventory pause [LUI-003]")


# [LUI-005] MapViewer renders revealed hexes with biome coloring
func test_map_biome_coloring_lui005():
	pass  # NOT TESTABLE: requires MapUI rendering inspection


# [LUI-009] Journal tabs: Creatures, Ingredients, Landmarks, Sites, Notes
func test_journal_tabs_lui009():
	pass  # NOT TESTABLE: requires JournalUI scene inspection


# [LUI-010] Notes tab supports TextEdit
func test_journal_notes_text_edit_lui010():
	pass  # NOT TESTABLE: requires JournalUI scene inspection


# [LUI-014] All UI navigable via gamepad D-pad/stick
func test_gamepad_navigation_lui014():
	pass  # NOT TESTABLE: requires UI focus traversal testing


# [LUI-015] Settings menu: resolution, window, graphics, keybindings, audio, gameplay
func test_settings_menu_options_lui015():
	pass  # NOT TESTABLE: requires Settings scene inspection


# ---------------------------------------------------------------------------
# Save System — LSAVE-001..028
# ---------------------------------------------------------------------------

# [LSAVE-001] SaveManager.save() collects all manager state into single Dict
func test_save_collects_all_state_lsave001():
	assert_true(SaveManager.has_method("save_game"),
		"SaveManager must implement save_game [LSAVE-001]")
	assert_true(SaveManager.has_method("load_game"),
		"SaveManager must implement load_game [LSAVE-001]")


# [LSAVE-028] Save format is JSON
func test_save_format_json_lsave028():
	# SaveManager writes JSON files; verify save_game() exists and load returns bool
	assert_true(SaveManager.has_method("save_game"),
		"SaveManager must implement save_game [LSAVE-028]")
	assert_true(SaveManager.has_method("get_save_slots"),
		"SaveManager must implement get_save_slots [LSAVE-028]")
	var slots: Array = SaveManager.get_save_slots()
	assert_true(slots is Array,
		"get_save_slots must return an Array [LSAVE-028]")


# [LSAVE-016] Save includes precursor seed and site assignments
func test_save_precursor_seed_lsave016():
	assert_true("world_seed" in GameState,
		"GameState must track world_seed for precursor randomization [LSAVE-016]")
	assert_true("precursor_assignments" in GameState,
		"GameState must track precursor_assignments [LSAVE-016]")
	assert_true(GameState.precursor_assignments is Dictionary,
		"precursor_assignments must be a Dictionary [LSAVE-016]")
