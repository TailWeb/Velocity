extends Node2D
class_name BaseLevel
## Base Level - Foundation for all game levels
## Handles level setup, checkpoints, hazards, and completion

signal level_ready
signal checkpoint_activated(checkpoint: Node2D)
signal goal_reached

@export var level_id: String = ""
@export var level_name: String = "Untitled"
@export var background_music: String = "chapter1"
@export var spawn_position: Vector2 = Vector2(100, 400)
@export var enable_ghost: bool = true

# Level bounds
@export var level_bounds: Rect2 = Rect2(0, 0, 5000, 1000)

# References
@onready var player: Player = $Player
@onready var tilemap: TileMap = $TileMap
@onready var parallax_background: ParallaxBackground = $ParallaxBackground
@onready var hazards_container: Node2D = $Hazards
@onready var checkpoints_container: Node2D = $Checkpoints
@onready var collectibles_container: Node2D = $Collectibles
@onready var goal_area: Area2D = $Goal
@onready var camera: Camera2D
@onready var hud: GameHUD = $HUD
@onready var ghost_player: GhostPlayer = $GhostPlayer

# Level state
var current_checkpoint: Vector2 = Vector2.ZERO
var collected_stars: Array[int] = []
var is_level_complete: bool = false

func _ready() -> void:
	_setup_level()
	_connect_signals()
	_start_level()

func _setup_level() -> void:
	# Set spawn position
	current_checkpoint = spawn_position

	if player:
		player.global_position = spawn_position
		player.checkpoint_position = spawn_position
		camera = player.get_node_or_null("Camera2D")

	# Setup camera limits
	if camera:
		camera.limit_left = int(level_bounds.position.x)
		camera.limit_top = int(level_bounds.position.y)
		camera.limit_right = int(level_bounds.end.x)
		camera.limit_bottom = int(level_bounds.end.y)

	# Load ghost if available
	if ghost_player and enable_ghost:
		if ghost_player.load_ghost_data(level_id):
			ghost_player.visible = SaveManager.get_setting("show_ghost")
		else:
			ghost_player.visible = false

	# Setup background music
	AudioManager.play_music(background_music)

func _connect_signals() -> void:
	if player:
		player.died.connect(_on_player_died)
		player.respawned.connect(_on_player_respawned)
		player.checkpoint_reached.connect(_on_checkpoint_reached)

	if goal_area:
		goal_area.body_entered.connect(_on_goal_entered)

	# Connect all checkpoints
	if checkpoints_container:
		for checkpoint in checkpoints_container.get_children():
			if checkpoint is Area2D:
				checkpoint.body_entered.connect(_on_checkpoint_area_entered.bind(checkpoint))

	# Connect all collectibles
	if collectibles_container:
		var idx = 0
		for collectible in collectibles_container.get_children():
			if collectible is Area2D:
				collectible.body_entered.connect(_on_collectible_entered.bind(idx))
			idx += 1

	# Connect hazards
	if hazards_container:
		for hazard in hazards_container.get_children():
			if hazard is Area2D:
				hazard.body_entered.connect(_on_hazard_entered)

func _start_level() -> void:
	# Initialize game manager
	GameManager.start_level(level_id)

	# Start ghost playback
	if ghost_player and ghost_player.visible:
		ghost_player.start_playback()

	level_ready.emit()

func _process(delta: float) -> void:
	_check_out_of_bounds()
	_handle_input()

func _check_out_of_bounds() -> void:
	if player and not is_level_complete:
		# Death plane
		if player.global_position.y > level_bounds.end.y + 200:
			player.die()

func _handle_input() -> void:
	if Input.is_action_just_pressed("restart"):
		_restart_level()

	if Input.is_action_just_pressed("pause"):
		GameManager.toggle_pause()

func _on_player_died() -> void:
	if ghost_player:
		ghost_player.reset_playback()

func _on_player_respawned() -> void:
	if ghost_player and ghost_player.visible:
		ghost_player.start_playback()

func _on_checkpoint_reached(pos: Vector2) -> void:
	current_checkpoint = pos

func _on_checkpoint_area_entered(body: Node2D, checkpoint: Node2D) -> void:
	if body != player:
		return

	var checkpoint_pos = checkpoint.global_position
	if checkpoint_pos != current_checkpoint:
		current_checkpoint = checkpoint_pos
		player.set_checkpoint(checkpoint_pos)
		checkpoint_activated.emit(checkpoint)

		# Visual feedback for checkpoint
		_activate_checkpoint_visual(checkpoint)

func _activate_checkpoint_visual(checkpoint: Node2D) -> void:
	# Add glow effect, particle burst, etc.
	var sprite = checkpoint.get_node_or_null("Sprite2D")
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.CYAN, 0.2)

	AudioManager.play_sfx("checkpoint")

func _on_collectible_entered(body: Node2D, idx: int) -> void:
	if body != player:
		return

	if idx in collected_stars:
		return

	collected_stars.append(idx)

	# Get the collectible node
	var collectible = collectibles_container.get_child(idx)
	if collectible:
		# Collect animation
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(collectible, "scale", Vector2.ZERO, 0.2)
		tween.tween_property(collectible, "modulate:a", 0.0, 0.2)
		tween.tween_callback(collectible.queue_free)

	AudioManager.play_sfx("star_collect")

func _on_hazard_entered(body: Node2D) -> void:
	if body == player:
		player.die()

func _on_goal_entered(body: Node2D) -> void:
	if body != player or is_level_complete:
		return

	is_level_complete = true
	_complete_level()

func _complete_level() -> void:
	goal_reached.emit()

	# Stop player movement
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)

	# Stop ghost
	if ghost_player:
		ghost_player.stop_playback()

	# Notify game manager
	GameManager.complete_level()

	# Visual celebration
	_play_completion_effects()

func _play_completion_effects() -> void:
	AudioManager.play_sfx("level_complete")

	# Screen flash
	TransitionManager.flash(Color.WHITE, 0.15)

	# Camera zoom on player
	if camera:
		var tween = create_tween()
		tween.tween_property(camera, "zoom", Vector2(2.0, 2.0), 0.5).set_ease(Tween.EASE_OUT)

func _restart_level() -> void:
	# Quick restart without transition
	player.global_position = spawn_position
	player.velocity = Vector2.ZERO
	player.checkpoint_position = spawn_position
	current_checkpoint = spawn_position
	is_level_complete = false
	player.set_physics_process(true)

	if camera:
		camera.zoom = Vector2(1.5, 1.5)

	GameManager.respawn()

	if ghost_player:
		ghost_player.reset_playback()
		ghost_player.start_playback()

func proceed_to_next_level() -> void:
	var next_level = GameManager.get_next_level()
	if next_level != "":
		var path = "res://scenes/levels/%s.tscn" % next_level
		TransitionManager.transition_to_scene(path, TransitionManager.TransitionType.HORIZONTAL_WIPE)
	else:
		# Return to level select
		TransitionManager.transition_to_scene("res://scenes/ui/LevelSelect.tscn")
