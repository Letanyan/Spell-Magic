
shader_type spatial;
render_mode specular_toon, ensure_correct_normals;

uniform sampler2D noise;
uniform float height_scale = 0.05;
uniform float radius = 1;
uniform float displacement = 0.01;



void vertex() {
	vec2 pos = VERTEX.xz;
	float n = texture(noise, pos / radius).x;
	float tx = texture(noise, vec2(sin(TIME / 8.0), 0)).x * 0.3 + 0.8;
	float tz = texture(noise, vec2(0, sin(TIME / 8.0))).x * 0.3 + 0.8;
	float ty = 1.0 - ((0.3 - (tx - 0.8)) + (0.3 - (tz - 0.8))); // texture(noise, vec2(cos(TIME / 8.0), sin(TIME / 8.0))).x * 0.8 + 0.2;
	float k = clamp(sin(TIME * n * 3.0) / 4.0 + 1.0, 1.0 - displacement, 1.0 + displacement);
	vec3 result = vec3(VERTEX.x * tx, VERTEX.y * ty, VERTEX.z * tz);
	
	vec3 posPlusTangent = VERTEX + TANGENT * 0.01;
	posPlusTangent = vec3(posPlusTangent.x * tx, posPlusTangent.y * ty, posPlusTangent.z * tz);
	
	vec3 bitangent = cross(NORMAL, TANGENT);
	vec3 posPlusBitangent = VERTEX + bitangent * 0.01;
	posPlusBitangent = vec3(posPlusBitangent.x * tx, posPlusBitangent.y * ty, posPlusBitangent.z * tz);

	vec3 modTangent = posPlusTangent - result;
	vec3 modBitangent = posPlusBitangent - result;
	
	vec3 modNormal = cross(modTangent, modBitangent);
	NORMAL = normalize(modNormal);
	VERTEX = result;
}

void fragment() {
	ALBEDO = NORMAL;
	float fresnel = sqrt(1.0 - dot(NORMAL, VIEW));
	ALBEDO = vec3(0.02, 0.05, 0.5) + (0.01 * fresnel);
	METALLIC = 0.0;
	ROUGHNESS = 1.0;
	RIM = 0.2;
	ALPHA = 1.0;
}
