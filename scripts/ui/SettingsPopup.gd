extends Control
class_name SettingsPopup
## Settings Popup - Audio, visuals, and gameplay settings

@onready var panel: Panel = $Panel
@onready var close_button: Button = $Panel/CloseButton
@onready var master_slider: HSlider = $Panel/VBoxContainer/MasterVolume/Slider
@onready var music_slider: HSlider = $Panel/VBoxContainer/MusicVolume/Slider
@onready var sfx_slider: HSlider = $Panel/VBoxContainer/SFXVolume/Slider
@onready var screen_shake_toggle: CheckButton = $Panel/VBoxContainer/ScreenShake/Toggle
@onready var show_timer_toggle: CheckButton = $Panel/VBoxContainer/ShowTimer/Toggle
@onready var show_ghost_toggle: CheckButton = $Panel/VBoxContainer/ShowGhost/Toggle
@onready var show_deaths_toggle: CheckButton = $Panel/VBoxContainer/ShowDeaths/Toggle
@onready var particles_toggle: CheckButton = $Panel/VBoxContainer/Particles/Toggle
@onready var speedrun_toggle: CheckButton = $Panel/VBoxContainer/SpeedrunMode/Toggle
@onready var fullscreen_toggle: CheckButton = $Panel/VBoxContainer/Fullscreen/Toggle

func _ready() -> void:
	_load_settings()
	_connect_signals()
	_animate_open()

func _load_settings() -> void:
	if master_slider:
		master_slider.value = AudioManager.get_master_volume()
	if music_slider:
		music_slider.value = AudioManager.get_music_volume()
	if sfx_slider:
		sfx_slider.value = AudioManager.get_sfx_volume()

	if screen_shake_toggle:
		screen_shake_toggle.button_pressed = SaveManager.get_setting("screen_shake")
	if show_timer_toggle:
		show_timer_toggle.button_pressed = SaveManager.get_setting("show_timer")
	if show_ghost_toggle:
		show_ghost_toggle.button_pressed = SaveManager.get_setting("show_ghost")
	if show_deaths_toggle:
		show_deaths_toggle.button_pressed = SaveManager.get_setting("show_death_count")
	if particles_toggle:
		particles_toggle.button_pressed = SaveManager.get_setting("particles_enabled")
	if speedrun_toggle:
		speedrun_toggle.button_pressed = SaveManager.get_setting("speedrun_mode")
	if fullscreen_toggle:
		fullscreen_toggle.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

func _connect_signals() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	if master_slider:
		master_slider.value_changed.connect(_on_master_changed)
	if music_slider:
		music_slider.value_changed.connect(_on_music_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_changed)

	if screen_shake_toggle:
		screen_shake_toggle.toggled.connect(_on_screen_shake_toggled)
	if show_timer_toggle:
		show_timer_toggle.toggled.connect(_on_show_timer_toggled)
	if show_ghost_toggle:
		show_ghost_toggle.toggled.connect(_on_show_ghost_toggled)
	if show_deaths_toggle:
		show_deaths_toggle.toggled.connect(_on_show_deaths_toggled)
	if particles_toggle:
		particles_toggle.toggled.connect(_on_particles_toggled)
	if speedrun_toggle:
		speedrun_toggle.toggled.connect(_on_speedrun_toggled)
	if fullscreen_toggle:
		fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)

func _animate_open() -> void:
	modulate.a = 0.0
	if panel:
		panel.scale = Vector2(0.8, 0.8)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	if panel:
		tween.tween_property(panel, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _animate_close() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	if panel:
		tween.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.15)
	tween.tween_callback(queue_free)

func _on_close_pressed() -> void:
	AudioManager.play_sfx("ui_back")
	_animate_close()

func _on_master_changed(value: float) -> void:
	AudioManager.set_master_volume(value)
	SaveManager.set_setting("master_volume", value)

func _on_music_changed(value: float) -> void:
	AudioManager.set_music_volume(value)
	SaveManager.set_setting("music_volume", value)

func _on_sfx_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value)
	SaveManager.set_setting("sfx_volume", value)
	AudioManager.play_sfx("ui_select")

func _on_screen_shake_toggled(enabled: bool) -> void:
	SaveManager.set_setting("screen_shake", enabled)
	AudioManager.play_sfx("ui_select")

func _on_show_timer_toggled(enabled: bool) -> void:
	SaveManager.set_setting("show_timer", enabled)
	AudioManager.play_sfx("ui_select")

func _on_show_ghost_toggled(enabled: bool) -> void:
	SaveManager.set_setting("show_ghost", enabled)
	AudioManager.play_sfx("ui_select")

func _on_show_deaths_toggled(enabled: bool) -> void:
	SaveManager.set_setting("show_death_count", enabled)
	AudioManager.play_sfx("ui_select")

func _on_particles_toggled(enabled: bool) -> void:
	SaveManager.set_setting("particles_enabled", enabled)
	AudioManager.play_sfx("ui_select")

func _on_speedrun_toggled(enabled: bool) -> void:
	SaveManager.set_setting("speedrun_mode", enabled)
	AudioManager.play_sfx("ui_select")

func _on_fullscreen_toggled(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	AudioManager.play_sfx("ui_select")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
