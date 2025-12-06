shader_type canvas_item;

// Dynamic 2D lighting shader
// Creates point light effects with color mixing

uniform vec4 light_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform float light_energy : hint_range(0.0, 5.0) = 1.0;
uniform float ambient_light : hint_range(0.0, 1.0) = 0.2;

void light() {
	// Custom light blending for neon effect
	float light_strength = LIGHT_COLOR.a * light_energy;

	// Additive blending for neon glow
	LIGHT = light_color.rgb * light_strength;

	// Add light color tinting
	LIGHT += LIGHT_COLOR.rgb * 0.5;
}
