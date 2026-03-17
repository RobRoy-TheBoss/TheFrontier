## AudioManager
## Handles 3D positional audio, biome ambience with crossfading,
## monster audio cues, survival threshold cues, and event-driven music.
extends Node

signal ambience_changed(biome: String)

# Ambience players (crossfade between two)
var _ambience_a: AudioStreamPlayer = null
var _ambience_b: AudioStreamPlayer = null
var _ambience_active: bool = true  # true = A, false = B
var _current_biome: String = ""

# Music player
var _music_player: AudioStreamPlayer = null
var _music_queue: Array = []

# Survival cue bus
var _survival_cue_player: AudioStreamPlayer = null

# Crossfade settings
const CROSSFADE_DURATION := 3.0

# Biome -> ambient sound path mapping
const BIOME_AMBIENCE := {
	"forest": "res://assets/audio/ambient/forest_loop.ogg",
	"coast": "res://assets/audio/ambient/coast_loop.ogg",
	"plains": "res://assets/audio/ambient/plains_loop.ogg",
	"swamp": "res://assets/audio/ambient/swamp_loop.ogg",
	"mountain": "res://assets/audio/ambient/mountain_loop.ogg",
	"deep_west": "res://assets/audio/ambient/deep_west_loop.ogg"
}

const SURVIVAL_CUES := {
	"hunger_low": "res://assets/audio/sfx/hunger_low.ogg",
	"hunger_critical": "res://assets/audio/sfx/hunger_critical.ogg",
	"thirst_low": "res://assets/audio/sfx/thirst_low.ogg",
	"fatigue_critical": "res://assets/audio/sfx/fatigue_critical.ogg",
	"injury": "res://assets/audio/sfx/injury_inflicted.ogg",
	"healing": "res://assets/audio/sfx/healing.ogg"
}


func _ready() -> void:
	add_to_group("audio_manager")
	_setup_players()
	_connect_signals()


func _setup_players() -> void:
	_ambience_a = AudioStreamPlayer.new()
	_ambience_a.bus = "Ambience"
	_ambience_a.volume_db = -10.0
	add_child(_ambience_a)

	_ambience_b = AudioStreamPlayer.new()
	_ambience_b.bus = "Ambience"
	_ambience_b.volume_db = -80.0
	add_child(_ambience_b)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.volume_db = -15.0
	add_child(_music_player)
	_music_player.finished.connect(_on_music_finished)

	_survival_cue_player = AudioStreamPlayer.new()
	_survival_cue_player.bus = "SFX"
	add_child(_survival_cue_player)


func _connect_signals() -> void:
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player")
	if player and player.survival:
		player.survival.survival_warning.connect(_on_survival_warning)
	if player and player.health:
		player.health.injury_inflicted.connect(_on_injury)


func set_biome(biome: String) -> void:
	if biome == _current_biome:
		return
	_current_biome = biome
	var path: String = BIOME_AMBIENCE.get(biome, "")
	if path == "":
		return
	_crossfade_ambience(path)
	ambience_changed.emit(biome)


func _crossfade_ambience(new_path: String) -> void:
	var incoming := _ambience_b if _ambience_active else _ambience_a
	var outgoing := _ambience_a if _ambience_active else _ambience_b
	_ambience_active = not _ambience_active
	var stream := _try_load_stream(new_path)
	if stream == null:
		return
	incoming.stream = stream
	incoming.play()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(incoming, "volume_db", -10.0, CROSSFADE_DURATION)
	tween.tween_property(outgoing, "volume_db", -80.0, CROSSFADE_DURATION)


func play_sfx_3d(sound_path: String, world_position: Vector3) -> void:
	var stream := _try_load_stream(sound_path)
	if stream == null:
		return
	var player_3d := AudioStreamPlayer3D.new()
	player_3d.stream = stream
	player_3d.global_position = world_position
	player_3d.bus = "SFX"
	player_3d.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE
	player_3d.max_distance = 60.0
	get_tree().root.add_child(player_3d)
	player_3d.play()
	player_3d.finished.connect(player_3d.queue_free)


func play_monster_cue(monster_id: String, world_position: Vector3) -> void:
	var monster := GameData.get_monster(monster_id)
	var cue: String = monster.get("audio_cue", "")
	if cue == "":
		return
	play_sfx_3d("res://assets/audio/sfx/" + cue + ".ogg", world_position)


func play_firearm_shot(world_position: Vector3) -> void:
	play_sfx_3d("res://assets/audio/sfx/musket_shot.ogg", world_position)


func play_event_music(event: String) -> void:
	var path := "res://assets/audio/music/" + event + ".ogg"
	var stream := _try_load_stream(path)
	if stream == null:
		return
	_music_player.stream = stream
	_music_player.play()


func _on_survival_warning(need: String, level: String) -> void:
	var key := need + "_" + level
	var path: String = SURVIVAL_CUES.get(key, "")
	if path == "" or _survival_cue_player.playing:
		return
	var stream := _try_load_stream(path)
	if stream:
		_survival_cue_player.stream = stream
		_survival_cue_player.play()


func _on_injury(injury_id: String) -> void:
	var path: String = SURVIVAL_CUES.get("injury", "")
	var stream := _try_load_stream(path)
	if stream:
		_survival_cue_player.stream = stream
		_survival_cue_player.play()
	play_event_music("injury_sting")


func _on_music_finished() -> void:
	if _music_queue.is_empty():
		return
	var next_path: String = _music_queue.pop_front()
	var stream := _try_load_stream(next_path)
	if stream:
		_music_player.stream = stream
		_music_player.play()


func queue_music(path: String) -> void:
	_music_queue.append(path)


func _try_load_stream(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		return null
	return load(path)


func set_settlement_tier_ambience(tier_index: int) -> void:
	# Richer settlement sound layers at higher tiers (AUD-198 SHOULD)
	var volume := -20.0 + (tier_index * 3.0)
	# Placeholder: adjust settlement ambient layer volume


## Play a non-positional 2D sound effect by logical name.
## Gracefully no-ops if the audio file is missing (common during development).
func play_sfx(sfx_name: String) -> void:
	var path := "res://assets/audio/sfx/" + sfx_name + ".wav"
	var stream := _try_load_stream(path)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "SFX"
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
