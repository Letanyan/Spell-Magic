shader_type spatial;
render_mode cull_disabled;
//render_mode unshaded;

uniform float alpha = 1.0;
uniform float period = 2.0;
uniform float len = 0.5;
uniform float radius = 0.25;
uniform float width = 0.1;
uniform float center_bend = 0.25;
uniform float center_bend_growth = 10.0;
uniform bool use_vertex_color = false;
uniform vec3 color: source_color = vec3(1);
uniform float comps[8];

void fragment() {
	ALBEDO = (use_vertex_color ? COLOR.rgb : color) * 2.0;
	ALPHA = use_vertex_color ? COLOR.a : alpha;
	NORMAL = -normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
}

void vertex() {
//	VERTEX.y = (VERTEX.y - 0.5) * 0.0 + sin(VERTEX.y + TIME);
	VERTEX.xz *= width * (sin(UV.y * 2.0 * PI + TIME / 10.0) / 2.0 + 0.5);
	VERTEX.y = VERTEX.y * len * sin(UV.y + TIME / 10.0);
	float fft = 0.0;
	float comp_count = 0.0;
	for (int i = 0; i < comps.length(); i++) {
		if (comps[i] != 0.0) {
			fft += sin((comps[i] * VERTEX.y + TIME) * period + float(INSTANCE_ID));
			comp_count += 1.0;
		}
	}
	
	VERTEX.z += (fft / comp_count) * radius;
	VERTEX.z += cos((UV.y - 0.5) * 4.0 * PI) * (cos(TIME * center_bend_growth + float(INSTANCE_ID)) / 2.0 + 0.5) * center_bend;
}