## MapTileBaker
## Renders each terrain mesh from directly above using an orthographic camera
## and saves a 256×256 PNG to user://map_tiles/{MeshName}.png.
##
## Usage:
##   1. Attach to any node in the scene.
##   2. Tick "Bake Tile Images" in the Inspector while the game is running.
##   3. Find the PNGs via: Project → Open User Data Folder → map_tiles/
##   4. Copy them to res://data/map_tiles/ and commit.
extends Node

@export var bake_tile_images: bool = false:
	set(v):
		bake_tile_images = false
		if v:
			call_deferred(&"_bake_all")

const TILE_SIZE     := Vector2i(256, 256)
const CAM_HEIGHT    := 300.0
const ORTHO_SIZE    := 430.0   # world units visible across the viewport (hex diameter + padding)
const OUT_DIR       := "user://map_tiles"
const HEX_R_WORLD  := 200.0  # circumradius in world units, must match HexAssetScatterer


func _bake_all() -> void:
	DirAccess.make_dir_absolute(OUT_DIR)

	# Collect unique mesh paths from the current map JSON
	var map_path := "res://data/maps/%s.json" % WorldManager.current_map_id
	var file := FileAccess.open(map_path, FileAccess.READ)
	if file == null:
		push_error("MapTileBaker: cannot open %s" % map_path)
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if not data is Dictionary or not data.has("tiles"):
		return

	var seen: Dictionary = {}
	for tile in data["tiles"]:
		var mesh: String = tile.get("mesh", "")
		if mesh != "" and not seen.has(mesh):
			seen[mesh] = true

	print("MapTileBaker: baking %d unique meshes…" % seen.size())
	for mesh in seen:
		await _bake_mesh("res://assets/terrain/" + mesh)
	print("MapTileBaker: done. Files in: ", OUT_DIR)


func _bake_mesh(mesh_path: String) -> void:
	var packed := load(mesh_path) as PackedScene
	if packed == null:
		push_error("MapTileBaker: cannot load %s" % mesh_path)
		return

	# Build an isolated SubViewport with its own world so main scene geometry
	# doesn't bleed in
	var vp := SubViewport.new()
	vp.size = TILE_SIZE
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	# Top-down orthographic camera
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = ORTHO_SIZE
	cam.position = Vector3(0.0, CAM_HEIGHT, 0.0)
	cam.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	vp.add_child(cam)

	# Simple directional light so the mesh isn't flat-lit
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55.0, 45.0, 0.0)
	light.light_energy = 1.2
	vp.add_child(light)

	var mesh_inst := packed.instantiate()
	vp.add_child(mesh_inst)

	# Flat water plane at the correct relative height (world water Y=8.5, tile Y=10.0)
	var water_plane := PlaneMesh.new()
	water_plane.size = Vector2(ORTHO_SIZE, ORTHO_SIZE)
	var water_mat := StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.06, 0.28, 0.55, 1.0)
	water_plane.surface_set_material(0, water_mat)
	var water_mi := MeshInstance3D.new()
	water_mi.mesh = water_plane
	water_mi.position = Vector3(0.0, -1.5, 0.0)
	vp.add_child(water_mi)

	# Wait two frames: one to process, one to render
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	var image := vp.get_texture().get_image()
	_apply_hex_mask(image)
	_apply_map_style(image)
	var name   := mesh_path.get_file().get_basename()
	var out    := "%s/%s.png" % [OUT_DIR, name]
	image.save_png(out)
	print("  saved: ", out)

	vp.queue_free()


func _apply_hex_mask(image: Image) -> void:
	var w  := image.get_width()
	var h  := image.get_height()
	var cx := w / 2.0
	var cy := h / 2.0
	# Hex circumradius in pixels, scaled from world units
	var R_px: float = float(w) * HEX_R_WORLD / ORTHO_SIZE + 10.0  # +2px to close sub-pixel gaps between tiles
	for y in range(h):
		for x in range(w):
			if not _point_in_hex(float(x) - cx, float(y) - cy, R_px):
				image.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))


# Regular hexagon test with vertices at 0°,60°,120°,180°,240°,300°.
# Returns true if (px,py) is inside a hex of circumradius R centered at origin.
func _point_in_hex(px: float, py: float, R: float) -> bool:
	var ax := absf(px)
	var ay := absf(py)
	if ay > R * 0.866025:           # outside flat top/bottom edges
		return false
	if ax * 0.866025 + ay * 0.5 > R * 0.866025:  # outside diagonal edges
		return false
	return true


func _apply_map_style(image: Image) -> void:
	_box_blur(image, 2)
	_greyscale_tint(image)


# Simple box blur — only samples opaque pixels so it doesn't bleed outside the hex mask.
func _box_blur(image: Image, radius: int) -> void:
	var w := image.get_width()
	var h := image.get_height()
	var src := image.duplicate()
	for y in range(h):
		for x in range(w):
			if src.get_pixel(x, y).a < 0.01:
				continue
			var sum := Color(0.0, 0.0, 0.0, 0.0)
			var count := 0
			for dy in range(-radius, radius + 1):
				for dx in range(-radius, radius + 1):
					var nx := x + dx
					var ny := y + dy
					if nx >= 0 and nx < w and ny >= 0 and ny < h:
						var p := src.get_pixel(nx, ny)
						if p.a > 0.01:
							sum += p
							count += 1
			if count > 0:
				image.set_pixel(x, y, sum / float(count))


# Converts to greyscale then applies a parchment tint.
# Tune TINT to shift the colour cast.
func _greyscale_tint(image: Image) -> void:
	# Warm parchment tint — tweak these to taste
	const TINT := Color(0.82, 0.70, 0.48, 1.0)
	var w := image.get_width()
	var h := image.get_height()
	for y in range(h):
		for x in range(w):
			var c := image.get_pixel(x, y)
			if c.a < 0.01:
				continue
			var grey: float = c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			image.set_pixel(x, y, Color(
				grey * TINT.r,
				grey * TINT.g,
				grey * TINT.b,
				c.a
			))
