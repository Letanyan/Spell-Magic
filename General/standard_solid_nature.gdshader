// NOTE: Shader automatically converted from Godot Engine 4.0.3.stable's StandardMaterial3D.

shader_type spatial;
#include "basic.gdshaderinc"
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_toon,specular_schlick_ggx,vertex_lighting;
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
uniform float green_amount: hint_range(0.0, 1.0, 0.05) = 0.0;

uniform float wind_speed_multiplier = 0.0;
uniform vec3 wind_speed_strength = vec3(0.0, 0.0, 0.0);
// we need a tiling noise here!
uniform sampler2D wind_noise : hint_default_black;
uniform sampler2D wind_speed_change : hint_default_white;
uniform bool invert_wind_effect = false;

//varying vec4 instance_custom;

void vertex() {
	ROUGHNESS=roughness;
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	//instance_custom = INSTANCE_CUSTOM;

	float wind_speed = texture(wind_speed_change, vec2(0.5, TIME * wind_speed_multiplier)).r;
	vec2 wind_dir = vec2(
		texture(wind_noise, vec2(TIME * wind_speed * 0.1, 0.5)).r * 2.0 - 1.0,
		texture(wind_noise, vec2(0.5, TIME * wind_speed * 0.1)).r * 2.0 - 1.0
	);
	float displacement_effect = pow(1.0 - VERTEX.y, 3.0);
	if (invert_wind_effect) {
		displacement_effect = 1.0 - VERTEX.y;
	}

	VERTEX.x += wind_dir.x * 1.0 * wind_speed * displacement_effect * wind_speed_strength.x;
	VERTEX.y += wind_dir.y * 1.0 * wind_speed * displacement_effect * wind_speed_strength.y;
	VERTEX.z += wind_dir.y * 1.0 * wind_speed * displacement_effect * wind_speed_strength.z;
}

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = albedo;//texture(texture_albedo,base_uv);
	//albedo_tex *= albedo;
	albedo_tex = mix(albedo_tex, mix(vec4(COLOR.rgb, 1.0), albedo, 1.0 - green_amount), 0.9);
	//albedo_tex = mix(albedo_tex, vec4(COLOR.rgb, 1.0), 0.9);

	vec3 temp_color = rgb2hsv(albedo_tex.rgb);
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
