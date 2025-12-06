extends Node
## InputManager - Handles input buffering and advanced input processing
## Provides coyote time, jump buffering, and input state management

signal input_action(action: String, pressed: bool)

# Input buffer settings
const JUMP_BUFFER_TIME: float = 0.12
const DASH_BUFFER_TIME: float = 0.1
const COYOTE_TIME: float = 0.1
const WALL_COYOTE_TIME: float = 0.08

# Buffer states
var jump_buffer_timer: float = 0.0
var dash_buffer_timer: float = 0.0
var coyote_timer: float = 0.0
var wall_coyote_timer: float = 0.0
var wall_coyote_direction: int = 0

# Input states
var move_direction: float = 0.0
var is_jump_pressed: bool = false
var is_jump_just_pressed: bool = false
var is_dash_pressed: bool = false
var is_dash_just_pressed: bool = false
var is_slide_pressed: bool = false
var is_restart_pressed: bool = false
var is_pause_pressed: bool = false

# Advanced input tracking
var last_horizontal_direction: int = 1
var input_sequence: Array[Dictionary] = []
var max_sequence_length: int = 10

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	_update_buffers(delta)
	_update_input_states()

func _update_buffers(delta: float) -> void:
	# Decrease buffer timers
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta

	if dash_buffer_timer > 0:
		dash_buffer_timer -= delta

	if coyote_timer > 0:
		coyote_timer -= delta

	if wall_coyote_timer > 0:
		wall_coyote_timer -= delta

func _update_input_states() -> void:
	# Movement
	var left = Input.get_action_strength("move_left")
	var right = Input.get_action_strength("move_right")
	move_direction = right - left

	if move_direction != 0:
		last_horizontal_direction = sign(move_direction)

	# Jump
	is_jump_just_pressed = Input.is_action_just_pressed("jump")
	is_jump_pressed = Input.is_action_pressed("jump")

	if is_jump_just_pressed:
		jump_buffer_timer = JUMP_BUFFER_TIME
		_record_input("jump", true)

	# Dash
	is_dash_just_pressed = Input.is_action_just_pressed("dash")
	is_dash_pressed = Input.is_action_pressed("dash")

	if is_dash_just_pressed:
		dash_buffer_timer = DASH_BUFFER_TIME
		_record_input("dash", true)

	# Slide
	is_slide_pressed = Input.is_action_pressed("slide")

	# Game control
	is_restart_pressed = Input.is_action_just_pressed("restart")
	is_pause_pressed = Input.is_action_just_pressed("pause")

	# Emit input events
	if is_jump_just_pressed:
		input_action.emit("jump", true)
	if Input.is_action_just_released("jump"):
		input_action.emit("jump", false)
	if is_dash_just_pressed:
		input_action.emit("dash", true)

func _record_input(action: String, pressed: bool) -> void:
	input_sequence.append({
		"action": action,
		"pressed": pressed,
		"time": Time.get_ticks_msec()
	})

	if input_sequence.size() > max_sequence_length:
		input_sequence.pop_front()

# Buffer consumption methods
func consume_jump_buffer() -> bool:
	if jump_buffer_timer > 0:
		jump_buffer_timer = 0.0
		return true
	return false

func consume_dash_buffer() -> bool:
	if dash_buffer_timer > 0:
		dash_buffer_timer = 0.0
		return true
	return false

func has_jump_buffer() -> bool:
	return jump_buffer_timer > 0

func has_dash_buffer() -> bool:
	return dash_buffer_timer > 0

# Coyote time methods
func start_coyote_time() -> void:
	coyote_timer = COYOTE_TIME

func start_wall_coyote_time(wall_direction: int) -> void:
	wall_coyote_timer = WALL_COYOTE_TIME
	wall_coyote_direction = wall_direction

func has_coyote_time() -> bool:
	return coyote_timer > 0

func has_wall_coyote_time() -> bool:
	return wall_coyote_timer > 0

func consume_coyote_time() -> bool:
	if coyote_timer > 0:
		coyote_timer = 0.0
		return true
	return false

func consume_wall_coyote_time() -> int:
	if wall_coyote_timer > 0:
		wall_coyote_timer = 0.0
		return wall_coyote_direction
	return 0

# Helper methods
func get_movement_vector() -> Vector2:
	return Vector2(move_direction, 0)

func get_aim_direction() -> Vector2:
	# For dash direction - combines horizontal input with vertical
	var vertical = 0.0
	if Input.is_action_pressed("jump"):
		vertical = -1.0
	elif is_slide_pressed:
		vertical = 1.0

	var dir = Vector2(move_direction, vertical)
	if dir.length() > 0:
		return dir.normalized()
	else:
		return Vector2(last_horizontal_direction, 0)

func is_moving() -> bool:
	return abs(move_direction) > 0.1

func get_facing_direction() -> int:
	return last_horizontal_direction

# Reset all buffers (used on death/respawn)
func reset_buffers() -> void:
	jump_buffer_timer = 0.0
	dash_buffer_timer = 0.0
	coyote_timer = 0.0
	wall_coyote_timer = 0.0
	input_sequence.clear()
