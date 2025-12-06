extends Control
class_name MainMenu
## Main Menu - Entry point with stylish animations

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var play_button: Button = $VBoxContainer/ButtonContainer/PlayButton
@onready var editor_button: Button = $VBoxContainer/ButtonContainer/EditorButton
@onready var customize_button: Button = $VBoxContainer/ButtonContainer/CustomizeButton
@onready var settings_button: Button = $VBoxContainer/ButtonContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/ButtonContainer/QuitButton
@onready var version_label: Label = $VersionLabel
@onready var background: TextureRect = $Background
@onready var particles: GPUParticles2D = $BackgroundParticles

var selected_index: int = 0
var buttons: Array[Button] = []
var title_bob_time: float = 0.0

const NEON_CYAN: Color = Color(0.0, 1.0, 1.0)
const NEON_MAGENTA: Color = Color(1.0, 0.0, 1.0)
const NEON_VIOLET: Color = Color(0.6, 0.2, 1.0)

func _ready() -> void:
	_setup_buttons()
	_animate_entrance()
	AudioManager.play_music("menu")

func _setup_buttons() -> void:
	buttons = [play_button, editor_button, customize_button, settings_button, quit_button]

	for i in range(buttons.size()):
		var btn = buttons[i]
		if btn:
			btn.focus_entered.connect(_on_button_focus.bind(i))
			btn.mouse_entered.connect(_on_button_hover.bind(i))

	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if editor_button:
		editor_button.pressed.connect(_on_editor_pressed)
	if customize_button:
		customize_button.pressed.connect(_on_customize_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

	# Focus first button
	if play_button:
		play_button.grab_focus()

func _animate_entrance() -> void:
	# Fade in and slide animations
	modulate.a = 0.0

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

	# Title animation
	if title_label:
		title_label.position.y -= 50
		tween.tween_property(title_label, "position:y", title_label.position.y + 50, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Button stagger animation
	for i in range(buttons.size()):
		var btn = buttons[i]
		if btn:
			btn.modulate.a = 0.0
			btn.position.x -= 100
			tween.tween_property(btn, "modulate:a", 1.0, 0.3).set_delay(0.1 + i * 0.08)
			tween.tween_property(btn, "position:x", btn.position.x + 100, 0.3).set_delay(0.1 + i * 0.08).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	# Title glow animation
	title_bob_time += delta
	if title_label:
		var glow_intensity = 0.5 + sin(title_bob_time * 2.0) * 0.2
		title_label.modulate = NEON_CYAN.lerp(NEON_MAGENTA, (sin(title_bob_time) + 1.0) * 0.5)

	# Handle input
	if Input.is_action_just_pressed("ui_down"):
		_change_selection(1)
	elif Input.is_action_just_pressed("ui_up"):
		_change_selection(-1)

func _change_selection(direction: int) -> void:
	selected_index = (selected_index + direction + buttons.size()) % buttons.size()
	if buttons[selected_index]:
		buttons[selected_index].grab_focus()
	AudioManager.play_sfx("ui_select")

func _on_button_focus(index: int) -> void:
	selected_index = index
	_highlight_button(index)

func _on_button_hover(index: int) -> void:
	selected_index = index
	if buttons[index]:
		buttons[index].grab_focus()
	AudioManager.play_sfx("ui_hover")

func _highlight_button(index: int) -> void:
	for i in range(buttons.size()):
		var btn = buttons[i]
		if btn:
			if i == index:
				btn.modulate = NEON_CYAN
				var tween = create_tween()
				tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.1)
			else:
				btn.modulate = Color.WHITE
				btn.scale = Vector2.ONE

func _on_play_pressed() -> void:
	AudioManager.play_sfx("ui_confirm")
	TransitionManager.transition_to_scene("res://scenes/ui/LevelSelect.tscn", TransitionManager.TransitionType.HORIZONTAL_WIPE)

func _on_editor_pressed() -> void:
	AudioManager.play_sfx("ui_confirm")
	TransitionManager.transition_to_scene("res://scenes/editor/LevelEditor.tscn", TransitionManager.TransitionType.PIXELATE)

func _on_customize_pressed() -> void:
	AudioManager.play_sfx("ui_confirm")
	TransitionManager.transition_to_scene("res://scenes/ui/CustomizationMenu.tscn", TransitionManager.TransitionType.DIAMOND)

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("ui_confirm")
	# Show settings popup
	var settings_popup = preload("res://scenes/ui/SettingsPopup.tscn").instantiate()
	add_child(settings_popup)

func _on_quit_pressed() -> void:
	AudioManager.play_sfx("ui_confirm")
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(get_tree().quit)
