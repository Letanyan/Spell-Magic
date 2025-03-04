// NOTE: Shader automatically converted from Godot Engine 4.0.3.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_toon,specular_schlick_ggx,unshaded;
uniform vec4 foreground : source_color;
uniform vec4 background : source_color;
uniform float percentage = 1.0;
uniform vec2 corner_radius = vec2(0.01, 0.1);
uniform vec2 outline_size = vec2(0.01, 0.1);
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform sampler2D color_transitions : source_color;
uniform bool billboard = true;

uniform sampler2D texture_albedo : source_color,filter_linear_mipmap,repeat_enable;
uniform float point_size : hint_range(0,128);
uniform float roughness : hint_range(0,1);
uniform sampler2D texture_metallic : hint_default_white,filter_linear_mipmap,repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r,filter_linear_mipmap,repeat_enable;
uniform float specular;
uniform float metallic;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;


void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	if (billboard) {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
				MAIN_CAM_INV_VIEW_MATRIX[0],
				MAIN_CAM_INV_VIEW_MATRIX[1],
				MAIN_CAM_INV_VIEW_MATRIX[2],
				MODEL_MATRIX[3]);
		MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);

		// Y-Billboard
		//MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), MODEL_MATRIX[3]);
		//MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	}
}

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	vec4 color_at_percentage = texture(color_transitions, vec2(clamp(percentage, 0.01, 0.99), 0.0));

	float x = UV.x;
	float y = UV.y;

	vec2 top_left = vec2(corner_radius.x, corner_radius.y);
	vec2 top_right = vec2(1.0 - corner_radius.x, corner_radius.y);
	vec2 bottom_left = vec2(corner_radius.x, 1.0 - corner_radius.y);
	vec2 bottom_right = vec2(1.0 - corner_radius.x, 1.0 - corner_radius.y);

	float hide_corner = 1.0;
	bool should_outline_corner = false;
	float distance_to_corner = 0.0;
	float distance_to_outline_corner = 0.0;
	if (0.0 <= x && x < top_left.x && 0.0 <= y && y < top_left.y) {
		distance_to_corner = pow(x - top_left.x, 2.0) / pow(corner_radius.x, 2.0) + pow(y - top_left.y, 2.0) / pow(corner_radius.y, 2.0);
		distance_to_outline_corner = pow(x - top_left.x, 2.0) / pow(corner_radius.x - outline_size.x, 2.0) + pow(y - top_left.y, 2.0) / pow(corner_radius.y - outline_size.y, 2.0);
	} else if (top_right.x <= x && x < 1.0 && 0.0 <= y && y < top_right.y) {
		distance_to_corner = pow(x - top_right.x, 2.0) / pow(corner_radius.x, 2.0) + pow(y - top_right.y, 2.0) / pow(corner_radius.y, 2.0);
		distance_to_outline_corner = pow(x - top_right.x, 2.0) / pow(corner_radius.x - outline_size.x, 2.0) + pow(y - top_right.y, 2.0) / pow(corner_radius.y - outline_size.y, 2.0);
	} else if (0.0 <= x && x < bottom_left.x && bottom_left.y < y && y <= 1.0) {
		distance_to_corner = pow(x - bottom_left.x, 2.0) / pow(corner_radius.x, 2.0) + pow(y - bottom_left.y, 2.0) / pow(corner_radius.y, 2.0);
		distance_to_outline_corner = pow(x - bottom_left.x, 2.0) / pow(corner_radius.x - outline_size.x, 2.0) + pow(y - bottom_left.y, 2.0) / pow(corner_radius.y - outline_size.y, 2.0);
	} else if (bottom_right.x <= x && x < 1.0 && bottom_right.y < y && y <= 1.0) {
		distance_to_corner = pow(x - bottom_right.x, 2.0) / pow(corner_radius.x, 2.0) + pow(y - bottom_right.y, 2.0) / pow(corner_radius.y, 2.0);
		distance_to_outline_corner = pow(x - bottom_right.x, 2.0) / pow(corner_radius.x - outline_size.x, 2.0) + pow(y - bottom_right.y, 2.0) / pow(corner_radius.y - outline_size.y, 2.0);
	}
	if (length(distance_to_corner) > 0.0) {
		hide_corner = distance_to_corner <= 1.0 ? 1.0 : 0.0;
		should_outline_corner = distance_to_corner <= 1.0 && distance_to_outline_corner >= 1.0;
	}


	if (should_outline_corner || x < outline_size.x || x > 1.0 - outline_size.x || y < outline_size.y || y > 1.0 - outline_size.y) {
		ALBEDO = outline_color.rgb;
		ALPHA = outline_color.a * hide_corner;
	} else if (UV.x < percentage) {
		ALBEDO = foreground.rgb * albedo_tex.rgb * color_at_percentage.rgb;
		ALPHA = foreground.a * albedo_tex.a * color_at_percentage.a * hide_corner;
	} else {
		ALBEDO = background.rgb * albedo_tex.rgb;
		ALPHA = background.a * hide_corner;
	}
	float metallic_tex = dot(texture(texture_metallic,base_uv),metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	vec4 roughness_texture_channel = vec4(1.0,0.0,0.0,0.0);
	float roughness_tex = dot(texture(texture_roughness,base_uv),roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	SPECULAR = specular;
}
