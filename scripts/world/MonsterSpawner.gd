## MonsterSpawner
## Places a static monster at this node's position and respawns it on death.
extends Node3D

@export var monster_id: String = "prowler"
@export var respawn_time: float = 10.0

const MONSTER_SCENE := preload("res://scenes/monsters/MonsterBase.tscn")

var _monster: Node = null


func _ready() -> void:
	call_deferred("_spawn")


func _spawn() -> void:
	_monster = MONSTER_SCENE.instantiate()
	_monster.monster_id = monster_id
	_monster.static_mode = true
	add_child(_monster)
	_monster.position = Vector3.ZERO
	_monster.died.connect(_on_died)


func _on_died(_id: String, _pos: Vector3) -> void:
	_monster = null
	await get_tree().create_timer(respawn_time).timeout
	_spawn()
