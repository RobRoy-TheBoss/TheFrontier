## CompassBar
## Scrolling compass tape drawn via _draw().
## Set heading_deg each frame and call queue_redraw().
extends Control

var heading_deg: float = 0.0

const DEGREES_VISIBLE := 90.0  # total degrees shown across the full width

const CARDINALS := {
	0: "N", 45: "NE", 90: "E", 135: "SE",
	180: "S", 225: "SW", 270: "W", 315: "NW",
}

func _draw() -> void:
	var w := size.x
	var h := size.y
	var cx := w * 0.5
	var px_per_deg := w / DEGREES_VISIBLE

	var font      := ThemeDB.fallback_font
	var font_size := 13

	# Draw ticks from nearest multiple of 5 below left edge to right edge
	var start_d: float = floor((heading_deg - DEGREES_VISIBLE * 0.5) / 5.0) * 5.0
	var end_d: float   = ceil((heading_deg + DEGREES_VISIBLE * 0.5) / 5.0) * 5.0

	var d := start_d
	while d <= end_d:
		var x       := cx + (d - heading_deg) * px_per_deg
		var norm    := roundi(fposmod(d, 360.0))
		var mod45   := norm % 45 == 0
		var mod15   := roundi(fposmod(d, 15.0)) == 0

		if mod45:
			draw_line(Vector2(x, 0), Vector2(x, h * 0.55), Color(1.0, 0.95, 0.7), 2.0)
			var label: String = CARDINALS.get(norm, "")
			if label != "":
				var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
				draw_string(font, Vector2(x - tw * 0.5, h - 4), label,
					HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 0.95, 0.7))
		elif mod15:
			draw_line(Vector2(x, h * 0.2), Vector2(x, h * 0.55), Color(1.0, 0.95, 0.7, 0.75), 1.5)
			var deg_label := "%d" % norm
			var dlw := font.get_string_size(deg_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			draw_string(font, Vector2(x - dlw * 0.5, h - 4), deg_label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 0.95, 0.7, 0.65))
		else:
			draw_line(Vector2(x, h * 0.38), Vector2(x, h * 0.55), Color(1.0, 0.95, 0.7, 0.4), 1.0)

		d += 5.0
