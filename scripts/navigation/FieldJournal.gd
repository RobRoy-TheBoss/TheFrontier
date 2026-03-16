## FieldJournal
## Manages all journal entries: creature observations, ingredient notes,
## precursor site records, and freeform player notes.
extends Node

signal entry_added(entry: Dictionary)

var entries: Array = []

enum EntryType { CREATURE, INGREDIENT, PRECURSOR_SITE, PLACE_OF_POWER, NOTE, RESOURCE, LANDMARK }


func _ready() -> void:
	add_to_group("field_journal")


func record_creature(monster_id: String, observation: String = "") -> void:
	if _has_entry(EntryType.CREATURE, monster_id):
		return
	var monster := GameData.get_monster(monster_id)
	var entry := {
		"type": EntryType.CREATURE,
		"id": monster_id,
		"name": monster.get("name", monster_id),
		"description": monster.get("description", ""),
		"observation": observation,
		"day": GameState.current_day
	}
	entries.append(entry)
	entry_added.emit(entry)


func record_ingredient(resource_id: String, notes: String = "") -> void:
	if _has_entry(EntryType.INGREDIENT, resource_id):
		return
	var entry := {
		"type": EntryType.INGREDIENT,
		"id": resource_id,
		"notes": notes,
		"day": GameState.current_day
	}
	entries.append(entry)
	entry_added.emit(entry)


func record_site(site_id: String, entry_type: String, discipline_id: String = "") -> void:
	var type := EntryType.PLACE_OF_POWER if entry_type == "place_of_power" else EntryType.PRECURSOR_SITE
	if _has_entry(type, site_id):
		return
	var entry := {
		"type": type,
		"id": site_id,
		"discipline_id": discipline_id,
		"area_id": GameState.current_area_id,
		"day": GameState.current_day,
		"position": { "x": 0, "y": 0, "z": 0 }  # Set by PrecursorSite
	}
	entries.append(entry)
	entry_added.emit(entry)


func add_note(title: String, body: String) -> void:
	var entry := {
		"type": EntryType.NOTE,
		"title": title,
		"body": body,
		"day": GameState.current_day,
		"area_id": GameState.current_area_id
	}
	entries.append(entry)
	entry_added.emit(entry)


func record_resource(resource_id: String, area_id: String, richness: float) -> void:
	var entry := {
		"type": EntryType.RESOURCE,
		"id": resource_id,
		"area_id": area_id,
		"richness": richness,
		"day": GameState.current_day
	}
	entries.append(entry)
	entry_added.emit(entry)


func record_landmark(landmark_id: String, player_name: String, position: Vector3) -> void:
	var entry := {
		"type": EntryType.LANDMARK,
		"id": landmark_id,
		"name": player_name,
		"position": { "x": position.x, "y": position.y, "z": position.z },
		"day": GameState.current_day
	}
	entries.append(entry)
	entry_added.emit(entry)


func get_entries_of_type(type: EntryType) -> Array:
	return entries.filter(func(e): return e["type"] == type)


func _has_entry(type: EntryType, id: String) -> bool:
	for e in entries:
		if e["type"] == type and e.get("id", "") == id:
			return true
	return false


func get_save_data() -> Array:
	return entries.duplicate(true)


func apply_save_data(data: Array) -> void:
	entries = data.duplicate(true)
