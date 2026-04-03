## HexMapCanvas
## Draws discovered hex tiles as a top-down flat-top hex grid.
## Set tile_entries and call queue_redraw() to refresh.
extends Control

# Array of { col, row, mesh, discovered }
var tile_entries: Array = []

const COL_STEP   := 300.0
const ROW_STEP   := 346.0
const ODD_OFFSET := 173.0
const HEX_R      := 200.0  # world-space circumradius
const PADDING     := 1.2    # extra space around the tile bounds

# Colour by mesh prefix
const MESH_COLORS := {
	"River":   Color(0.25, 0.55, 0.85, 1.0),
	"Costal":  Color(0.20, 0.70, 0.75, 1.0),
	"Hills":   Color(0.40, 0.65, 0.30, 1.0),
	"Mountain":Color(0.55, 0.50, 0.45, 1.0),
	"Plateau": Color(0.70, 0.65, 0.40, 1.0),
}
const COLOR_DEFAULT    := Color(0.45, 0.55, 0.40, 1.0)
const COLOR_UNDISCOVERED := Color(0.15, 0.15, 0.15, 0.0)  # fully transparent


func _draw() -> void:
	if tile_entries.is_empty():
		return

	var scale_factor := _compute_scale()
	var offset       := _compute_offset(scale_factor)

	for entry in tile_entries:
		if not entry.get("discovered", false):
			continue
		var center := _tile_screen_pos(entry["col"], entry["row"], scale_factor, offset)
		var r      := HEX_R * scale_factor
		var color  := _mesh_color(entry.get("mesh", ""))
		draw_colored_polygon(_hex_points(center, r), color)
		draw_polyline(_hex_points(center, r) + PackedVector2Array([_hex_points(center, r)[0]]),
			color.darkened(0.3), 1.5)


func _hex_points(center: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(6):
		var angle := deg_to_rad(60.0 * i)
		pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	return pts


func _tile_screen_pos(col: int, row: int, scale_factor: float, offset: Vector2) -> Vector2:
	var wx: float = col * COL_STEP
	var wz: float = row * ROW_STEP + (ODD_OFFSET if absi(col) % 2 == 1 else 0)
	return Vector2(wx * scale_factor, wz * scale_factor) + offset


func _compute_scale() -> float:
	var min_x :=  INF; var max_x := -INF
	var min_z :=  INF; var max_z := -INF
	for entry in tile_entries:
		var wx: float = entry["col"] * COL_STEP
		var wz: float = entry["row"] * ROW_STEP + (ODD_OFFSET if absi(int(entry["col"])) % 2 == 1 else 0)
		min_x = minf(min_x, wx); max_x = maxf(max_x, wx)
		min_z = minf(min_z, wz); max_z = maxf(max_z, wz)
	var world_w := (max_x - min_x + HEX_R * 2.0) * PADDING
	var world_h := (max_z - min_z + HEX_R * 2.0) * PADDING
	if world_w == 0 or world_h == 0:
		return 1.0
	return minf(size.x / world_w, size.y / world_h)


func _compute_offset(scale_factor: float) -> Vector2:
	var min_x :=  INF; var min_z :=  INF
	for entry in tile_entries:
		var wx: float = entry["col"] * COL_STEP
		var wz: float = entry["row"] * ROW_STEP + (ODD_OFFSET if absi(int(entry["col"])) % 2 == 1 else 0)
		min_x = minf(min_x, wx); min_z = minf(min_z, wz)
	var content_w := 0.0; var content_h := 0.0
	for entry in tile_entries:
		var wx: float = entry["col"] * COL_STEP
		var wz: float = entry["row"] * ROW_STEP + (ODD_OFFSET if absi(int(entry["col"])) % 2 == 1 else 0)
		content_w = maxf(content_w, (wx - min_x) * scale_factor)
		content_h = maxf(content_h, (wz - min_z) * scale_factor)
	var pad_x := (size.x - content_w) * 0.5
	var pad_z := (size.y - content_h) * 0.5
	return Vector2(pad_x - min_x * scale_factor, pad_z - min_z * scale_factor)


func _mesh_color(mesh: String) -> Color:
	for prefix in MESH_COLORS:
		if mesh.begins_with(prefix):
			return MESH_COLORS[prefix]
	return COLOR_DEFAULT
