shader_type spatial;

uniform sampler2D noise;

void vertex() {
	vec2 pixel = 1.0 / vec2(textureSize(noise, 0)); 
	vec2 w = vec2(clamp(UV.x, pixel.x, 1.0 - pixel.x), clamp(UV.y, pixel.y, 1.0 - pixel.y));
	
	vec4 clr = texture(noise, w);
	VERTEX.y = clr.r * 50.0;
}

void fragment() {
	vec2 pixel = 1.0 / vec2(textureSize(noise, 0)); 
	vec2 w = vec2(clamp(UV.x, pixel.x, 1.0 - pixel.x), clamp(UV.y, pixel.y, 1.0 - pixel.y));
	
	vec4 clr = texture(noise, w);
	ALBEDO = vec3(clr.x, clr.y, clr.z);
}
