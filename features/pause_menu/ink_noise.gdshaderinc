// Noise shared by the pause menu ink shaders.
//
// fBm used to be computed procedurally (5 octaves of hashed value noise per
// call), which was most of the pause menu's GPU cost. It is now one lookup into
// a pre-baked, seamless fractal NoiseTexture2D (generated in-engine, see
// pause_menu.tscn). One texture tile spans 4 noise units.

uniform sampler2D ink_noise_texture : repeat_enable, filter_linear_mipmap;

// Squeezes the full 0..1 texture range toward 0.5 to match the softer
// contrast of the old procedural fBm.
const float INK_NOISE_CONTRAST = 0.7;

float ink_fbm(vec2 p) {
	return mix(0.5, texture(ink_noise_texture, p * 0.25).r, INK_NOISE_CONTRAST);
}
