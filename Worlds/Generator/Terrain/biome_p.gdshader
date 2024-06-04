shader_type spatial;
render_mode diffuse_toon, skip_vertex_transform, blend_mix;

//uniform sampler2D elevation: source_color;
uniform sampler2D temperature: source_color;
uniform sampler2D dryness: source_color;
uniform float texture_width;
uniform float texture_depth;

void vertex() {
//	NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

vec3 biome_color(vec4 V, vec2 uv) {
	// hack because fastnoise generates textures with 1 pixel edges that have increased saturation?
	vec2 pixel = 1.0 / vec2(textureSize(temperature, 0)); 
	vec2 w = vec2(clamp(uv.x, pixel.x, 1.0 - pixel.x), clamp(uv.y, pixel.y, 1.0 - pixel.y));
	float t = texture(temperature, w).r;
	float d = texture(dryness, w).r;

	vec3 color = vec3(1);

	vec3 colors[9] = {
		vec3(0.23, 0.83, 0.23),
		vec3(0, 1, 1),
		vec3(0.55, 0.28, 0.0),
		vec3(1, 1, 0),
		vec3(0, 0.4, 0.0),
		vec3(1, 0.5, 0),
		vec3(1, 1, 1),
		vec3(0, 0, 0),
		vec3(1, 0, 0)
	};
	vec2 locations[9] = {
		vec2(0.5, 0.5),
		vec2(0.25, 0.75),
		vec2(0.5, 0.75),
		vec2(0.75, 1.0),
		vec2(0.25, 0.75),
		vec2(0.75, 0.75),
		vec2(0, 0),
		vec2(1, 0),
		vec2(1, 1)
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
		//if (dist <= 1.0) {
			//color = color * c;
		//}
		if (dist < min_distance) {
			min_distance = dist;
			index = i;
			color = c;
		}
	}
	
	return color;
}

void fragment() {
	vec4 v = INV_VIEW_MATRIX * vec4(VERTEX, 1);
	
	vec3 color = biome_color(v, UV);
	
	float norm_angle = distance(vec3(0, 1, 0), -normalize(cross(dFdx(v.xyz), dFdy(v.xyz))));
	if (norm_angle > inversesqrt(2)) {
		float blend = clamp(1.0 - pow(1.0 - (norm_angle - inversesqrt(2.0)), 5.0), 0.0, 1.0);
		color = mix(color, vec3(0.15), blend);
	}

	ALBEDO = color;
	//ALBEDO = texture(dryness, UV).rgb;
	NORMAL = -normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
}

//void light() {
//	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ATTENUATION;
//	SPECULAR_LIGHT = BACKLIGHT;
//}