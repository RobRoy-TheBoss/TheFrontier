## HexMapLoader
## Reads a map JSON and instantiates hex Area tiles at runtime.
##
## Grid → world position formula:
##   world_x = col * 300
##   world_z = row * 346 + (173 if abs(col) is odd)
##   world_y = elevation * 5
##
## Rotation is in degrees around the Y axis.
## Elevation: 1 = 5 m, 2 = 10 m, etc.
extends Node3D

const COL_STEP   := 300
const ROW_STEP   := 346
const ODD_OFFSET := 173
const ELEV_STEP  := 5.0

const AREA_SCENE          := preload("res://scenes/world/Area.tscn")
const TERRAIN_LOADER_SCRIPT := preload("res://scripts/world/HexTerrainLoader.gd")

@export var bake_all_areas: bool = false:
	set(v):
		bake_all_areas = false
		if v:
			call_deferred(&"_do_bake_all")

@export var clear_all_bakes: bool = false:
	set(v):
		clear_all_bakes = false
		if v:
			call_deferred(&"_do_clear_all")

func _do_bake_all() -> void:
	for area in get_children():
		var loader := area.get_node_or_null("HexTerrainLoader")
		if loader:
			loader._bake()
	print("HexMapLoader: all areas baked.")

func _do_clear_all() -> void:
	for area in get_children():
		var loader := area.get_node_or_null("HexTerrainLoader")
		if loader:
			loader._clear()
	print("HexMapLoader: all bakes cleared.")

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var map_path := "res://data/maps/%s.json" % WorldManager.current_map_id
	var file := FileAccess.open(map_path, FileAccess.READ)
	if file == null:
		push_error("HexMapLoader: cannot open %s" % map_path)
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if not data is Dictionary or not data.has("tiles"):
		push_error("HexMapLoader: invalid JSON — missing 'tiles' array")
		return
	for tile in data["tiles"]:
		_spawn(tile)


func _spawn(tile: Dictionary) -> void:
	var col: int       = int(tile["col"])
	var row: int       = int(tile["row"])
	var mesh: String   = tile["mesh"]
	var facing: int    = int(tile.get("facing", 0))
	var elevation: int = int(tile.get("elevation", 2))

	var wx := col * COL_STEP
	var wy := elevation * ELEV_STEP
	var wz := row * ROW_STEP + (ODD_OFFSET if absi(col) % 2 == 1 else 0)
	var rot_rad := -deg_to_rad(facing * 60.0)  # clockwise, 0=0° 1=60° ... 5=300°

	var area := AREA_SCENE.instantiate()
	area.name = "%d_%d" % [col, row]
	area.transform = Transform3D(Basis(Vector3.UP, rot_rad), Vector3(wx, wy, wz))
	area.set("area_id",     "%d_%d_%s" % [col, row, mesh.get_basename()])
	area.set("area_bounds", Vector3(360, 20, 360))
	# Derive spawn table and biome from hex template via mesh filename
	var hex_template: Dictionary = DataLoader.get_hex_template_for_mesh(mesh)
	area.set("biome", hex_template.get("biome_type", "forest"))
	var spawn_entries: Array = hex_template.get("spawn_entries", [])
	if not spawn_entries.is_empty():
		area.set("spawn_table", spawn_entries)
	add_child(area)

	var loader := Node.new()
	loader.name = "HexTerrainLoader"
	loader.set_script(TERRAIN_LOADER_SCRIPT)
	loader.set("terrain_mesh_path", "res://assets/terrain/" + mesh)
	area.add_child(loader)
