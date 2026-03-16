## PrecursorSite
## Represents a precursor ruin or Place of Power.
## Type (discipline) is unknown until visited, assigned by WorldManager from world seed.
extends Node3D

@export var site_id: String = "precursor_site_00"
@export var is_place_of_power: bool = false  # Determined at runtime by WorldManager

var _discovered: bool = false
var _discipline_id: String = ""


func _ready() -> void:
	add_to_group("precursor_site")
	# Resolve discipline from world randomization
	_discipline_id = GameState.get_precursor_assignment(site_id)
	is_place_of_power = (_discipline_id != "")


func interact(player: Node) -> void:
	if not _discovered:
		_on_discovered(player)

	if is_place_of_power:
		_show_attunement_prompt(player)
	else:
		_show_ruin_ui(player)

	DisciplineManager.add_xp("ritualist", "precursor_site_visited")
	DisciplineManager.add_xp("survivalist", "off_road_travel_km")


func _on_discovered(player: Node) -> void:
	_discovered = true
	WorldManager.discover_precursor_site(site_id)
	# Add to field journal
	var journal := get_tree().get_first_node_in_group("field_journal")
	if journal and journal.has_method("record_site"):
		var entry_type := "place_of_power" if is_place_of_power else "ruin"
		journal.record_site(site_id, entry_type, _discipline_id)


func _show_attunement_prompt(player: Node) -> void:
	var ui := get_tree().get_first_node_in_group("attunement_ui")
	if ui and ui.has_method("show_prompt"):
		ui.show_prompt(site_id, _discipline_id, self)


func _show_ruin_ui(player: Node) -> void:
	# Show generic ruin description, possible loot
	pass


func attempt_attunement(player: Node) -> bool:
	return WorldManager.attune_to_site(site_id)
