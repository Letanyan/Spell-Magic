shader_type spatial;
render_mode diffuse_toon, skip_vertex_transform, blend_mix;

//uniform sampler2D elevation: source_color;
uniform sampler2D biome_x: source_color;
uniform sampler2D biome_y: source_color;
uniform sampler2D height;
uniform float texture_width;
uniform float texture_depth;

void vertex() {
//	NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	//vec2 pixel = 1.0 / vec2(textureSize(height, 0)); 
	//vec2 w = vec2(clamp(UV.x, pixel.x, 1.0 - pixel.x), clamp(UV.y, pixel.y, 1.0 - pixel.y));
	//VERTEX.y += texture(height, w).r;
}

#define axial_weight 2.0

// (a.x, a.y, b.x, b.y) within range [0, 1]
float axial_dependant_distance(vec2 a, vec2 b) {
	return abs(b.x - a.x) * axial_weight + abs(b.y - a.y);
}

vec3 biome_color(vec4 V, vec2 uv) {
	// hack because fastnoise generates textures with 1 pixel edges that have increased saturation?
	vec2 pixel = 1.0 / vec2(textureSize(biome_x, 0)); 
	vec2 w = vec2(clamp(uv.x, pixel.x, 1.0 - pixel.x), clamp(uv.y, pixel.y, 1.0 - pixel.y));
	float bx = texture(biome_x, w).r;
	float by = texture(biome_y, w).r;

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
		vec2(0.50, 0.50), // grassland
		vec2(0.75, 0.00), // taiga
		vec2(0.50, 0.25), // forest
		vec2(0.25, 0.75), // desert
		vec2(0.25, 0.25), // jungle
		vec2(0.25, 0.50), // savannah
		vec2(1.00, 0.50), // tundra
		vec2(1.00, 0.00), // otherworld
		vec2(0.00, 1.00)  // hfil
	};

	vec2 p = vec2(bx, by);
	float distances[9];
	float total_distance = 0.0;
	int index = 0;
	float min_distance = 100000.0;
	for (int i = 0; i < 9; i++) {
		float dist = axial_dependant_distance(p, locations[i]);
		distances[i] = dist;
		if (dist <= (axial_weight + 1.0)) {
			vec3 c = mix(vec3(1), colors[i], pow(1.0 - dist / (axial_weight + 1.0), 3.0));
			color = color * c;
		}
		if (dist < min_distance) {
			min_distance = dist;
			index = i;
			//color = colors[i];
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
	//vec2 pixel = 1.0 / vec2(textureSize(biome_x, 0)); 
	//vec2 w = vec2(clamp(UV.x, pixel.x, 1.0 - pixel.x), clamp(UV.y, pixel.y, 1.0 - pixel.y));
	//ALBEDO = texture(biome_w, w).rgb;
	NORMAL = -normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
}

//void light() {
//	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ATTENUATION;
//	SPECULAR_LIGHT = BACKLIGHT;
//}