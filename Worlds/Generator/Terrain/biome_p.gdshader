shader_type spatial;
render_mode diffuse_toon, skip_vertex_transform, blend_mix;

#include "res://General/basic.gdshaderinc"

//uniform sampler2D elevation: source_color;
uniform sampler2D biome_x: source_color;
uniform sampler2D biome_y: source_color;
uniform sampler2D noise: source_color;
uniform vec2 locations[9];
const float noise_weights[9] = {
	0.0, // grassland
	0.0, // taiga
	0.0, // forest
	1.5, // desert
	0.0, // jungle
	0.0, // savannah
	0.0, // tundra
	0.0, // otherworld
	0.0  // hfil
};
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
};

void vertex() {
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

#define axial_weight 2.0
const int PRIME_X = 501125321;
const int PRIME_Y = 1136930381;
// (a.x, a.y, b.x, b.y) within range [0, 1]
float axial_dependant_distance(vec2 a, vec2 b) {
	return abs(b.x - a.x) * axial_weight + abs(b.y - a.y);
}
float cubic_lerp( float a, float b, float c, float d, float t )
{
	float p = d - c - ( a - b );
	return t * t * t * p + t * t * ( a - b - p ) + t * ( c - a ) + b;
}
int hash( int seed, int x_primed, int y_primed )
{
	return ( seed ^ x_primed ^ y_primed ) * 0x27d4eb2d;
}
float val_coord( int seed, int x_primed, int y_primed )
{
    int hash = hash( seed, x_primed, y_primed );
    hash *= hash;
    hash ^= hash << 19;
    return float( hash ) * ( 1.0 / 2147483648.0 );
}
float single_value_cubic( int seed, float x, float y )
{
    int x1 = int( floor( x ));
    int y1 = int( floor( y ));

    float xs = x - float( x1 );
    float ys = y - float( y1 );

    x1 *= PRIME_X;
    y1 *= PRIME_Y;
    int x0 = x1 - PRIME_X;
    int y0 = y1 - PRIME_Y;
    int x2 = x1 + PRIME_X;
    int y2 = y1 + PRIME_Y;
    int x3 = x1 + ( PRIME_X << 1 );
    int y3 = y1 + ( PRIME_Y << 1 );

    return cubic_lerp(
        cubic_lerp( val_coord( seed, x0, y0 ), val_coord( seed, x1, y0 ), val_coord( seed, x2, y0 ), val_coord( seed, x3, y0 ), xs ),
        cubic_lerp( val_coord( seed, x0, y1 ), val_coord( seed, x1, y1 ), val_coord( seed, x2, y1 ), val_coord( seed, x3, y1 ), xs ),
        cubic_lerp( val_coord( seed, x0, y2 ), val_coord( seed, x1, y2 ), val_coord( seed, x2, y2 ), val_coord( seed, x3, y2 ), xs ),
        cubic_lerp( val_coord( seed, x0, y3 ), val_coord( seed, x1, y3 ), val_coord( seed, x2, y3 ), val_coord( seed, x3, y3 ), xs ),
    ys ) * ( 1.0 / ( 1.5 * 1.5 ));
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
			vec3 c = oklab_mix(vec3(1.0), biome_colors[i].rgb, mix_alpha);// - texture(noise, uv * 16.0).rgb * noise_weights[i] * pow(mix_alpha, 2.0);
			color = color * vec4(c, mix(1, biome_colors[i].a, mix_alpha));
		}
		if (dist < min_distance) {
			min_distance = dist;
			index = i;
			//color = biome_colors[i];
			//color.rgb -= texture(noise, uv).rgb * noise_weights[i];
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