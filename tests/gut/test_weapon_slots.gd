## test_weapon_slots.gd
## GUT Runtime Tests — Weapon Slots (PC-005)
## Traces to: LPC-020, LPC-021, LPC-045
##
## RUNTIME ONLY: Requires Godot 4 + GUT. Run via Godot editor → GUT panel.

extends GutTest

var _player: CharacterBody3D
var _inventory: PlayerInventory


func before_all() -> void:
	_player = preload("res://scenes/player/Player.tscn").instantiate()
	add_child(_player)
	_inventory = _player.get_node("PlayerInventory")


func before_each() -> void:
	# Reset weapon slots to empty
	_inventory.weapon_slots[0] = {}
	_inventory.weapon_slots[1] = {}
	_inventory.active_weapon_slot = 0
	_inventory.items.clear()


func after_all() -> void:
	_player.queue_free()


# ---------------------------------------------------------------------------
# [LPC-020] The player shall have exactly 2 weapon slots.
# ---------------------------------------------------------------------------

func test_player_has_exactly_two_weapon_slots_lpc020():
	assert_eq(_inventory.weapon_slots.size(), 2,
		"weapon_slots must contain exactly 2 entries [LPC-020]")


func test_weapon_slots_are_dicts_lpc020():
	assert_true(_inventory.weapon_slots[0] is Dictionary,
		"weapon_slots[0] must be a Dictionary [LPC-020]")
	assert_true(_inventory.weapon_slots[1] is Dictionary,
		"weapon_slots[1] must be a Dictionary [LPC-020]")


func test_equip_weapon_to_slot_zero_lpc020():
	_inventory.add_item("hunting_knife", 1)
	_inventory.equip_to_weapon_slot("hunting_knife", 0)
	assert_eq(_inventory.weapon_slots[0].get("item_id", ""), "hunting_knife",
		"Weapon equipped to slot 0 must appear in weapon_slots[0] [LPC-020]")


func test_equip_weapon_to_slot_one_lpc020():
	_inventory.add_item("shortsword", 1)
	_inventory.equip_to_weapon_slot("shortsword", 1)
	assert_eq(_inventory.weapon_slots[1].get("item_id", ""), "shortsword",
		"Weapon equipped to slot 1 must appear in weapon_slots[1] [LPC-020]")


func test_each_slot_holds_independent_weapon_lpc020():
	_inventory.add_item("hunting_knife", 1)
	_inventory.add_item("shortsword", 1)
	_inventory.equip_to_weapon_slot("hunting_knife", 0)
	_inventory.equip_to_weapon_slot("shortsword", 1)
	assert_eq(_inventory.weapon_slots[0].get("item_id", ""), "hunting_knife",
		"Slot 0 must hold hunting_knife [LPC-020]")
	assert_eq(_inventory.weapon_slots[1].get("item_id", ""), "shortsword",
		"Slot 1 must hold shortsword [LPC-020]")


# ---------------------------------------------------------------------------
# [LPC-021] A quick-swap input shall swap the active weapon slot.
# ---------------------------------------------------------------------------

func test_active_weapon_slot_starts_at_zero_lpc021():
	assert_eq(_inventory.active_weapon_slot, 0,
		"active_weapon_slot must default to 0 [LPC-021]")


func test_swap_weapon_slot_toggles_to_one_lpc021():
	_inventory.swap_weapon_slot()
	assert_eq(_inventory.active_weapon_slot, 1,
		"swap_weapon_slot() must set active_weapon_slot to 1 [LPC-021]")


func test_swap_weapon_slot_wraps_back_to_zero_lpc021():
	_inventory.swap_weapon_slot()
	_inventory.swap_weapon_slot()
	assert_eq(_inventory.active_weapon_slot, 0,
		"Two swaps must return active_weapon_slot to 0 [LPC-021]")


func test_get_active_weapon_returns_slot_zero_item_lpc021():
	_inventory.add_item("hunting_knife", 1)
	_inventory.equip_to_weapon_slot("hunting_knife", 0)
	assert_eq(_inventory.get_active_weapon().get("item_id", ""), "hunting_knife",
		"get_active_weapon() must return the item in the active slot [LPC-021]")


func test_get_active_weapon_returns_slot_one_after_swap_lpc021():
	_inventory.add_item("hunting_knife", 1)
	_inventory.add_item("shortsword", 1)
	_inventory.equip_to_weapon_slot("hunting_knife", 0)
	_inventory.equip_to_weapon_slot("shortsword", 1)
	_inventory.swap_weapon_slot()
	assert_eq(_inventory.get_active_weapon().get("item_id", ""), "shortsword",
		"get_active_weapon() must return slot 1 item after swap [LPC-021]")


func test_get_active_weapon_empty_when_slot_empty_lpc021():
	assert_true(_inventory.get_active_weapon().is_empty(),
		"get_active_weapon() must return empty dict when slot is empty [LPC-021]")


func test_weapon_swap_input_action_exists_lpc021():
	assert_true(InputMap.has_action("weapon_swap"),
		"weapon_swap input action must be defined [LPC-021]")


# ---------------------------------------------------------------------------
# [LPC-045] At launch, no off-hand system shall exist. All weapons main-hand only.
# ---------------------------------------------------------------------------

func test_no_offhand_slot_in_weapon_slots_lpc045():
	# weapon_slots is an Array[2], not a named "offhand" concept
	assert_eq(_inventory.weapon_slots.size(), 2,
		"weapon_slots must be exactly 2 — no off-hand third slot [LPC-045]")


func test_offhand_equip_slot_is_not_used_lpc045():
	# The legacy "offhand" equipped key must remain empty / not interact with weapon_slots
	_inventory.add_item("hunting_knife", 1)
	_inventory.equip_to_weapon_slot("hunting_knife", 0)
	assert_true(_inventory.equipped.get("offhand", {}).is_empty(),
		"equip_to_weapon_slot must not populate the offhand equipped slot [LPC-045]")
