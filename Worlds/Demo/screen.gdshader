shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D noise_texture : repeat_enable;
uniform sampler2D debug_texture : repeat_disable;
uniform float underwater = 0.0;

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float snapped(float value, float multiple) {
	return round(value / multiple) * multiple;
}

vec3 snapped3(vec3 value, float multiple) {
	value.x = snapped(value.x, multiple);
	value.y = snapped(value.y, multiple);
	value.z = snapped(value.z, multiple);
	return value;
}

void fragment() {
	#define tex screen_texture
	//#define tex debug_texture
	if (underwater > 0.0) {
		vec2 offset = texture(noise_texture, UV + sin(TIME / 10.0) / 1.0).rg * 0.05;
		vec2 base_uv = UV + offset;
		
		vec4 col = texture(tex, base_uv) * 0.16;
	    col += texture(tex, base_uv + vec2(0.0, SCREEN_PIXEL_SIZE.y)) * 0.15;
	    col += texture(tex, base_uv + vec2(0.0, -SCREEN_PIXEL_SIZE.y)) * 0.15;
	    col += texture(tex, base_uv + vec2(0.0, 2.0 * SCREEN_PIXEL_SIZE.y)) * 0.12;
	    col += texture(tex, base_uv + vec2(0.0, 2.0 * -SCREEN_PIXEL_SIZE.y)) * 0.12;
	    col += texture(tex, base_uv + vec2(0.0, 3.0 * SCREEN_PIXEL_SIZE.y)) * 0.09;
	    col += texture(tex, base_uv + vec2(0.0, 3.0 * -SCREEN_PIXEL_SIZE.y)) * 0.09;
	    col += texture(tex, base_uv + vec2(0.0, 4.0 * SCREEN_PIXEL_SIZE.y)) * 0.05;
	    col += texture(tex, base_uv + vec2(0.0, 4.0 * -SCREEN_PIXEL_SIZE.y)) * 0.05;
		
	    COLOR = mix(col, vec4(0, 0.1, 0.2, 1.0), underwater);
	} else {
		COLOR = texture(tex, UV);
	}
	
	//vec3 hsv = rgb2hsv(COLOR.rgb);
	//hsv.x = snapped(hsv.x, 1.0 / 16.0);
	//hsv.y = snapped(hsv.y, 0.25);
	//hsv.z = snapped(hsv.z, 0.25);
	//
	//COLOR.rgb = hsv2rgb(hsv);
}
