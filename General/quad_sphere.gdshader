// NOTE: Shader automatically converted from Godot Engine 4.0.3.stable's StandardMaterial3D.

shader_type spatial;
#include "basic.gdshaderinc"
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_toon,specular_schlick_ggx,vertex_lighting,shadows_disabled;
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

uniform float sph_size : hint_range(0.01, 1.0, 0.001) = 0.02;

varying vec3 spos;
varying vec3 roc;
varying float sp_size;

#define CAMERA_MATRIX INV_VIEW_MATRIX
#define INV_CAMERA_MATRIX VIEW_MATRIX
#define WORLD_MATRIX MODEL_MATRIX


void vertex() {
	//MODELVIEW_MATRIX = INV_CAMERA_MATRIX * mat4(CAMERA_MATRIX[0],CAMERA_MATRIX[1],CAMERA_MATRIX[2],WORLD_MATRIX[3]);

	mat4 mat_world = mat4(normalize(CAMERA_MATRIX[0])*length(WORLD_MATRIX[0]),normalize(CAMERA_MATRIX[1])*length(WORLD_MATRIX[0]),normalize(CAMERA_MATRIX[2])*length(WORLD_MATRIX[2]),WORLD_MATRIX[3]);

	MODELVIEW_MATRIX = INV_CAMERA_MATRIX * mat_world;
	spos=mat_world[3].xyz;
	sp_size=2./max(length(WORLD_MATRIX[0].xyz),0.0001);
	roc=CAMERA_MATRIX[3].xyz*sp_size;

	ROUGHNESS=roughness;
	UV=UV*uv1_scale.xy+uv1_offset.xy;
}

// The MIT License
// Copyright © 2014 Inigo Quilez
// https://iquilezles.org/www/articles/intersectors/intersectors.htm
float sphIntersect(in vec3 ro, in vec3 rd, in vec4 sph) {
	vec3 oc = ro - sph.xyz;
	float b = dot( oc, rd );
	float c = dot( oc, oc ) - sph.w*sph.w;
	float h = b*b - c;
	if( h<0.0 ) return -1.0;
	return -b - sqrt( h );
}

vec3 sphNormal( in vec3 pos, in vec4 sph ) {
	vec3 V = normalize(pos-sph.xyz);
    return snap(V, vec3(0.5));
}

vec4 sph_img(vec3 rd, vec3 lght, vec3 ro, vec3 sp, float sp_sz, vec3 bcol) {
    vec4 sph = vec4(sp, sp_sz);
    vec3 lig = lght;
    vec3 col = vec3(0.0);

    float tmin = 1e10;
    vec3 nor = vec3(0.0);
    float occ = 1.0;

	float a = 0.0;

    float t2 = sphIntersect( ro, rd, sph );
	t2 = max(t2,0.001); //to fix black color
    if (t2 > 0.002 && t2 < tmin) {
        tmin = t2;
        vec3 pos = ro + t2*rd;
        nor = sphNormal(pos, sph);
        occ = 0.5 + 0.5 * nor.y;
	}

    if (tmin < 1000.0) {
        vec3 pos = ro + tmin*rd;
		col = vec3(1.0);
		a = 1.0;
		float shade_value = 0.0;
		shade_value = clamp(dot(nor, lig), 0.0, 1.0); //base shadow
		col = mix(vec3(0.0), bcol, shade_value);
    }
    col = sqrt(col);
    return vec4(col, a);
}

void light() {
	vec3 rd = normalize(((CAMERA_MATRIX) * vec4(normalize(-VIEW), 0.0)).xyz);
	vec3 lgt = normalize(((CAMERA_MATRIX) * vec4(normalize(LIGHT), 0.0)).xyz);
	vec4 col = vec4(0.);
	vec3 lc = LIGHT_COLOR*0.1;
	col = sph_img(normalize(rd), normalize(lgt), roc, spos * sp_size, sph_size, lc); //no fix
	SPECULAR_LIGHT += col.rgb * ATTENUATION * ALBEDO;
	DIFFUSE_LIGHT += col.rgb * ATTENUATION * ALBEDO;
	ALPHA = col.w;
}

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	albedo_tex *= COLOR;

	vec3 temp_color = rgb2hsv(albedo.rgb * albedo_tex.rgb);
	temp_color.b = 1.0 - pow(1.0 - temp_color.b, 2.0);
	ALBEDO = hsv2rgb(temp_color);

	ALPHA *= albedo.a * albedo_tex.a;
	float metallic_tex = dot(texture(texture_metallic,base_uv),metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	vec4 roughness_texture_channel = vec4(1.0,0.0,0.0,0.0);
	float roughness_tex = dot(texture(texture_roughness,base_uv),roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	SPECULAR = specular;
	//NORMAL = -normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
}
