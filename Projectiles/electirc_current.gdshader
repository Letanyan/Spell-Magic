shader_type spatial;
render_mode unshaded;

uniform float alpha = 1.0;
uniform float period = 2.0;
uniform float len = 0.5;
uniform float radius = 0.25;
uniform float width = 0.1;
uniform bool use_vertex_color = false;
uniform vec3 color: source_color = vec3(1);
uniform float comps[8];

void fragment() {
	ALBEDO = use_vertex_color ? COLOR.rgb : color;
	ALPHA = use_vertex_color ? COLOR.a : alpha;
}

void vertex() {
//	VERTEX.y = (VERTEX.y - 0.5) * 0.0 + sin(VERTEX.y + TIME);
	VERTEX.xz *= width * (sin(UV.y * 2.0 * PI + TIME) / 2.0 + 0.5);
	VERTEX.y = VERTEX.y * len * sin(UV.y + TIME);
	float fft = 0.0;
	float comp_count = 0.0;
	for (int i = 0; i < comps.length(); i++) {
		if (comps[i] != 0.0) {
			fft += sin((comps[i] * VERTEX.y + TIME) * period + float(INSTANCE_ID));
			comp_count += 1.0;
		}
	}
	
	VERTEX.z = VERTEX.z + (fft / comp_count) * radius;
}