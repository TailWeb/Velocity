extends Node2D
class_name GhostPlayer
## Ghost replay of best time for speedrun comparison

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var trail: GPUParticles2D = $TrailParticles

var ghost_data: Array[Dictionary] = []
var current_frame_index: int = 0
var is_playing: bool = false
var playback_time: float = 0.0

const GHOST_ALPHA: float = 0.4
const GHOST_COLOR: Color = Color(1.0, 1.0, 1.0, 0.4)

func _ready() -> void:
	# Set ghost appearance
	modulate = GHOST_COLOR
	if sprite:
		sprite.modulate.a = GHOST_ALPHA

func load_ghost_data(level_id: String) -> bool:
	ghost_data = SaveManager.load_ghost_data(level_id)
	return ghost_data.size() > 0

func set_ghost_data(data: Array[Dictionary]) -> void:
	ghost_data = data

func start_playback() -> void:
	if ghost_data.is_empty():
		visible = false
		return

	visible = true
	is_playing = true
	playback_time = 0.0
	current_frame_index = 0

func stop_playback() -> void:
	is_playing = false
	visible = false

func reset_playback() -> void:
	playback_time = 0.0
	current_frame_index = 0
	if ghost_data.size() > 0:
		_apply_frame(ghost_data[0])

func _process(delta: float) -> void:
	if not is_playing or ghost_data.is_empty():
		return

	playback_time += delta

	# Find the appropriate frame
	while current_frame_index < ghost_data.size() - 1:
		if ghost_data[current_frame_index + 1].time <= playback_time:
			current_frame_index += 1
		else:
			break

	# Apply frame data with interpolation
	if current_frame_index < ghost_data.size():
		var current_data = ghost_data[current_frame_index]

		# Interpolate position if we have a next frame
		if current_frame_index < ghost_data.size() - 1:
			var next_data = ghost_data[current_frame_index + 1]
			var t = (playback_time - current_data.time) / max(0.001, next_data.time - current_data.time)
			t = clamp(t, 0.0, 1.0)

			global_position = current_data.position.lerp(next_data.position, t)
		else:
			global_position = current_data.position

		_apply_frame(current_data)

	# Check if playback is complete
	if current_frame_index >= ghost_data.size() - 1:
		if ghost_data.size() > 0 and playback_time > ghost_data[-1].time + 1.0:
			stop_playback()

func _apply_frame(frame_data: Dictionary) -> void:
	if sprite:
		if sprite.sprite_frames and sprite.sprite_frames.has_animation(frame_data.animation):
			if sprite.animation != frame_data.animation:
				sprite.play(frame_data.animation)
		sprite.flip_h = frame_data.flip_h

	# Trail based on velocity
	if trail:
		var speed = frame_data.velocity.length() if frame_data.has("velocity") else 0
		trail.emitting = speed > 200

func sync_with_time(time: float) -> void:
	playback_time = time

	# Binary search for correct frame
	var left = 0
	var right = ghost_data.size() - 1

	while left < right:
		var mid = (left + right + 1) / 2
		if ghost_data[mid].time <= time:
			left = mid
		else:
			right = mid - 1

	current_frame_index = left

	if current_frame_index < ghost_data.size():
		_apply_frame(ghost_data[current_frame_index])
		global_position = ghost_data[current_frame_index].position
