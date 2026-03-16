## MusicManager
## Autoload singleton. Manages background music with crossfading (LAUD-001).
## Uses two AudioStreamPlayer nodes (A and B) that swap roles on each crossfade.
## Biome ambient tracks play looping; event music plays once and returns to biome.
extends Node

## Currently active biome identifier (used to avoid re-triggering the same track).
var current_biome: String = ""

# Crossfade duration in seconds.
const CROSSFADE_DURATION: float = 2.0

# Two stream players that take turns being the active track.
var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer

# Which player is currently the "active" (audible) one.
var _active_player: AudioStreamPlayer
var _inactive_player: AudioStreamPlayer

# Fade state
var _fading: bool = false
var _fade_elapsed: float = 0.0

# When an event track finishes, we resume this biome.
var _queued_biome: String = ""


func _ready() -> void:
	_player_a = AudioStreamPlayer.new()
	_player_b = AudioStreamPlayer.new()
	_player_a.bus = "Music"
	_player_b.bus = "Music"
	add_child(_player_a)
	add_child(_player_b)
	_active_player   = _player_a
	_inactive_player = _player_b

	# Resume biome when a one-shot event track ends.
	_player_a.finished.connect(_on_player_finished.bind(_player_a))
	_player_b.finished.connect(_on_player_finished.bind(_player_b))


func _process(delta: float) -> void:
	if not _fading:
		return
	_fade_elapsed += delta
	var t := clampf(_fade_elapsed / CROSSFADE_DURATION, 0.0, 1.0)

	_inactive_player.volume_db = linear_to_db(t)          # fade in
	_active_player.volume_db   = linear_to_db(1.0 - t)    # fade out

	if t >= 1.0:
		_active_player.stop()
		_active_player.volume_db = linear_to_db(1.0)
		# Swap roles
		var tmp := _active_player
		_active_player   = _inactive_player
		_inactive_player = tmp
		_fading = false


# --- Public API ---

## Crossfade to the ambient track for biome. No-op if already playing this biome.
func play_biome_track(biome: String) -> void:
	if biome == current_biome and _active_player.playing:
		return
	current_biome = biome
	_queued_biome = ""
	var path := "res://audio/music/biome_%s.ogg" % biome
	_crossfade_to(path, true)


## Play a one-shot event music track, then return to current biome.
func play_event_music(event: String) -> void:
	_queued_biome = current_biome
	var path := "res://audio/music/event_%s.ogg" % event
	_crossfade_to(path, false)


## Stop all music immediately.
func stop_music() -> void:
	_fading = false
	_player_a.stop()
	_player_b.stop()
	current_biome = ""
	_queued_biome = ""


## Set the volume (dB) on an audio bus (e.g. "Music", "Master").
func set_volume(bus: String, db: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx == -1:
		push_warning("[MusicManager] set_volume: unknown bus '%s'" % bus)
		return
	AudioServer.set_bus_volume_db(idx, db)


# --- Private helpers ---

func _crossfade_to(stream_path: String, looping: bool) -> void:
	var stream := load(stream_path) as AudioStream
	if stream == null:
		push_warning("[MusicManager] Could not load stream: " + stream_path)
		return

	# Prepare the inactive player, then start the fade.
	_inactive_player.stream = stream
	_inactive_player.volume_db = linear_to_db(0.0)
	_inactive_player.play()

	# If nothing was playing before, skip the fade.
	if not _active_player.playing:
		_active_player.stop()
		var tmp := _active_player
		_active_player   = _inactive_player
		_inactive_player = tmp
		_active_player.volume_db = linear_to_db(1.0)
		return

	_fading = true
	_fade_elapsed = 0.0


func _on_player_finished(player: AudioStreamPlayer) -> void:
	# Only care about the currently active player finishing (i.e. one-shot event track).
	if player != _active_player:
		return
	if _queued_biome != "":
		var biome := _queued_biome
		_queued_biome = ""
		current_biome = ""  # Force re-trigger in play_biome_track.
		play_biome_track(biome)
