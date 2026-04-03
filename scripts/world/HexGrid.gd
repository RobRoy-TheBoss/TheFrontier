## HexGrid
## Editor tool — call get_transform(col, row) to get the correct world Transform3D
## for a hex area at grid position (col, row).
##
## Grid math:
##   x = col * 300
##   z = row * 346 + (173 if col is odd)
##   y = 0 (set elevation separately via Position.y in the inspector)
##
## Area ID convention:
##   {col}_{row}_{glb_name}_{rotation_steps}
##   where rotation_steps is the number of 60° increments (0–5), 0 meaning no rotation.
##   Examples:
##     0_0_costal1_0       ← CrestportBay, no rotation
##     1_0_Forest1_3       ← col 1 row 0, Forest1.glb, rotated 180°
##     2_1_Forest2_0       ← col 2 row 1, Forest2.glb, no rotation
@tool
extends Node

const COL_STEP_X  := 300.0
const ROW_STEP_Z  := 346.0
const ODD_OFFSET_Z := 173.0


static func get_position(col: int, row: int, elevation: float = 0.0) -> Vector3:
	var x := col * COL_STEP_X
	var z := row * ROW_STEP_Z + (ODD_OFFSET_Z if col % 2 == 1 else 0.0)
	return Vector3(x, elevation, z)


## Returns [Transform3D, rotation_steps] so the caller can build the area_id.
## area_id format: {col}_{row}_{glb_name_without_extension}_{rotation_steps}
## Returns [Transform3D, rotation_steps] — use rotation_steps as the suffix in the area_id.
## Pass rotation_override 0–5 to fix a specific rotation, or leave as -1 for random.
static func get_transform(col: int, row: int, elevation: float = 0.0, rotation_override: int = -1) -> Array:
	var steps := rotation_override if rotation_override >= 0 else randi() % 6
	var basis := Basis(Vector3.UP, deg_to_rad(steps * 60.0))
	return [Transform3D(basis, get_position(col, row, elevation)), steps]
