## NPC
## Base class for all settlement NPCs. Handles interaction dispatch.
extends CharacterBody3D

enum NPCRole { BOSS, MAYOR, MERCHANT_GENERAL, MERCHANT_WEAPONS, MERCHANT_ARMOR,
               MERCHANT_ALCHEMY, BLACKSMITH, ENHANCER, INNKEEPER }

@export var npc_role: NPCRole = NPCRole.MERCHANT_GENERAL
@export var settlement_id: String = ""
@export var display_name: String = "Trader"

@onready var name_label: Label3D = $NameLabel
@onready var interact_prompt: Label3D = $InteractPrompt


func _ready() -> void:
	add_to_group("npc")
	if name_label:
		name_label.text = display_name


func interact(player: Node) -> void:
	match npc_role:
		NPCRole.BOSS:
			_interact_boss(player)
		NPCRole.MAYOR:
			_interact_mayor(player)
		NPCRole.MERCHANT_GENERAL:
			_open_shop("general", player)
		NPCRole.MERCHANT_WEAPONS:
			_open_shop("weapons", player)
		NPCRole.MERCHANT_ARMOR:
			_open_shop("armor", player)
		NPCRole.MERCHANT_ALCHEMY:
			_open_shop_and_crafting(player)
		NPCRole.BLACKSMITH:
			_open_shop("weapons", player)
		NPCRole.ENHANCER:
			_open_discipline_enhancer(player)
		NPCRole.INNKEEPER:
			_offer_sleep(player)
	# Track last settlement visited
	player.set_meta("last_settlement_visited", settlement_id)
	# Check pending flag reports
	_check_flag_report(player)


func _interact_boss(player: Node) -> void:
	# Trading Post boss sells flags and basic goods
	_open_shop("general", player)


func _interact_mayor(player: Node) -> void:
	# Village+ mayor sells flags and manages settlement info
	var ui := get_tree().get_first_node_in_group("settlement_ui")
	if ui and ui.has_method("show_settlement"):
		ui.show_settlement(settlement_id)


func _open_shop(shop_type: String, player: Node) -> void:
	var ui := get_tree().get_first_node_in_group("shop_ui")
	if ui and ui.has_method("open_shop"):
		ui.open_shop(settlement_id, shop_type)


func _open_shop_and_crafting(player: Node) -> void:
	_open_shop("reagents", player)
	var crafting_ui := get_tree().get_first_node_in_group("crafting_ui")
	if crafting_ui and crafting_ui.has_method("open"):
		crafting_ui.open(AlchemySystem.Station.TOWN_ALCHEMIST)


func _open_discipline_enhancer(player: Node) -> void:
	# Only available at Cities
	var s := SettlementManager.get_settlement(settlement_id)
	if s == null or s.tier_index < 3:
		return
	var ui := get_tree().get_first_node_in_group("discipline_ui")
	if ui and ui.has_method("toggle"):
		ui.toggle()


func _offer_sleep(player: Node) -> void:
	# Mark last rested settlement
	for sid in SettlementManager.settlements:
		var s: SettlementManager.SettlementData = SettlementManager.settlements[sid]
		s.last_rested_here = (sid == settlement_id)
	player._do_sleep()


func _check_flag_report(player: Node) -> void:
	var flags := get_tree().get_nodes_in_group("settlement_flag")
	for flag in flags:
		if flag.has_method("on_player_returned_to_settlement"):
			flag.on_player_returned_to_settlement(settlement_id)
