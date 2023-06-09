shader_type spatial;
render_mode cull_disabled;

uniform sampler2D noise;
uniform sampler2D ripples;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

void vertex() {
	VERTEX.y += texture(noise, UV + TIME / 16.0).r * 2.0 - 1.0;
}

void fragment() {
	// Place fragment code here.
	float __depth_tex = texture(DEPTH_TEXTURE,SCREEN_UV).r;
	vec4 __depth_world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, __depth_tex, 1.0);
	__depth_world_pos.xyz /= __depth_world_pos.w;
	float depth = 1.0 - clamp(1.0 - smoothstep(__depth_world_pos.z + 1.0, __depth_world_pos.z, VERTEX.z), 0.0, 1.0);
	depth = abs(sin((TIME * 0.5 + depth) * 3.0)) * depth + pow(depth, 20.0);
//	depth = texture(ripples, SCREEN_UV + TIME / 16.0).r * round(depth);
//	depth = round(depth);
	
	vec3 water_color = vec3(0, 0.1, 0.2) * texture(noise, UV + TIME / 16.0).rgb; 
	ALBEDO = mix(water_color, vec3(1), depth);
//	ALBEDO = vec3(UV.x, 0, UV.y);
	ALPHA = 0.9;
	ROUGHNESS = 0.0;
	METALLIC = 1.0;
	NORMAL = -normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
//	RIM = 10.0;
//	NORMAL = mix(NORMAL, vec3(0, 0, 0), 0.5);
}