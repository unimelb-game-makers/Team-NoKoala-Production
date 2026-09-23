shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled, diffuse_lambert, specular_disabled;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D emission_texture : source_color, filter_linear_mipmap_anisotropic;

uniform vec4 shadow_tint : source_color = vec4(0.58, 0.62, 0.78, 1.0);
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.46;
uniform float shadow_softness : hint_range(0.001, 0.25) = 0.045;
uniform float base_brightness : hint_range(0.0, 1.0) = 0.82;
uniform float light_energy : hint_range(0.0, 2.0) = 0.68;

uniform vec4 rim_color : source_color = vec4(0.75, 0.84, 1.0, 1.0);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.16;
uniform float rim_width : hint_range(0.0, 1.0) = 0.3;
uniform float rim_softness : hint_range(0.001, 0.25) = 0.025;

uniform vec4 highlight_color : source_color = vec4(1.0);
uniform float highlight_strength : hint_range(0.0, 1.0) = 0.12;
uniform float highlight_size : hint_range(0.01, 1.0) = 0.2;

uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;
uniform float emission_strength : hint_range(0.0, 2.0) = 1.0;
uniform float alpha_scissor : hint_range(0.0, 1.0) = 0.5;
uniform float unshaded_mix : hint_range(0.0, 1.0) = 0.0;

group_uniforms face_shadow;
uniform bool face_shadow_enabled = false;
uniform vec3 face_forward_axis = vec3(0.0, -1.0, 0.0);
uniform vec3 face_right_axis = vec3(1.0, 0.0, 0.0);
uniform vec3 face_up_axis = vec3(0.0, 0.0, -1.0);
uniform float face_shadow_coverage : hint_range(0.0, 1.0) = 0.58;
uniform float face_shadow_curve : hint_range(-0.5, 0.5) = 0.12;
uniform float face_vertical_influence : hint_range(0.0, 1.0) = 0.2;
uniform float face_backlight_cutoff : hint_range(-1.0, 1.0) = -0.25;
uniform float face_backlight_softness : hint_range(0.001, 0.5) = 0.1;
group_uniforms;

void fragment() {
	vec4 base = texture(albedo_texture, UV);
	ALBEDO = base.rgb;
	ALPHA = base.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor;
	NORMAL_MAP = texture(normal_texture, UV).rgb;
	NORMAL_MAP_DEPTH = normal_strength;
	// A constant shadow floor keeps the unlit band flat. Direct lights only add
	// the difference between this tint and the fully lit texture.
	vec3 flat_shadow = base.rgb * shadow_tint.rgb * base_brightness;
	EMISSION = mix(flat_shadow, base.rgb, unshaded_mix);
	EMISSION += texture(emission_texture, UV).rgb * emission_strength;
	ROUGHNESS = 0.9;
	METALLIC = 0.0;
}

void light() {
	float ndotl = dot(NORMAL, LIGHT);
	float light_value = ndotl * 0.5 + 0.5;
	float lit_band = smoothstep(
		shadow_threshold - shadow_softness,
		shadow_threshold + shadow_softness,
		light_value
	);

	if (face_shadow_enabled) {
		// LIGHT is view-space. Convert it to model space so the pattern follows
		// the character instead of the camera.
		vec3 world_light = normalize((INV_VIEW_MATRIX * vec4(LIGHT, 0.0)).xyz);
		vec3 local_light = normalize(inverse(mat3(MODEL_MATRIX)) * world_light);
		float horizontal_light = dot(local_light, normalize(face_right_axis));
		float forward_light = dot(local_light, normalize(face_forward_axis));
		float vertical_light = dot(local_light, normalize(face_up_axis));
		float side_amount = abs(horizontal_light) /
			max(abs(horizontal_light) + max(forward_light, 0.0), 0.001);

		// Analytic face SDF: mirror the pattern toward the light and bend the
		// boundary around the cheek/nose region.
		vec2 face_uv = (UV - vec2(0.5, 0.52)) * 2.0;
		float light_side = mix(1.0, sign(horizontal_light), step(0.001, abs(horizontal_light)));
		float oriented_x = face_uv.x * light_side;
		float cheek_curve = face_shadow_curve * (face_uv.y * face_uv.y - 0.18);
		float vertical_offset = vertical_light * face_vertical_influence;
		float face_pattern = oriented_x + cheek_curve + vertical_offset;
		float face_edge = mix(-1.05, 0.2, side_amount * face_shadow_coverage);

		lit_band = smoothstep(
			face_edge - shadow_softness,
			face_edge + shadow_softness,
			face_pattern
		);

		// Suppress the entire lit pattern once the light passes behind the
		// character's face.
		float front_light_mask = smoothstep(
			face_backlight_cutoff - face_backlight_softness,
			face_backlight_cutoff + face_backlight_softness,
			forward_light
		);
		lit_band *= front_light_mask;
	}

	float rim_facing = 1.0 - max(dot(NORMAL, VIEW), 0.0);
	float rim_edge = 1.0 - rim_width;
	float rim_band = smoothstep(
		rim_edge - rim_softness,
		rim_edge + rim_softness,
		rim_facing
	);
	float rim = rim_band * rim_strength;
	vec3 half_vector = normalize(LIGHT + VIEW);
	float specular_term = pow(max(dot(NORMAL, half_vector), 0.0), 2.0 / max(highlight_size, 0.01));
	float anime_highlight = smoothstep(0.55, 0.7, specular_term) * highlight_strength;

	vec3 light_difference = ALBEDO * (vec3(1.0) - shadow_tint.rgb);
	if (face_shadow_enabled) {
		// Keep the illuminated face at one constant tone. The light direction
		// selects the authored-style pattern, but attenuation and view effects
		// do not shade the interior of that pattern.
		vec3 flat_face_light = light_difference * lit_band * base_brightness;
		flat_face_light *= LIGHT_COLOR * light_energy;
		DIFFUSE_LIGHT += mix(flat_face_light, vec3(0.0), unshaded_mix);
	} else {
		vec3 shaded = light_difference * lit_band * base_brightness * LIGHT_COLOR;
		shaded += rim_color.rgb * rim * lit_band * LIGHT_COLOR * base_brightness;
		shaded += highlight_color.rgb * anime_highlight * lit_band * LIGHT_COLOR * base_brightness;
		shaded *= light_energy;
		DIFFUSE_LIGHT += mix(shaded * ATTENUATION, vec3(0.0), unshaded_mix);
	}
}
