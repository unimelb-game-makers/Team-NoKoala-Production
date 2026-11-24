shader_type canvas_item;

// Watercolor ink that bleeds in from the right edge of the screen.
// `progress` drives how far it has spread; `anim_time` keeps the edges moving.

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float anim_time = 0.0;
uniform float aspect = 1.7778;
uniform float max_reach : hint_range(0.0, 1.0) = 0.45;
uniform float edge_softness : hint_range(0.001, 0.5) = 0.08;
uniform float edge_raggedness : hint_range(0.0, 1.0) = 0.35;
uniform float flow_speed = 0.15;
uniform float noise_scale = 3.0;
uniform vec4 ink_color : source_color = vec4(0.96, 0.92, 0.85, 1.0);
uniform vec4 pool_color : source_color = vec4(0.88, 0.82, 0.72, 1.0);

// Shared noise (kept inline: web builds don't run the shader preprocessor, so
// include and define directives fail there). Keep in sync with the other ink shader.
// One lookup into a pre-baked, seamless fractal NoiseTexture2D (see
// pause_menu.tscn); one texture tile spans 4 noise units. The contrast factor
// squeezes the 0..1 range toward 0.5 for softer variation.
uniform sampler2D ink_noise_texture : repeat_enable, filter_linear_mipmap;
const float INK_NOISE_CONTRAST = 0.7;

float ink_fbm(vec2 p) {
	return mix(0.5, texture(ink_noise_texture, p * 0.25).r, INK_NOISE_CONTRAST);
}

void fragment() {
	float t = anim_time * flow_speed;
	vec2 p = vec2(UV.x * aspect, UV.y) * noise_scale;

	// Domain warp: noise sampled through noise gives the curling, bleeding edge.
	vec2 warp = vec2(ink_fbm(p + vec2(t, 0.0)), ink_fbm(p + vec2(5.2, 1.3) - vec2(0.0, t)));
	float n = ink_fbm(p + 2.0 * warp);

	// Positive inside the ink, negative outside. The -0.2 bias keeps the
	// screen fully clear at progress 0 despite the noise offset.
	float distance_from_right = 1.0 - UV.x;
	float field = progress * (max_reach + 0.2) - 0.2 - distance_from_right
		+ (n - 0.5) * edge_raggedness;
	float mask = smoothstep(0.0, edge_softness, field);

	// Pigment pooling inside the ink, plus a darker dried rim near the edge.
	float pools = smoothstep(0.05, 0.4, field)
		* smoothstep(0.4, 0.7, ink_fbm(p * 1.5 - warp + vec2(t * 0.5)));
	float rim = 1.0 - smoothstep(0.0, 0.05, abs(field - 0.03));
	vec3 col = mix(ink_color.rgb, pool_color.rgb, max(pools, rim * 0.6));

	// Thin wash at the outer edge, denser toward the right.
	float density = mix(0.75, 1.0, smoothstep(0.0, 0.3, field));
	COLOR = vec4(col, mask * density * ink_color.a * smoothstep(0.0, 0.15, progress));
}
