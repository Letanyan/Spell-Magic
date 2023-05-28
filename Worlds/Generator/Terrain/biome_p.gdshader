shader_type spatial;
render_mode diffuse_toon, skip_vertex_transform, blend_mix;

uniform sampler2D elevation: source_color;
uniform sampler2D temperature: source_color;
uniform sampler2D dryness: source_color;
uniform float texture_width;
uniform float texture_depth;

void vertex() {
//	NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 v = INV_VIEW_MATRIX * vec4(VERTEX, 1);

	// hack because godot generates textures with 1 pixel edges that have increased saturation?
	vec2 pixel = 1.0 / vec2(textureSize(elevation, 0)); 
	vec2 w = vec2(clamp(UV.x, pixel.x, 1.0 - pixel.x), clamp(UV.y, pixel.y, 1.0 - pixel.y));
	float e = texture(elevation, w).r;
	float t = texture(temperature, w).r;
	float d = texture(dryness, w).r;

	vec3 color = vec3(1);
	vec3 normal = vec3(0);

//	vec3 taiga = vec3(0, 1, 1);
//	vec3 grassland = mix(vec3(1, 0.776, 0.282), texture(grass, UV).rgb, 1.0);
//	vec3 forest = mix(vec3(0.1, 0.05, 0.05), texture(forest_ground, w * 48.0).rgb, 0.1);
//	vec3 desert = vec3(1, 1, 0);
//	vec3 jungle = vec3(0, 0.25, 0.25);
//	vec3 water = vec3(0, 0, 1);
//	vec3 savannah = vec3(1, 0.5, 0);
//	vec3 tundra = vec3(1, 1, 1);

	vec3 colors[9] = {
		vec3(1, 0, 0),
		vec3(0, 0, 0),
		vec3(1, 1, 1),
		vec3(1, 0.5, 0),
		vec3(0, 0.25, 0.25),
		vec3(1, 1, 0),
		vec3(0.282, 0.133, 0.0),
		vec3(1, 0.776, 0.282),
		vec3(0, 1, 1)
	};
	vec2 locations[9] = {
		vec2(1, 1),
		vec2(1, 0),
		vec2(0, 0),
		vec2(0.75, 0.75),
		vec2(0.25, 0.75),
		vec2(0.75, 1.0),
		vec2(0.5, 0.75),
		vec2(0.5, 0.5),
		vec2(0.25, 0.75)
	};

	vec2 p = vec2(d, t);
	float distances[9];
	float total_distance = 0.0;
	int index = 0;
	float min_distance = 100.0;
	for (int i = 0; i < 9; i++) {
		float dist = distance(p, locations[i]);
		distances[i] = dist;
		vec3 c = mix(colors[i], vec3(1), dist);
		if (dist <= 1.0) {
			color = color * c;
		}
		if (dist < min_distance) {
			min_distance = dist;
			index = i;
		}
	}

	float norm_angle = distance(vec3(0, 1, 0), normalize(NORMAL));
	if (norm_angle > inversesqrt(8.0)) {
		float blend = clamp(1.0 - pow(1.0 - (norm_angle - inversesqrt(8.0)), 5.0), 0.0, 1.0);
		color = mix(color, vec3(0.15), 0.25);
	}

	ALBEDO = color;
	NORMAL = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
}

//void light() {
//	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ATTENUATION;
//	SPECULAR_LIGHT = BACKLIGHT;
//}