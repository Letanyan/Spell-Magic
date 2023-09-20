shader_type spatial;
//render_mode unshaded;

uniform vec4 start_color: source_color = vec4(0, 0, 0, 1);
uniform vec4 end_color: source_color = vec4(1, 1, 1, 1);
uniform float speed = 1.0;

void fragment() {
	vec4 color = mix(start_color, end_color, 1.0 - (cos(TIME * speed) / 2.0 + 0.5));
	ALBEDO = color.rgb * 2.0;
	ALPHA = color.a;
	NORMAL = -normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
}
