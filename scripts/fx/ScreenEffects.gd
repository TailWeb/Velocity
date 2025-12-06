extends CanvasLayer
class_name ScreenEffects
## Screen-wide visual effects - shake, flash, chromatic aberration

signal shake_started
signal shake_ended

@onready var color_rect: ColorRect = $ColorRect
var shake_amount: float = 0.0
var shake_decay: float = 5.0
var original_offset: Vector2 = Vector2.ZERO

# Chromatic aberration
var chromatic_strength: float = 0.0
var chromatic_target: float = 0.0

func _ready() -> void:
	_setup_effects()

func _setup_effects() -> void:
	if not color_rect:
		color_rect = ColorRect.new()
		color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(color_rect)

	# Apply post-processing shader
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float chromatic_strength : hint_range(0.0, 0.05) = 0.0;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.3;
uniform float scanline_strength : hint_range(0.0, 0.5) = 0.1;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec4 color = vec4(0.0);

	// Chromatic aberration
	if (chromatic_strength > 0.0) {
		color.r = texture(SCREEN_TEXTURE, uv + vec2(chromatic_strength, 0.0)).r;
		color.g = texture(SCREEN_TEXTURE, uv).g;
		color.b = texture(SCREEN_TEXTURE, uv - vec2(chromatic_strength, 0.0)).b;
		color.a = 1.0;
	} else {
		color = texture(SCREEN_TEXTURE, uv);
	}

	// Vignette
	vec2 center = uv - 0.5;
	float dist = length(center);
	float vignette = smoothstep(0.7, 0.4, dist);
	color.rgb *= mix(1.0 - vignette_strength, 1.0, vignette);

	// Scanlines
	float scanline = sin(uv.y * 800.0) * 0.5 + 0.5;
	color.rgb -= scanline * scanline_strength;

	COLOR = color;
}
"""
	var material = ShaderMaterial.new()
	material.shader = shader
	color_rect.material = material

func _process(delta: float) -> void:
	# Process screen shake
	if shake_amount > 0:
		shake_amount = max(0, shake_amount - shake_decay * delta)
		var shake_offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		offset = original_offset + shake_offset

		if shake_amount <= 0:
			offset = original_offset
			shake_ended.emit()

	# Process chromatic aberration
	chromatic_strength = lerp(chromatic_strength, chromatic_target, 10.0 * delta)
	if color_rect and color_rect.material:
		color_rect.material.set_shader_parameter("chromatic_strength", chromatic_strength)

func shake(amount: float = 10.0, decay: float = 5.0) -> void:
	if not SaveManager.get_setting("screen_shake"):
		return

	shake_amount = max(shake_amount, amount)
	shake_decay = decay
	shake_started.emit()

func flash(color: Color = Color.WHITE, duration: float = 0.1) -> void:
	var flash_rect = ColorRect.new()
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.color = color
	add_child(flash_rect)

	var tween = create_tween()
	tween.tween_property(flash_rect, "modulate:a", 0.0, duration)
	tween.tween_callback(flash_rect.queue_free)

func set_chromatic_aberration(strength: float) -> void:
	chromatic_target = strength

func pulse_chromatic(strength: float = 0.02, duration: float = 0.2) -> void:
	chromatic_target = strength
	await get_tree().create_timer(duration).timeout
	chromatic_target = 0.0

func death_effect() -> void:
	flash(Color.RED, 0.15)
	shake(15.0, 8.0)
	pulse_chromatic(0.03, 0.3)

func dash_effect() -> void:
	pulse_chromatic(0.015, 0.1)
	shake(3.0, 10.0)

func impact_effect(intensity: float = 1.0) -> void:
	flash(Color.WHITE, 0.05 * intensity)
	shake(5.0 * intensity, 8.0)
