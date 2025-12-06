extends CharacterBody2D
class_name Player
## Player Controller - Precision platformer movement
## Features: dash, double jump, wall-jump, wall-slide, coyote time, input buffering

signal died
signal respawned
signal checkpoint_reached(position: Vector2)
signal dash_started
signal dash_ended
signal jumped(is_double: bool)
signal wall_jumped(direction: int)
signal landed

# Movement constants
const GRAVITY: float = 1800.0
const MAX_FALL_SPEED: float = 1200.0
const GROUND_SPEED: float = 450.0
const AIR_SPEED: float = 400.0
const ACCELERATION: float = 2800.0
const DECELERATION: float = 2400.0
const AIR_ACCELERATION: float = 2000.0
const AIR_DECELERATION: float = 1200.0
const TURN_SPEED_MULTIPLIER: float = 1.8

# Jump constants
const JUMP_VELOCITY: float = -620.0
const JUMP_CUT_MULTIPLIER: float = 0.4
const DOUBLE_JUMP_VELOCITY: float = -550.0

# Dash constants
const DASH_SPEED: float = 900.0
const DASH_DURATION: float = 0.15
const DASH_COOLDOWN: float = 0.3

# Wall movement constants
const WALL_SLIDE_SPEED: float = 150.0
const WALL_JUMP_VELOCITY: Vector2 = Vector2(450.0, -580.0)
const WALL_JUMP_LOCK_TIME: float = 0.12
const WALL_STICK_TIME: float = 0.1

# State tracking
enum State { IDLE, RUNNING, JUMPING, FALLING, DASHING, WALL_SLIDING, DEAD, SPAWNING }
var current_state: State = State.IDLE
var previous_state: State = State.IDLE

# Jump tracking
var jumps_remaining: int = 2
var has_double_jump: bool = true

# Dash tracking
var can_dash: bool = true
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.RIGHT

# Wall tracking
var is_on_wall_left: bool = false
var is_on_wall_right: bool = false
var wall_direction: int = 0
var wall_stick_timer: float = 0.0
var wall_jump_lock_timer: float = 0.0

# Spawn/Death
var spawn_position: Vector2 = Vector2.ZERO
var checkpoint_position: Vector2 = Vector2.ZERO
var is_dead: bool = false

# Ghost recording
var ghost_record_timer: float = 0.0
const GHOST_RECORD_INTERVAL: float = 0.05

# Facing direction
var facing_direction: int = 1

# Components
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var wall_check_left: RayCast2D = $WallCheckLeft
@onready var wall_check_right: RayCast2D = $WallCheckRight
@onready var trail_particles: GPUParticles2D = $TrailParticles
@onready var dash_particles: GPUParticles2D = $DashParticles
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var state_machine: Node = $StateMachine

# Visual feedback
var squash_stretch: Vector2 = Vector2.ONE
var target_squash_stretch: Vector2 = Vector2.ONE

func _ready() -> void:
	spawn_position = global_position
	checkpoint_position = spawn_position
	_setup_visual_style()

func _setup_visual_style() -> void:
	# Apply customization
	var color = CustomizationManager.get_current_color()
	if sprite:
		sprite.modulate = color
	if trail_particles:
		var material = trail_particles.process_material as ParticleProcessMaterial
		if material:
			material.color = color

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Update timers
	_update_timers(delta)

	# Check wall contact
	_check_walls()

	# Handle state
	match current_state:
		State.IDLE, State.RUNNING:
			_state_ground(delta)
		State.JUMPING, State.FALLING:
			_state_air(delta)
		State.DASHING:
			_state_dash(delta)
		State.WALL_SLIDING:
			_state_wall_slide(delta)
		State.SPAWNING:
			_state_spawning(delta)

	# Apply movement
	move_and_slide()

	# Update visuals
	_update_animation()
	_update_visual_effects(delta)

	# Record ghost data
	_record_ghost(delta)

func _update_timers(delta: float) -> void:
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	if wall_jump_lock_timer > 0:
		wall_jump_lock_timer -= delta

	if wall_stick_timer > 0:
		wall_stick_timer -= delta

func _check_walls() -> void:
	is_on_wall_left = wall_check_left.is_colliding() if wall_check_left else false
	is_on_wall_right = wall_check_right.is_colliding() if wall_check_right else false

	if is_on_wall_left:
		wall_direction = -1
	elif is_on_wall_right:
		wall_direction = 1
	else:
		wall_direction = 0

func _state_ground(delta: float) -> void:
	var input_dir = InputManager.move_direction

	# Reset abilities on ground
	jumps_remaining = 2
	can_dash = true

	# Apply gravity
	velocity.y += GRAVITY * delta
	velocity.y = min(velocity.y, MAX_FALL_SPEED)

	# Horizontal movement
	_apply_horizontal_movement(delta, input_dir, GROUND_SPEED, ACCELERATION, DECELERATION)

	# Update facing
	if input_dir != 0:
		facing_direction = sign(input_dir)

	# Check for jump
	if InputManager.consume_jump_buffer():
		_jump()

	# Check for dash
	if InputManager.is_dash_just_pressed and can_dash:
		_start_dash()

	# Check if we left the ground
	if not is_on_floor():
		InputManager.start_coyote_time()
		_change_state(State.FALLING)
		return

	# Update state
	if abs(velocity.x) > 10:
		_change_state(State.RUNNING)
	else:
		_change_state(State.IDLE)

func _state_air(delta: float) -> void:
	var input_dir = InputManager.move_direction

	# Apply gravity (reduced during jump hold for variable height)
	var gravity_mult = 1.0
	if velocity.y < 0 and not InputManager.is_jump_pressed:
		gravity_mult = 2.0  # Faster fall when jump released

	velocity.y += GRAVITY * gravity_mult * delta
	velocity.y = min(velocity.y, MAX_FALL_SPEED)

	# Horizontal movement (slightly less control in air)
	if wall_jump_lock_timer <= 0:
		_apply_horizontal_movement(delta, input_dir, AIR_SPEED, AIR_ACCELERATION, AIR_DECELERATION)

	# Update facing
	if input_dir != 0 and wall_jump_lock_timer <= 0:
		facing_direction = sign(input_dir)

	# Check for wall slide
	if wall_direction != 0 and velocity.y > 0:
		var pressing_toward_wall = (wall_direction < 0 and input_dir < 0) or (wall_direction > 0 and input_dir > 0)
		if pressing_toward_wall:
			_change_state(State.WALL_SLIDING)
			return

	# Check for jump (double jump or coyote time)
	if InputManager.consume_jump_buffer():
		if InputManager.consume_coyote_time():
			_jump()
		elif jumps_remaining > 0 and has_double_jump:
			_double_jump()

	# Check for dash
	if InputManager.is_dash_just_pressed and can_dash:
		_start_dash()

	# Check for landing
	if is_on_floor():
		_land()
		return

	# Update state
	if velocity.y < 0:
		_change_state(State.JUMPING)
	else:
		_change_state(State.FALLING)

func _state_dash(delta: float) -> void:
	dash_timer -= delta

	# Dash movement (no gravity)
	velocity = dash_direction * DASH_SPEED

	if dash_timer <= 0:
		_end_dash()
		return

	# Can still land during dash
	if is_on_floor() and dash_direction.y >= 0:
		_end_dash()
		_land()

func _state_wall_slide(delta: float) -> void:
	var input_dir = InputManager.move_direction

	# Wall slide gravity
	velocity.y = min(velocity.y + GRAVITY * 0.1 * delta, WALL_SLIDE_SPEED)

	# Check if still on wall
	var on_wall = (wall_direction < 0 and is_on_wall_left) or (wall_direction > 0 and is_on_wall_right)
	var pressing_wall = (wall_direction < 0 and input_dir < -0.5) or (wall_direction > 0 and input_dir > 0.5)

	if not on_wall or not pressing_wall:
		if wall_stick_timer <= 0:
			wall_stick_timer = WALL_STICK_TIME
		elif wall_stick_timer <= 0:
			InputManager.start_wall_coyote_time(wall_direction)
			_change_state(State.FALLING)
			return

	# Wall jump
	if InputManager.consume_jump_buffer():
		_wall_jump()
		return

	# Dash off wall
	if InputManager.is_dash_just_pressed and can_dash:
		_start_dash()
		return

	# Check for landing
	if is_on_floor():
		_land()
		return

	# Facing away from wall
	facing_direction = -wall_direction

func _state_spawning(delta: float) -> void:
	# Wait for spawn animation to complete
	pass

func _apply_horizontal_movement(delta: float, input_dir: float, max_speed: float, accel: float, decel: float) -> void:
	if input_dir != 0:
		# Accelerating
		var target_speed = input_dir * max_speed

		# Extra acceleration when turning
		var current_accel = accel
		if sign(velocity.x) != sign(input_dir) and abs(velocity.x) > 10:
			current_accel *= TURN_SPEED_MULTIPLIER

		velocity.x = move_toward(velocity.x, target_speed, current_accel * delta)
	else:
		# Decelerating
		velocity.x = move_toward(velocity.x, 0, decel * delta)

func _jump() -> void:
	velocity.y = JUMP_VELOCITY
	jumps_remaining -= 1
	_change_state(State.JUMPING)

	# Visual feedback
	_apply_squash_stretch(Vector2(0.6, 1.4))
	AudioManager.play_sfx("jump")
	jumped.emit(false)

func _double_jump() -> void:
	velocity.y = DOUBLE_JUMP_VELOCITY
	jumps_remaining -= 1
	_change_state(State.JUMPING)

	# Reset dash in air
	can_dash = true

	# Visual feedback
	_apply_squash_stretch(Vector2(0.7, 1.3))
	AudioManager.play_sfx("double_jump")
	jumped.emit(true)

func _wall_jump() -> void:
	velocity.x = WALL_JUMP_VELOCITY.x * -wall_direction
	velocity.y = WALL_JUMP_VELOCITY.y
	wall_jump_lock_timer = WALL_JUMP_LOCK_TIME
	facing_direction = -wall_direction

	# Reset abilities
	jumps_remaining = 1  # Allow one more jump after wall jump
	can_dash = true

	_change_state(State.JUMPING)

	AudioManager.play_sfx("wall_jump")
	wall_jumped.emit(-wall_direction)

func _start_dash() -> void:
	is_dashing = true
	can_dash = false
	dash_timer = DASH_DURATION
	dash_cooldown_timer = DASH_COOLDOWN

	# Get dash direction from input
	dash_direction = InputManager.get_aim_direction()
	if dash_direction == Vector2.ZERO:
		dash_direction = Vector2(facing_direction, 0)

	_change_state(State.DASHING)

	# Visual feedback
	if dash_particles:
		dash_particles.emitting = true
	AudioManager.play_sfx("dash")
	dash_started.emit()

func _end_dash() -> void:
	is_dashing = false

	# Maintain some momentum
	velocity = dash_direction * DASH_SPEED * 0.5

	if dash_particles:
		dash_particles.emitting = false

	# Determine next state
	if is_on_floor():
		_change_state(State.IDLE)
	else:
		_change_state(State.FALLING)

	dash_ended.emit()

func _land() -> void:
	jumps_remaining = 2
	can_dash = true
	wall_jump_lock_timer = 0

	# Visual feedback
	_apply_squash_stretch(Vector2(1.3, 0.7))
	AudioManager.play_sfx("land")
	landed.emit()

	if abs(velocity.x) > 10:
		_change_state(State.RUNNING)
	else:
		_change_state(State.IDLE)

func _change_state(new_state: State) -> void:
	if new_state == current_state:
		return

	previous_state = current_state
	current_state = new_state

func _update_animation() -> void:
	if not sprite:
		return

	sprite.flip_h = facing_direction < 0

	var anim_name = "idle"
	match current_state:
		State.IDLE:
			anim_name = "idle"
		State.RUNNING:
			anim_name = "run"
		State.JUMPING:
			anim_name = "jump"
		State.FALLING:
			anim_name = "fall"
		State.DASHING:
			anim_name = "dash"
		State.WALL_SLIDING:
			anim_name = "wall_slide"
		State.DEAD:
			anim_name = "death"
		State.SPAWNING:
			anim_name = "spawn"

	if sprite.animation != anim_name:
		sprite.play(anim_name)

func _update_visual_effects(delta: float) -> void:
	# Squash and stretch interpolation
	squash_stretch = squash_stretch.lerp(target_squash_stretch, 15.0 * delta)
	target_squash_stretch = target_squash_stretch.lerp(Vector2.ONE, 10.0 * delta)

	if sprite:
		sprite.scale = squash_stretch

	# Trail particles based on speed
	if trail_particles:
		var speed = velocity.length()
		trail_particles.emitting = speed > 200 and not is_dead

func _apply_squash_stretch(value: Vector2) -> void:
	squash_stretch = value
	target_squash_stretch = value

func _record_ghost(delta: float) -> void:
	ghost_record_timer += delta
	if ghost_record_timer >= GHOST_RECORD_INTERVAL:
		ghost_record_timer = 0.0
		var anim_name = sprite.animation if sprite else "idle"
		var flip = sprite.flip_h if sprite else false
		GameManager.add_ghost_frame(global_position, velocity, anim_name, flip)

func die() -> void:
	if is_dead:
		return

	is_dead = true
	_change_state(State.DEAD)
	velocity = Vector2.ZERO

	# Visual feedback
	if animation_player:
		animation_player.play("death")
	AudioManager.play_sfx("death")

	GameManager.die()
	died.emit()

	# Respawn after delay
	await get_tree().create_timer(0.8).timeout
	respawn()

func respawn() -> void:
	is_dead = false
	global_position = checkpoint_position
	velocity = Vector2.ZERO

	# Reset abilities
	jumps_remaining = 2
	can_dash = true
	is_dashing = false
	dash_timer = 0.0

	_change_state(State.SPAWNING)

	# Visual feedback
	if animation_player:
		animation_player.play("spawn")
	AudioManager.play_sfx("respawn")

	GameManager.respawn()
	respawned.emit()

	# Brief invulnerability
	await get_tree().create_timer(0.5).timeout
	_change_state(State.IDLE)

func set_checkpoint(pos: Vector2) -> void:
	if pos != checkpoint_position:
		checkpoint_position = pos
		AudioManager.play_sfx("checkpoint")
		checkpoint_reached.emit(pos)

func _on_hazard_entered(area: Area2D) -> void:
	die()
