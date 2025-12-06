shader_type canvas_item;

// CRT scanline effect for retro aesthetic
// Adds subtle scanlines and vignette

uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float scanline_count : hint_range(100.0, 1000.0) = 400.0;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float vignette_radius : hint_range(0.0, 1.0) = 0.7;
uniform float flicker_speed : hint_range(0.0, 20.0) = 5.0;
uniform float flicker_amount : hint_range(0.0, 0.1) = 0.02;

void fragment() {
	vec4 color = texture(TEXTURE, UV);

	// Scanlines
	float scanline = sin(UV.y * scanline_count * 3.14159) * 0.5 + 0.5;
	scanline = pow(scanline, 2.0);
	color.rgb -= scanline * scanline_intensity;

	// Vignette
	vec2 center = UV - 0.5;
	float dist = length(center);
	float vignette = smoothstep(vignette_radius, vignette_radius - 0.3, dist);
	color.rgb *= mix(1.0 - vignette_intensity, 1.0, vignette);

	// Subtle flicker
	float flicker = 1.0 + sin(TIME * flicker_speed) * flicker_amount;
	color.rgb *= flicker;

	COLOR = color;
}
