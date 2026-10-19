// Faith bar: the filled (red) art left of `progress`, the empty (grey) art
// right of it, with the glow softly masked so it bleeds a little past the cut.
// TEXTURE is the filled art; all three textures share the same canvas.
shader_type canvas_item;

uniform sampler2D empty_tex : source_color, filter_linear;
uniform sampler2D glow_tex : source_color, filter_linear;
uniform float progress : hint_range(0.0, 1.0) = 1.0;
// UV.x range mapped to 0%..100%, so the faded tails of the line don't eat into it
uniform float fill_start : hint_range(0.0, 1.0) = 0.05;
uniform float fill_end : hint_range(0.0, 1.0) = 0.95;
uniform float glow_feather : hint_range(0.0, 0.5) = 0.08;
// Multiplies the filled art and glow (not the empty art), e.g. for low faith
uniform vec4 tint : source_color = vec4(1.0);

void fragment() {
	float p = mix(fill_start, fill_end, progress);

	vec4 full = texture(TEXTURE, UV) * tint;
	vec4 empty = texture(empty_tex, UV);
	vec4 bar = UV.x <= p ? full : empty;

	vec4 glow = texture(glow_tex, UV) * tint;
	glow.a *= 1.0 - smoothstep(p - glow_feather, p + glow_feather, UV.x);

	// bar over glow
	float a = bar.a + glow.a * (1.0 - bar.a);
	vec3 rgb = (bar.rgb * bar.a + glow.rgb * glow.a * (1.0 - bar.a)) / max(a, 0.0001);
	COLOR = vec4(rgb, a);
}
