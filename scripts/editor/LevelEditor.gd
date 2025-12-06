extends Node2D
class_name LevelEditor
## Level Editor - Create custom levels with tile placement, testing, and save/load

signal level_saved(path: String)
signal level_loaded(path: String)
signal test_started
signal test_ended

# Editor state
enum EditorMode { PLACE, ERASE, SELECT, TEST }
var current_mode: EditorMode = EditorMode.PLACE
var is_testing: bool = false

# Tile selection
var selected_tile_id: int = 0
var tile_categories: Dictionary = {
	"Platforms": [0, 1, 2, 3, 4],
	"Hazards": [16, 17, 18, 19, 20, 21],
	"Interactables": [32, 33, 34, 35],
	"Decorations": [48, 49, 50, 51, 52]
}

# Level data
var level_data: Dictionary = {
	"name": "Untitled Level",
	"author": "Player",
	"version": 1,
	"width": 100,
	"height": 50,
	"spawn_point": Vector2(64, 400),
	"goal_point": Vector2(3000, 400),
	"tiles": {},
	"objects": [],
	"background": "city_far",
	"music": "chapter1"
}

# Grid settings
const TILE_SIZE: int = 32
const GRID_COLOR: Color = Color(0.3, 0.3, 0.4, 0.3)
const GRID_MAJOR_COLOR: Color = Color(0.4, 0.4, 0.5, 0.5)

# Camera
var camera_position: Vector2 = Vector2.ZERO
var camera_zoom: float = 1.0
var is_panning: bool = false
var pan_start: Vector2 = Vector2.ZERO

# Nodes
@onready var tilemap: TileMap = $TileMap
@onready var camera: Camera2D = $Camera2D
@onready var ui_layer: CanvasLayer = $UILayer
@onready var grid_overlay: Node2D = $GridOverlay
@onready var cursor_preview: Sprite2D = $CursorPreview
@onready var player_spawn_marker: Sprite2D = $PlayerSpawnMarker
@onready var goal_marker: Sprite2D = $GoalMarker
@onready var test_player: CharacterBody2D = null

# UI Elements
@onready var tile_palette: Control = $UILayer/TilePalette
@onready var properties_panel: Control = $UILayer/PropertiesPanel
@onready var toolbar: Control = $UILayer/Toolbar
@onready var level_name_input: LineEdit = $UILayer/PropertiesPanel/LevelNameInput
@onready var save_button: Button = $UILayer/Toolbar/SaveButton
@onready var load_button: Button = $UILayer/Toolbar/LoadButton
@onready var test_button: Button = $UILayer/Toolbar/TestButton
@onready var menu_button: Button = $UILayer/Toolbar/MenuButton
@onready var mode_buttons: HBoxContainer = $UILayer/Toolbar/ModeButtons

func _ready() -> void:
	_setup_tilemap()
	_setup_ui()
	_setup_markers()
	_center_camera()

	AudioManager.play_music("editor")

func _setup_tilemap() -> void:
	if not tilemap:
		tilemap = TileMap.new()
		add_child(tilemap)

	# Configure tilemap layers
	# Layer 0: Background decorations
	# Layer 1: Main platforms/walls
	# Layer 2: Hazards
	# Layer 3: Foreground decorations

func _setup_ui() -> void:
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
	if load_button:
		load_button.pressed.connect(_on_load_pressed)
	if test_button:
		test_button.pressed.connect(_on_test_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

	_setup_tile_palette()
	_setup_mode_buttons()

func _setup_tile_palette() -> void:
	if not tile_palette:
		return

	# Create tile buttons for each category
	for category in tile_categories.keys():
		var category_label = Label.new()
		category_label.text = category
		category_label.add_theme_font_size_override("font_size", 14)
		tile_palette.add_child(category_label)

		var grid = GridContainer.new()
		grid.columns = 4

		for tile_id in tile_categories[category]:
			var tile_button = Button.new()
			tile_button.custom_minimum_size = Vector2(40, 40)
			tile_button.text = str(tile_id)
			tile_button.pressed.connect(_on_tile_selected.bind(tile_id))
			grid.add_child(tile_button)

		tile_palette.add_child(grid)

func _setup_mode_buttons() -> void:
	if not mode_buttons:
		return

	var modes = ["PLACE", "ERASE", "SELECT"]
	for i in range(modes.size()):
		var btn = Button.new()
		btn.text = modes[i]
		btn.toggle_mode = true
		btn.button_pressed = (i == 0)
		btn.pressed.connect(_on_mode_changed.bind(i))
		mode_buttons.add_child(btn)

func _setup_markers() -> void:
	# Player spawn marker
	if player_spawn_marker:
		player_spawn_marker.position = level_data.spawn_point
		player_spawn_marker.modulate = Color.GREEN

	# Goal marker
	if goal_marker:
		goal_marker.position = level_data.goal_point
		goal_marker.modulate = Color.MAGENTA

func _center_camera() -> void:
	if camera:
		camera.position = level_data.spawn_point

func _process(delta: float) -> void:
	if is_testing:
		_process_test_mode(delta)
	else:
		_process_edit_mode(delta)

func _process_edit_mode(delta: float) -> void:
	_handle_camera_input(delta)
	_update_cursor_preview()

func _process_test_mode(delta: float) -> void:
	# Test mode - player controls handled by player script
	if Input.is_action_just_pressed("editor_test") or Input.is_action_just_pressed("pause"):
		_end_test()

func _unhandled_input(event: InputEvent) -> void:
	if is_testing:
		return

	# Mouse input for tile placement
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton

		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				_place_tile_at_mouse()
			elif current_mode == EditorMode.PLACE:
				pass  # Stop placing

		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			if mouse_event.pressed:
				_erase_tile_at_mouse()

		elif mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
			is_panning = mouse_event.pressed
			pan_start = get_global_mouse_position()

		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(1.1)

		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(0.9)

	elif event is InputEventMouseMotion:
		var motion_event = event as InputEventMouseMotion

		if is_panning:
			var delta_pos = get_global_mouse_position() - pan_start
			camera.position -= delta_pos
			pan_start = get_global_mouse_position()

		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and current_mode == EditorMode.PLACE:
			_place_tile_at_mouse()

		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or current_mode == EditorMode.ERASE:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				_erase_tile_at_mouse()

	# Keyboard shortcuts
	if event is InputEventKey:
		var key_event = event as InputEventKey
		if key_event.pressed:
			if key_event.keycode == KEY_S and key_event.ctrl_pressed:
				_on_save_pressed()
			elif key_event.keycode == KEY_O and key_event.ctrl_pressed:
				_on_load_pressed()
			elif key_event.keycode == KEY_ENTER or key_event.keycode == KEY_F5:
				_on_test_pressed()
			elif key_event.keycode == KEY_ESCAPE:
				if is_testing:
					_end_test()
				else:
					_on_menu_pressed()

func _handle_camera_input(delta: float) -> void:
	var move_speed = 500.0 / camera_zoom

	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		camera.position.y -= move_speed * delta
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		camera.position.y += move_speed * delta
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		camera.position.x -= move_speed * delta
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		camera.position.x += move_speed * delta

func _zoom_camera(factor: float) -> void:
	camera_zoom = clamp(camera_zoom * factor, 0.25, 4.0)
	if camera:
		camera.zoom = Vector2(camera_zoom, camera_zoom)

func _get_tile_pos_at_mouse() -> Vector2i:
	var mouse_pos = get_global_mouse_position()
	return Vector2i(
		int(floor(mouse_pos.x / TILE_SIZE)),
		int(floor(mouse_pos.y / TILE_SIZE))
	)

func _update_cursor_preview() -> void:
	if not cursor_preview:
		return

	var tile_pos = _get_tile_pos_at_mouse()
	cursor_preview.position = Vector2(tile_pos) * TILE_SIZE + Vector2(TILE_SIZE/2, TILE_SIZE/2)

	match current_mode:
		EditorMode.PLACE:
			cursor_preview.modulate = Color(0, 1, 1, 0.5)
		EditorMode.ERASE:
			cursor_preview.modulate = Color(1, 0, 0, 0.5)
		EditorMode.SELECT:
			cursor_preview.modulate = Color(1, 1, 0, 0.5)

func _place_tile_at_mouse() -> void:
	if current_mode != EditorMode.PLACE:
		return

	var tile_pos = _get_tile_pos_at_mouse()
	_place_tile(tile_pos, selected_tile_id)

func _erase_tile_at_mouse() -> void:
	var tile_pos = _get_tile_pos_at_mouse()
	_erase_tile(tile_pos)

func _place_tile(pos: Vector2i, tile_id: int) -> void:
	if not tilemap:
		return

	# Store in level data
	var key = "%d,%d" % [pos.x, pos.y]
	level_data.tiles[key] = tile_id

	# Place in tilemap
	var atlas_coords = _get_atlas_coords(tile_id)
	tilemap.set_cell(1, pos, 0, atlas_coords)

	AudioManager.play_sfx("ui_select")

func _erase_tile(pos: Vector2i) -> void:
	if not tilemap:
		return

	var key = "%d,%d" % [pos.x, pos.y]
	level_data.tiles.erase(key)

	tilemap.erase_cell(1, pos)

func _get_atlas_coords(tile_id: int) -> Vector2i:
	# Convert tile ID to atlas coordinates (16 tiles per row)
	return Vector2i(tile_id % 16, tile_id / 16)

func _on_tile_selected(tile_id: int) -> void:
	selected_tile_id = tile_id
	current_mode = EditorMode.PLACE
	AudioManager.play_sfx("ui_select")

func _on_mode_changed(mode_idx: int) -> void:
	current_mode = mode_idx as EditorMode
	AudioManager.play_sfx("ui_select")

func _on_save_pressed() -> void:
	AudioManager.play_sfx("ui_confirm")
	_save_level()

func _on_load_pressed() -> void:
	AudioManager.play_sfx("ui_confirm")
	_show_load_dialog()

func _on_test_pressed() -> void:
	AudioManager.play_sfx("ui_confirm")
	if is_testing:
		_end_test()
	else:
		_start_test()

func _on_menu_pressed() -> void:
	AudioManager.play_sfx("ui_back")
	TransitionManager.transition_to_scene("res://scenes/ui/MainMenu.tscn")

func _save_level() -> void:
	# Update level data
	if level_name_input:
		level_data.name = level_name_input.text

	# Generate filename
	var filename = level_data.name.to_lower().replace(" ", "_")
	var path = "user://levels/" + filename + ".json"

	# Ensure directory exists
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("levels"):
		dir.make_dir("levels")

	# Save to file
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(level_data, "\t"))
		file.close()
		level_saved.emit(path)
		print("Level saved to: " + path)
	else:
		push_error("Failed to save level")

func _show_load_dialog() -> void:
	# Show file dialog or level browser
	var levels_path = "user://levels/"
	var dir = DirAccess.open(levels_path)

	if not dir:
		push_warning("No levels directory found")
		return

	var levels: Array[String] = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			levels.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	if levels.is_empty():
		push_warning("No levels found")
		return

	# For now, load the first level found (in a full implementation, show a dialog)
	_load_level(levels_path + levels[0])

func _load_level(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to load level: " + path)
		return

	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()

	if error != OK:
		push_error("Failed to parse level JSON")
		return

	level_data = json.get_data()
	_rebuild_tilemap()

	if level_name_input:
		level_name_input.text = level_data.name

	level_loaded.emit(path)
	print("Level loaded: " + path)

func _rebuild_tilemap() -> void:
	if not tilemap:
		return

	# Clear existing tiles
	tilemap.clear()

	# Place all tiles from level data
	for key in level_data.tiles:
		var parts = key.split(",")
		var pos = Vector2i(int(parts[0]), int(parts[1]))
		var tile_id = level_data.tiles[key]
		var atlas_coords = _get_atlas_coords(tile_id)
		tilemap.set_cell(1, pos, 0, atlas_coords)

	# Update markers
	if player_spawn_marker:
		player_spawn_marker.position = level_data.spawn_point
	if goal_marker:
		goal_marker.position = level_data.goal_point

func _start_test() -> void:
	is_testing = true
	test_started.emit()

	# Hide editor UI
	if ui_layer:
		ui_layer.visible = false

	# Spawn player
	var player_scene = preload("res://scenes/player/Player.tscn")
	test_player = player_scene.instantiate()
	test_player.global_position = level_data.spawn_point
	add_child(test_player)

	# Attach camera to player
	if camera:
		camera.reparent(test_player)
		camera.position = Vector2(0, -50)

	GameManager.start_level("custom_test", GameManager.GameMode.CLASSIC_RUNNER)

func _end_test() -> void:
	is_testing = false
	test_ended.emit()

	# Remove player
	if test_player:
		if camera:
			camera.reparent(self)
		test_player.queue_free()
		test_player = null

	# Show editor UI
	if ui_layer:
		ui_layer.visible = true

	# Reset camera
	_center_camera()

func _draw() -> void:
	if is_testing:
		return

	# Draw grid
	_draw_grid()

func _draw_grid() -> void:
	var viewport_rect = get_viewport_rect()
	var start_x = int(camera.position.x - viewport_rect.size.x / 2 / camera_zoom) / TILE_SIZE * TILE_SIZE
	var end_x = int(camera.position.x + viewport_rect.size.x / 2 / camera_zoom) / TILE_SIZE * TILE_SIZE + TILE_SIZE
	var start_y = int(camera.position.y - viewport_rect.size.y / 2 / camera_zoom) / TILE_SIZE * TILE_SIZE
	var end_y = int(camera.position.y + viewport_rect.size.y / 2 / camera_zoom) / TILE_SIZE * TILE_SIZE + TILE_SIZE

	# Minor grid lines
	for x in range(start_x, end_x, TILE_SIZE):
		var color = GRID_MAJOR_COLOR if x % (TILE_SIZE * 10) == 0 else GRID_COLOR
		draw_line(Vector2(x, start_y), Vector2(x, end_y), color)

	for y in range(start_y, end_y, TILE_SIZE):
		var color = GRID_MAJOR_COLOR if y % (TILE_SIZE * 10) == 0 else GRID_COLOR
		draw_line(Vector2(start_x, y), Vector2(end_x, y), color)
