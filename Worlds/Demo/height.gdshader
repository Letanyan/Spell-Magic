shader_type spatial;

uniform sampler2D elevation;
uniform sampler2D temperature;
uniform sampler2D dryness;
uniform float texture_width;
uniform float texture_depth;

void vertex() {
	
}

void fragment() {
	vec4 v = INV_VIEW_MATRIX * vec4(VERTEX, 1);
	
	vec2 w = vec2(v.x / texture_width, v.z / texture_depth);
	float e = texture(elevation, w).r;
	float t = texture(temperature, w).r;
	float d = texture(dryness, w).r;
	
	vec3 color = vec3(0, 0, 0);
	
	vec3 taiga = vec3(0, 1, 1);
	vec3 grassland = vec3(0, 1, 0);
	vec3 forest = vec3(0, 0.5, 0.5);
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
		} else if (d >= 0.5 && d <= 1.0) {
			color = taiga;
		}
	} else if (t >= 0.3 && t < 0.6) {
		if (d >= 0.0 && d < 0.1) {
			color = forest;
		} else if (d >= 0.1 && d < 0.4) {
			color = forest;
		} else if (d >= 0.4 && d < 0.7) {
			color = grassland;
		} else if (d >= 0.7 && d < 0.9) {
			color = grassland;
		} else if (d >= 0.9 && d <= 1.0) {
			color = desert;
		}
	} else if (t >= 0.6 && t < 0.8) {
		if (d >= 0.0 && d < 0.1) {
			color = jungle;
		} else if (d >= 0.1 && d < 0.4) {
			color = forest;
		} else if (d >= 0.4 && d < 0.7) {
			color = grassland;
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
			color = vec3(1, 1, 1); // hfil
		} else {
			color = water;
		}
	} else if (e >= 0.01 && e < 0.2) {
		color = water;
	} else if (e >= 0.99 && e <= 1.0) {
		if (t >= 0.0 && t < 0.3) {
			color = tundra;
		} else if (t >= 0.3 && t < 0.9) {
			color = taiga;
		} else if (t >= 0.9 && t <= 1.0) {
			color = vec3(0, 0, 0); // otherworld
		}
	}
	ALBEDO = color;
//	ALBEDO = vec3(v.y / 50.0 + 0.5);
}
