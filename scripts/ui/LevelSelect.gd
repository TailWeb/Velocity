extends Control
class_name LevelSelect
## Level Selection screen with chapter tabs and level grid

signal level_selected(level_id: String)

@onready var chapter_tabs: TabContainer = $MarginContainer/VBoxContainer/ChapterTabs
@onready var back_button: Button = $MarginContainer/BackButton
@onready var total_stars_label: Label = $MarginContainer/StatsPanel/TotalStarsLabel
@onready var total_medals_label: Label = $MarginContainer/StatsPanel/TotalMedalsLabel
@onready var playtime_label: Label = $MarginContainer/StatsPanel/PlaytimeLabel

var level_buttons: Dictionary = {}
var selected_level: String = ""

const CHAPTER_NAMES: Array[String] = ["CHAPTER 1: AWAKENING", "CHAPTER 2: ASCENSION", "CHAPTER 3: TERMINUS"]
const LEVELS_PER_CHAPTER: int = 5

const MEDAL_ICONS: Dictionary = {
	0: "none",
	1: "bronze",
	2: "silver",
	3: "gold",
	4: "platinum"
}

func _ready() -> void:
	_setup_chapters()
	_setup_back_button()
	_update_stats()
	_animate_entrance()

func _setup_chapters() -> void:
	if not chapter_tabs:
		return

	# Clear existing tabs
	for child in chapter_tabs.get_children():
		child.queue_free()

	# Create chapter tabs
	for chapter_idx in range(3):
		var chapter_container = _create_chapter_container(chapter_idx + 1)
		chapter_container.name = CHAPTER_NAMES[chapter_idx]
		chapter_tabs.add_child(chapter_container)

func _create_chapter_container(chapter_num: int) -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 20)

	var grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)

	# Get levels for this chapter
	var chapter_prefix = "ch%d_" % chapter_num

	for level_id in GameManager.campaign_levels:
		if level_id.begins_with(chapter_prefix):
			var level_button = _create_level_button(level_id)
			grid.add_child(level_button)
			level_buttons[level_id] = level_button

	container.add_child(grid)
	return container

func _create_level_button(level_id: String) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(180, 120)

	# Get level data
	var level_data = SaveManager.get_level_data(level_id)
	var is_unlocked = GameManager.is_level_unlocked(level_id)
	var is_completed = level_data.has("completed") and level_data.completed

	# Parse level number from ID
	var parts = level_id.split("_")
	var level_num = parts[1] if parts.size() > 1 else "??"
	var level_name = " ".join(parts.slice(2)).capitalize() if parts.size() > 2 else level_id

	# Build button content
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var num_label = Label.new()
	num_label.text = level_num.lstrip("0")
	num_label.add_theme_font_size_override("font_size", 36)
	num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var name_label = Label.new()
	name_label.text = level_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	vbox.add_child(num_label)
	vbox.add_child(name_label)

	# Medal indicator
	if is_completed and level_data.has("best_medal"):
		var medal_label = Label.new()
		var medal_type = MEDAL_ICONS.get(level_data.best_medal, "none")
		medal_label.text = medal_type.to_upper()
		medal_label.add_theme_font_size_override("font_size", 12)
		medal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		match medal_type:
			"bronze": medal_label.modulate = Color(0.8, 0.5, 0.2)
			"silver": medal_label.modulate = Color(0.75, 0.75, 0.8)
			"gold": medal_label.modulate = Color(1.0, 0.84, 0.0)
			"platinum": medal_label.modulate = Color(0.9, 0.9, 0.95)

		vbox.add_child(medal_label)

	# Best time
	if is_completed and level_data.has("best_time"):
		var time_label = Label.new()
		time_label.text = GameManager.format_time(level_data.best_time)
		time_label.add_theme_font_size_override("font_size", 11)
		time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		time_label.modulate = Color(0.7, 0.7, 0.8)
		vbox.add_child(time_label)

	button.add_child(vbox)

	# Style based on state
	var style_normal = StyleBoxFlat.new()
	var style_hover = StyleBoxFlat.new()
	var style_pressed = StyleBoxFlat.new()

	if not is_unlocked:
		# Locked
		style_normal.bg_color = Color(0.1, 0.1, 0.15, 0.8)
		style_normal.border_color = Color(0.3, 0.3, 0.35)
		button.disabled = true
		num_label.text = "?"
		name_label.text = "LOCKED"
		vbox.modulate = Color(0.5, 0.5, 0.5)
	elif is_completed:
		# Completed
		style_normal.bg_color = Color(0.05, 0.15, 0.1, 0.9)
		style_normal.border_color = Color(0.2, 0.8, 0.4)
		style_hover.bg_color = Color(0.1, 0.25, 0.15, 0.95)
		style_hover.border_color = Color(0.3, 1.0, 0.5)
	else:
		# Unlocked but not completed
		style_normal.bg_color = Color(0.1, 0.05, 0.2, 0.9)
		style_normal.border_color = Color(0, 1, 1)
		style_hover.bg_color = Color(0.15, 0.08, 0.3, 0.95)
		style_hover.border_color = Color(1, 0, 1)

	style_normal.border_width_left = 2
	style_normal.border_width_top = 2
	style_normal.border_width_right = 2
	style_normal.border_width_bottom = 2
	style_normal.corner_radius_top_left = 8
	style_normal.corner_radius_top_right = 8
	style_normal.corner_radius_bottom_left = 8
	style_normal.corner_radius_bottom_right = 8

	style_hover.border_width_left = 3
	style_hover.border_width_top = 3
	style_hover.border_width_right = 3
	style_hover.border_width_bottom = 3
	style_hover.corner_radius_top_left = 8
	style_hover.corner_radius_top_right = 8
	style_hover.corner_radius_bottom_left = 8
	style_hover.corner_radius_bottom_right = 8

	style_pressed.bg_color = style_hover.bg_color
	style_pressed.border_color = Color.WHITE
	style_pressed.border_width_left = 3
	style_pressed.border_width_top = 3
	style_pressed.border_width_right = 3
	style_pressed.border_width_bottom = 3
	style_pressed.corner_radius_top_left = 8
	style_pressed.corner_radius_top_right = 8
	style_pressed.corner_radius_bottom_left = 8
	style_pressed.corner_radius_bottom_right = 8

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("focus", style_hover)

	# Connect signal
	button.pressed.connect(_on_level_button_pressed.bind(level_id))
	button.mouse_entered.connect(_on_level_button_hover.bind(level_id))

	return button

func _setup_back_button() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func _update_stats() -> void:
	var total_stars = SaveManager.get_total_stars()
	var medals = SaveManager.get_total_medals()
	var playtime = SaveManager.save_data.player.total_playtime

	if total_stars_label:
		total_stars_label.text = "STARS: %d" % total_stars

	if total_medals_label:
		total_medals_label.text = "MEDALS: %d/%d/%d/%d" % [
			medals.platinum, medals.gold, medals.silver, medals.bronze
		]

	if playtime_label:
		var hours = int(playtime) / 3600
		var minutes = (int(playtime) % 3600) / 60
		playtime_label.text = "PLAYTIME: %02d:%02d" % [hours, minutes]

func _animate_entrance() -> void:
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func _on_level_button_pressed(level_id: String) -> void:
	selected_level = level_id
	AudioManager.play_sfx("ui_confirm")

	# Load level
	var level_path = "res://scenes/levels/%s.tscn" % level_id
	if ResourceLoader.exists(level_path):
		TransitionManager.transition_to_scene(level_path, TransitionManager.TransitionType.HORIZONTAL_WIPE)
	else:
		# Use procedural level or show error
		push_warning("Level scene not found: " + level_path)
		_load_procedural_level(level_id)

func _on_level_button_hover(level_id: String) -> void:
	AudioManager.play_sfx("ui_hover")

func _on_back_pressed() -> void:
	AudioManager.play_sfx("ui_back")
	TransitionManager.transition_to_scene("res://scenes/ui/MainMenu.tscn", TransitionManager.TransitionType.HORIZONTAL_WIPE)

func _load_procedural_level(level_id: String) -> void:
	# Load a base level scene and configure it
	var base_level = "res://scenes/levels/BaseLevel.tscn"
	if ResourceLoader.exists(base_level):
		GameManager.current_level_id = level_id
		TransitionManager.transition_to_scene(base_level, TransitionManager.TransitionType.HORIZONTAL_WIPE)
