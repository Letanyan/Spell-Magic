shader_type spatial;
//render_mode depth_prepass_alpha;

uniform float ratio;
uniform sampler2D noise;

uniform vec4 emission_color : source_color = vec4(1);
uniform float emission_amount;

uniform float burn_size : hint_range(0, 2);
uniform float dissolve_amount : hint_range(0, 1);

void fragment() {
//	ALPHA = texture(noise, UV).r < ratio ? 0.0 : 1.0;
	float sample = texture(noise, UV).r;
	float emission_value = 1.0 - smoothstep(dissolve_amount, dissolve_amount + burn_size, sample);
	EMISSION = vec3(emission_value * emission_amount * emission_color.rgb);
	ALBEDO = vec3(0);
	ALPHA = smoothstep(dissolve_amount - burn_size, dissolve_amount, sample);
}
