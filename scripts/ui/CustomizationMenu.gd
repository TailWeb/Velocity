extends Control
class_name CustomizationMenu
## Customization Menu - Skins, colors, and trails selection

@onready var skin_grid: GridContainer = $MarginContainer/HBoxContainer/SkinPanel/SkinGrid
@onready var color_grid: GridContainer = $MarginContainer/HBoxContainer/ColorPanel/ColorGrid
@onready var trail_grid: GridContainer = $MarginContainer/HBoxContainer/TrailPanel/TrailGrid
@onready var preview_sprite: AnimatedSprite2D = $MarginContainer/HBoxContainer/PreviewPanel/PreviewSprite
@onready var preview_trail: GPUParticles2D = $MarginContainer/HBoxContainer/PreviewPanel/PreviewTrail
@onready var back_button: Button = $MarginContainer/BackButton
@onready var item_name_label: Label = $MarginContainer/HBoxContainer/PreviewPanel/ItemNameLabel
@onready var item_desc_label: Label = $MarginContainer/HBoxContainer/PreviewPanel/ItemDescLabel
@onready var unlock_label: Label = $MarginContainer/HBoxContainer/PreviewPanel/UnlockLabel

var selected_skin: String = ""
var selected_color: String = ""
var selected_trail: String = ""

func _ready() -> void:
	_load_current_customization()
	_populate_grids()
	_setup_back_button()
	_update_preview()
	_animate_entrance()

func _load_current_customization() -> void:
	selected_skin = CustomizationManager.current_skin
	selected_color = CustomizationManager.current_color
	selected_trail = CustomizationManager.current_trail

func _populate_grids() -> void:
	_populate_skin_grid()
	_populate_color_grid()
	_populate_trail_grid()

func _populate_skin_grid() -> void:
	if not skin_grid:
		return

	for child in skin_grid.get_children():
		child.queue_free()

	for skin_id in CustomizationManager.get_all_skins():
		var btn = _create_item_button(skin_id, "skin")
		skin_grid.add_child(btn)

func _populate_color_grid() -> void:
	if not color_grid:
		return

	for child in color_grid.get_children():
		child.queue_free()

	for color_id in CustomizationManager.get_all_colors():
		var btn = _create_color_button(color_id)
		color_grid.add_child(btn)

func _populate_trail_grid() -> void:
	if not trail_grid:
		return

	for child in trail_grid.get_children():
		child.queue_free()

	for trail_id in CustomizationManager.get_all_trails():
		var btn = _create_item_button(trail_id, "trail")
		trail_grid.add_child(btn)

func _create_item_button(item_id: String, category: String) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(80, 80)

	var is_unlocked = false
	var item_name = item_id.capitalize()

	if category == "skin":
		is_unlocked = CustomizationManager.is_skin_unlocked(item_id)
		var data = CustomizationManager.get_skin_data(item_id)
		item_name = data.get("name", item_id.capitalize())
	else:  # trail
		is_unlocked = CustomizationManager.is_trail_unlocked(item_id)
		var data = CustomizationManager.get_trail_data(item_id)
		item_name = data.get("name", item_id.capitalize())

	btn.text = item_name if is_unlocked else "?"
	btn.disabled = not is_unlocked

	# Style
	var style = StyleBoxFlat.new()
	if is_unlocked:
		style.bg_color = Color(0.1, 0.05, 0.2, 0.9)
		style.border_color = Color(0.3, 0.3, 0.4)

		# Highlight if currently selected
		var is_selected = (category == "skin" and item_id == selected_skin) or \
						  (category == "trail" and item_id == selected_trail)
		if is_selected:
			style.border_color = Color(0, 1, 1)
			style.shadow_color = Color(0, 1, 1, 0.3)
			style.shadow_size = 8
	else:
		style.bg_color = Color(0.05, 0.05, 0.1, 0.8)
		style.border_color = Color(0.2, 0.2, 0.25)

	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)

	btn.pressed.connect(_on_item_selected.bind(item_id, category))
	btn.mouse_entered.connect(_on_item_hover.bind(item_id, category))

	return btn

func _create_color_button(color_id: String) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(50, 50)

	var is_unlocked = CustomizationManager.is_color_unlocked(color_id)
	var color = CustomizationManager.get_color(color_id)

	btn.text = "" if is_unlocked else "?"
	btn.disabled = not is_unlocked

	var style = StyleBoxFlat.new()
	if is_unlocked:
		style.bg_color = color
		style.border_color = Color.WHITE if color_id == selected_color else color.darkened(0.3)
	else:
		style.bg_color = Color(0.1, 0.1, 0.15)
		style.border_color = Color(0.2, 0.2, 0.25)

	style.border_width_left = 3 if color_id == selected_color else 2
	style.border_width_top = 3 if color_id == selected_color else 2
	style.border_width_right = 3 if color_id == selected_color else 2
	style.border_width_bottom = 3 if color_id == selected_color else 2
	style.corner_radius_top_left = 25
	style.corner_radius_top_right = 25
	style.corner_radius_bottom_left = 25
	style.corner_radius_bottom_right = 25

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)

	btn.pressed.connect(_on_color_selected.bind(color_id))
	btn.mouse_entered.connect(_on_color_hover.bind(color_id))

	return btn

func _setup_back_button() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func _update_preview() -> void:
	# Update preview sprite with selected skin and color
	if preview_sprite:
		var color = CustomizationManager.get_color(selected_color)
		preview_sprite.modulate = color
		preview_sprite.play("idle")

	# Update preview trail
	if preview_trail:
		if selected_trail == "none":
			preview_trail.emitting = false
		else:
			preview_trail.emitting = true
			var material = preview_trail.process_material as ParticleProcessMaterial
			if material:
				material.color = CustomizationManager.get_color(selected_color)

func _show_item_info(item_id: String, category: String) -> void:
	var item_data: Dictionary = {}
	var is_unlocked: bool = false

	if category == "skin":
		item_data = CustomizationManager.get_skin_data(item_id)
		is_unlocked = CustomizationManager.is_skin_unlocked(item_id)
	elif category == "trail":
		item_data = CustomizationManager.get_trail_data(item_id)
		is_unlocked = CustomizationManager.is_trail_unlocked(item_id)
	elif category == "color":
		item_data = {"name": item_id.capitalize(), "description": "Player color", "unlock_condition": "default"}
		is_unlocked = CustomizationManager.is_color_unlocked(item_id)

	if item_name_label:
		item_name_label.text = item_data.get("name", item_id.capitalize())

	if item_desc_label:
		item_desc_label.text = item_data.get("description", "")

	if unlock_label:
		if is_unlocked:
			unlock_label.text = "UNLOCKED"
			unlock_label.modulate = Color.GREEN
		else:
			var condition = item_data.get("unlock_condition", "Unknown")
			unlock_label.text = "LOCKED: " + _format_unlock_condition(condition)
			unlock_label.modulate = Color(1, 0.5, 0.5)

func _format_unlock_condition(condition: String) -> String:
	match condition:
		"default": return "Available"
		"complete_chapter_1": return "Complete Chapter 1"
		"complete_chapter_2": return "Complete Chapter 2"
		"complete_chapter_3": return "Complete Chapter 3"
		"complete_all_levels": return "Complete all levels"
		"10_gold_medals": return "Earn 10 Gold Medals"
		"5_platinum_medals": return "Earn 5 Platinum Medals"
		"1_platinum_medal": return "Earn 1 Platinum Medal"
		"100_deaths": return "Die 100 times"
		"50_stars": return "Collect 50 Stars"
		"under_30_sec_any_level": return "Beat any level under 30 seconds"
		"all_colors_unlocked": return "Unlock all colors"
		_: return condition.replace("_", " ").capitalize()

func _on_item_selected(item_id: String, category: String) -> void:
	AudioManager.play_sfx("ui_confirm")

	if category == "skin":
		selected_skin = item_id
		CustomizationManager.set_skin(item_id)
	elif category == "trail":
		selected_trail = item_id
		CustomizationManager.set_trail(item_id)

	_populate_grids()  # Refresh to update selection highlighting
	_update_preview()

func _on_color_selected(color_id: String) -> void:
	AudioManager.play_sfx("ui_confirm")
	selected_color = color_id
	CustomizationManager.set_color(color_id)
	_populate_color_grid()  # Refresh
	_update_preview()

func _on_item_hover(item_id: String, category: String) -> void:
	AudioManager.play_sfx("ui_hover")
	_show_item_info(item_id, category)

func _on_color_hover(color_id: String) -> void:
	AudioManager.play_sfx("ui_hover")
	_show_item_info(color_id, "color")

func _on_back_pressed() -> void:
	AudioManager.play_sfx("ui_back")
	TransitionManager.transition_to_scene("res://scenes/ui/MainMenu.tscn")

func _animate_entrance() -> void:
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
