shader_type canvas_item;

#define PI 3.14159265
#define T TIME * 0.005

uniform float wobble: hint_range(0.0, 100.0, 1.0) = 10.0;
uniform vec3 panning = vec3(1.0);
uniform float speed: hint_range(0.0, 1.0, 0.001) = 0.005;

mat2 Rot(float a) {
    float s = sin(a);
	float c = cos(a);
    return mat2(vec2(c, -s), vec2(s, c));
}

float GyroScope(vec3 p) {
    p *= 10.;
    return abs(.7 * dot(sin(vec3(p.xy * Rot(-sin(TIME * speed) * PI), p.z)), cos(vec3(p.yx * Rot(sin(TIME * speed) * PI), p.z)))) -.03;
}

float GoobyGop(vec2 uv) {
    float g = GyroScope(uv.xyy + panning * cos(TIME * speed));
    g = mix (min(g, GyroScope(uv.yyx - sin(TIME * speed))), max(g, GyroScope(uv.yyx - sin(TIME * speed))), 0.5) * 1.1;
    return dot(g , g );
}

void fragment() {
	vec2 uv = UV;
	uv.x += GoobyGop(uv/wobble);
	uv.y -= GoobyGop(uv/wobble);
	uv = fract(uv);
	vec4 text = texture(TEXTURE, uv);

	COLOR = text;
}