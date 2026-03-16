## SettlementFlag
## The physical flag object planted in the world by the player.
## Tracks pending founding state and is destroyed if player dies before reporting.
extends Node3D

var area_id: String = ""
var purchased_at_settlement_id: String = ""
var is_pending_report: bool = true

@onready var flag_mesh: MeshInstance3D = $FlagMesh


func _ready() -> void:
	add_to_group("settlement_flag")


func initialize(in_area_id: String, purchased_at: String) -> void:
	area_id = in_area_id
	purchased_at_settlement_id = purchased_at
	is_pending_report = true


func on_player_returned_to_settlement(settlement_id: String) -> void:
	if settlement_id != purchased_at_settlement_id:
		return
	# Found! Trigger founding via settlement node
	var settlement_nodes := get_tree().get_nodes_in_group("settlement_node")
	for node in settlement_nodes:
		if node.settlement_id == purchased_at_settlement_id:
			node.report_flag_founding(area_id)
			break
	is_pending_report = false
	queue_free()


func destroy_on_player_death() -> void:
	# Called by Player on death
	queue_free()
