extends Camera2D
class_name GameCamera
## Advanced camera with smooth following, look-ahead, and effects

@export var follow_speed: float = 8.0
@export var look_ahead_distance: float = 100.0
@export var look_ahead_speed: float = 3.0
@export var vertical_offset: float = -50.0

# Camera effects
var shake_amount: float = 0.0
var shake_decay: float = 5.0
var base_offset: Vector2 = Vector2.ZERO

# Look ahead
var look_ahead_target: Vector2 = Vector2.ZERO
var current_look_ahead: Vector2 = Vector2.ZERO

# Target tracking
var target: Node2D = null
var target_velocity: Vector2 = Vector2.ZERO

# Zoom
var target_zoom: Vector2 = Vector2(1.5, 1.5)
var zoom_speed: float = 3.0

# Bounds
var use_limits: bool = true

func _ready() -> void:
	base_offset = Vector2(0, vertical_offset)
	position_smoothing_enabled = true
	position_smoothing_speed = follow_speed

func _process(delta: float) -> void:
	_process_shake(delta)
	_process_look_ahead(delta)
	_process_zoom(delta)

func _process_shake(delta: float) -> void:
	if shake_amount > 0:
		shake_amount = max(0, shake_amount - shake_decay * delta)
		var shake_offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		offset = base_offset + current_look_ahead + shake_offset
	else:
		offset = base_offset + current_look_ahead

func _process_look_ahead(delta: float) -> void:
	if target and target is CharacterBody2D:
		target_velocity = (target as CharacterBody2D).velocity

	# Calculate look-ahead based on velocity
	if target_velocity.length() > 50:
		look_ahead_target = target_velocity.normalized() * look_ahead_distance
		look_ahead_target.y *= 0.5  # Less vertical look-ahead
	else:
		look_ahead_target = Vector2.ZERO

	current_look_ahead = current_look_ahead.lerp(look_ahead_target, look_ahead_speed * delta)

func _process_zoom(delta: float) -> void:
	zoom = zoom.lerp(target_zoom, zoom_speed * delta)

func set_target(new_target: Node2D) -> void:
	target = new_target
	if target:
		global_position = target.global_position + base_offset

func shake(amount: float = 10.0, decay: float = 5.0) -> void:
	shake_amount = max(shake_amount, amount)
	shake_decay = decay

func set_zoom_level(new_zoom: float, instant: bool = false) -> void:
	target_zoom = Vector2(new_zoom, new_zoom)
	if instant:
		zoom = target_zoom

func focus_on_point(point: Vector2, zoom_level: float = 2.0, duration: float = 0.5) -> void:
	# Temporarily focus on a point (for cutscenes, completion, etc.)
	var original_position = global_position
	var original_zoom = zoom

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", point, duration).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "zoom", Vector2(zoom_level, zoom_level), duration)

func set_limits(rect: Rect2) -> void:
	limit_left = int(rect.position.x)
	limit_top = int(rect.position.y)
	limit_right = int(rect.end.x)
	limit_bottom = int(rect.end.y)
	use_limits = true

func clear_limits() -> void:
	limit_left = -10000000
	limit_top = -10000000
	limit_right = 10000000
	limit_bottom = 10000000
	use_limits = false
