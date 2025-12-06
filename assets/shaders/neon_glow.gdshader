shader_type canvas_item;

// Neon glow shader for player and UI elements
// Creates a soft, pulsing glow effect around sprites

uniform vec4 glow_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform float glow_intensity : hint_range(0.0, 5.0) = 2.0;
uniform float glow_size : hint_range(0.0, 20.0) = 4.0;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.0;
uniform float pulse_amount : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	vec4 original = texture(TEXTURE, UV);

	// Calculate glow by sampling surrounding pixels
	float glow = 0.0;
	float pixel_size = 1.0 / 64.0; // Adjust based on texture size

	for (float x = -glow_size; x <= glow_size; x += 1.0) {
		for (float y = -glow_size; y <= glow_size; y += 1.0) {
			float dist = length(vec2(x, y));
			if (dist <= glow_size) {
				vec2 offset = vec2(x, y) * pixel_size;
				float sample_alpha = texture(TEXTURE, UV + offset).a;
				glow += sample_alpha * (1.0 - dist / glow_size);
			}
		}
	}

	// Normalize glow
	glow = glow / (glow_size * glow_size * 0.5);

	// Apply pulse
	float pulse = 1.0 + sin(TIME * pulse_speed) * pulse_amount;
	glow *= pulse;

	// Combine glow with original
	vec4 glow_result = glow_color * glow * glow_intensity;
	glow_result.a *= (1.0 - original.a); // Only glow outside the sprite

	COLOR = original + glow_result;
}
