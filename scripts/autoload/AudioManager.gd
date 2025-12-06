extends Node
## AudioManager - Handles all audio playback and mixing
## Manages music tracks, sound effects, and audio bus levels

signal music_changed(track_name: String)
signal beat_hit(beat_index: int)

# Audio buses
var master_bus_idx: int
var music_bus_idx: int
var sfx_bus_idx: int

# Music players
var music_player: AudioStreamPlayer
var music_player_next: AudioStreamPlayer
var current_track: String = ""
var is_crossfading: bool = false
var crossfade_duration: float = 1.0

# SFX pool for concurrent sounds
var sfx_pool: Array[AudioStreamPlayer] = []
var sfx_pool_size: int = 16
var sfx_pool_index: int = 0

# Sound effect library (preloaded)
var sfx_library: Dictionary = {}

# Music library
var music_library: Dictionary = {}

# Beat tracking for reactive music
var bpm: float = 120.0
var beat_interval: float = 0.5
var beat_timer: float = 0.0
var current_beat: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Get audio bus indices
	master_bus_idx = AudioServer.get_bus_index("Master")
	music_bus_idx = AudioServer.get_bus_index("Music") if AudioServer.get_bus_index("Music") >= 0 else master_bus_idx
	sfx_bus_idx = AudioServer.get_bus_index("SFX") if AudioServer.get_bus_index("SFX") >= 0 else master_bus_idx

	_setup_audio_players()
	_preload_sounds()

func _setup_audio_players() -> void:
	# Main music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music" if AudioServer.get_bus_index("Music") >= 0 else "Master"
	add_child(music_player)

	# Secondary music player for crossfades
	music_player_next = AudioStreamPlayer.new()
	music_player_next.bus = music_player.bus
	music_player_next.volume_db = -80
	add_child(music_player_next)

	# SFX pool
	for i in range(sfx_pool_size):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
		add_child(player)
		sfx_pool.append(player)

func _preload_sounds() -> void:
	# Define sound effects (will load actual files when they exist)
	sfx_library = {
		# Player actions
		"jump": null,
		"double_jump": null,
		"dash": null,
		"wall_slide": null,
		"wall_jump": null,
		"land": null,
		"footstep": null,

		# Game events
		"death": null,
		"respawn": null,
		"checkpoint": null,
		"level_complete": null,
		"medal_bronze": null,
		"medal_silver": null,
		"medal_gold": null,
		"medal_platinum": null,
		"star_collect": null,
		"coin_collect": null,

		# UI
		"ui_select": null,
		"ui_confirm": null,
		"ui_back": null,
		"ui_hover": null,
		"ui_error": null,
		"countdown_tick": null,
		"countdown_go": null,

		# Ambient/FX
		"electric_hum": null,
		"wind": null,
		"neon_flicker": null
	}

	# Music tracks
	music_library = {
		"menu": null,
		"chapter1": null,
		"chapter2": null,
		"chapter3": null,
		"boss": null,
		"victory": null,
		"editor": null
	}

	# Load actual audio files if they exist
	_load_audio_files()

func _load_audio_files() -> void:
	var sfx_path = "res://assets/audio/sfx/"
	var music_path = "res://assets/audio/music/"

	# Try to load SFX (check .wav first, then .ogg)
	for key in sfx_library.keys():
		var path = sfx_path + key + ".wav"
		if ResourceLoader.exists(path):
			sfx_library[key] = load(path)
			print("Loaded SFX: ", key)
		else:
			path = sfx_path + key + ".ogg"
			if ResourceLoader.exists(path):
				sfx_library[key] = load(path)
				print("Loaded SFX: ", key)

	# Try to load music (check .wav first, then .ogg, then .mp3)
	for key in music_library.keys():
		var path = music_path + key + ".wav"
		if ResourceLoader.exists(path):
			music_library[key] = load(path)
			print("Loaded Music: ", key)
		else:
			path = music_path + key + ".ogg"
			if ResourceLoader.exists(path):
				music_library[key] = load(path)
				print("Loaded Music: ", key)
			else:
				path = music_path + key + ".mp3"
				if ResourceLoader.exists(path):
					music_library[key] = load(path)
					print("Loaded Music: ", key)

func _process(delta: float) -> void:
	# Handle music crossfade
	if is_crossfading:
		_process_crossfade(delta)

	# Beat tracking
	if music_player.playing:
		beat_timer += delta
		if beat_timer >= beat_interval:
			beat_timer -= beat_interval
			current_beat += 1
			beat_hit.emit(current_beat)

func _process_crossfade(delta: float) -> void:
	var fade_speed = 80.0 / crossfade_duration * delta

	# Fade out current
	if music_player.volume_db > -80:
		music_player.volume_db -= fade_speed

	# Fade in next
	if music_player_next.volume_db < 0:
		music_player_next.volume_db = min(music_player_next.volume_db + fade_speed, 0)

	# Crossfade complete
	if music_player.volume_db <= -80:
		music_player.stop()

		# Swap players
		var temp = music_player
		music_player = music_player_next
		music_player_next = temp

		is_crossfading = false

func play_music(track_name: String, fade: bool = true) -> void:
	if track_name == current_track:
		return

	current_track = track_name

	if not music_library.has(track_name) or music_library[track_name] == null:
		push_warning("Music track not found: " + track_name)
		return

	var stream = music_library[track_name]

	if fade and music_player.playing:
		# Crossfade to new track
		music_player_next.stream = stream
		music_player_next.volume_db = -80
		music_player_next.play()
		is_crossfading = true
	else:
		music_player.stream = stream
		music_player.volume_db = 0
		music_player.play()

	music_changed.emit(track_name)

func stop_music(fade: bool = true) -> void:
	if fade:
		is_crossfading = true
		music_player_next.stop()
		music_player_next.volume_db = 0
	else:
		music_player.stop()
		music_player_next.stop()

	current_track = ""

func play_sfx(sfx_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if not sfx_library.has(sfx_name) or sfx_library[sfx_name] == null:
		# Generate placeholder sound if audio doesn't exist
		_play_procedural_sfx(sfx_name, volume_db, pitch_scale)
		return

	var player = sfx_pool[sfx_pool_index]
	sfx_pool_index = (sfx_pool_index + 1) % sfx_pool_size

	player.stream = sfx_library[sfx_name]
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()

func _play_procedural_sfx(sfx_name: String, volume_db: float, pitch_scale: float) -> void:
	# Generate simple procedural sounds as placeholders
	# These will be replaced by actual audio assets

	var player = sfx_pool[sfx_pool_index]
	sfx_pool_index = (sfx_pool_index + 1) % sfx_pool_size

	# Create a simple noise generator for placeholder
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100
	generator.buffer_length = 0.1

	# Different sounds based on type
	match sfx_name:
		"jump", "double_jump", "wall_jump":
			generator.buffer_length = 0.15
		"dash":
			generator.buffer_length = 0.2
		"death":
			generator.buffer_length = 0.5
		"ui_select", "ui_hover":
			generator.buffer_length = 0.05
		_:
			generator.buffer_length = 0.1

	# Note: In a real implementation, we'd fill the buffer with generated audio
	# For now, we just skip playing if no asset exists

func play_sfx_positional(sfx_name: String, position: Vector2, volume_db: float = 0.0) -> void:
	# For 2D positional audio - could use AudioStreamPlayer2D pool
	play_sfx(sfx_name, volume_db)

func set_master_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(master_bus_idx, linear_to_db(value))

func set_music_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(music_bus_idx, linear_to_db(value))

func set_sfx_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(sfx_bus_idx, linear_to_db(value))

func get_master_volume() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(master_bus_idx))

func get_music_volume() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(music_bus_idx))

func get_sfx_volume() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_idx))

func set_bpm(new_bpm: float) -> void:
	bpm = new_bpm
	beat_interval = 60.0 / bpm
