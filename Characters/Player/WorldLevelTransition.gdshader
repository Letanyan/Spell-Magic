shader_type canvas_item;

#include "res://General/basic.gdshaderinc"

uniform sampler2D biome_x: source_color;
uniform sampler2D biome_y: source_color;
uniform sampler2D height: source_color;
uniform float transition: hint_range(0.0, 1.0, 0.01);
uniform vec2 locations[9];

void vertex() {
	// Called for every vertex the material is visible on.
}

#define axial_weight 2.0
const int PRIME_X = 501125321;
const int PRIME_Y = 1136930381;
// (a.x, a.y, b.x, b.y) within range [0, 1]
float axial_dependant_distance(vec2 a, vec2 b) {
	return abs(b.x - a.x) * axial_weight + abs(b.y - a.y);
}
vec4 biome_color(vec2 uv) {
	// hack because fastnoise generates textures with 1 pixel edges that have increased saturation?
	vec2 pixel = 1.0 / vec2(textureSize(biome_x, 0));
	vec2 w = vec2(clamp(uv.x, pixel.x, 1.0 - pixel.x), clamp(uv.y, pixel.y, 1.0 - pixel.y));
	float bx = texture(biome_x, w).r;
	float by = texture(biome_y, w).r;

	vec4 color = vec4(1);

	// use alpha channel to store cliff side gray color
	vec4 colors[9] = {
		vec4(0.23, 0.83, 0.23, 0.15), // grassland
		vec4(0, 1, 1, 0.1),           // taiga
		vec4(0.55, 0.28, 0.0, 0.08),  // forest
		vec4(1, 1, 0, 0.2),           // desert
		vec4(0, 0.4, 0.0, 0.08),      // jungle
		vec4(1, 0.5, .0, 0.2),        // savannah
		vec4(1, 1, 1, 1.0),           // tundra
		vec4(0, 0, 0, 1.0),           // otherworld
		vec4(1, 0, 0, 0.0)            // hfil
	};

	vec2 p = vec2(bx, by);
	float distances[9];
	int index = 0;
	float min_distance = 100000.0;
	for (int i = 0; i < 9; i++) {
		float dist = axial_dependant_distance(p, locations[i]);
		//float dist = distance(w, locations[i]);
		distances[i] = dist;
		if (dist <= (axial_weight + 1.0)) {
			float mix_alpha = pow(1.0 - dist / (axial_weight + 1.0), 3.0);
			vec3 c = oklab_mix(vec3(1), colors[i].rgb, mix_alpha);
			color = color * vec4(c, mix(1, colors[i].a, mix_alpha));

			//vec4 c = mix(vec4(1), colors[i], pow(1.0 - dist / (axial_weight + 1.0), 3.0));
			//color = color * c;
		}
		if (dist < min_distance) {
			min_distance = dist;
			index = i;
			//color = colors[i];
		}
	}

	color.rgb = rgb2hsv(color.rgb);
	color.b = 1.0 - pow(1.0 - color.b, 2.0);
	color.rgb = hsv2rgb(color.rgb);

	return color;
}

void fragment() {
	vec4 color = biome_color(UV);
	//color = mix(color, texture(noise, UV).rgba, 0.05);
	vec4 alpha = smoothstep(1.0 - transition, (1.0 - transition) + 0.05, texture(height, UV));

	COLOR = vec4(color.rgb, alpha.r);
	//vec2 pixel = 1.0 / vec2(textureSize(biome_x, 0));
	//vec2 w = vec2(clamp(UV.x, pixel.x, 1.0 - pixel.x), clamp(UV.y, pixel.y, 1.0 - pixel.y));
	//ALBEDO = texture(biome_w, w).rgb;
	//NORMAL = -normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
}
