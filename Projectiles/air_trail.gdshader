shader_type spatial;
render_mode unshaded;

uniform float alpha = 0.2;
uniform float period = 1.0;
uniform float len = 1.0;
uniform float radius = 1.0;
uniform float width = 0.1;

void fragment() {
	ALBEDO = vec3(0.75, 1, 0.75);
	ALPHA = alpha;
}

void vertex() {
//	VERTEX.y = (VERTEX.y - 0.5) * 0.0 + sin(VERTEX.y + TIME);
	VERTEX.xz *= width;
	VERTEX.y = VERTEX.y * len;
	VERTEX.z = VERTEX.z + cos((VERTEX.y + TIME) * period) * radius;
}