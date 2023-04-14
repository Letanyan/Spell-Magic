shader_type spatial;

void vertex() {
	
}

void fragment() {
	vec4 v = INV_VIEW_MATRIX * vec4(VERTEX, 1);
	ALBEDO = vec3(v.y / 50.0 + 0.5);
}
