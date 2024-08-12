shader_type spatial;

render_mode unshaded, depth_draw_always, blend_mix, cull_disabled, alpha_to_coverage;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D noise_texture : repeat_enable;

uniform float underwater = 0.0;
uniform float depth_distance: hint_range(0.0, 500.0, 1.0) = 10.0;

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	float depth_blend = 1.0;
	vec3 underwater_color = vec3(0);
	vec2 base_uv = SCREEN_UV;
	
	if (underwater > 0.0) {
		vec2 offset = texture(noise_texture, UV + sin(TIME / 10.0) / 1.0).rg * 0.05;
		base_uv += offset;
		
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
		
	    underwater_color = mix(col.rgb, vec3(0, 0.1, 0.2), underwater);
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
}

