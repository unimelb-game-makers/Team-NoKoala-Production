shader_type canvas_item;

// Cheap blur of everything drawn behind this rect, from a low screen mip level.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_lod : hint_range(0.0, 6.0) = 3.5;

void fragment() {
	vec2 o = SCREEN_PIXEL_SIZE * exp2(blur_lod) * 0.5;
	vec3 col = 0.25 * (
		textureLod(screen_texture, SCREEN_UV + vec2(o.x, o.y), blur_lod).rgb
		+ textureLod(screen_texture, SCREEN_UV + vec2(-o.x, o.y), blur_lod).rgb
		+ textureLod(screen_texture, SCREEN_UV + vec2(o.x, -o.y), blur_lod).rgb
		+ textureLod(screen_texture, SCREEN_UV + vec2(-o.x, -o.y), blur_lod).rgb);
	COLOR = vec4(col, 1.0);
}
