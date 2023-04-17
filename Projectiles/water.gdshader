
shader_type spatial;
render_mode specular_toon;

uniform sampler2D noise;
uniform float height_scale = 0.05;
uniform float radius = 1;
uniform float displacement = 0.01;

float wave(vec2 position){
  position += texture(noise, position / 10.0).x * 2.0 - 1.0;
  vec2 wv = 1.0 - abs(sin(position));
  return pow(1.0 - pow(wv.x * wv.y, 0.65), 4.0);
}

float height(vec2 position, float time) {
	float d = wave((position + time) * 0.4) * 0.3;
 	d += wave((position - time) * 0.3) * 0.3;
 	d += wave((position + time) * 0.5) * 0.2;
 	d += wave((position - time) * 0.6) * 0.2;
	return clamp(d, 0.25, 1.5);
}

void vertex() {
	vec2 pos = VERTEX.xz;
//	float k = height(pos, TIME);
	float n = texture(noise, pos / radius).x;
	float k = clamp(sin(TIME * n * 3.0) / 4.0 + 1.0, 1.0 - displacement, 1.0 + displacement);
	VERTEX *= k;
	NORMAL = normalize(vec3(
		k - height(pos + vec2(0.1, 0.0), TIME),
		0.1,
		k - height(pos + vec2(0.0, 0.1), TIME)
	));
}

void fragment() {
	float fresnel = sqrt(1.0 - dot(NORMAL, VIEW));
	ALBEDO = vec3(0.02, 0.05, 0.1) + (0.01 * fresnel);
	METALLIC = 0.0;
	ROUGHNESS = 0.01 * (1.0 - fresnel);
	RIM = 0.2;
	ALPHA = 0.75;
}
