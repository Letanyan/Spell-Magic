shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx,vertex_lighting,shadows_disabled,unshaded;

uniform sampler2D noise_tex : hint_default_white;
uniform vec4 bg_color : source_color = vec4( 1.0, 0.75, 0.3, 1.0 );
uniform vec4 fg_color : source_color = vec4( 1.0, 0.03, 0.001, 1.0 );
uniform vec2 movement_speed = vec2( 0.0, 0.25 );
uniform float scale_speed: hint_range(0.0, 1.0, 0.1) = 0.5;

void vertex() {
	VERTEX.z += sin(TIME * 0.5 + VERTEX.x / 5000.0) * 100.0 + 100.0;
	VERTEX.y += sin(TIME * 0.5 + VERTEX.x / 5000.0) * 100.0 + 25.0;
	//VERTEX.x += sin(TIME + VERTEX.y / 5000.0) * 50.0;
}

void fragment( )
{
	float scale = (sin(TIME * scale_speed) / 2.0 * 0.5 + 0.5 + 0.5);
	vec2 base = (UV - 0.5 * (scale - 1.0)) * scale + TIME * movement_speed;
	
	float noise = texture(noise_tex, base).r;
	vec4 color = mix( bg_color, fg_color, noise);

	ALPHA = 1.0;
	ALBEDO = color.rgb;
}
