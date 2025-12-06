extends CanvasLayer
## TransitionManager - Handles scene transitions with stylish effects
## Provides various transition types for different game states

signal transition_started
signal transition_midpoint
signal transition_finished

enum TransitionType {
	FADE,
	HORIZONTAL_WIPE,
	VERTICAL_WIPE,
	DIAMOND,
	PIXELATE,
	GLITCH,
	CIRCLE,
	DISSOLVE
}

var current_transition: TransitionType = TransitionType.FADE
var is_transitioning: bool = false
var transition_progress: float = 0.0
var transition_duration: float = 0.5
var transition_color: Color = Color(0.05, 0.02, 0.1, 1.0)

# Nodes
var color_rect: ColorRect
var shader_material: ShaderMaterial

# Pending scene change
var pending_scene: String = ""
var pending_callback: Callable

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_transition_rect()

func _setup_transition_rect() -> void:
	color_rect = ColorRect.new()
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.color = Color.TRANSPARENT

	# Create shader for advanced transitions
	var shader_code = """
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform int transition_type : hint_range(0, 7) = 0;
uniform vec4 transition_color : source_color = vec4(0.05, 0.02, 0.1, 1.0);
uniform vec2 screen_size = vec2(1920.0, 1080.0);

float random(vec2 co) {
	return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float alpha = 0.0;
	float p = progress;

	// Fade
	if (transition_type == 0) {
		alpha = p;
	}
	// Horizontal wipe
	else if (transition_type == 1) {
		float edge = p * 1.2;
		alpha = smoothstep(edge - 0.1, edge, uv.x);
	}
	// Vertical wipe
	else if (transition_type == 2) {
		float edge = p * 1.2;
		alpha = smoothstep(edge - 0.1, edge, uv.y);
	}
	// Diamond
	else if (transition_type == 3) {
		float diamond = abs(uv.x - 0.5) + abs(uv.y - 0.5);
		alpha = smoothstep(p * 1.5, p * 1.5 - 0.1, diamond);
	}
	// Pixelate
	else if (transition_type == 4) {
		float pixel_size = mix(1.0, 100.0, p);
		vec2 pixelated_uv = floor(uv * screen_size / pixel_size) * pixel_size / screen_size;
		float dist = length(pixelated_uv - vec2(0.5));
		alpha = smoothstep(1.0 - p * 1.2, 1.0 - p * 1.2 + 0.1, dist);
	}
	// Glitch
	else if (transition_type == 5) {
		float noise = random(vec2(floor(uv.y * 50.0), floor(TIME * 10.0)));
		float glitch_offset = noise * p * 0.5;
		float threshold = p + glitch_offset * 0.5;
		alpha = step(threshold, random(vec2(floor(uv.y * 30.0), p)));
		alpha = mix(alpha, p, p);
	}
	// Circle
	else if (transition_type == 6) {
		float dist = length(uv - vec2(0.5));
		float radius = (1.0 - p) * 0.8;
		alpha = smoothstep(radius, radius - 0.05, dist);
	}
	// Dissolve
	else if (transition_type == 7) {
		float noise = random(uv * 100.0 + TIME);
		alpha = step(1.0 - p, noise);
	}

	COLOR = vec4(transition_color.rgb, alpha * transition_color.a);
}
"""

	var shader = Shader.new()
	shader.code = shader_code

	shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	shader_material.set_shader_parameter("progress", 0.0)
	shader_material.set_shader_parameter("transition_type", 0)
	shader_material.set_shader_parameter("transition_color", transition_color)
	shader_material.set_shader_parameter("screen_size", Vector2(1920, 1080))

	color_rect.material = shader_material
	add_child(color_rect)

func transition_to_scene(scene_path: String, type: TransitionType = TransitionType.FADE, duration: float = 0.5) -> void:
	if is_transitioning:
		return

	pending_scene = scene_path
	current_transition = type
	transition_duration = duration
	_start_transition_out()

func transition_with_callback(callback: Callable, type: TransitionType = TransitionType.FADE, duration: float = 0.5) -> void:
	if is_transitioning:
		return

	pending_callback = callback
	pending_scene = ""
	current_transition = type
	transition_duration = duration
	_start_transition_out()

func _start_transition_out() -> void:
	is_transitioning = true
	transition_progress = 0.0

	shader_material.set_shader_parameter("transition_type", current_transition)
	shader_material.set_shader_parameter("transition_color", transition_color)

	transition_started.emit()

	var tween = create_tween()
	tween.tween_method(_update_transition_progress, 0.0, 1.0, transition_duration / 2)
	tween.tween_callback(_on_transition_midpoint)
	tween.tween_method(_update_transition_progress, 1.0, 0.0, transition_duration / 2)
	tween.tween_callback(_on_transition_finished)

func _update_transition_progress(value: float) -> void:
	transition_progress = value
	shader_material.set_shader_parameter("progress", value)

func _on_transition_midpoint() -> void:
	transition_midpoint.emit()

	if pending_scene != "":
		get_tree().change_scene_to_file(pending_scene)
	elif pending_callback.is_valid():
		pending_callback.call()

func _on_transition_finished() -> void:
	is_transitioning = false
	pending_scene = ""
	pending_callback = Callable()
	transition_finished.emit()

func flash(color: Color = Color.WHITE, duration: float = 0.1) -> void:
	# Quick flash effect for impacts
	var flash_rect = ColorRect.new()
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.color = color
	flash_rect.modulate.a = 0.5
	add_child(flash_rect)

	var tween = create_tween()
	tween.tween_property(flash_rect, "modulate:a", 0.0, duration)
	tween.tween_callback(flash_rect.queue_free)

func screen_shake(intensity: float = 10.0, duration: float = 0.2) -> void:
	# Signal for camera to handle shake
	# This is handled by the game camera
	pass

func set_transition_color(color: Color) -> void:
	transition_color = color
	shader_material.set_shader_parameter("transition_color", color)

func quick_fade_out(duration: float = 0.3) -> void:
	if is_transitioning:
		return

	var tween = create_tween()
	shader_material.set_shader_parameter("transition_type", TransitionType.FADE)
	tween.tween_method(_update_transition_progress, 0.0, 1.0, duration)

func quick_fade_in(duration: float = 0.3) -> void:
	var tween = create_tween()
	tween.tween_method(_update_transition_progress, 1.0, 0.0, duration)
	tween.tween_callback(func(): is_transitioning = false)
