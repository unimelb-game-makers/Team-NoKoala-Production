shader_type spatial;
// Compatibility-safe: unshaded alpha-blended overlay, no depth write.
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled, specular_disabled;

// --- look -------------------------------------------------------------------
uniform vec4 line_color : source_color = vec4(0.55, 0.85, 1.0, 0.9);
uniform float cell_size = 1.0;          // world units per cell (match GridMap.cell_size)
uniform float grid_offset = 0.5;        // 0.5 = lines on cell edges for centered GridMap cells
uniform float line_width : hint_range(0.0, 0.5) = 0.04;  // fraction of a cell
uniform float line_softness : hint_range(0.0, 4.0) = 1.0; // extra AA in pixels; 0 = derivative-only

// --- circular fade --------------------------------------------------------
uniform float inner_radius = 3.0;  // world units: fully visible inside this
uniform float outer_radius = 7.0;  // world units: fully transparent past this
uniform float global_alpha : hint_range(0.0, 1.0) = 1.0; // fade the whole thing in/out

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Grid coordinate in cells, world-aligned so lines never crawl as the quad moves.
	vec2 coord = world_pos.xz / cell_size;

	// Triangle wave -> 0 exactly on a grid line.
	vec2 g = abs(fract(coord + grid_offset) - 0.5);

	// Screen-space derivative gives 1px-consistent lines regardless of camera distance.
	vec2 aa = fwidth(coord) * (0.5 + line_softness);
	vec2 lines = smoothstep(line_width + aa, line_width - aa, g);
	float line = max(lines.x, lines.y);

	// Radial mask centred on the quad's own origin (which we park under the cursor).
	float d = distance(world_pos.xz, (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xz);
	float mask = 1.0 - smoothstep(inner_radius, outer_radius, d);

	ALBEDO = line_color.rgb;
	ALPHA = line_color.a * line * mask * global_alpha;
}
