## CombatManager
## Autoload singleton. Tracks player combat state — whether monsters are
## actively targeting the player, manages combat-start/end events, and
## tracks per-combat arrow expenditure.
## LLR: LCBT-001..004
extends Node

# Set of monster IDs currently targeting the player
var targeting_monsters: Array = []
var in_combat: bool = false
var arrows_fired_this_combat: int = 0

signal combat_started
signal combat_ended


func _ready() -> void:
	pass


## Call when a monster begins targeting the player.
func on_monster_target(monster_id: String) -> void:
	if monster_id not in targeting_monsters:
		var was_in_combat := in_combat
		targeting_monsters.append(monster_id)
		in_combat = targeting_monsters.size() > 0
		if in_combat and not was_in_combat:
			arrows_fired_this_combat = 0
			emit_signal("combat_started")


## Call when a monster stops targeting the player (dead, fled, out of range).
func on_monster_disengage(monster_id: String) -> void:
	targeting_monsters.erase(monster_id)
	if targeting_monsters.is_empty() and in_combat:
		in_combat = false
		emit_signal("combat_ended")


## Register an arrow fired during combat.
func register_arrow_fired() -> void:
	if in_combat:
		arrows_fired_this_combat += 1


## Force-clear combat state (e.g., on player death or area transition).
func clear_combat() -> void:
	var was_in_combat := in_combat
	targeting_monsters.clear()
	in_combat = false
	arrows_fired_this_combat = 0
	if was_in_combat:
		emit_signal("combat_ended")
