// Hotbar slot background: frosted glass (blurred screen behind the slot under
// the translucent TEXTURE) cross-faded into the opaque selected background.
// TEXTURE and selected_tex share the same canvas and diamond shape.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform sampler2D selected_tex : source_color, filter_linear;
uniform float selected_amount : hint_range(0.0, 1.0) = 0.0;
// Blur radius in screen pixels
uniform float blur_radius : hint_range(0.0, 32.0) = 10.0;

const int BLUR_TAPS = 24;
const float GOLDEN_ANGLE = 2.39996323;

// Spiral sampling at mip 0, since the Compatibility renderer has no screen mipmaps
vec3 blurred_screen(vec2 uv, vec2 pixel_size) {
	vec3 sum = texture(screen_tex, uv).rgb;
	for (int i = 1; i < BLUR_TAPS; i++) {
		float r = sqrt(float(i) / float(BLUR_TAPS)) * blur_radius;
		float theta = float(i) * GOLDEN_ANGLE;
		sum += texture(screen_tex, uv + vec2(cos(theta), sin(theta)) * r * pixel_size).rgb;
	}
	return sum / float(BLUR_TAPS);
}

void fragment() {
	vec4 glass = texture(TEXTURE, UV);
	vec4 selected = texture(selected_tex, UV);
	// The selected art is opaque, so its alpha is the diamond's coverage
	float mask = selected.a;

	vec3 frosted = blurred_screen(SCREEN_UV, SCREEN_PIXEL_SIZE);
	float glass_a = mask > 0.0 ? clamp(glass.a / mask, 0.0, 1.0) : 0.0;
	vec3 unselected_rgb = mix(frosted, glass.rgb, glass_a);

	COLOR = vec4(mix(unselected_rgb, selected.rgb, selected_amount), mask);
}
