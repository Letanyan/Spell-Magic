shader_type spatial;

uniform sampler2D text;

void fragment() {
	// Place fragment code here.
	vec3 color = texture(text, UV).rgb;
	float r = color.r;
	float g = color.g;
	float b = color.b;
	
	ALBEDO = vec3(r, g, b);
}
