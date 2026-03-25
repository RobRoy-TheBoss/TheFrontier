## CrestportTown
## Procedurally builds the town of Crestport Bay using Kenney fantasy town kit assets.
## Piece size assumed: 1m wide × 1m tall (FBX imports at half the nominal 2m grid).
## All wall rings use half-integer piece centers on a 1m step.
extends Node3D

const _B := "res://assets/models/kenney_fantasy-town-kit/Models/FBX format/"

var _assets := {}


func _ready() -> void:
	_load_assets()
	_build_roads()
	_build_market_square()
	_build_buildings()
	_build_dock()
	_place_windmill()
	_build_forest_ring()
	_scatter_rocks()


func _load_assets() -> void:
	var keys := {
		"wall":           "wall.fbx",
		"wall_wood":      "wall-wood.fbx",
		"wall_corner":    "wall-corner.fbx",
		"wall_corner_wd": "wall-wood-corner.fbx",
		"wall_win":       "wall-window-glass.fbx",
		"wall_win_wd":    "wall-wood-window-shutters.fbx",
		"wall_door":      "wall-door.fbx",
		"wall_door_wd":   "wall-wood-door.fbx",
		"roof_gable":     "roof-gable.fbx",
		"roof_gable_end": "roof-gable-end.fbx",
		"roof_corner":    "roof-corner.fbx",
		"roof_gable_top": "roof-gable-top.fbx",
		"stall":          "stall.fbx",
		"stall_green":    "stall-green.fbx",
		"stall_red":      "stall-red.fbx",
		"fountain":       "fountain-round.fbx",
		"lantern":        "lantern.fbx",
		"road":           "road.fbx",
		"planks":         "planks.fbx",
		"tree":           "tree.fbx",
		"tree_high":      "tree-high.fbx",
		"tree_round":     "tree-high-round.fbx",
		"tree_crooked":   "tree-crooked.fbx",
		"rock_large":     "rock-large.fbx",
		"rock_small":     "rock-small.fbx",
		"chimney":        "chimney.fbx",
		"cart":           "cart.fbx",
		"windmill":       "windmill.fbx",
		"banner_red":     "banner-red.fbx",
		"banner_green":   "banner-green.fbx",
		"pillar":         "pillar-stone.fbx",
	}
	for k in keys:
		_assets[k] = load(_B + keys[k])


func _p(key: String, pos: Vector3, rot_y: float = 0.0, parent: Node3D = null) -> Node3D:
	var scene: PackedScene = _assets.get(key)
	if scene == null:
		return null
	var n: Node3D = scene.instantiate()
	n.position = pos
	n.rotation.y = rot_y
	(parent if parent else self).add_child(n)
	return n


# ---------------------------------------------------------------------------
# Roads  (1 m tiles)
# ---------------------------------------------------------------------------

func _build_roads() -> void:
	# North-south spine, 4 tiles wide, from spawn southward to chapel
	var iz := -15.0
	while iz >= -112.0:
		for ix in [-1.5, -0.5, 0.5, 1.5]:
			_p("road", Vector3(ix, 0, iz))
		iz -= 1.0

	# East-west cross road at market level z ≈ -55
	var ix := -30.0
	while ix <= 30.0:
		if abs(ix) > 2.0:
			_p("road", Vector3(ix, 0, -55.5), PI / 2.0)
			_p("road", Vector3(ix, 0, -56.5), PI / 2.0)
		ix += 1.0

	# Cross road at hall level z ≈ -86
	ix = -22.0
	while ix <= 22.0:
		if abs(ix) > 2.0:
			_p("road", Vector3(ix, 0, -86.5), PI / 2.0)
			_p("road", Vector3(ix, 0, -87.5), PI / 2.0)
		ix += 1.0


# ---------------------------------------------------------------------------
# Market square
# ---------------------------------------------------------------------------

func _build_market_square() -> void:
	_p("fountain", Vector3(0, 0, -55))

	_p("stall_green", Vector3(-10, 0, -55),  PI / 2.0)
	_p("stall_red",   Vector3( 10, 0, -55), -PI / 2.0)
	_p("stall",       Vector3( -6, 0, -46),  PI)
	_p("stall_green", Vector3(  0, 0, -46),  PI)
	_p("stall_red",   Vector3(  6, 0, -46),  PI)
	_p("stall",       Vector3(  0, 0, -64))
	_p("stall_green", Vector3( -5, 0, -64))
	_p("stall_red",   Vector3(  5, 0, -64))

	_p("cart", Vector3(-7, 0, -51),  PI / 5.0)
	_p("cart", Vector3( 8, 0, -59), -PI / 4.0)

	_p("banner_red",   Vector3(-22, 1.5, -66))
	_p("banner_green", Vector3( 22, 1.5, -66))

	# Lantern pillars at square corners
	for cx: float in [-12.0, 12.0]:
		for cz: float in [-44.0, -66.0]:
			_p("pillar",  Vector3(cx, 0, cz))
			_p("lantern", Vector3(cx, 1, cz))


# ---------------------------------------------------------------------------
# Buildings
# ---------------------------------------------------------------------------

func _build_buildings() -> void:
	# [center, hw, hd, style, name]
	# hw/hd are the half-extents in meters; pieces fill the span -hw..+hw
	var defs: Array = [
		[Vector3(-20, 0, -68), 4, 3, "wood",  "CrowsNestInn"],
		[Vector3( 20, 0, -68), 4, 3, "stone", "MerchantExchange"],
		[Vector3(  0, 0, -88), 5, 3, "stone", "HarbormasterHall"],
		[Vector3(-20, 0, -46), 3, 2, "stone", "ArmorersForge"],
		[Vector3( 20, 0, -46), 3, 2, "wood",  "GeneralStore"],
		[Vector3(  0, 0, -90), 3, 4, "stone", "WayfarersChapel"],
	]
	for d: Array in defs:
		_build_structure(d[0], d[1], d[2], d[3], d[4])


func _build_structure(center: Vector3, hw: int, hd: int, style: String, bname: String) -> void:
	var container := Node3D.new()
	container.name = bname
	add_child(container)

	var wood := style == "wood"
	_ring_walls(container, center,                     hw, hd, wood, false)
	_ring_walls(container, center + Vector3(0, 1, 0),  hw, hd, wood, true)
	_gable_roof(container, center + Vector3(0, 2, 0),  hw, hd)
	_p("chimney", center + Vector3(float(hw) - 0.5, 3.0, float(-hd) + 0.5), 0.0, container)

	var body  := StaticBody3D.new()
	var cnode := CollisionShape3D.new()
	var box   := BoxShape3D.new()
	box.size = Vector3(float(hw) * 2.0 + 0.3, 3.0, float(hd) * 2.0 + 0.3)
	cnode.shape    = box
	cnode.position = Vector3(0, 1.5, 0)
	body.add_child(cnode)
	body.position = center
	container.add_child(body)


## Place wall pieces around a rectangle.
## hw/hd are half-extents in metres; wall spans -hw..+hw and -hd..+hd.
## Pieces are 1 m wide; centres sit at half-integer offsets (±0.5, ±1.5, …).
func _ring_walls(parent: Node3D, center: Vector3, hw: int, hd: int, wood: bool, upper: bool) -> void:
	var plain := "wall_wood"    if wood else "wall"
	var win   := "wall_win_wd"  if wood else "wall_win"
	var door  := "wall_door_wd" if wood else "wall_door"
	var corn  := "wall_corner_wd" if wood else "wall_corner"

	# South face — exterior faces +Z (player-side); FBX default face is -Z so rot PI
	var n_x := hw * 2
	var door_idx := n_x / 2
	var idx := 0
	var ix := float(-hw) + 0.5
	while ix < float(hw):
		var w := door if (not upper and idx == door_idx) \
				else (win if (ix < float(-hw) + 1.5 or ix > float(hw) - 1.5) else plain)
		_p(w, center + Vector3(ix, 0, float(hd)), PI, parent)
		idx += 1
		ix  += 1.0

	# North face — exterior faces -Z; rot 0
	ix = float(-hw) + 0.5
	while ix < float(hw):
		var w := win if (ix < float(-hw) + 1.5 or ix > float(hw) - 1.5) and upper else plain
		_p(w, center + Vector3(ix, 0, float(-hd)), 0.0, parent)
		ix += 1.0

	# West face — exterior faces -X; rot -PI/2
	var iz := float(-hd) + 0.5
	while iz < float(hd):
		var w := win if abs(iz) < 0.6 and not upper else plain
		_p(w, center + Vector3(float(-hw), 0, iz), -PI / 2.0, parent)
		iz += 1.0

	# East face — exterior faces +X; rot PI/2
	iz = float(-hd) + 0.5
	while iz < float(hd):
		var w := win if abs(iz) < 0.6 and not upper else plain
		_p(w, center + Vector3(float(hw), 0, iz), PI / 2.0, parent)
		iz += 1.0

	# Corners (NW / NE / SW / SE) — rotations flipped to match face convention
	_p(corn, center + Vector3(float(-hw), 0, float(-hd)), -PI / 2.0, parent)
	_p(corn, center + Vector3(float( hw), 0, float(-hd)),  0.0,      parent)
	_p(corn, center + Vector3(float(-hw), 0, float( hd)),  PI,       parent)
	_p(corn, center + Vector3(float( hw), 0, float( hd)),  PI / 2.0, parent)


func _gable_roof(parent: Node3D, base: Vector3, hw: int, hd: int) -> void:
	# Gable ends — same flip as walls
	var ix := float(-hw) + 0.5
	while ix < float(hw):
		_p("roof_gable_end", base + Vector3(ix, 0, float( hd)), PI,  parent)
		_p("roof_gable_end", base + Vector3(ix, 0, float(-hd)), 0.0, parent)
		ix += 1.0
	# Sloping sides — flipped
	var iz := float(-hd) + 0.5
	while iz < float(hd):
		_p("roof_gable", base + Vector3(float(-hw), 0, iz), -PI / 2.0, parent)
		_p("roof_gable", base + Vector3(float( hw), 0, iz),  PI / 2.0, parent)
		iz += 1.0
	# Ridge cap
	ix = float(-hw) + 0.5
	while ix < float(hw):
		_p("roof_gable_top", base + Vector3(ix, 0.5, 0), 0.0, parent)
		ix += 1.0
	# Roof corners — flipped
	_p("roof_corner", base + Vector3(float(-hw), 0, float(-hd)), -PI / 2.0, parent)
	_p("roof_corner", base + Vector3(float( hw), 0, float(-hd)),  0.0,      parent)
	_p("roof_corner", base + Vector3(float(-hw), 0, float( hd)),  PI,       parent)
	_p("roof_corner", base + Vector3(float( hw), 0, float( hd)),  PI / 2.0, parent)


# ---------------------------------------------------------------------------
# Dock
# ---------------------------------------------------------------------------

func _build_dock() -> void:
	var iz := -14.0
	while iz <= 12.0:
		for ix: float in [-1.5, -0.5, 0.5, 1.5]:
			_p("planks", Vector3(ix, 0, iz))
		iz += 1.0


# ---------------------------------------------------------------------------
# Windmill
# ---------------------------------------------------------------------------

func _place_windmill() -> void:
	_p("windmill", Vector3(-44, 0, -90))


# ---------------------------------------------------------------------------
# Forest ring
# ---------------------------------------------------------------------------

func _build_forest_ring() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var trees: Array[String] = ["tree", "tree_high", "tree_round", "tree_crooked"]

	# Coordinates are local (×2 = world). Terrain edge is world ±190 → local ±95.
	var step := 5.0
	var gx := -90.0
	while gx <= 90.0:
		var gz := -90.0
		while gz <= 90.0:
			var d := Vector2(gx, gz).length()
			if d >= 35.0 and d <= 90.0:
				var px := gx + rng.randf_range(-2.0, 2.0)
				var pz := gz + rng.randf_range(-2.0, 2.0)
				# Skip NS road corridor
				if abs(px) < 3.0 and pz > -58.0 and pz < -5.0:
					gz += step
					continue
				# Skip EW road corridors
				if abs(pz + 28.0) < 3.0 and abs(px) < 18.0:
					gz += step
					continue
				if abs(pz + 43.0) < 3.0 and abs(px) < 13.0:
					gz += step
					continue
				var tk: String = trees[rng.randi() % trees.size()]
				var n := _p(tk, Vector3(px, 0, pz))
				if n:
					n.rotation.y = rng.randf_range(0.0, TAU)
					n.scale = Vector3.ONE * rng.randf_range(0.85, 1.5)
			gz += step
		gx += step

	# Extra flanking trees on east/west sides
	for _i in range(25):
		var side := 1.0 if rng.randi() % 2 == 0 else -1.0
		var px := side * rng.randf_range(19.0, 33.0)
		var pz := rng.randf_range(-59.0, -11.0)
		if abs(pz + 28.0) < 4.0:
			continue
		var tk: String = trees[rng.randi() % trees.size()]
		var n := _p(tk, Vector3(px, 0, pz))
		if n:
			n.rotation.y = rng.randf_range(0.0, TAU)
			n.scale = Vector3.ONE * rng.randf_range(0.8, 1.3)


# ---------------------------------------------------------------------------
# Rock scatter
# ---------------------------------------------------------------------------

func _scatter_rocks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var rocks: Array[String] = ["rock_large", "rock_small"]
	for _i in range(35):
		var angle := rng.randf_range(0.0, TAU)
		var r     := rng.randf_range(25.0, 82.0)
		var px := cos(angle) * r
		var pz := sin(angle) * r
		if abs(px) < 3.5 and pz > -58.0 and pz < -5.0:
			continue
		var rk: String = rocks[rng.randi() % rocks.size()]
		var n := _p(rk, Vector3(px, 0, pz))
		if n:
			n.rotation.y = rng.randf_range(0.0, TAU)
