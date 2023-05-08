shader_type spatial;

uniform sampler2D noise;
uniform float off_x;
uniform float off_y;
uniform float texture_width;

void vertex() {
	//VERTEX.y = VERTEX.y * 0.0;
	//vec4 clr = texture(noise, VERTEX.xz / 100.0);
	//ALBEDO = vec3(clr.x, clr.y, clr.z);
}

void fragment() {
	vec4 v = INV_VIEW_MATRIX * vec4(VERTEX, 1);
	
//	vec2 w = vec2((v.x + texture_x) / texture_width, (v.z + texture_y) / texture_depth);
//	vec2 w = vec2(mod(v.x, texture_width) / texture_width, mod(v.z, texture_depth) / texture_depth);
//	vec2 w = vec2(v.x / texture_width + 0.5, v.z / texture_depth + 0.5);
	vec2 w = vec2(fract(v.x / texture_width + 0.5), fract(v.z / texture_width + 0.5));
	
	vec4 clr = texture(noise, w);
	ALBEDO = vec3(clr.x, clr.y, clr.z);
}
