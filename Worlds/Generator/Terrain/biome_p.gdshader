shader_type spatial;
render_mode diffuse_toon, skip_vertex_transform, blend_mix;

#include "res://General/basic.gdshaderinc"

//uniform sampler2D elevation: source_color;
uniform sampler2D biome_x: source_color;
uniform sampler2D biome_y: source_color;
uniform vec2 locations[9];
// use alpha channel to store cliff side gray color
const vec4 biome_colors[9] = {
	vec4(0.23, 0.83, 0.23, 0.15), // grassland
	vec4(0, 1, 1, 0.1),           // taiga
	vec4(0.55, 0.28, 0.0, 0.08),  // forest
	vec4(1, 1, 0, 0.2),           // desert
	vec4(0, 0.4, 0.0, 0.08),      // jungle
	vec4(1, 0.5, .0, 0.2),        // savannah
	vec4(1, 1, 1, 1.0),           // tundra
	vec4(0, 0, 0, 1.0),           // otherworld
	vec4(1, 0, 0, 0.0)            // hfil
	//vec4(0.0, 1.0, 0.0, 0.15), // grassland
	//vec4(0.0, 1.0, 1.0, 0.1), // taiga
	//vec4(0.0, 0.5, 0.0, 0.08), // forest
	//vec4(1.0, 1.0, 0.0, 0.2), // desert
	//vec4(0.0, 0.5, 0.3, 0.08), // jungle
	//vec4(1.0, 0.5, 0.0, 0.2), // savannah
	//vec4(1.0, 1.0, 1.0, 1.0), // tundra
	//vec4(0.0, 0.0, 0.0, 1.0), // otherworld
	//vec4(1.0, 0.0, 0.0, 0.0) // hfil
};

void vertex() {
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

#define axial_weight 2.0
// (a.x, a.y, b.x, b.y) within range [0, 1]
float axial_dependant_distance(vec2 a, vec2 b) {
	return abs(b.x - a.x) * axial_weight + abs(b.y - a.y);
}

vec4 biome_color(vec4 V, vec2 uv) {
	// hack because fastnoise generates textures with 1 pixel edges that have increased saturation?
	vec2 pixel = 1.0 / vec2(textureSize(biome_x, 0));
	vec2 w = vec2(clamp(uv.x, pixel.x, 1.0 - pixel.x), clamp(uv.y, pixel.y, 1.0 - pixel.y));
	float bx = texture(biome_x, w).r;
	float by = texture(biome_y, w).r;

	vec4 color = vec4(1);

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
			vec3 c = oklab_mix(vec3(1.0), biome_colors[i].rgb, mix_alpha);
			color = color * vec4(c, mix(1, biome_colors[i].a, mix_alpha));
		}
		if (dist < min_distance) {
			min_distance = dist;
			index = i;
			//color = biome_colors[i];
		}
	}

	color.rgb = rgb2hsv(color.rgb);
	color.b = 1.0 - pow(1.0 - color.b, 2.0);
	color.rgb = hsv2rgb(color.rgb);

	return color;
}

void fragment() {
	vec4 v = INV_VIEW_MATRIX * vec4(VERTEX, 1);

	vec4 color = biome_color(v, UV);
	//color = mix(color, texture(noise, UV).rgba, 0.05);

	float norm_angle = distance(vec3(0, 1, 0), -normalize(cross(dFdx(v.xyz), dFdy(v.xyz))));
	if (norm_angle > inversesqrt(2.0)) {
		float blend = clamp(1.0 - pow(1.0 - (norm_angle - inversesqrt(2.0)), 5.0), 0.0, 1.0);
		color.rgb = mix(color.rgb, vec3(color.a), blend);
	}

	ALBEDO = color.rgb;
	//vec2 pixel = 1.0 / vec2(textureSize(biome_x, 0));
	//vec2 w = vec2(clamp(UV.x, pixel.x, 1.0 - pixel.x), clamp(UV.y, pixel.y, 1.0 - pixel.y));
	//ALBEDO = texture(biome_w, w).rgb;
	//ROUGHNESS = 1.0;
	NORMAL = -normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
}

//void light() {
//	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ATTENUATION;
//	SPECULAR_LIGHT = BACKLIGHT;
//}