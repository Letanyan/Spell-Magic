// NOTE: Shader automatically converted from Godot Engine 4.0.3.stable's StandardMaterial3D.

shader_type spatial;
#include "basic.gdshaderinc"
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx,vertex_lighting;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color,filter_linear_mipmap,repeat_enable;
uniform float point_size : hint_range(0,128);
uniform float roughness : hint_range(0,1);
uniform sampler2D texture_metallic : hint_default_white,filter_linear_mipmap,repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r,filter_linear_mipmap,repeat_enable;
uniform sampler2D texture_normal : hint_roughness_normal,filter_linear_mipmap,repeat_enable;
uniform float normal_scale : hint_range(-16,16);
uniform float specular;
uniform float metallic;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

uniform vec3 nature_mat_green_blend: source_color = vec3(1);
uniform vec3 nature_mat_brown_blend: source_color = vec3(1);


void vertex() {
	ROUGHNESS=roughness;
	UV=UV*uv1_scale.xy+uv1_offset.xy;
}

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	if (base_uv.y > 0.125 && base_uv.y < 0.125 + 0.0625) {
		albedo_tex = mix(albedo_tex, vec4(nature_mat_green_blend, 1), 0.9);
	}
	if (base_uv.y < 0.0625) {
		albedo_tex = mix(albedo_tex, vec4(nature_mat_brown_blend, 1), 0.9);
	}
	albedo_tex *= COLOR;

	vec3 temp_color = rgb2hsv(albedo.rgb * albedo_tex.rgb);
	temp_color.b = 1.0 - pow(1.0 - temp_color.b, 2.0);
	ALBEDO = hsv2rgb(temp_color);

	float metallic_tex = dot(texture(texture_metallic,base_uv),metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	vec4 roughness_texture_channel = vec4(1.0,0.0,0.0,0.0);
	float roughness_tex = dot(texture(texture_roughness,base_uv),roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	SPECULAR = specular;
	if (abs(normal_scale - 0.0) < 0.0001) {
		NORMAL_MAP = texture(texture_normal,base_uv).rgb;
		NORMAL_MAP_DEPTH = normal_scale;
	}
	NORMAL = -normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
}
