shader_type canvas_item;

// Chromatic aberration for screen effects
// Used during dash, death, and intense moments

uniform float strength : hint_range(0.0, 0.1) = 0.005;
uniform float direction : hint_range(0.0, 6.28) = 0.0;
uniform bool enabled = true;

void fragment() {
	if (!enabled || strength <= 0.0) {
		COLOR = texture(TEXTURE, UV);
		return;
	}

	vec2 dir = vec2(cos(direction), sin(direction)) * strength;

	// Sample RGB channels at offset positions
	float r = texture(TEXTURE, UV + dir).r;
	float g = texture(TEXTURE, UV).g;
	float b = texture(TEXTURE, UV - dir).b;
	float a = texture(TEXTURE, UV).a;

	COLOR = vec4(r, g, b, a);
}
