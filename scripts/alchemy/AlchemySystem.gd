## AlchemySystem
## Handles recipe lookup, ingredient validation, and brewing execution.
## Works at campfire (basic), alchemy set (advanced), and home workshop (all).
extends Node

enum Station { CAMPFIRE, ALCHEMY_SET, HOME_WORKSHOP, TOWN_ALCHEMIST }

signal brew_succeeded(recipe_id: String, output_item: String, count: int)
signal brew_failed(recipe_id: String, reason: String)


func can_brew(recipe_id: String, station: Station, player_inventory: PlayerInventory) -> bool:
	var recipe := GameData.get_recipe(recipe_id)
	if recipe.is_empty():
		return false
	if not _station_matches(recipe.get("station", "campfire"), station):
		return false
	var disc_req: String = recipe.get("discipline_required", "")
	if disc_req != "" and not _has_discipline_ability(disc_req):
		return false
	for ingredient in recipe.get("ingredients", []):
		if player_inventory.get_item_count(ingredient["item_id"]) < ingredient["count"]:
			return false
	return true


func brew(recipe_id: String, station: Station, player_inventory: PlayerInventory) -> bool:
	if not can_brew(recipe_id, station, player_inventory):
		brew_failed.emit(recipe_id, "Requirements not met")
		return false
	var recipe := GameData.get_recipe(recipe_id)
	# Consume ingredients
	for ingredient in recipe.get("ingredients", []):
		player_inventory.remove_item(ingredient["item_id"], ingredient["count"])
	# Add output
	var output_id: String = recipe.get("output_item", "")
	var output_count: int = recipe.get("output_count", 1)
	player_inventory.add_item(output_id, output_count)

	DisciplineManager.add_xp("alchemist", "potion_brewed")
	brew_succeeded.emit(recipe_id, output_id, output_count)
	return true


func get_available_recipes(station: Station, player_inventory: PlayerInventory) -> Array:
	var available := []
	for recipe_id in GameData.recipes:
		if can_brew(recipe_id, station, player_inventory):
			available.append(GameData.get_recipe(recipe_id))
	return available


func _station_matches(recipe_station: String, station: Station) -> bool:
	match recipe_station:
		"campfire":
			return station in [Station.CAMPFIRE, Station.ALCHEMY_SET, Station.HOME_WORKSHOP, Station.TOWN_ALCHEMIST]
		"alchemy_set":
			return station in [Station.ALCHEMY_SET, Station.HOME_WORKSHOP, Station.TOWN_ALCHEMIST]
		"camp":
			return station in [Station.ALCHEMY_SET, Station.HOME_WORKSHOP]
		_:
			return false


func _has_discipline_ability(ability_ref: String) -> bool:
	# Format: "discipline_id_ability_id" e.g. "artificer_ammo_smith"
	var parts := ability_ref.split("_", false, 1)
	if parts.size() < 2:
		return false
	# Try splitting as "discipline" + "_" + "ability"
	for disc_id in GameData.disciplines:
		if ability_ref.begins_with(disc_id + "_"):
			var ability_id := ability_ref.substr(disc_id.length() + 1)
			return DisciplineManager.is_ability_unlocked(disc_id, ability_id)
	return false
