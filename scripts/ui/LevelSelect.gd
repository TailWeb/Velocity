extends Control
class_name LevelSelect
## Level Selection screen with chapter tabs and level grid

signal level_selected(level_id: String)

@onready var chapter_tabs: TabContainer = $MarginContainer/VBoxContainer/ChapterTabs
@onready var back_button: Button = $MarginContainer/VBoxContainer/HeaderContainer/BackButton
@onready var total_stars_label: Label = $MarginContainer/VBoxContainer/StatsPanel/TotalStarsLabel
@onready var total_medals_label: Label = $MarginContainer/VBoxContainer/StatsPanel/TotalMedalsLabel
@onready var playtime_label: Label = $MarginContainer/VBoxContainer/StatsPanel/PlaytimeLabel

var level_buttons: Dictionary = {}
var selected_level: String = ""

const CHAPTER_NAMES: Array[String] = ["CHAPTER 1", "CHAPTER 2", "CHAPTER 3"]
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
		push_error("ChapterTabs not found!")
		return

	# Clear existing tabs
	for child in chapter_tabs.get_children():
		child.queue_free()

	# Wait a frame for cleanup
	await get_tree().process_frame

	# Create chapter tabs
	for chapter_idx in range(3):
		var chapter_container = _create_chapter_container(chapter_idx + 1)
		chapter_container.name = CHAPTER_NAMES[chapter_idx]
		chapter_tabs.add_child(chapter_container)

func _create_chapter_container(chapter_num: int) -> Control:
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_bottom", 30)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 25)
	grid.add_theme_constant_override("v_separation", 25)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Get levels for this chapter
	var chapter_prefix = "ch%d_" % chapter_num
	var level_count = 0

	for level_id in GameManager.campaign_levels:
		if level_id.begins_with(chapter_prefix):
			var level_button = _create_level_button(level_id)
			grid.add_child(level_button)
			level_buttons[level_id] = level_button
			level_count += 1

	if level_count == 0:
		var empty_label = Label.new()
		empty_label.text = "No levels yet"
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		grid.add_child(empty_label)

	margin.add_child(grid)
	scroll.add_child(margin)
	return scroll

func _create_level_button(level_id: String) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(160, 140)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

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
	vbox.add_theme_constant_override("separation", 5)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 10
	vbox.offset_right = -10
	vbox.offset_top = 10
	vbox.offset_bottom = -10

	var num_label = Label.new()
	num_label.text = level_num.lstrip("0")
	if num_label.text == "":
		num_label.text = "0"
	num_label.add_theme_font_size_override("font_size", 42)
	num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var name_label = Label.new()
	name_label.text = level_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD

	vbox.add_child(num_label)
	vbox.add_child(name_label)

	# Medal indicator
	if is_completed and level_data.has("best_medal"):
		var medal_label = Label.new()
		var medal_type = MEDAL_ICONS.get(level_data.best_medal, "none")
		medal_label.text = medal_type.to_upper()
		medal_label.add_theme_font_size_override("font_size", 13)
		medal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		match medal_type:
			"bronze": medal_label.add_theme_color_override("font_color", Color(0.8, 0.5, 0.2))
			"silver": medal_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
			"gold": medal_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
			"platinum": medal_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))

		vbox.add_child(medal_label)

	# Best time
	if is_completed and level_data.has("best_time"):
		var time_label = Label.new()
		time_label.text = GameManager.format_time(level_data.best_time)
		time_label.add_theme_font_size_override("font_size", 12)
		time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		time_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		vbox.add_child(time_label)

	button.add_child(vbox)

	# Style based on state
	var style_normal = StyleBoxFlat.new()
	var style_hover = StyleBoxFlat.new()
	var style_pressed = StyleBoxFlat.new()
	var style_disabled = StyleBoxFlat.new()

	# Common style properties
	for style in [style_normal, style_hover, style_pressed, style_disabled]:
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2

	if not is_unlocked:
		# Locked
		style_normal.bg_color = Color(0.08, 0.08, 0.12, 0.9)
		style_normal.border_color = Color(0.25, 0.25, 0.3)
		style_disabled.bg_color = style_normal.bg_color
		style_disabled.border_color = style_normal.border_color
		button.disabled = true
		num_label.text = "?"
		name_label.text = "LOCKED"
		num_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
		name_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	elif is_completed:
		# Completed - green theme
		style_normal.bg_color = Color(0.05, 0.15, 0.08, 0.95)
		style_normal.border_color = Color(0.2, 0.8, 0.4)
		style_hover.bg_color = Color(0.08, 0.22, 0.12, 0.98)
		style_hover.border_color = Color(0.3, 1.0, 0.5)
		style_hover.shadow_color = Color(0.2, 1.0, 0.4, 0.3)
		style_hover.shadow_size = 8
		style_pressed.bg_color = Color(0.1, 0.25, 0.15, 1.0)
		style_pressed.border_color = Color.WHITE
		num_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	else:
		# Unlocked but not completed - cyan theme
		style_normal.bg_color = Color(0.08, 0.05, 0.18, 0.95)
		style_normal.border_color = Color(0, 0.9, 0.9)
		style_hover.bg_color = Color(0.12, 0.08, 0.25, 0.98)
		style_hover.border_color = Color(1, 0, 1)
		style_hover.shadow_color = Color(1, 0, 1, 0.3)
		style_hover.shadow_size = 8
		style_pressed.bg_color = Color(0.15, 0.1, 0.3, 1.0)
		style_pressed.border_color = Color.WHITE
		num_label.add_theme_color_override("font_color", Color(0, 1, 1))

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("disabled", style_disabled)
	button.add_theme_stylebox_override("focus", style_hover)

	# Connect signals
	if not button.disabled:
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
	level_selected.emit(level_id)

	# Load level
	var level_path = "res://scenes/levels/%s.tscn" % level_id
	if ResourceLoader.exists(level_path):
		TransitionManager.transition_to_scene(level_path, TransitionManager.TransitionType.HORIZONTAL_WIPE)
	else:
		# Use base level
		_load_procedural_level(level_id)

func _on_level_button_hover(level_id: String) -> void:
	AudioManager.play_sfx("ui_hover")

func _on_back_pressed() -> void:
	AudioManager.play_sfx("ui_back")
	TransitionManager.transition_to_scene("res://scenes/ui/MainMenu.tscn", TransitionManager.TransitionType.HORIZONTAL_WIPE)

func _load_procedural_level(level_id: String) -> void:
	var base_level = "res://scenes/levels/BaseLevel.tscn"
	if ResourceLoader.exists(base_level):
		GameManager.current_level_id = level_id
		TransitionManager.transition_to_scene(base_level, TransitionManager.TransitionType.HORIZONTAL_WIPE)
