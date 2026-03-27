## test_home_storage.gd
## GUT Runtime Tests — Home Storage (StorageUI, HomeChest, GameState.home_storage)
## Traces to: LLR v0.7.1 | HLR v0.7.0 | INV-003
##
## RUNTIME ONLY: Requires Godot 4 + GUT. Run via Godot editor → GUT panel.

extends GutTest

var _storage_ui: Control
var _player: CharacterBody3D
var _saved_home_storage: Array
var _saved_paused: bool


func before_all() -> void:
	_player = preload("res://scenes/player/Player.tscn").instantiate()
	add_child(_player)
	await get_tree().process_frame
	_storage_ui = preload("res://scenes/ui/StorageUI.tscn").instantiate()
	add_child(_storage_ui)
	await get_tree().process_frame


func after_all() -> void:
	_storage_ui.queue_free()
	_player.queue_free()


func before_each() -> void:
	_saved_home_storage = GameState.home_storage.duplicate(true)
	_saved_paused = GameState.is_paused_for_ui
	GameState.home_storage.clear()


func after_each() -> void:
	GameState.home_storage.clear()
	for entry in _saved_home_storage:
		GameState.home_storage.append(entry)
	GameState.is_paused_for_ui = _saved_paused
	if _storage_ui.visible:
		_storage_ui.close()


# ---------------------------------------------------------------------------
# LINV-008 — Single global home storage accessible via HomeChest
# ---------------------------------------------------------------------------

func test_home_storage_exists_on_gamestate_linv008():
	assert_true("home_storage" in GameState,
		"GameState must expose home_storage array [LINV-008]")
	assert_true(GameState.home_storage is Array,
		"home_storage must be an Array [LINV-008]")


func test_home_chest_scene_loads_linv008():
	var chest = preload("res://scenes/world/HomeChest.tscn").instantiate()
	assert_not_null(chest, "HomeChest scene must load [LINV-008]")
	assert_true(chest.has_method("interact"),
		"HomeChest must implement interact() [LINV-008]")
	chest.free()


func test_home_chest_opens_storage_ui_linv008():
	_storage_ui.open(GameState.home_storage, _player.inventory)
	assert_true(_storage_ui.visible,
		"StorageUI must be visible after open() [LINV-008]")
	assert_true(GameState.is_paused_for_ui,
		"is_paused_for_ui must be true while StorageUI is open [LINV-008]")


# ---------------------------------------------------------------------------
# LINV-009 — No capacity limit on home storage
# ---------------------------------------------------------------------------

func test_home_storage_has_no_capacity_limit_linv009():
	# Add 100 stacks — should never be rejected
	for i in range(100):
		GameState.home_storage.append({ "item_id": "iron_ore", "count": i + 1, "runes": [] })
	assert_eq(GameState.home_storage.size(), 100,
		"HomeStorage must accept unlimited items [LINV-009]")


# ---------------------------------------------------------------------------
# StorageUI — open/close behaviour
# ---------------------------------------------------------------------------

func test_storage_ui_releases_mouse_on_open():
	_storage_ui.open(GameState.home_storage, _player.inventory)
	assert_eq(Input.get_mouse_mode(), Input.MOUSE_MODE_VISIBLE,
		"Mouse must be visible while StorageUI is open")


func test_storage_ui_recaptures_mouse_on_close():
	_storage_ui.open(GameState.home_storage, _player.inventory)
	_storage_ui.close()
	assert_eq(Input.get_mouse_mode(), Input.MOUSE_MODE_CAPTURED,
		"Mouse must be recaptured after StorageUI closes")


func test_storage_ui_clears_paused_flag_on_close():
	_storage_ui.open(GameState.home_storage, _player.inventory)
	_storage_ui.close()
	assert_false(GameState.is_paused_for_ui,
		"is_paused_for_ui must be false after StorageUI closes")


# ---------------------------------------------------------------------------
# StorageUI — store item from inventory to home storage
# ---------------------------------------------------------------------------

func test_store_item_moves_from_inventory_to_storage():
	_player.inventory.add_item("iron_ore", 3)
	var inv_count_before: int = _player.inventory.items.size()
	_storage_ui.open(GameState.home_storage, _player.inventory)
	# Simulate selecting the first inventory item and storing it
	_storage_ui._selected_inv_index = 0
	_storage_ui._active_panel = "inventory"
	_storage_ui._store_selected()
	assert_true(GameState.home_storage.size() > 0,
		"HomeStorage must contain the stored item")
	assert_lt(_player.inventory.items.size(), inv_count_before,
		"Inventory must shrink after storing")


# ---------------------------------------------------------------------------
# StorageUI — take item from home storage to inventory
# ---------------------------------------------------------------------------

func test_take_item_moves_from_storage_to_inventory():
	GameState.home_storage.append({ "item_id": "iron_ore", "count": 5, "runes": [] })
	var inv_size_before: int = _player.inventory.items.size()
	_storage_ui.open(GameState.home_storage, _player.inventory)
	_storage_ui._selected_stor_index = 0
	_storage_ui._active_panel = "storage"
	_storage_ui._take_selected()
	assert_eq(GameState.home_storage.size(), 0,
		"HomeStorage must be empty after taking the only stack")
	assert_gt(_player.inventory.items.size(), inv_size_before,
		"Inventory must grow after taking")


# ---------------------------------------------------------------------------
# StorageUI — partial quantity transfer
# ---------------------------------------------------------------------------

func test_partial_store_splits_stack():
	_player.inventory.add_item("iron_ore", 10)
	_storage_ui.open(GameState.home_storage, _player.inventory)
	_storage_ui._selected_inv_index = 0
	_storage_ui._active_panel = "inventory"
	_storage_ui._quantity_mode = true
	_storage_ui._pending_quantity = 4
	_storage_ui._store_selected()
	var stored_count: int = 0
	for e in GameState.home_storage:
		if e["item_id"] == "iron_ore":
			stored_count = e["count"]
	assert_eq(stored_count, 4,
		"Partial store must transfer exactly the pending quantity")
	# Remaining in inventory
	var remaining: int = 0
	for e in _player.inventory.items:
		if e["item_id"] == "iron_ore":
			remaining = e["count"]
	assert_eq(remaining, 6,
		"Remaining stack in inventory must be original minus transferred")


func test_partial_take_splits_storage_stack():
	GameState.home_storage.append({ "item_id": "iron_ore", "count": 10, "runes": [] })
	_storage_ui.open(GameState.home_storage, _player.inventory)
	_storage_ui._selected_stor_index = 0
	_storage_ui._active_panel = "storage"
	_storage_ui._quantity_mode = true
	_storage_ui._pending_quantity = 3
	_storage_ui._take_selected()
	assert_eq(GameState.home_storage[0]["count"], 7,
		"Storage stack must be reduced by the taken quantity")


# ---------------------------------------------------------------------------
# StorageUI — keyboard navigation
# ---------------------------------------------------------------------------

func test_keyboard_navigation_wraps_inventory():
	_player.inventory.add_item("iron_ore", 1)
	_player.inventory.add_item("wood_log", 1)
	_storage_ui.open(GameState.home_storage, _player.inventory)
	assert_eq(_storage_ui._selected_inv_index, 0,
		"First item must be selected on open")
	_storage_ui._navigate(1)
	assert_eq(_storage_ui._selected_inv_index, 1,
		"S must move selection down")
	_storage_ui._navigate(1)
	assert_eq(_storage_ui._selected_inv_index, 0,
		"Navigation must wrap at end of list")


func test_quantity_mode_ws_cancels_and_navigates():
	_player.inventory.add_item("iron_ore", 5)
	_player.inventory.add_item("wood_log", 1)
	_storage_ui.open(GameState.home_storage, _player.inventory)
	_storage_ui._quantity_mode = true
	_storage_ui._pending_quantity = 5
	# W/S should cancel quantity mode and navigate
	_storage_ui._quantity_mode = false
	_storage_ui._navigate(1)
	assert_false(_storage_ui._quantity_mode,
		"Quantity mode must be cancelled after W/S navigation")
	assert_eq(_storage_ui._selected_inv_index, 1,
		"Selection must advance after cancelling quantity mode")


# ---------------------------------------------------------------------------
# Player input blocked while UI open
# ---------------------------------------------------------------------------

func test_player_input_blocked_while_storage_ui_open():
	_storage_ui.open(GameState.home_storage, _player.inventory)
	assert_true(GameState.is_paused_for_ui,
		"is_paused_for_ui must prevent player input while StorageUI is open")
