shader_type spatial;

uniform sampler2D noise;
uniform float off_x;
uniform float off_y;

void vertex() {
	//VERTEX.y = VERTEX.y * 0.0;
	//vec4 clr = texture(noise, VERTEX.xz / 100.0);
	//ALBEDO = vec3(clr.x, clr.y, clr.z);
}

void fragment() {
	// Place fragment code here.
	vec4 v = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
//	vec4 w = vec4(v.x + off_x, v.y, v.z + off_y, v.w);
	vec4 clr = texture(noise, v.xz / 50.0 + 0.5);
	ALBEDO = vec3(clr.x, clr.y, clr.z);
}
