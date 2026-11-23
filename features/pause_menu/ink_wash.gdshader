shader_type canvas_item;

// Repaints whatever is on screen behind the pause menu as a watercolor ink wash.
// Detail is blurred away and the image is split into a few flat blocks of
// paper / wash / ink tones from the ink-spread palette. Block edges are warped
// and feathered by noise so they bleed like wet ink, and pigment collects in a
// darker rim along each edge, the way watercolor dries.
// `strength` blends from the original image (0) to the full effect (1).

#include "res://features/pause_menu/ink_noise.gdshaderinc"

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float anim_time = 0.0;
uniform float aspect = 1.7778;

group_uniforms palette;
uniform vec4 paper_color : source_color = vec4(0.96, 0.92, 0.85, 1.0);
uniform vec4 wash_color : source_color = vec4(0.88, 0.82, 0.72, 1.0);
uniform vec4 ink_color : source_color = vec4(0.45, 0.37, 0.28, 1.0);
// Lifts dark scenes so night shots don't turn into a solid block of ink.
uniform float exposure : hint_range(0.1, 2.0) = 0.6;

group_uniforms blocks;
// How many tone blocks the image is split into.
uniform float levels : hint_range(2.0, 8.0) = 4.0;
// Blur radius in pixels; larger merges more detail into each block.
uniform float blur_radius : hint_range(0.0, 24.0) = 6.0;
// Softness of the step between two blocks (0 = hard, 0.5 = smooth gradient).
uniform float edge_softness : hint_range(0.0, 0.5) = 0.12;
uniform float tone_unevenness : hint_range(0.0, 0.5) = 0.12;

group_uniforms bleed;
// Large-scale warp of block shapes, in screen fractions.
uniform float bleed : hint_range(0.0, 0.05) = 0.015;
// Fine noise that frays block edges.
uniform float feather : hint_range(0.0, 0.3) = 0.05;
uniform float flow_speed = 0.05;

group_uniforms pigment;
// Width in pixels of the darker rim where pigment collects at block edges.
uniform float rim_width : hint_range(0.0, 12.0) = 4.0;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.35;
uniform float granulation : hint_range(0.0, 0.3) = 0.1;
uniform float grain : hint_range(0.0, 0.3) = 0.06;

float luminance(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

// Golden-angle disk blur of the screen luminance.
float blurred_lum(vec2 uv, vec2 pixel) {
	const int SAMPLES = 16;
	float sum = 0.0;
	for (int i = 0; i < SAMPLES; i++) {
		float r = sqrt((float(i) + 0.5) / float(SAMPLES)) * blur_radius;
		float a = float(i) * 2.39996;
		sum += luminance(texture(screen_texture, uv + vec2(cos(a), sin(a)) * r * pixel).rgb);
	}
	return sum / float(SAMPLES);
}

vec3 palette(float q) {
	vec3 col = mix(ink_color.rgb, wash_color.rgb, smoothstep(0.0, 0.5, q));
	return mix(col, paper_color.rgb, smoothstep(0.5, 1.0, q));
}

void fragment() {
	vec3 original = texture(screen_texture, SCREEN_UV).rgb;
	vec2 p = vec2(SCREEN_UV.x * aspect, SCREEN_UV.y) * 6.0;
	float t = anim_time * flow_speed;

	// Warp the sample position so block shapes look like they've run.
	vec2 warp = vec2(ink_fbm(p * 0.8 + t), ink_fbm(p * 0.8 + vec2(3.1, 7.4) - t)) - 0.5;
	vec2 uv = SCREEN_UV + warp * bleed;

	float base = pow(clamp(blurred_lum(uv, SCREEN_PIXEL_SIZE), 0.0, 1.0), exposure);
	float l = base + (ink_fbm(p * 0.7) - 0.5) * tone_unevenness;
	// Fray the block edges with finer, slowly moving noise.
	l += (ink_fbm(p * 4.0 + t * 3.0) - 0.5) * feather;

	// Split into flat blocks with a soft step between them.
	float scaled = clamp(l, 0.0, 0.999) * levels;
	float band = floor(scaled);
	float f = fract(scaled);
	float level = band + smoothstep(1.0 - edge_softness, 1.0, f);
	vec3 col = palette(level / max(levels - 1.0, 1.0));

	// Pigment rim: estimate the pixel distance to the next lighter block from
	// the luminance gradient and darken the darker side of that edge. Only where
	// the image itself has an edge, so noise-made blotches stay soft.
	float to_edge = (1.0 - f) / levels;
	float edge_px = to_edge / max(fwidth(l), 1e-4);
	float rim = 1.0 - smoothstep(0.0, rim_width, edge_px);
	rim *= smoothstep(0.004, 0.02, fwidth(base));
	col = mix(col, col * ink_color.rgb / max(wash_color.rgb, vec3(0.01)), rim * rim_strength);

	// Granulation (pigment settling, stronger in dark areas) and paper grain.
	float darkness = 1.0 - level / max(levels - 1.0, 1.0);
	col *= 1.0 - granulation * darkness * (ink_fbm(p * 12.0) - 0.5) * 2.0;
	col *= 1.0 - grain * (ink_fbm(p * 8.0 + 11.0) - 0.5);

	COLOR = vec4(mix(original, col, strength), 1.0);
}
