extends Node
## GameManager - Central game state and flow controller
## Handles game modes, level management, speedrun timing, and progression

signal level_started(level_id: String)
signal level_completed(level_id: String, time: float, medals: Dictionary)
signal player_died
signal player_respawned
signal game_paused(is_paused: bool)
signal medal_earned(medal_type: String, level_id: String)

enum GameMode { CLASSIC_RUNNER, SHIP_RUNNER, EDITOR, MENU }
enum MedalType { NONE, BRONZE, SILVER, GOLD, PLATINUM }

# Current state
var current_mode: GameMode = GameMode.MENU
var current_level_id: String = ""
var current_chapter: int = 1
var is_paused: bool = false
var is_playing: bool = false

# Speedrun timing
var level_time: float = 0.0
var best_time: float = INF
var ghost_data: Array[Dictionary] = []
var current_ghost_frame: int = 0
var is_recording_ghost: bool = false

# Player stats
var total_deaths: int = 0
var total_playtime: float = 0.0
var current_attempt: int = 0

# Level data
var level_data: Dictionary = {}
var campaign_levels: Array[String] = []
var custom_levels: Array[String] = []

# Medal thresholds (in seconds) - per level configuration
var medal_thresholds: Dictionary = {}

# Constants
const GHOST_RECORD_INTERVAL: float = 0.05
const MAX_GHOST_FRAMES: int = 36000  # 30 minutes max

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_campaign_structure()

func _process(delta: float) -> void:
	if is_playing and not is_paused:
		level_time += delta
		total_playtime += delta

		if is_recording_ghost:
			_record_ghost_frame()

func _load_campaign_structure() -> void:
	# Define campaign levels structure
	campaign_levels = [
		# Chapter 1 - Tutorial & Basics
		"ch1_01_awakening",
		"ch1_02_first_steps",
		"ch1_03_momentum",
		"ch1_04_walls",
		"ch1_05_dash_intro",
		# Chapter 2 - Core Mechanics
		"ch2_01_vertical_climb",
		"ch2_02_chain_dash",
		"ch2_03_precision",
		"ch2_04_speedway",
		"ch2_05_gauntlet",
		# Chapter 3 - Advanced
		"ch3_01_neon_city",
		"ch3_02_skyline",
		"ch3_03_descent",
		"ch3_04_labyrinth",
		"ch3_05_terminus",
	]

	# Set medal thresholds for each level
	medal_thresholds = {
		"ch1_01_awakening": {"bronze": 60.0, "silver": 45.0, "gold": 30.0, "platinum": 20.0},
		"ch1_02_first_steps": {"bronze": 90.0, "silver": 60.0, "gold": 40.0, "platinum": 25.0},
		"ch1_03_momentum": {"bronze": 120.0, "silver": 80.0, "gold": 50.0, "platinum": 35.0},
		"ch1_04_walls": {"bronze": 100.0, "silver": 70.0, "gold": 45.0, "platinum": 30.0},
		"ch1_05_dash_intro": {"bronze": 90.0, "silver": 60.0, "gold": 40.0, "platinum": 28.0},
		"ch2_01_vertical_climb": {"bronze": 150.0, "silver": 100.0, "gold": 70.0, "platinum": 50.0},
		"ch2_02_chain_dash": {"bronze": 120.0, "silver": 80.0, "gold": 55.0, "platinum": 40.0},
		"ch2_03_precision": {"bronze": 180.0, "silver": 120.0, "gold": 80.0, "platinum": 55.0},
		"ch2_04_speedway": {"bronze": 60.0, "silver": 45.0, "gold": 32.0, "platinum": 24.0},
		"ch2_05_gauntlet": {"bronze": 240.0, "silver": 180.0, "gold": 120.0, "platinum": 90.0},
		"ch3_01_neon_city": {"bronze": 200.0, "silver": 150.0, "gold": 100.0, "platinum": 75.0},
		"ch3_02_skyline": {"bronze": 180.0, "silver": 130.0, "gold": 90.0, "platinum": 65.0},
		"ch3_03_descent": {"bronze": 150.0, "silver": 110.0, "gold": 75.0, "platinum": 55.0},
		"ch3_04_labyrinth": {"bronze": 300.0, "silver": 220.0, "gold": 160.0, "platinum": 120.0},
		"ch3_05_terminus": {"bronze": 360.0, "silver": 270.0, "gold": 200.0, "platinum": 150.0},
	}

func start_level(level_id: String, mode: GameMode = GameMode.CLASSIC_RUNNER) -> void:
	current_level_id = level_id
	current_mode = mode
	level_time = 0.0
	current_attempt += 1
	is_playing = true
	is_paused = false
	is_recording_ghost = true
	ghost_data.clear()
	current_ghost_frame = 0

	# Load best time for this level
	var save_data = SaveManager.get_level_data(level_id)
	if save_data.has("best_time"):
		best_time = save_data.best_time
	else:
		best_time = INF

	level_started.emit(level_id)

func complete_level() -> void:
	is_playing = false
	is_recording_ghost = false

	var is_new_best = level_time < best_time
	if is_new_best:
		best_time = level_time
		SaveManager.save_ghost_data(current_level_id, ghost_data)

	var earned_medal = calculate_medal(level_time)
	var medals_data = {
		"time": level_time,
		"medal": earned_medal,
		"is_new_best": is_new_best,
		"attempt": current_attempt
	}

	SaveManager.save_level_completion(current_level_id, level_time, earned_medal)

	if earned_medal != MedalType.NONE:
		medal_earned.emit(MedalType.keys()[earned_medal], current_level_id)

	level_completed.emit(current_level_id, level_time, medals_data)

func calculate_medal(time: float) -> MedalType:
	if not medal_thresholds.has(current_level_id):
		return MedalType.NONE

	var thresholds = medal_thresholds[current_level_id]

	if time <= thresholds.platinum:
		return MedalType.PLATINUM
	elif time <= thresholds.gold:
		return MedalType.GOLD
	elif time <= thresholds.silver:
		return MedalType.SILVER
	elif time <= thresholds.bronze:
		return MedalType.BRONZE
	else:
		return MedalType.NONE

func die() -> void:
	total_deaths += 1
	is_recording_ghost = false
	player_died.emit()

func respawn() -> void:
	level_time = 0.0
	current_attempt += 1
	ghost_data.clear()
	current_ghost_frame = 0
	is_recording_ghost = true
	is_playing = true
	player_respawned.emit()

func toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	game_paused.emit(is_paused)

func _record_ghost_frame() -> void:
	if ghost_data.size() >= MAX_GHOST_FRAMES:
		return

	# Ghost frame data will be populated by the player
	# This is called from player script

func add_ghost_frame(position: Vector2, velocity: Vector2, animation: String, flip_h: bool) -> void:
	if not is_recording_ghost or ghost_data.size() >= MAX_GHOST_FRAMES:
		return

	ghost_data.append({
		"time": level_time,
		"position": position,
		"velocity": velocity,
		"animation": animation,
		"flip_h": flip_h
	})

func get_ghost_frame_at_time(time: float) -> Dictionary:
	if ghost_data.is_empty():
		return {}

	for i in range(ghost_data.size() - 1, -1, -1):
		if ghost_data[i].time <= time:
			return ghost_data[i]

	return ghost_data[0]

func format_time(time: float) -> String:
	var minutes = int(time) / 60
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 1000)
	return "%02d:%02d.%03d" % [minutes, seconds, milliseconds]

func get_level_index(level_id: String) -> int:
	return campaign_levels.find(level_id)

func get_next_level() -> String:
	var current_index = get_level_index(current_level_id)
	if current_index >= 0 and current_index < campaign_levels.size() - 1:
		return campaign_levels[current_index + 1]
	return ""

func is_level_unlocked(level_id: String) -> bool:
	var index = get_level_index(level_id)
	if index <= 0:
		return true  # First level always unlocked

	# Check if previous level is completed
	var prev_level = campaign_levels[index - 1]
	var save_data = SaveManager.get_level_data(prev_level)
	return save_data.has("completed") and save_data.completed
