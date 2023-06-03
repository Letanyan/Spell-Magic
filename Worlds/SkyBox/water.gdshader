shader_type spatial;

uniform sampler2D noise;

void vertex() {
	VERTEX.y += texture(noise, UV + TIME / 16.0).r * 2.0 - 1.0;
}

void fragment() {
	// Place fragment code here.
	ALBEDO = vec3(0, 0.1, 0.2);
//	ALBEDO = vec3(UV.x, 0, UV.y);
	ALPHA = 0.9;
	NORMAL = -normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	ROUGHNESS = 0.0;
	METALLIC = 1.0;
//	RIM = 10.0;
//	NORMAL = mix(NORMAL, vec3(0, 0, 0), 0.5);
}
