## HexGrid
## Autoload singleton. Pure-math hex grid utilities for LMAP-001..006.
## Uses flat-top axial coordinates. No scene state; safe to call from any system.
extends Node

## World-space radius of a single hex cell (center to corner).
## Change this once before _ready() or adjust at runtime — all functions use it live.
var hex_size: float = 1.0

## The six axial direction vectors in clockwise order starting at "east" (flat-top).
## Index corresponds to the edge index used by get_shared_edge_index().
const AXIAL_DIRECTIONS: Array = [
	Vector2i( 1,  0),   # 0 — E
	Vector2i( 1, -1),   # 1 — NE
	Vector2i( 0, -1),   # 2 — NW
	Vector2i(-1,  0),   # 3 — W
	Vector2i(-1,  1),   # 4 — SW
	Vector2i( 0,  1),   # 5 — SE
]


## Convert flat-top axial coordinates (q, r) to a world-space Vector3 (y = 0).
func axial_to_world(q: int, r: int) -> Vector3:
	var x := hex_size * (3.0 / 2.0 * q)
	var z := hex_size * (sqrt(3.0) / 2.0 * q + sqrt(3.0) * r)
	return Vector3(x, 0.0, z)


## Convert a world-space position back to the nearest axial coordinate.
func world_to_axial(world_pos: Vector3) -> Vector2i:
	# Inverse of axial_to_world for flat-top layout
	var q_f := (2.0 / 3.0 * world_pos.x) / hex_size
	var r_f := (-1.0 / 3.0 * world_pos.x + sqrt(3.0) / 3.0 * world_pos.z) / hex_size
	return _axial_round(q_f, r_f)


## Return all 6 axial neighbors of hex (q, r).
func get_neighbors(q: int, r: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for d in AXIAL_DIRECTIONS:
		result.append(Vector2i(q + d.x, r + d.y))
	return result


## Axial hex distance (number of steps on the grid).
func hex_distance(q1: int, r1: int, q2: int, r2: int) -> int:
	var dq := q2 - q1
	var dr := r2 - r1
	# Standard axial distance formula
	return (abs(dq) + abs(dr) + abs(dq + dr)) / 2


## Return all hexes exactly [radius] steps from (q, r) as an Array[Vector2i].
func get_ring(q: int, r: int, radius: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if radius <= 0:
		result.append(Vector2i(q, r))
		return result
	# Start at the hex [radius] steps in direction 4 (SW), then walk around.
	var dir_start: Vector2i = AXIAL_DIRECTIONS[4]
	var cq := q + dir_start.x * radius
	var cr := r + dir_start.y * radius
	for i in range(6):
		var dir: Vector2i = AXIAL_DIRECTIONS[i]
		for _j in range(radius):
			result.append(Vector2i(cq, cr))
			cq += dir.x
			cr += dir.y
	return result


## Returns the edge index (0–5) shared between two adjacent hexes, or -1 if not adjacent.
## Edge index matches the AXIAL_DIRECTIONS constant (direction FROM hex_a TO hex_b).
func get_shared_edge_index(q1: int, r1: int, q2: int, r2: int) -> int:
	var dq := q2 - q1
	var dr := r2 - r1
	var delta := Vector2i(dq, dr)
	for i in range(AXIAL_DIRECTIONS.size()):
		if AXIAL_DIRECTIONS[i] == delta:
			return i
	return -1


# --- Private helpers ---

## Cube-coordinate rounding projected back to axial.
func _axial_round(q_f: float, r_f: float) -> Vector2i:
	var s_f := -q_f - r_f
	var rq := roundi(q_f)
	var rr := roundi(r_f)
	var rs := roundi(s_f)
	var dq := abs(rq - q_f)
	var dr := abs(rr - r_f)
	var ds := abs(rs - s_f)
	if dq > dr and dq > ds:
		rq = -rr - rs
	elif dr > ds:
		rr = -rq - rs
	# rs is unused after rounding — axial only needs q and r
	return Vector2i(rq, rr)
