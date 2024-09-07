// NOTE: Shader automatically converted from Godot Engine 4.3.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D wet_tex_under : source_color, filter_linear_mipmap;
uniform sampler2D wet_tex_progress : source_color, filter_linear_mipmap;
uniform vec4 wet_color: source_color;
uniform float wet_progress : hint_range(0.0, 1.0, 0.01);

uniform sampler2D freeze_tex_under : source_color, filter_linear_mipmap;
uniform sampler2D freeze_tex_progress : source_color, filter_linear_mipmap;
uniform vec4 freeze_color: source_color;
uniform float freeze_progress : hint_range(0.0, 1.0, 0.01);

uniform sampler2D burning_tex_under : source_color, filter_linear_mipmap;
uniform sampler2D burning_tex_progress : source_color, filter_linear_mipmap;
uniform vec4 burning_color: source_color;
uniform float burning_progress : hint_range(0.0, 1.0, 0.01);


void vertex() {
	// Billboard Mode: Y-Billboard
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			vec4(normalize(cross(vec3(0.0, 1.0, 0.0), MAIN_CAM_INV_VIEW_MATRIX[2].xyz)), 0.0),
			vec4(0.0, 1.0, 0.0, 0.0),
			vec4(normalize(cross(MAIN_CAM_INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
			MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

vec4 progress_bar(vec2 uv, sampler2D base, sampler2D over, float progress, vec4 highlight) {
	uv.x *= 3.0;
	vec4 tex = vec4(0);
	if (progress <= 0.0) {
		highlight.a = 0.0;
	} else if (uv.y > (1.0 - progress)) {
		tex = texture(over, uv);
	} else {
		highlight = vec4(1);
		tex = texture(base, uv);
	}
	return vec4(highlight.rgb * tex.rgb, tex.a * highlight.a);
}

void fragment() {
	vec2 uv = UV;
	if (uv.x < 0.33) {
		vec4 color = progress_bar(UV, wet_tex_under, wet_tex_progress, wet_progress, wet_color);
		ALBEDO = color.rgb;
		ALPHA = color.a;
	} else if (uv.x < 0.66) {
		vec4 color = progress_bar(UV, freeze_tex_under, freeze_tex_progress, freeze_progress, freeze_color);
		ALBEDO = color.rgb;
		ALPHA = color.a;
	} else {
		vec4 color = progress_bar(UV, burning_tex_under, burning_tex_progress, burning_progress, burning_color);
		ALBEDO = color.rgb;
		ALPHA = color.a;
	}
}
