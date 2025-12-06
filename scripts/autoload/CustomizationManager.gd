extends Node
## CustomizationManager - Handles player customization options
## Manages skins, colors, trails, and visual effects

signal customization_changed(category: String, value: String)
signal item_unlocked(category: String, item_id: String)

# Color palette (Neon theme)
var COLOR_PALETTE: Dictionary = {
	"cyan": Color(0.0, 1.0, 1.0),
	"magenta": Color(1.0, 0.0, 1.0),
	"violet": Color(0.6, 0.2, 1.0),
	"pink": Color(1.0, 0.4, 0.7),
	"blue": Color(0.2, 0.4, 1.0),
	"green": Color(0.2, 1.0, 0.5),
	"yellow": Color(1.0, 1.0, 0.2),
	"orange": Color(1.0, 0.5, 0.0),
	"red": Color(1.0, 0.2, 0.3),
	"white": Color(1.0, 1.0, 1.0),
	"gold": Color(1.0, 0.84, 0.0),
	"rainbow": Color.WHITE  # Special - handled differently
}

# Skin definitions
var SKINS: Dictionary = {
	"default": {
		"name": "Runner",
		"description": "The classic runner",
		"unlock_condition": "default",
		"sprite_path": "res://assets/sprites/player/skins/default/"
	},
	"ninja": {
		"name": "Shadow",
		"description": "Silent and swift",
		"unlock_condition": "complete_chapter_1",
		"sprite_path": "res://assets/sprites/player/skins/ninja/"
	},
	"cyber": {
		"name": "Cyber",
		"description": "Enhanced with tech",
		"unlock_condition": "10_gold_medals",
		"sprite_path": "res://assets/sprites/player/skins/cyber/"
	},
	"ghost": {
		"name": "Phantom",
		"description": "Between worlds",
		"unlock_condition": "100_deaths",
		"sprite_path": "res://assets/sprites/player/skins/ghost/"
	},
	"neon": {
		"name": "Neon",
		"description": "Pure energy",
		"unlock_condition": "5_platinum_medals",
		"sprite_path": "res://assets/sprites/player/skins/neon/"
	},
	"glitch": {
		"name": "Glitch",
		"description": "Reality bender",
		"unlock_condition": "complete_all_levels",
		"sprite_path": "res://assets/sprites/player/skins/glitch/"
	}
}

# Trail definitions
var TRAILS: Dictionary = {
	"none": {
		"name": "None",
		"description": "No trail",
		"unlock_condition": "default",
		"particle_scene": null
	},
	"default": {
		"name": "Spark",
		"description": "Simple spark trail",
		"unlock_condition": "default",
		"particle_scene": "res://scenes/fx/trails/SparkTrail.tscn"
	},
	"flame": {
		"name": "Flame",
		"description": "Burning trail",
		"unlock_condition": "complete_chapter_2",
		"particle_scene": "res://scenes/fx/trails/FlameTrail.tscn"
	},
	"electric": {
		"name": "Electric",
		"description": "Crackling energy",
		"unlock_condition": "under_30_sec_any_level",
		"particle_scene": "res://scenes/fx/trails/ElectricTrail.tscn"
	},
	"pixel": {
		"name": "Pixel",
		"description": "Digital fragments",
		"unlock_condition": "50_stars",
		"particle_scene": "res://scenes/fx/trails/PixelTrail.tscn"
	},
	"rainbow": {
		"name": "Rainbow",
		"description": "All colors",
		"unlock_condition": "all_colors_unlocked",
		"particle_scene": "res://scenes/fx/trails/RainbowTrail.tscn"
	},
	"galaxy": {
		"name": "Galaxy",
		"description": "Cosmic dust",
		"unlock_condition": "1_platinum_medal",
		"particle_scene": "res://scenes/fx/trails/GalaxyTrail.tscn"
	}
}

# Current customization
var current_skin: String = "default"
var current_trail: String = "default"
var current_color: String = "cyan"

# Unlock tracking
var unlocked_skins: Array[String] = ["default"]
var unlocked_trails: Array[String] = ["none", "default"]
var unlocked_colors: Array[String] = ["cyan", "magenta", "violet"]

func _ready() -> void:
	call_deferred("_load_customization")

func _load_customization() -> void:
	var data = SaveManager.get_customization()
	current_skin = data.current_skin
	current_trail = data.current_trail
	current_color = data.current_color
	unlocked_skins = Array(data.unlocked_skins, TYPE_STRING, "", null)
	unlocked_trails = Array(data.unlocked_trails, TYPE_STRING, "", null)
	unlocked_colors = Array(data.unlocked_colors, TYPE_STRING, "", null)

func get_current_color() -> Color:
	if current_color == "rainbow":
		# Return cycling rainbow color
		var time = Time.get_ticks_msec() / 1000.0
		return Color.from_hsv(fmod(time * 0.5, 1.0), 1.0, 1.0)
	return COLOR_PALETTE.get(current_color, Color.CYAN)

func get_color(color_id: String) -> Color:
	return COLOR_PALETTE.get(color_id, Color.CYAN)

func set_skin(skin_id: String) -> bool:
	if skin_id in unlocked_skins and SKINS.has(skin_id):
		current_skin = skin_id
		_save_customization()
		customization_changed.emit("skin", skin_id)
		return true
	return false

func set_trail(trail_id: String) -> bool:
	if trail_id in unlocked_trails and TRAILS.has(trail_id):
		current_trail = trail_id
		_save_customization()
		customization_changed.emit("trail", trail_id)
		return true
	return false

func set_color(color_id: String) -> bool:
	if color_id in unlocked_colors and COLOR_PALETTE.has(color_id):
		current_color = color_id
		_save_customization()
		customization_changed.emit("color", color_id)
		return true
	return false

func unlock_skin(skin_id: String) -> void:
	if skin_id not in unlocked_skins and SKINS.has(skin_id):
		unlocked_skins.append(skin_id)
		SaveManager.unlock_skin(skin_id)
		item_unlocked.emit("skin", skin_id)

func unlock_trail(trail_id: String) -> void:
	if trail_id not in unlocked_trails and TRAILS.has(trail_id):
		unlocked_trails.append(trail_id)
		SaveManager.unlock_trail(trail_id)
		item_unlocked.emit("trail", trail_id)

func unlock_color(color_id: String) -> void:
	if color_id not in unlocked_colors and COLOR_PALETTE.has(color_id):
		unlocked_colors.append(color_id)
		SaveManager.unlock_color(color_id)
		item_unlocked.emit("color", color_id)

func is_skin_unlocked(skin_id: String) -> bool:
	return skin_id in unlocked_skins

func is_trail_unlocked(trail_id: String) -> bool:
	return trail_id in unlocked_trails

func is_color_unlocked(color_id: String) -> bool:
	return color_id in unlocked_colors

func get_skin_data(skin_id: String) -> Dictionary:
	return SKINS.get(skin_id, {})

func get_trail_data(trail_id: String) -> Dictionary:
	return TRAILS.get(trail_id, {})

func get_all_skins() -> Array[String]:
	var skins: Array[String] = []
	for skin_id in SKINS.keys():
		skins.append(skin_id)
	return skins

func get_all_trails() -> Array[String]:
	var trails: Array[String] = []
	for trail_id in TRAILS.keys():
		trails.append(trail_id)
	return trails

func get_all_colors() -> Array[String]:
	var colors: Array[String] = []
	for color_id in COLOR_PALETTE.keys():
		colors.append(color_id)
	return colors

func _save_customization() -> void:
	SaveManager.set_customization(current_skin, current_trail, current_color)

func check_unlocks() -> void:
	# Check for new unlocks based on game progress
	var save_data = SaveManager.save_data

	# Check skin unlocks
	for skin_id in SKINS.keys():
		if skin_id in unlocked_skins:
			continue

		var condition = SKINS[skin_id].unlock_condition
		if _check_condition(condition, save_data):
			unlock_skin(skin_id)

	# Check trail unlocks
	for trail_id in TRAILS.keys():
		if trail_id in unlocked_trails:
			continue

		var condition = TRAILS[trail_id].unlock_condition
		if _check_condition(condition, save_data):
			unlock_trail(trail_id)

	# Check color unlocks (earned through medals and progression)
	var medals = SaveManager.get_total_medals()

	if medals.gold >= 5 and "blue" not in unlocked_colors:
		unlock_color("blue")
	if medals.gold >= 10 and "green" not in unlocked_colors:
		unlock_color("green")
	if medals.platinum >= 1 and "gold" not in unlocked_colors:
		unlock_color("gold")
	if medals.platinum >= 5 and "rainbow" not in unlocked_colors:
		unlock_color("rainbow")
	if save_data.player.total_deaths >= 500 and "red" not in unlocked_colors:
		unlock_color("red")

func _check_condition(condition: String, save_data: Dictionary) -> bool:
	match condition:
		"default":
			return true
		"complete_chapter_1":
			return _is_chapter_complete(1, save_data)
		"complete_chapter_2":
			return _is_chapter_complete(2, save_data)
		"complete_chapter_3":
			return _is_chapter_complete(3, save_data)
		"complete_all_levels":
			return _all_levels_complete(save_data)
		"10_gold_medals":
			var medals = SaveManager.get_total_medals()
			return medals.gold + medals.platinum >= 10
		"5_platinum_medals":
			var medals = SaveManager.get_total_medals()
			return medals.platinum >= 5
		"1_platinum_medal":
			var medals = SaveManager.get_total_medals()
			return medals.platinum >= 1
		"100_deaths":
			return save_data.player.total_deaths >= 100
		"50_stars":
			return SaveManager.get_total_stars() >= 50
		"under_30_sec_any_level":
			for level_id in save_data.levels:
				if save_data.levels[level_id].best_time <= 30.0:
					return true
			return false
		"all_colors_unlocked":
			return unlocked_colors.size() >= COLOR_PALETTE.size() - 1  # Exclude rainbow itself

	return false

func _is_chapter_complete(chapter: int, save_data: Dictionary) -> bool:
	var chapter_prefix = "ch%d_" % chapter
	for level_id in GameManager.campaign_levels:
		if level_id.begins_with(chapter_prefix):
			if not save_data.levels.has(level_id) or not save_data.levels[level_id].completed:
				return false
	return true

func _all_levels_complete(save_data: Dictionary) -> bool:
	for level_id in GameManager.campaign_levels:
		if not save_data.levels.has(level_id) or not save_data.levels[level_id].completed:
			return false
	return true
