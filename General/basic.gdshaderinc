vec3 oklab_mix( vec3 colA, vec3 colB, float h )
{
    // https://bottosson.github.io/posts/oklab
    const mat3 kCONEtoLMS = mat3(
         vec3(0.4121656120,  0.2118591070,  0.0883097947),
         vec3(0.5362752080,  0.6807189584,  0.2818474174),
         vec3(0.0514575653,  0.1074065790,  0.6302613616));
    const mat3 kLMStoCONE = mat3(
         vec3(4.0767245293, -1.2681437731, -0.0041119885),
        vec3(-3.3072168827,  2.6093323231, -0.7034763098),
         vec3(0.2307590544, -0.3411344290,  1.7068625689));

    // rgb to cone (arg of pow can't be negative)
    vec3 lmsA = pow( kCONEtoLMS*colA, vec3(1.0/3.0) );
    vec3 lmsB = pow( kCONEtoLMS*colB, vec3(1.0/3.0) );
    // lerp
    vec3 lms = mix( lmsA, lmsB, h );
    // gain in the middle (no oaklab anymore, but looks better?)
 // lms *= 1.0+0.2*h*(1.0-h);
    // cone to rgb
    return kLMStoCONE*(lms*lms*lms);
}

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

float snapf(float x, float amount) {
	return ceil(x / amount) * amount;
}

vec3 snap(vec3 v, vec3 amount) {
	return vec3(snapf(v.x, amount.x), snapf(v.y, amount.y), snapf(v.z, amount.z));
}