## SnareTrap
## Placed by Survivalist Trapper ability. Checked on sleep for small game yield.
extends Node3D

var was_set: bool = false
var set_on_day: int = 0

@onready var trigger_area: Area3D = $TriggerArea
@onready var mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	add_to_group("snare_trap")
	was_set = true
	set_on_day = GameState.current_day


func check_harvest() -> Array:
	if not was_set:
		return []
	# Yield based on region difficulty (easier in east)
	var yield_count := randi_range(0, 2)
	if yield_count == 0:
		return []
	was_set = false
	var items := []
	for i in range(yield_count):
		items.append({ "item_id": "raw_meat", "count": 1 })
	DisciplineManager.add_xp("survivalist", "trap_check")
	# Re-set the trap
	was_set = true
	set_on_day = GameState.current_day
	return items
