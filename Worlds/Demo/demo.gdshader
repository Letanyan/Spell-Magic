shader_type spatial;
render_mode specular_toon;

uniform sampler2D noise;
uniform float height_scale = 0.25;

float height(vec2 position) {
	return texture(noise, position / 1000.0).x * 50.0;
}

void vertex() {
	vec2 pos = VERTEX.xz;
	float k = height(pos);
	VERTEX.y = k;
	NORMAL = normalize(vec3(
		k - height(pos + vec2(0.1, 0.0)),
		0.1,
		k - height(pos + vec2(0.0, 0.1))
	));
	
	COLOR = vec4(1, 0, 0, 1);
}

void fragment() {
	float fresnel = sqrt(1.0 - dot(NORMAL, VIEW));
	ALBEDO = vec3(0.01, 0.05, 0.03) + (0.1 * fresnel);
	//METALLIC = 0.0;
	//ROUGHNESS = 0.01 * (1.0 - fresnel);
	//RIM = 0.2;
}
