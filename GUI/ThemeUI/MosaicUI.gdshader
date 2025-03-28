shader_type canvas_item;

vec2 random(vec2 uv) {
	return vec2(fract(sin(dot(uv.xy,
		vec2(12.98,78.23))) * 43758.54));
}

vec2 voronoi(vec2 uv, float columns, float rows) {
	vec2 index_uv = floor(vec2(uv.x * columns, uv.y * rows));
	vec2 fract_uv = fract(vec2(uv.x * columns, uv.y * rows));
	
	float minimum_dist = 1000.0;  
	vec2 minimum_point;

	for (float y= -1.0; y <= 1.0; y++) {
		for (float x= -1.0; x <= 1.0; x++) {
			vec2 neighbor = vec2(float(x),float(y));
			vec2 point = random(index_uv + neighbor);
			float speed = 0.5;
			point = vec2( cos(TIME * point.x * 0.01), sin(TIME * point.y * 0.05) ) * 0.5 + 0.5;

			vec2 diff = neighbor + point - fract_uv;
			float dist = length(diff);
			if(dist < minimum_dist) {
				minimum_dist = dist;
				minimum_point = point;
			}
		}
	}
	return minimum_point;
}
void fragment() {
	vec3 voronoi = vec3(voronoi(UV, 10.0, 5.0).r);
	COLOR.rgb = texture(TEXTURE, voronoi.xy).rgb;
	COLOR.a = 1.0 - clamp(voronoi.x, 0.0, 0.1);
}
