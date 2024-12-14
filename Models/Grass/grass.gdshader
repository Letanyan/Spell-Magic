// NOTE: Shader automatically converted from Godot Engine 4.0.2.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx,shadows_disabled;
uniform vec4 albedo : source_color;
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

uniform float wind_speed_multiplier = 0.2;
uniform float wind_strength = 0.2;
// How big, in world space, is the noise texture
// wind will tile every wind_texture_tile_size
uniform float wind_texture_tile_size = 20.0;
uniform float wind_vertical_strength = 0.0;
uniform sampler2D wind_horizontal_direction : hint_default_black;

uniform sampler2D color_ramp : hint_default_black;
// we need a tiling noise here!
uniform sampler2D wind_noise : hint_default_black;
uniform sampler2D wind_speed_change : hint_default_white;

uniform vec3 character_position;
uniform float character_radius = 3.0;
uniform sampler2D character_distance_falloff_curve : hint_default_black;
uniform float character_push_strength = 1.0;

varying float debug_wind;

varying vec4 instance_custom;

global uniform float tick_time_s;

void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	instance_custom = INSTANCE_CUSTOM;

	vec4 world_coord = INV_VIEW_MATRIX * vec4(VERTEX, 0);

	float wind_speed = texture(wind_speed_change, vec2(0.5, TIME * wind_speed_multiplier)).r;
	vec2 wind_dir = vec2(
		texture(wind_horizontal_direction, vec2(TIME * wind_speed * 0.1, 0.5 + instance_custom.a)).r * 2.0 - 1.0,
		texture(wind_horizontal_direction, vec2(0.5 + instance_custom.a, TIME * wind_speed * 0.1)).r * 2.0 - 1.0
	);
	vec2 normalized_wind_direction = wind_dir; // normalize(wind_dir);
	float displacement_affect = pow(1.0 - UV.y, 3.0);

	VERTEX.x += normalized_wind_direction.x * 0.001 * displacement_affect * wind_speed;
	VERTEX.z += normalized_wind_direction.y * 0.001 * displacement_affect * wind_speed;
	
	//COLOR.a = 1.0;

	/*
	// At the moment the blades are pushed away in a perfectly circular manner.
	// We could distort the distance to the character based on a noise, to break a bit the
	// circular shape. We could distort the falloff by sampling in a noise based on the xz coordinates.
	// The task is left to the reader

	vec3 dir_to_character = character_position - (VIEW_MATRIX[3].xyz);
	// uncomment the following line to have a horizontal only character push
	dir_to_character.y = 0.0;
	float distance_to_character = length(dir_to_character);
	float falloff = 1.0 - smoothstep(0.0, 1.0, distance_to_character/character_radius);
	 //Because we operate in vertex space, we need to convert the direction to the character
	// in vertex space. Otherwise, it wouldn't work for rotated blades of grass.
	// comment the next line to observe how the blades are not all facing away from the character.
	dir_to_character = (inverse(VIEW_MATRIX) * vec4(dir_to_character, 0.0)).xyz;
	dir_to_character = normalize(dir_to_character);

	// sample the curve based on how far we are from the character, in normalized coordinates
	float falloff_curve = texture(character_distance_falloff_curve, vec2(falloff)).x;
	// direction to character is inverted because we want to point away from it
	VERTEX += normalize(-dir_to_character) * falloff_curve * character_push_strength * displacement_affect;
	*/
}

void fragment() {
	vec2 base_uv = UV;
	vec3 albedo_tex = mix(instance_custom.rgb, instance_custom.rgb * 1.5, 1.0 - UV.y);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	//ALPHA = clamp(abs(COLOR.a - tick_time_s), 0.0, 1.0);
	float metallic_tex = dot(texture(texture_metallic,base_uv),metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	vec4 roughness_texture_channel = vec4(1.0,0.0,0.0,0.0);
	float roughness_tex = dot(texture(texture_roughness,base_uv),roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	SPECULAR = specular;
	NORMAL = -normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
}
