shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_front, unshaded, shadows_disabled;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic;
uniform vec4 outline_color : source_color = vec4(0.055, 0.045, 0.09, 1.0);
uniform float outline_width_pixels : hint_range(0.0, 12.0, 0.1) = 2.0;
uniform float alpha_scissor : hint_range(0.0, 1.0) = 0.5;

void vertex() {
	vec4 view_position = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 clip_position = PROJECTION_MATRIX * view_position;
	vec3 view_normal = normalize(mat3(MODELVIEW_MATRIX) * NORMAL);
	vec2 screen_normal = (PROJECTION_MATRIX * vec4(view_normal, 0.0)).xy;
	float screen_normal_length = length(screen_normal);

	if (screen_normal_length > 0.0001) {
		screen_normal /= screen_normal_length;
		vec2 pixel_size = 2.0 / VIEWPORT_SIZE;
		clip_position.xy += screen_normal * outline_width_pixels * pixel_size * clip_position.w;
	}

	POSITION = clip_position;
}

void fragment() {
	float texture_alpha = texture(albedo_texture, UV).a;
	ALBEDO = outline_color.rgb;
	ALPHA = texture_alpha * outline_color.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor;
}
