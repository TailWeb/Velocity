extends Node
## SaveManager - Handles all persistent data storage
## Saves player progress, level completions, customization, and ghost data

signal save_completed
signal load_completed
signal data_corrupted(backup_restored: bool)

const SAVE_PATH = "user://velocity_save.json"
const GHOST_PATH = "user://ghosts/"
const BACKUP_PATH = "user://velocity_save_backup.json"
const SETTINGS_PATH = "user://settings.json"

var save_data: Dictionary = {
	"version": 1,
	"player": {
		"name": "Runner",
		"total_deaths": 0,
		"total_playtime": 0.0,
		"player_level": 1,
		"experience": 0,
		"stars_collected": 0
	},
	"levels": {},
	"achievements": [],
	"customization": {
		"current_skin": "default",
		"current_trail": "default",
		"current_color": "cyan",
		"unlocked_skins": ["default"],
		"unlocked_trails": ["default", "none"],
		"unlocked_colors": ["cyan", "magenta", "violet"]
	},
	"settings": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"screen_shake": true,
		"show_timer": true,
		"show_ghost": true,
		"show_death_count": true,
		"particles_enabled": true,
		"speedrun_mode": false
	}
}

func _ready() -> void:
	_ensure_directories()
	load_game()

func _ensure_directories() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		if not dir.dir_exists("ghosts"):
			dir.make_dir("ghosts")

func save_game() -> void:
	# Update runtime stats
	save_data.player.total_deaths = GameManager.total_deaths
	save_data.player.total_playtime = GameManager.total_playtime

	# Create backup first
	if FileAccess.file_exists(SAVE_PATH):
		var backup = FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
		var original = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if backup and original:
			backup.store_string(original.get_as_text())
			original.close()
			backup.close()

	# Save main file
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		save_completed.emit()
	else:
		push_error("Failed to save game data")

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		# First time - use defaults
		save_game()
		load_completed.emit()
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		file.close()

		if error == OK:
			var loaded_data = json.get_data()
			if loaded_data is Dictionary:
				_merge_save_data(loaded_data)
				GameManager.total_deaths = save_data.player.total_deaths
				GameManager.total_playtime = save_data.player.total_playtime
				load_completed.emit()
				return

		# Data corrupted - try backup
		push_warning("Save data corrupted, attempting backup restore")
		if _restore_backup():
			data_corrupted.emit(true)
		else:
			data_corrupted.emit(false)
			save_game()

func _merge_save_data(loaded: Dictionary) -> void:
	# Deep merge to preserve new fields
	for key in loaded.keys():
		if save_data.has(key):
			if loaded[key] is Dictionary and save_data[key] is Dictionary:
				for subkey in loaded[key].keys():
					save_data[key][subkey] = loaded[key][subkey]
			else:
				save_data[key] = loaded[key]

func _restore_backup() -> bool:
	if not FileAccess.file_exists(BACKUP_PATH):
		return false

	var file = FileAccess.open(BACKUP_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		file.close()

		if error == OK:
			var loaded_data = json.get_data()
			if loaded_data is Dictionary:
				_merge_save_data(loaded_data)
				save_game()
				return true

	return false

func save_level_completion(level_id: String, time: float, medal: int) -> void:
	if not save_data.levels.has(level_id):
		save_data.levels[level_id] = {
			"completed": false,
			"best_time": INF,
			"best_medal": 0,
			"attempts": 0,
			"deaths": 0,
			"stars": [],
			"first_completion": 0.0
		}

	var level_data = save_data.levels[level_id]

	if not level_data.completed:
		level_data.first_completion = Time.get_unix_time_from_system()
		# Award experience for first completion
		add_experience(100 + (medal * 50))

	level_data.completed = true
	level_data.attempts = GameManager.current_attempt

	if time < level_data.best_time:
		level_data.best_time = time
		# Award experience for new best time
		add_experience(25)

	if medal > level_data.best_medal:
		level_data.best_medal = medal
		# Award experience for new medal
		add_experience(medal * 25)

	save_game()

func get_level_data(level_id: String) -> Dictionary:
	if save_data.levels.has(level_id):
		return save_data.levels[level_id]
	return {}

func save_ghost_data(level_id: String, ghost_frames: Array) -> void:
	var ghost_file = GHOST_PATH + level_id + ".ghost"
	var file = FileAccess.open(ghost_file, FileAccess.WRITE)
	if file:
		# Convert to serializable format
		var serializable = []
		for frame in ghost_frames:
			serializable.append({
				"t": frame.time,
				"x": frame.position.x,
				"y": frame.position.y,
				"vx": frame.velocity.x,
				"vy": frame.velocity.y,
				"a": frame.animation,
				"f": frame.flip_h
			})
		file.store_string(JSON.stringify(serializable))
		file.close()

func load_ghost_data(level_id: String) -> Array[Dictionary]:
	var ghost_file = GHOST_PATH + level_id + ".ghost"
	if not FileAccess.file_exists(ghost_file):
		return []

	var file = FileAccess.open(ghost_file, FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		file.close()

		if error == OK:
			var data = json.get_data()
			var result: Array[Dictionary] = []
			for frame in data:
				result.append({
					"time": frame.t,
					"position": Vector2(frame.x, frame.y),
					"velocity": Vector2(frame.vx, frame.vy),
					"animation": frame.a,
					"flip_h": frame.f
				})
			return result

	return []

func add_experience(amount: int) -> void:
	save_data.player.experience += amount
	# Level up every 1000 XP
	var new_level = 1 + (save_data.player.experience / 1000)
	if new_level > save_data.player.player_level:
		save_data.player.player_level = new_level
		# Could trigger unlock notification here

func unlock_skin(skin_id: String) -> void:
	if skin_id not in save_data.customization.unlocked_skins:
		save_data.customization.unlocked_skins.append(skin_id)
		save_game()

func unlock_trail(trail_id: String) -> void:
	if trail_id not in save_data.customization.unlocked_trails:
		save_data.customization.unlocked_trails.append(trail_id)
		save_game()

func unlock_color(color_id: String) -> void:
	if color_id not in save_data.customization.unlocked_colors:
		save_data.customization.unlocked_colors.append(color_id)
		save_game()

func set_customization(skin: String, trail: String, color: String) -> void:
	save_data.customization.current_skin = skin
	save_data.customization.current_trail = trail
	save_data.customization.current_color = color
	save_game()

func get_customization() -> Dictionary:
	return save_data.customization

func get_setting(key: String) -> Variant:
	if save_data.settings.has(key):
		return save_data.settings[key]
	return null

func set_setting(key: String, value: Variant) -> void:
	save_data.settings[key] = value
	save_game()

func get_total_stars() -> int:
	var total = 0
	for level_id in save_data.levels:
		total += save_data.levels[level_id].stars.size()
	return total

func get_total_medals() -> Dictionary:
	var medals = {"bronze": 0, "silver": 0, "gold": 0, "platinum": 0}
	for level_id in save_data.levels:
		var medal = save_data.levels[level_id].best_medal
		match medal:
			1: medals.bronze += 1
			2: medals.silver += 1
			3: medals.gold += 1
			4: medals.platinum += 1
	return medals

func unlock_achievement(achievement_id: String) -> void:
	if achievement_id not in save_data.achievements:
		save_data.achievements.append(achievement_id)
		save_game()
