## CraftingUI
## Shared crafting interface for campfire, alchemy set, home workshop, and town alchemist.
extends Control

@onready var station_label: Label = $Panel/StationLabel
@onready var recipe_list: VBoxContainer = $Panel/RecipeList
@onready var ingredient_list: VBoxContainer = $Panel/IngredientList
@onready var brew_button: Button = $Panel/BrewButton
@onready var close_button: Button = $Panel/CloseButton

var _station: AlchemySystem.Station = AlchemySystem.Station.CAMPFIRE
var _selected_recipe_id: String = ""
var _filtered_recipe_ids: Array = []
var _alchemy_system: AlchemySystem = null
var _player: Node = null


func _ready() -> void:
	add_to_group("crafting_ui")
	_alchemy_system = AlchemySystem.new()
	if brew_button:
		brew_button.pressed.connect(_on_brew_pressed)
	if close_button:
		close_button.pressed.connect(_close)
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")


func open(station: AlchemySystem.Station) -> void:
	_station = station
	_filtered_recipe_ids = []
	visible = true
	GameState.is_paused_for_ui = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_refresh()


func show_recipes(recipe_ids: Array) -> void:
	_filtered_recipe_ids = recipe_ids
	open(_station)


func _refresh() -> void:
	if _player == null:
		return
	if station_label:
		match _station:
			AlchemySystem.Station.CAMPFIRE: station_label.text = "Campfire"
			AlchemySystem.Station.ALCHEMY_SET: station_label.text = "Alchemy Set"
			AlchemySystem.Station.HOME_WORKSHOP: station_label.text = "Home Workshop"
			AlchemySystem.Station.TOWN_ALCHEMIST: station_label.text = "Town Alchemist"
	_populate_recipes()


func _populate_recipes() -> void:
	if recipe_list == null:
		return
	for child in recipe_list.get_children():
		child.queue_free()

	var recipes_to_show: Array
	if _filtered_recipe_ids.is_empty():
		recipes_to_show = _alchemy_system.get_available_recipes(_station, _player.inventory)
	else:
		recipes_to_show = []
		for rid in _filtered_recipe_ids:
			var r := GameData.get_recipe(rid)
			if not r.is_empty():
				recipes_to_show.append(r)

	for recipe in recipes_to_show:
		var row := HBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = recipe.get("name", recipe.get("id", "?"))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var out_lbl := Label.new()
		out_lbl.text = "→ %s x%d" % [recipe.get("output_item", "?"), recipe.get("output_count", 1)]
		var can_make := _alchemy_system.can_brew(recipe.get("id", ""), _station, _player.inventory)
		var select_btn := Button.new()
		select_btn.text = "Craft"
		select_btn.disabled = not can_make
		var captured_id: String = recipe.get("id", "")
		select_btn.pressed.connect(func(): _select_and_brew(captured_id))
		row.add_child(name_lbl)
		row.add_child(out_lbl)
		row.add_child(select_btn)
		recipe_list.add_child(row)
		# Show ingredients
		var ing_row := HBoxContainer.new()
		for ing in recipe.get("ingredients", []):
			var have: int = _player.inventory.get_item_count(ing["item_id"])
			var need: int = ing["count"]
			var ing_lbl := Label.new()
			ing_lbl.text = "%s %d/%d  " % [ing["item_id"], have, need]
			ing_lbl.add_theme_color_override("font_color", Color.GREEN if have >= need else Color.RED)
			ing_lbl.add_theme_font_size_override("font_size", 10)
			ing_row.add_child(ing_lbl)
		recipe_list.add_child(ing_row)


func _select_and_brew(recipe_id: String) -> void:
	if _player == null:
		return
	if _alchemy_system.brew(recipe_id, _station, _player.inventory):
		_refresh()


func _on_brew_pressed() -> void:
	_select_and_brew(_selected_recipe_id)


func _close() -> void:
	visible = false
	GameState.is_paused_for_ui = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
