shader_type spatial;

float rand_from_seed(in uint seed) {
	int k;
	int s = int(seed);
	if (s == 0) s = 305420679;
	k = s / 127773;
	s = 16807 * (s - k * 127773) - 2836 * k;
	if (s < 0) s += 2147483647;
	seed = uint(s);
	return float(seed % uint(65536)) / 65535.0;
}

uint hash(uint x) {
  x = ((x >> uint(16)) ^ x) * uint(73244475);
  x = ((x >> uint(16)) ^ x) * uint(73244475);
  x = (x >> uint(16)) ^ x;
  return x;
}

uniform float time_scale = 1.0;
uniform float side_to_side = 5.0;
uniform float pivot = 0.5;
uniform float wave = 1.0;
uniform float twist = 1.0;
uniform float mask_black = 0.0;
uniform float mask_white = 1.0;
uniform sampler2D tex;

void vertex() {
	uint x = uint(INSTANCE_ID);
	float time = TIME * time_scale + (rand_from_seed(x) * 2.0 * PI);
	VERTEX.x += cos(time) * side_to_side;
	float pivot_angle = cos(time) * 0.1 * pivot;
	mat2 rotation_matrix = mat2(vec2(cos(pivot_angle), -sin(pivot_angle)), vec2(sin(pivot_angle), cos(pivot_angle)));
	VERTEX.xz = rotation_matrix * VERTEX.xz;
	float body = (VERTEX.z + 1.0) / 2.0;
	float mask = smoothstep(mask_black, mask_white, 1.0 - body);
	VERTEX.x += cos(time + body) * wave * mask;
	float twist_angle = cos(time + body) * 0.3 * twist;
	mat2 twist_matrix = mat2(vec2(cos(twist_angle), -sin(twist_angle)), vec2(sin(twist_angle), cos(twist_angle)));
	VERTEX.xy = mix(VERTEX.xy, twist_matrix * VERTEX.xy, mask);
}

void fragment() {
	vec4 v = INV_VIEW_MATRIX * vec4(VERTEX, 1);
	vec2 w = vec2(fract(v.x / 128.0 + 0.5), fract(v.z / 128.0 + 0.5));
	ALBEDO = texture(tex, UV).rgb;
	ALPHA = texture(tex, UV).a;
}
