// Value noise and fBm shared by the pause menu ink shaders.

float ink_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ink_value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(ink_hash(i), ink_hash(i + vec2(1.0, 0.0)), u.x),
		mix(ink_hash(i + vec2(0.0, 1.0)), ink_hash(i + vec2(1.0, 1.0)), u.x),
		u.y);
}

float ink_fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * ink_value_noise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}
