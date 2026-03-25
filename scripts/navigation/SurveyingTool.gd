## SurveyingTool
## Handles the three surveying tools: naked eye, spyglass, theodolite.
## Extends effective visual range for resource discovery.
class_name SurveyingTool
extends Node

enum SurveyTool { NAKED_EYE, SPYGLASS, THEODOLITE }

const NAKED_EYE_RANGE := 15.0
const SPYGLASS_RANGE := 50.0
const THEODOLITE_RANGE := 120.0

var _active_tool: SurveyTool = SurveyTool.NAKED_EYE
var _player: Node = null


func _ready() -> void:
	await get_tree().process_frame
	_player = get_parent()


func get_survey_range() -> float:
	match _active_tool:
		SurveyTool.NAKED_EYE:
			return NAKED_EYE_RANGE
		SurveyTool.SPYGLASS:
			return SPYGLASS_RANGE
		SurveyTool.THEODOLITE:
			return THEODOLITE_RANGE
	return NAKED_EYE_RANGE


func set_active_tool(tool: SurveyTool) -> void:
	_active_tool = tool


func try_upgrade_tool() -> void:
	if _player == null:
		return
	var inventory: PlayerInventory = _player.inventory
	if inventory.has_item("theodolite"):
		_active_tool = SurveyTool.THEODOLITE
	elif inventory.has_item("spyglass"):
		_active_tool = SurveyTool.SPYGLASS
	else:
		_active_tool = SurveyTool.NAKED_EYE


func survey_area(area_id: String) -> void:
	# Check resources within survey range
	var resource_nodes := get_tree().get_nodes_in_group("resource_node")
	for node in resource_nodes:
		if not is_instance_valid(node):
			continue
		var dist: float = node.global_position.distance_to(_player.global_position)
		if dist <= get_survey_range():
			if node.has_method("interact"):
				# Auto-discover resource
				WorldManager.log_resource_discovery(area_id, node.resource_id, node.richness)
