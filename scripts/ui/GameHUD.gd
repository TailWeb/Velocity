extends CanvasLayer
class_name GameHUD
## In-game HUD - Timer, death count, medal progress, speedrun info

@onready var timer_label: Label = $MarginContainer/TopBar/TimerContainer/TimerLabel
@onready var best_time_label: Label = $MarginContainer/TopBar/TimerContainer/BestTimeLabel
@onready var death_label: Label = $MarginContainer/TopBar/DeathContainer/DeathLabel
@onready var attempt_label: Label = $MarginContainer/TopBar/AttemptLabel
@onready var medal_progress: ProgressBar = $MarginContainer/TopBar/MedalProgress
@onready var medal_icon: TextureRect = $MarginContainer/TopBar/MedalProgress/MedalIcon
@onready var level_name_label: Label = $MarginContainer/TopBar/LevelNameLabel
@onready var pause_menu: Control = $PauseMenu
@onready var completion_panel: Control = $CompletionPanel

var is_paused: bool = false
var current_medal_threshold: float = 0.0
var medal_thresholds: Dictionary = {}

const MEDAL_COLORS: Dictionary = {
	"none": Color(0.5, 0.5, 0.5),
	"bronze": Color(0.8, 0.5, 0.2),
	"silver": Color(0.75, 0.75, 0.8),
	"gold": Color(1.0, 0.84, 0.0),
	"platinum": Color(0.9, 0.9, 0.95)
}

func _ready() -> void:
	GameManager.level_started.connect(_on_level_started)
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.player_died.connect(_on_player_died)
	GameManager.game_paused.connect(_on_game_paused)

	if pause_menu:
		pause_menu.visible = false
	if completion_panel:
		completion_panel.visible = false

func _process(_delta: float) -> void:
	_update_timer()
	_update_medal_progress()

func _update_timer() -> void:
	if not timer_label:
		return

	var time = GameManager.level_time
	timer_label.text = GameManager.format_time(time)

	# Color based on medal threshold
	var medal = _get_current_medal_tier(time)
	timer_label.modulate = MEDAL_COLORS.get(medal, Color.WHITE)

func _update_medal_progress() -> void:
	if not medal_progress or medal_thresholds.is_empty():
		return

	var time = GameManager.level_time

	# Find current and next medal threshold
	var thresholds = [
		medal_thresholds.get("platinum", 999),
		medal_thresholds.get("gold", 999),
		medal_thresholds.get("silver", 999),
		medal_thresholds.get("bronze", 999)
	]

	var next_threshold = 999.0
	for t in thresholds:
		if time < t:
			next_threshold = t

	if next_threshold < 999:
		medal_progress.max_value = next_threshold
		medal_progress.value = next_threshold - time
	else:
		medal_progress.value = 0

func _get_current_medal_tier(time: float) -> String:
	if medal_thresholds.is_empty():
		return "none"

	if time <= medal_thresholds.get("platinum", 0):
		return "platinum"
	elif time <= medal_thresholds.get("gold", 0):
		return "gold"
	elif time <= medal_thresholds.get("silver", 0):
		return "silver"
	elif time <= medal_thresholds.get("bronze", 0):
		return "bronze"
	return "none"

func _on_level_started(level_id: String) -> void:
	if level_name_label:
		level_name_label.text = _format_level_name(level_id)

	# Load medal thresholds
	if GameManager.medal_thresholds.has(level_id):
		medal_thresholds = GameManager.medal_thresholds[level_id]
	else:
		medal_thresholds = {}

	# Update best time display
	if best_time_label:
		if GameManager.best_time < INF:
			best_time_label.text = "BEST: " + GameManager.format_time(GameManager.best_time)
			best_time_label.visible = true
		else:
			best_time_label.visible = false

	# Reset UI
	_update_death_count()
	_update_attempt_count()

	if completion_panel:
		completion_panel.visible = false

func _on_level_completed(level_id: String, time: float, medals_data: Dictionary) -> void:
	_show_completion_panel(time, medals_data)

func _on_player_died() -> void:
	_update_death_count()
	_flash_death_counter()

func _on_game_paused(paused: bool) -> void:
	is_paused = paused
	if pause_menu:
		pause_menu.visible = paused
		if paused:
			_setup_pause_menu()

func _update_death_count() -> void:
	if death_label:
		death_label.text = str(GameManager.total_deaths)

func _update_attempt_count() -> void:
	if attempt_label:
		attempt_label.text = "ATTEMPT #" + str(GameManager.current_attempt)

func _flash_death_counter() -> void:
	if death_label:
		var tween = create_tween()
		tween.tween_property(death_label, "modulate", Color.RED, 0.1)
		tween.tween_property(death_label, "modulate", Color.WHITE, 0.2)
		tween.tween_property(death_label, "scale", Vector2(1.3, 1.3), 0.1)
		tween.tween_property(death_label, "scale", Vector2.ONE, 0.2)

func _format_level_name(level_id: String) -> String:
	# Convert ch1_01_awakening to "1-1 Awakening"
	var parts = level_id.split("_")
	if parts.size() >= 3:
		var chapter = parts[0].replace("ch", "")
		var number = parts[1].lstrip("0")
		if number == "":
			number = "0"
		var name_parts = parts.slice(2)
		var level_name = " ".join(name_parts).capitalize()
		return chapter + "-" + number + " " + level_name
	return level_id.capitalize()

func _show_completion_panel(time: float, medals_data: Dictionary) -> void:
	if not completion_panel:
		return

	completion_panel.visible = true

	# Animate panel entrance
	completion_panel.modulate.a = 0.0
	completion_panel.scale = Vector2(0.8, 0.8)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(completion_panel, "modulate:a", 1.0, 0.3)
	tween.tween_property(completion_panel, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Update completion panel content
	var time_label = completion_panel.get_node_or_null("TimeLabel")
	if time_label:
		time_label.text = GameManager.format_time(time)

	var medal_label = completion_panel.get_node_or_null("MedalLabel")
	if medal_label:
		var medal_name = GameManager.MedalType.keys()[medals_data.medal]
		medal_label.text = medal_name
		medal_label.modulate = MEDAL_COLORS.get(medal_name.to_lower(), Color.WHITE)

	var new_best = completion_panel.get_node_or_null("NewBestLabel")
	if new_best:
		new_best.visible = medals_data.is_new_best

func _setup_pause_menu() -> void:
	if not pause_menu:
		return

	var resume_btn = pause_menu.get_node_or_null("ResumeButton")
	var restart_btn = pause_menu.get_node_or_null("RestartButton")
	var menu_btn = pause_menu.get_node_or_null("MenuButton")

	if resume_btn and not resume_btn.pressed.is_connected(_on_resume_pressed):
		resume_btn.pressed.connect(_on_resume_pressed)
	if restart_btn and not restart_btn.pressed.is_connected(_on_restart_pressed):
		restart_btn.pressed.connect(_on_restart_pressed)
	if menu_btn and not menu_btn.pressed.is_connected(_on_menu_pressed):
		menu_btn.pressed.connect(_on_menu_pressed)

	if resume_btn:
		resume_btn.grab_focus()

func _on_resume_pressed() -> void:
	GameManager.toggle_pause()

func _on_restart_pressed() -> void:
	GameManager.toggle_pause()
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	GameManager.toggle_pause()
	TransitionManager.transition_to_scene("res://scenes/ui/MainMenu.tscn")
