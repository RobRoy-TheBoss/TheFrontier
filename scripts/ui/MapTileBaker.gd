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

const TILE_SIZE    := Vector2i(256, 256)
const CAM_HEIGHT   := 300.0
const ORTHO_SIZE   := 430.0   # world units visible across the viewport (hex diameter + padding)
const OUT_DIR      := "user://map_tiles"
const HEX_R_WORLD := 200.0   # circumradius in world units, must match HexAssetScatterer

# Height range for the height-map pass (model-space Y).
const Y_MIN := -2.0
const Y_MAX :=  8.0

# Radius (in pixels) over which to sum elevation change.
const RELIEF_RADIUS := 4

# How strongly accumulated relief darkens pixels. Tune after baking.
const GRADIENT_SCALE := 4.0

# Relief below this value is ignored (suppresses micro-detail noise).
const GRADIENT_THRESHOLD := 0.01

const HEIGHTMAP_SHADER := "
shader_type spatial;
render_mode unshaded;
uniform float y_min = -2.0;
uniform float y_max = 8.0;
void fragment() {
	float world_y = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).y;
	float t = clamp((world_y - y_min) / (y_max - y_min), 0.0, 1.0);
	ALBEDO = vec3(t);
	ALPHA = 1.0;
}
"


func _bake_all() -> void:
	DirAccess.make_dir_absolute(OUT_DIR)

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

	# Isolated SubViewport so main scene geometry doesn't bleed in
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

	var mesh_inst := packed.instantiate()
	vp.add_child(mesh_inst)

	# Override every mesh surface with the height shader
	var shader := Shader.new()
	shader.code = HEIGHTMAP_SHADER
	var height_mat := ShaderMaterial.new()
	height_mat.shader = shader
	height_mat.set_shader_parameter("y_min", Y_MIN)
	height_mat.set_shader_parameter("y_max", Y_MAX)
	_apply_material_recursive(mesh_inst, height_mat)

	# Wait two frames: one to process, one to render
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	var image := vp.get_texture().get_image()
	_apply_hex_mask(image)
	_apply_gradient_shading(image)
	_apply_sepia(image)
	var name := mesh_path.get_file().get_basename()
	var out  := "%s/%s.png" % [OUT_DIR, name]
	image.save_png(out)
	print("  saved: ", out)

	vp.queue_free()


func _apply_material_recursive(node: Node, mat: ShaderMaterial) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			for i in mi.mesh.get_surface_count():
				mi.set_surface_override_material(i, mat)
	for child in node.get_children():
		_apply_material_recursive(child, mat)


func _apply_hex_mask(image: Image) -> void:
	var w  := image.get_width()
	var h  := image.get_height()
	var cx := w / 2.0
	var cy := h / 2.0
	var R_px: float = float(w) * HEX_R_WORLD / ORTHO_SIZE - 1.0
	for y in range(h):
		for x in range(w):
			if not _point_in_hex(float(x) - cx, float(y) - cy, R_px):
				image.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))


func _point_in_hex(px: float, py: float, R: float) -> bool:
	var ax := absf(px)
	var ay := absf(py)
	if ay > R * 0.866025:
		return false
	if ax * 0.866025 + ay * 0.5 > R * 0.866025:
		return false
	return true


# Converts the raw height map into relief-shaded greyscale.
# Sums absolute height differences between centre and all pixels within
# RELIEF_RADIUS — flat areas stay bright, rough/hilly areas go dark.
func _apply_gradient_shading(image: Image) -> void:
	var src := image.duplicate()
	var w := image.get_width()
	var h := image.get_height()
	for y in range(h):
		for x in range(w):
			var c: Color = src.get_pixel(x, y)
			if c.a < 0.01:
				continue
			var centre_h := c.r
			var relief := 0.0
			var count := 0
			for dy in range(-RELIEF_RADIUS, RELIEF_RADIUS + 1):
				for dx in range(-RELIEF_RADIUS, RELIEF_RADIUS + 1):
					if dx == 0 and dy == 0:
						continue
					var nx := clampi(x + dx, 0, w - 1)
					var ny := clampi(y + dy, 0, h - 1)
					var n: Color = src.get_pixel(nx, ny)
					if n.a > 0.01:
						relief += absf(n.r - centre_h)
						count += 1
			if count > 0:
				relief /= float(count)
			var relief_filtered := maxf(relief - GRADIENT_THRESHOLD, 0.0)
			var brightness := 1.0 - clampf(relief_filtered * GRADIENT_SCALE, 0.0, 1.0)
			image.set_pixel(x, y, Color(brightness, brightness, brightness, c.a))


func _apply_sepia(image: Image) -> void:
	const TINT := Color(0.96, 0.90, 0.52, 1.0)
	var w := image.get_width()
	var h := image.get_height()
	for y in range(h):
		for x in range(w):
			var c := image.get_pixel(x, y)
			if c.a < 0.01:
				continue
			image.set_pixel(x, y, Color(c.r * TINT.r, c.r * TINT.g, c.r * TINT.b, c.a))
