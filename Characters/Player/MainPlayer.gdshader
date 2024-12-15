shader_type spatial;

render_mode unshaded, depth_draw_always, blend_mix, cull_disabled, alpha_to_coverage;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D normal_texture : hint_normal_roughness_texture, repeat_disable, filter_nearest;
uniform sampler2D noise_texture : repeat_enable;
uniform sampler2D caustic: source_color, repeat_enable;

uniform float underwater = 0.0;
uniform float depth_distance: hint_range(0.0, 500.0, 1.0) = 10.0;


void vertex() {
	POSITION = vec4(vec3(VERTEX.x, VERTEX.y, 0.5), 1.0);
}

void fragment() {
	float depth_blend = 1.0;
	vec3 underwater_color = vec3(0);
	vec2 base_uv = SCREEN_UV;

	if (underwater > 0.0) {
		vec2 offset = texture(noise_texture, UV + sin(TIME / 10.0) / 1.0).rg * 0.01;
		base_uv += offset;

		vec3 normal = texture(normal_texture, base_uv).xyz * 2.0 - 1.0;
		vec3 world_normal = (transpose(VIEW_MATRIX) * vec4(normal, 0.0)).xyz;

		#define tex screen_texture
		vec2 SCREEN_PIXEL_SIZE = 1.0 / vec2(textureSize(tex, 0));
		vec4 col = texture(tex, base_uv) * 0.16;
	    col += texture(tex, base_uv + vec2(0.0, SCREEN_PIXEL_SIZE.y)) * 0.15;
	    col += texture(tex, base_uv + vec2(0.0, -SCREEN_PIXEL_SIZE.y)) * 0.15;
	    col += texture(tex, base_uv + vec2(0.0, 2.0 * SCREEN_PIXEL_SIZE.y)) * 0.12;
	    col += texture(tex, base_uv + vec2(0.0, 2.0 * -SCREEN_PIXEL_SIZE.y)) * 0.12;
	    col += texture(tex, base_uv + vec2(0.0, 3.0 * SCREEN_PIXEL_SIZE.y)) * 0.09;
	    col += texture(tex, base_uv + vec2(0.0, 3.0 * -SCREEN_PIXEL_SIZE.y)) * 0.09;
	    col += texture(tex, base_uv + vec2(0.0, 4.0 * SCREEN_PIXEL_SIZE.y)) * 0.05;
	    col += texture(tex, base_uv + vec2(0.0, 4.0 * -SCREEN_PIXEL_SIZE.y)) * 0.05;

		vec2 normal_to_uv = (vec2(world_normal.x, world_normal.z) + UV) / 2.0;
		//vec2 normal_to_uv = vec2(world_normal.x, world_normal.z);
		vec3 cch = texture(caustic, (normal_to_uv - sin(TIME / 10.0)) * ((sin(TIME / 10.0) / 2.0 + 0.5) * 0.15 + 0.85) + vec2(TIME, 3.0) * 0.125).rgb;
		//vec3 ccv = texture(caustic, (sin(UV * cch.r) - sin(TIME / 10.0)) * ((sin(TIME / 10.0) / 2.0 + 0.5) * 0.15 + 0.85) + vec2(0.0, TIME) * 0.125).rgb;
		vec3 ccv = texture(caustic, (normal_to_uv - sin(TIME / 10.0)) * ((sin(TIME / 10.0) / 2.0 + 0.5) * 0.15 + 0.85) + vec2(0.0, TIME) * 0.125).rgb;
		vec3 caustic_color = pow((cch + ccv) / 2.0, vec3(7.0)) * 1.0;

	    underwater_color = mix(col.rgb, vec3(0, 0.1, 0.2), underwater) + caustic_color;
	} else {
		underwater_color = texture(tex, SCREEN_UV).rgb;
	}

	if (depth_distance > 0.0) {
		float depth = texture(depth_texture, base_uv).x;
		vec4 world = INV_PROJECTION_MATRIX * vec4(base_uv * 2.0 - 1.0, depth, 1.0);
		world.xyz /= world.w;
		depth_blend = smoothstep(world.z + depth_distance, world.z, VERTEX.z);
	}

	ALBEDO = mix(vec3(0, 0.1, 0.2), underwater_color, depth_blend);
	ALPHA = 0.99;
}
