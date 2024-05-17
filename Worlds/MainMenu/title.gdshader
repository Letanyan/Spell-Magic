shader_type spatial;

uniform uint base_seed = 1382;
uniform vec4 bg_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 fg_color : source_color = vec4(1.0);
uniform float xy_ratio = 1.0;

float rand(inout uint seed) {
  int k;
  int s = int(seed);
  if (s == 0)
    s = 305420679;
  k = s / 127773;
  s = 16807 * (s - k * 127773) - 2836 * k;
  if (s < 0)
    s += 2147483647;
  seed = uint(s);
  return float(seed % uint(65536)) / 65535.0;
}

float randn(inout uint seed) {
	return (rand(seed) - 0.5) * 2.0;
}

uint hash(uint x) {
  x = ((x >> uint(16)) ^ x) * uint(73244475);
  x = ((x >> uint(16)) ^ x) * uint(73244475);
  x = (x >> uint(16)) ^ x;
  return x;
}

bool is_in_circle(vec2 pos, vec3 circle) {
	return pow(pos.x - circle.x, 2.0) / pow(circle.z * xy_ratio, 2.0) + pow(pos.y - circle.y, 2.0) / pow(circle.z, 2.0) <= 1.0;
}

vec4 paint(vec4 bg, vec4 fg) {
	vec4 r = vec4(0.0);
	r.a = 1.0 - (1.0 - fg.a) * (1.0 - bg.a);
	if (r.a < 1.0e-6) return r;
	r.r = fg.r * fg.a / r.a + bg.r * bg.a * (1.0 - fg.a) / r.a;
	r.g = fg.g * fg.a / r.a + bg.g * bg.a * (1.0 - fg.a) / r.a;
	r.b = fg.b * fg.a / r.a + bg.b * bg.a * (1.0 - fg.a) / r.a;
	return r;
}

vec3 make_circle(inout uint seed, float t) {
	vec3 base = vec3(rand(seed), rand(seed), rand(seed) * 0.2);
	
	vec4 rot = vec4(rand(seed), rand(seed), rand(seed) * PI * 2.0 + t, rand(seed) * 0.3);
	
	base.x -= rot.x;
	base.y -= rot.y;
	
	float c = cos(rot.z / 10.0);
	float s = sin(rot.z / 10.0);
	base.x = base.x * c - base.y * s + rot.x;
	base.y = base.x * s + base.y * c + rot.y;
	
	base.z = base.z + rot.w * sin((t + rand(seed) * PI * 2.0) / 100.0);
	
	return base;
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	uint base = base_seed;
	
	vec4 final_color = bg_color;
	for (int i = 0; i < 100; i++) {
		uint seed = hash(base + uint(i));
		vec3 circ = make_circle(seed, TIME);
		if (is_in_circle(UV, circ)) {
			final_color = paint(final_color, fg_color);
		}
	}
	
	ALBEDO = final_color.rgb;
	ALPHA = final_color.a;
}