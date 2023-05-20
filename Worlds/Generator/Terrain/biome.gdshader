shader_type spatial;
render_mode diffuse_toon, skip_vertex_transform;

uniform sampler2D elevation;
uniform sampler2D temperature;
uniform sampler2D dryness;
uniform float texture_width;
uniform float texture_depth;

uniform sampler2D grass;
uniform sampler2D grass_normal;
uniform sampler2D forest_ground;
uniform sampler2D forest_ground_normal;

void vertex() {
//	vec2 pixel = 1.0 / vec2(textureSize(elevation, 0)); 
//	vec2 w = vec2(clamp(UV.x, pixel.x, 1.0 - pixel.x), clamp(UV.y, pixel.y, 1.0 - pixel.y));
//
//	vec4 clr = texture(elevation, w);
//	VERTEX.y = clr.r * 250.0;
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
//	NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec4 v = INV_VIEW_MATRIX * vec4(VERTEX, 1);
	
//	vec2 w = vec2((v.x + texture_x) / texture_width, (v.z + texture_y) / texture_depth);
//	vec2 w = vec2(mod(v.x, texture_width) / texture_width, mod(v.z, texture_depth) / texture_depth);
//	vec2 w = vec2(v.x / texture_width + 0.5, v.z / texture_depth + 0.5);

	vec2 tw = vec2(fract(v.x / texture_width + 0.5), fract(v.z / texture_depth + 0.5));

	// hack because godot generates textures with 1 pixel edges that have increased saturation?
	vec2 pixel = 1.0 / vec2(textureSize(elevation, 0)); 
	vec2 w = vec2(clamp(UV.x, pixel.x, 1.0 - pixel.x), clamp(UV.y, pixel.y, 1.0 - pixel.y));
	
	float e = texture(elevation, w).r;
	float t = texture(temperature, w).r;
	float d = texture(dryness, w).r;
	
	vec3 color = vec3(0, 0, 0);
	vec3 normal = vec3(0, 0, 0);
	
	vec3 taiga = vec3(0, 1, 1);
	vec3 grassland = mix(vec3(1, 0.776, 0.282), texture(grass, UV).rgb, 1.0);
	vec3 grassland_normal = texture(grass_normal, UV).rgb;
	vec3 forest = mix(vec3(0.1, 0.05, 0.05), texture(forest_ground, UV).rgb, 1.0);
	vec3 forest_normal = texture(forest_ground_normal, UV).rgb;
	vec3 desert = vec3(1, 1, 0);
	vec3 jungle = vec3(0, 0.25, 0.25);
	vec3 water = vec3(0, 0, 1);
	vec3 savannah = vec3(1, 0.5, 0);
	vec3 tundra = vec3(1, 1, 1);
	
	if (t >= 0.0 && t < 0.1) {
		color = taiga;
	} else if (t >= 0.1 && t < 0.3) {
		if (d >= 0.0 && d < 0.5) {
			color = grassland;
			normal = grassland_normal;
		} else if (d >= 0.5 && d <= 1.0) {
			color = taiga;
		}
	} else if (t >= 0.3 && t < 0.6) {
		if (d >= 0.0 && d < 0.1) {
			color = forest;
			normal = forest_normal;
		} else if (d >= 0.1 && d < 0.4) {
			color = forest;
			normal = forest_normal;
		} else if (d >= 0.4 && d < 0.7) {
			color = grassland;
			normal = grassland_normal;
		} else if (d >= 0.7 && d < 0.9) {
			color = grassland;
			normal = grassland_normal;
		} else if (d >= 0.9 && d <= 1.0) {
			color = desert;
		}
	} else if (t >= 0.6 && t < 0.8) {
		if (d >= 0.0 && d < 0.1) {
			color = jungle;
		} else if (d >= 0.1 && d < 0.4) {
			color = forest;
			normal = forest_normal;
		} else if (d >= 0.4 && d < 0.7) {
			color = grassland;
			normal = grassland_normal;
		} else if (d >= 0.7 && d < 0.9) {
			color = desert;
		} else if (d >= 0.9 && d <= 1.0) {
			color = desert;
		}
	} else if (t >= 0.8 && t <= 1.0) {
		if (d >= 0.0 && d < 0.1) {
			color = jungle;
		} else if (d >= 0.1 && d < 0.4) {
			color = jungle;
		} else if (d >= 0.4 && d < 0.7) {
			color = savannah;
		} else if (d >= 0.7 && d < 0.9) {
			color = savannah;
		} else if (d >= 0.9 && d <= 1.0) {
			color = desert;
		}
	}
	
	if (e >= 0.0 && e < 0.01) {
		if (t >= 0.9 && t <= 1.0) {
			color = vec3(1, 0, 0); // hfil
		} else {
			color = water;
		}
	} else if (e >= 0.01 && e < 0.2) {
		color = water;
	} else if (e >= 0.85 && e <= 1.0) {
		if (t >= 0.0 && t < 0.3) {
			color = tundra;
		} else if (t >= 0.3 && t < 0.9) {
			color = taiga;
		} else if (t >= 0.9 && t <= 1.0) {
			color = vec3(0, 0, 0); // otherworld
		}
	}
	
	if (distance(vec3(0, 1, 0), normalize(NORMAL)) > inversesqrt(8.0)) {
		color = vec3(0.25);
	}
	
	ALBEDO = color;
	if (normal != vec3(0)) {
		NORMAL_MAP = normal;
	} 
}
