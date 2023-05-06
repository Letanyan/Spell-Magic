shader_type particles;

float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453) * 2.0 - 1.0;
}

void start() {
	// Place start code here.
	TRANSFORM[3].xyz = vec3(0);
	TRANSFORM[0].xyz = vec3(1, 0, 0) * rand(vec2(TIME)) * 5.0;
	TRANSFORM[1].xyz = vec3(0, 1, 0) * rand(vec2(TIME)) * 5.0;
	TRANSFORM[2].xyz = vec3(0, 0, 1) * rand(vec2(TIME)) * 5.0;
	VELOCITY.x = 5.0 * rand(vec2(TIME));
	VELOCITY.y = 5.0 * rand(vec2(TIME));
	VELOCITY.z = 5.0 * rand(vec2(TIME));
	COLOR = vec4(1, 0, 1, 1);
}

void process() {
	// Place process code here.
	TRANSFORM[0].xyz *= 0.9;
	TRANSFORM[1].xyz *= 0.9;
	TRANSFORM[2].xyz *= 0.9;
//	TRANSFORM[0].xyz *= TIME / LIFETIME;
//	TRANSFORM[1].xyz *= 0.9;
//	TRANSFORM[2].xyz *= 0.9;
}