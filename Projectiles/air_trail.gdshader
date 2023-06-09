shader_type spatial;
//render_mode unshaded;

uniform float alpha = 1.0;
uniform float period = 2.0;
uniform float len = 0.5;
uniform float radius = 0.25;
uniform float width = 0.1;
uniform bool use_vertex_color = true;
uniform vec3 color: source_color = vec3(1);

void fragment() {
	ALBEDO = use_vertex_color ? COLOR.rgb : color;
	ALPHA = use_vertex_color ? COLOR.a : alpha;
	NORMAL = -normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
}

void vertex() {
//	VERTEX.y = (VERTEX.y - 0.5) * 0.0 + sin(VERTEX.y + TIME);
	VERTEX.xz *= width;
	VERTEX.y = VERTEX.y * len;
	VERTEX.z = VERTEX.z + sin((VERTEX.y + TIME) * period + float(INSTANCE_ID)) * radius;
	VERTEX.x = VERTEX.x + cos((VERTEX.y + TIME) * period + float(INSTANCE_ID)) * radius;
}