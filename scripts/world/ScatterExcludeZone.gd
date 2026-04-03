## ScatterExcludeZone
## Place as a child of any node in the scene. Any scatter candidate within
## `radius` world units (XZ only) of this node will be skipped during baking.
## After placing, re-bake the affected area to apply the exclusion.
@tool
extends Node3D

@export var radius: float = 5.0

func _ready() -> void:
	add_to_group("scatter_exclude")
