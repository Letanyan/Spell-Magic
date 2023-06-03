shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float underwater = 0.0;

void fragment() {
	if (underwater > 0.0) {
		vec4 col = texture(screen_texture, SCREEN_UV) * 0.16;
	    col += texture(screen_texture, SCREEN_UV + vec2(0.0, SCREEN_PIXEL_SIZE.y)) * 0.15;
	    col += texture(screen_texture, SCREEN_UV + vec2(0.0, -SCREEN_PIXEL_SIZE.y)) * 0.15;
	    col += texture(screen_texture, SCREEN_UV + vec2(0.0, 2.0 * SCREEN_PIXEL_SIZE.y)) * 0.12;
	    col += texture(screen_texture, SCREEN_UV + vec2(0.0, 2.0 * -SCREEN_PIXEL_SIZE.y)) * 0.12;
	    col += texture(screen_texture, SCREEN_UV + vec2(0.0, 3.0 * SCREEN_PIXEL_SIZE.y)) * 0.09;
	    col += texture(screen_texture, SCREEN_UV + vec2(0.0, 3.0 * -SCREEN_PIXEL_SIZE.y)) * 0.09;
	    col += texture(screen_texture, SCREEN_UV + vec2(0.0, 4.0 * SCREEN_PIXEL_SIZE.y)) * 0.05;
	    col += texture(screen_texture, SCREEN_UV + vec2(0.0, 4.0 * -SCREEN_PIXEL_SIZE.y)) * 0.05;
		
	    COLOR = mix(col, vec4(0, 0.1, 0.2, 1.0), underwater);
	} else {
		COLOR = texture(screen_texture, UV);
	}
	
}
