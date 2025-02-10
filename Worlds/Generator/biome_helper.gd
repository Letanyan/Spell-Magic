class_name BiomeHelper

enum SkyColorKind { DAY_TOP, DAY_BOTTOM, SUNSET_TOP, SUNSET_BOTTOM, NIGHT_TOP, NIGHT_BOTTOM }

func color_for_biome(_biome: World.Biome) -> Color:
	match _biome:
		World.Biome.WATER: return Color(0.2, 0.5, 1)
		World.Biome.TAIGA: return Color(0, 1, 1)
		World.Biome.GRASSLAND: return Color(0, 1, 0)
		World.Biome.FOREST: return Color(0, 0.5, 0.5)
		World.Biome.DESERT: return Color(1, 1, 0)
		World.Biome.JUNGLE: return Color(0, 0.25, 0.25)
		World.Biome.SAVANNAH: return Color(1, 0.5, 0)
		World.Biome.TUNDRA: return Color(1, 1, 1)
		World.Biome.OTHERWORLD: return Color(0, 0, 0)
		World.Biome.HFIL: return Color(1, 0, 0)
		_: return Color(1, 0, 1)
		
func real_color_for_biome(_biome: World.Biome) -> Color:
	var vec := NoiseBlender.biome_colors[_biome as int - 1]
	return Color(vec.x, vec.y, vec.z)

func update_for_world_environment(result: Dictionary, env: WorldEnvironment, sun: DirectionalLight3D, moon: DirectionalLight3D, level: float, b: World.Biome, day_time: float) -> void:	
	result["*fog_density"] = 0.0
	result["*fog_sky_affect"] = 0.0
	result["*fog_light_color"] = Color.GRAY
	result["*ambient_light_color"] = environment_ambient_color(b, day_time, sun, moon)
	match b:
		World.Biome.GRASSLAND:
			result["day_top_color"] = Color(0.1, 0.6, 1, 1)
			result["day_bottom_color"] = Color(0.43, 1, 0.8195, 1)
			result["sunset_top_color"] = Color(0.7085, 0.47, 1, 1)
			result["sunset_bottom_color"] = Color(1, 0.3667, 0.24, 1)
			result["night_top_color"] = Color(0.02, 0, 0.039, 1)
			result["night_bottom_color"] = Color(0.0819, 0.2411, 0.39, 1)
			result["horizon_color"] = Color(0, 0.702, 0.8, 1)
			result["horizon_blur"] = 0.05
			result["clouds_edge_color"] = Color(0.941, 0.961, 1, 1)
			result["clouds_top_color"] = Color(1, 1, 1, 1)
			result["clouds_middle_color"] = Color(0.922, 0.922, 0.98, 1)
			result["clouds_bottom_color"] = Color(0.831, 0.831, 0.941, 1)
			result["clouds_speed"] = 1.0
			result["clouds_scale"] = 2.2
			result["clouds_cutoff"] = 0.6
			result["clouds_weight"] = 0.0
			result["clouds_blur"] = 0.27
		World.Biome.FOREST:
			result["day_top_color"] = Color(0, 0.3725, 1, 1)
			result["day_bottom_color"] = Color(0.4627, 1, 0.4275, 1)
			result["sunset_top_color"] = Color(0.702, 0.749, 1, 1)
			result["sunset_bottom_color"] = Color(1, 0.9176, 0.2353, 1)
			result["night_top_color"] = Color(0.02, 0, 0.04, 1)
			result["night_bottom_color"] = Color(0.102, 0.4824, 0.2, 1)
			result["horizon_color"] = Color(0, 0.7, 0.8, 1)
			result["horizon_blur"] = 0.05000000074506
			result["clouds_edge_color"] = Color(0.8, 0.8, 0.98, 1)
			result["clouds_top_color"] = Color(1, 1, 1, 1)
			result["clouds_middle_color"] = Color(0.92, 0.92, 0.98, 1)
			result["clouds_bottom_color"] = Color(0.83, 0.83, 0.94, 1)
			result["clouds_speed"] = 1.0
			result["clouds_scale"] = 2.2
			result["clouds_cutoff"] = 0.3
			result["clouds_weight"] = 0.0
			result["clouds_blur"] = 0.25
		World.Biome.TAIGA:
			result["day_top_color"] = Color(0.05, 0, 1, 1)
			result["day_bottom_color"] = Color(0, 0.8367, 0.9796, 1)
			result["sunset_top_color"] = Color(0.66, 0.9377, 1, 1)
			result["sunset_bottom_color"] = Color(1, 0.35, 0.5992, 1)
			result["night_top_color"] = Color(0.02, 0, 0.04, 1)
			result["night_bottom_color"] = Color(0.1034, 0.1636, 0.22, 1)
			result["horizon_color"] = Color(0, 0.7, 0.8, 1)
			result["horizon_blur"] = 0.05000000074506
			result["clouds_edge_color"] = Color(0.8, 0.8, 0.98, 1)
			result["clouds_top_color"] = Color(1, 1, 1, 1)
			result["clouds_middle_color"] = Color(0.92, 0.92, 0.98, 1)
			result["clouds_bottom_color"] = Color(0.83, 0.83, 0.94, 1)
			result["clouds_speed"] = 0.999999977648
			result["clouds_scale"] = 2.27999994903744
			result["clouds_cutoff"] = 0.43999999016512
			result["clouds_weight"] = 0.0
			result["clouds_blur"] = 0.78999998234192
		World.Biome.JUNGLE:
			result["day_top_color"] = Color(0, 0.53, 0.1943, 1)
			result["day_bottom_color"] = Color(0, 0.63, 0.567, 1)
			result["sunset_top_color"] = Color(0.5553, 0.42, 1, 1)
			result["sunset_bottom_color"] = Color(0.368, 0.48, 0, 1)
			result["night_top_color"] = Color(0.02, 0, 0.04, 1)
			result["night_bottom_color"] = Color(0.1269, 0.27, 0.2175, 1)
			result["horizon_color"] = Color(0, 0.7, 0.8, 1)
			result["horizon_blur"] = 0.05000000074506
			result["clouds_edge_color"] = Color(0.8, 0.8, 0.98, 1)
			result["clouds_top_color"] = Color(1, 1, 1, 1)
			result["clouds_middle_color"] = Color(0.92, 0.92, 0.98, 1)
			result["clouds_bottom_color"] = Color(0.83, 0.83, 0.94, 1)
			result["clouds_speed"] = 0.999999977648
			result["clouds_scale"] = 2.27999994903744
			result["clouds_cutoff"] = 0.43999999016512
			result["clouds_weight"] = 0.3999999910592
			result["clouds_blur"] = 0.0
		World.Biome.DESERT:
			result["day_top_color"] = Color(0, 0.4833, 1, 1)
			result["day_bottom_color"] = Color(0, 0.9333, 1, 1)
			result["sunset_top_color"] = Color(0.3667, 0, 1, 1)
			result["sunset_bottom_color"] = Color(1, 0.7, 0, 1)
			result["night_top_color"] = Color(0, 0.136, 0.34, 1)
			result["night_bottom_color"] = Color(0.2162, 0.4031, 0.46, 1)
			result["horizon_color"] = Color(0, 0.7, 0.8, 1)
			result["horizon_blur"] = 0.05000000074506
			result["clouds_edge_color"] = Color(0.8, 0.8, 0.98, 1)
			result["clouds_top_color"] = Color(1, 1, 1, 1)
			result["clouds_middle_color"] = Color(0.92, 0.92, 0.98, 1)
			result["clouds_bottom_color"] = Color(0.83, 0.83, 0.94, 1)
			result["clouds_speed"] = 0.73999998345952
			result["clouds_scale"] = 3.999999910592
			result["clouds_cutoff"] = 0.15999999642368
			result["clouds_weight"] = 0.0
			result["clouds_blur"] = 0.999999977648
		World.Biome.SAVANNAH:
			result["day_top_color"] = Color(0.27, 0.562, 1, 1)
			result["day_bottom_color"] = Color(0.81, 0.9683, 1, 1)
			result["sunset_top_color"] = Color(1, 0.35, 0, 1)
			result["sunset_bottom_color"] = Color(1, 0.55, 0, 1)
			result["night_top_color"] = Color(0, 0.216, 0.54, 1)
			result["night_bottom_color"] = Color(0, 0, 0, 1)
			result["horizon_color"] = Color(0, 0.7, 0.8, 1)
			result["horizon_blur"] = 0.05
			result["clouds_edge_color"] = Color(0.8, 0.8, 0.98, 1)
			result["clouds_top_color"] = Color(1, 1, 1, 1)
			result["clouds_middle_color"] = Color(0.92, 0.92, 0.98, 1)
			result["clouds_bottom_color"] = Color(0.83, 0.83, 0.94, 1)
			result["clouds_speed"] = 2.0499999541784
			result["clouds_scale"] = 1.30999997071888
			result["clouds_cutoff"] = 0.6999999843536
			result["clouds_weight"] = 0.0
			result["clouds_blur"] = 0.0
		World.Biome.TUNDRA:
			result["day_top_color"] = Color(0.51, 0.706, 1, 1)
			result["day_bottom_color"] = Color(1, 1, 1, 1)
			result["sunset_top_color"] = Color(0.7958, 0.51, 1, 1)
			result["sunset_bottom_color"] = Color(1, 0.7795, 0.51, 1)
			result["night_top_color"] = Color(0, 0.12, 0.3, 1)
			result["night_bottom_color"] = Color(0.2444, 0.4557, 0.52, 1)
			result["horizon_color"] = Color(0, 0.7, 0.8, 1)
			result["horizon_blur"] = 0.05
			result["clouds_edge_color"] = Color(0.8, 0.8, 0.98, 1)
			result["clouds_top_color"] = Color(1, 1, 1, 1)
			result["clouds_middle_color"] = Color(0.92, 0.92, 0.98, 1)
			result["clouds_bottom_color"] = Color(0.83, 0.83, 0.94, 1)
			result["clouds_speed"] = 5.86999986879376
			result["clouds_scale"] = 3.999999910592
			result["clouds_cutoff"] = 0.6499999854712
			result["clouds_weight"] = 0.0
			result["clouds_blur"] = 0.0
			
			result["*fog_density"] = lerpf(0.0, 0.1, level / 100.0)
			result["*fog_sky_affect"] = lerpf(0.1, 0.75, level / 100.0)
			result["*fog_light_color"] = Color.WHITE
		World.Biome.OTHERWORLD:
			result["day_top_color"] = Color(0, 1, 1, 1)
			result["day_bottom_color"] = Color(0, 0.0167, 1, 1)
			result["sunset_top_color"] = Color(0, 0, 1, 1)
			result["sunset_bottom_color"] = Color(1, 0, 1, 1)
			result["night_top_color"] = Color(0, 0, 1, 1)
			result["night_bottom_color"] = Color(0, 0, 0, 1)
			result["horizon_color"] = Color(0, 0.7, 0.8, 1)
			result["horizon_blur"] = 0.05
			result["clouds_edge_color"] = Color(0.8, 0.8, 0.98, 1)
			result["clouds_top_color"] = Color(1, 1, 1, 1)
			result["clouds_middle_color"] = Color(0.92, 0.92, 0.98, 1)
			result["clouds_bottom_color"] = Color(0.83, 0.83, 0.94, 1)
			result["clouds_speed"] = 19.99999955296
			result["clouds_scale"] = 0.43999999016512
			result["clouds_cutoff"] = 0.31999999284736
			result["clouds_weight"] = 0.0
			result["clouds_blur"] = 0.999999977648
		World.Biome.HFIL:
			result["day_top_color"] = Color(1, 0, 0, 1)
			result["day_bottom_color"] = Color(1, 0.0157, 1, 1)
			result["sunset_top_color"] = Color(1, 0, 1, 1)
			result["sunset_bottom_color"] = Color(1, 1, 0, 1)
			result["night_top_color"] = Color(1, 0, 0, 1)
			result["night_bottom_color"] = Color(0, 0, 0, 1)
			result["horizon_color"] = Color(0, 0.7, 0.8, 1)
			result["horizon_blur"] = 0.05
			result["clouds_edge_color"] = Color(0.8, 0.8, 0.98, 1)
			result["clouds_top_color"] = Color(1, 1, 1, 1)
			result["clouds_middle_color"] = Color(0.92, 0.92, 0.98, 1)
			result["clouds_bottom_color"] = Color(0.83, 0.83, 0.94, 1)
			result["clouds_speed"] = 0.0
			result["clouds_scale"] = 3.999999910592
			result["clouds_cutoff"] = 0.499999988824
			result["clouds_weight"] = 0.999999977648
			result["clouds_blur"] = 0.61999998614176

func sky_color(b: World.Biome, kind: SkyColorKind) -> Color:
	var result := Color(1, 1, 1)
	match b:
		World.Biome.GRASSLAND:
			if kind == SkyColorKind.DAY_TOP: result = Color(0.1, 0.6, 1, 1)
			if kind == SkyColorKind.DAY_BOTTOM: result = Color(0.43, 1, 0.8195, 1)
			if kind == SkyColorKind.SUNSET_TOP: result = Color(0.7085, 0.47, 1, 1)
			if kind == SkyColorKind.SUNSET_BOTTOM: result = Color(1, 0.3667, 0.24, 1)
			if kind == SkyColorKind.NIGHT_TOP: result = Color(0.02, 0, 0.039, 1)
			if kind == SkyColorKind.NIGHT_BOTTOM: result = Color(0.0819, 0.2411, 0.39, 1)
		World.Biome.FOREST:
			if kind == SkyColorKind.DAY_TOP: result = Color(0, 0.3725, 1, 1)
			if kind == SkyColorKind.DAY_BOTTOM: result = Color(0.4627, 1, 0.4275, 1)
			if kind == SkyColorKind.SUNSET_TOP: result = Color(0.702, 0.749, 1, 1)
			if kind == SkyColorKind.SUNSET_BOTTOM: result = Color(1, 0.9176, 0.2353, 1)
			if kind == SkyColorKind.NIGHT_TOP: result = Color(0.02, 0, 0.04, 1)
			if kind == SkyColorKind.NIGHT_BOTTOM: result = Color(0.102, 0.4824, 0.2, 1)
		World.Biome.TAIGA:
			if kind == SkyColorKind.DAY_TOP: result = Color(0.05, 0, 1, 1)
			if kind == SkyColorKind.DAY_BOTTOM: result = Color(0, 0.8367, 0.9796, 1)
			if kind == SkyColorKind.SUNSET_TOP: result = Color(0.66, 0.9377, 1, 1)
			if kind == SkyColorKind.SUNSET_BOTTOM: result = Color(1, 0.35, 0.5992, 1)
			if kind == SkyColorKind.NIGHT_TOP: result = Color(0.02, 0, 0.04, 1)
			if kind == SkyColorKind.NIGHT_BOTTOM: result = Color(0.1034, 0.1636, 0.22, 1)
		World.Biome.JUNGLE:
			if kind == SkyColorKind.DAY_TOP: result = Color(0, 0.53, 0.1943, 1)
			if kind == SkyColorKind.DAY_BOTTOM: result = Color(0, 0.63, 0.567, 1)
			if kind == SkyColorKind.SUNSET_TOP: result = Color(0.5553, 0.42, 1, 1)
			if kind == SkyColorKind.SUNSET_BOTTOM: result = Color(0.368, 0.48, 0, 1)
			if kind == SkyColorKind.NIGHT_TOP: result = Color(0.02, 0, 0.04, 1)
			if kind == SkyColorKind.NIGHT_BOTTOM: result = Color(0.1269, 0.27, 0.2175, 1)
		World.Biome.DESERT:
			if kind == SkyColorKind.DAY_TOP: result = Color(0, 0.4833, 1, 1)
			if kind == SkyColorKind.DAY_BOTTOM: result = Color(0, 0.9333, 1, 1)
			if kind == SkyColorKind.SUNSET_TOP: result = Color(0.3667, 0, 1, 1)
			if kind == SkyColorKind.SUNSET_BOTTOM: result = Color(1, 0.7, 0, 1)
			if kind == SkyColorKind.NIGHT_TOP: result = Color(0, 0.136, 0.34, 1)
			if kind == SkyColorKind.NIGHT_BOTTOM: result = Color(0.2162, 0.4031, 0.46, 1)
		World.Biome.SAVANNAH:
			if kind == SkyColorKind.DAY_TOP: result = Color(0.27, 0.562, 1, 1)
			if kind == SkyColorKind.DAY_BOTTOM: result = Color(0.81, 0.9683, 1, 1)
			if kind == SkyColorKind.SUNSET_TOP: result = Color(1, 0.35, 0, 1)
			if kind == SkyColorKind.SUNSET_BOTTOM: result = Color(1, 0.55, 0, 1)
			if kind == SkyColorKind.NIGHT_TOP: result = Color(0, 0.216, 0.54, 1)
			if kind == SkyColorKind.NIGHT_BOTTOM: result = Color(0, 0, 0, 1)
		World.Biome.TUNDRA:
			if kind == SkyColorKind.DAY_TOP: result = Color(0.51, 0.706, 1, 1)
			if kind == SkyColorKind.DAY_BOTTOM: result = Color(1, 1, 1, 1)
			if kind == SkyColorKind.SUNSET_TOP: result = Color(0.7958, 0.51, 1, 1)
			if kind == SkyColorKind.SUNSET_BOTTOM: result = Color(1, 0.7795, 0.51, 1)
			if kind == SkyColorKind.NIGHT_TOP: result = Color(0, 0.12, 0.3, 1)
			if kind == SkyColorKind.NIGHT_BOTTOM: result = Color(0.2444, 0.4557, 0.52, 1)
		World.Biome.OTHERWORLD:
			if kind == SkyColorKind.DAY_TOP: result = Color(0, 1, 1, 1)
			if kind == SkyColorKind.DAY_BOTTOM: result = Color(0, 0.0167, 1, 1)
			if kind == SkyColorKind.SUNSET_TOP: result = Color(0, 0, 1, 1)
			if kind == SkyColorKind.SUNSET_BOTTOM: result = Color(1, 0, 1, 1)
			if kind == SkyColorKind.NIGHT_TOP: result = Color(0, 0, 1, 1)
			if kind == SkyColorKind.NIGHT_BOTTOM: result = Color(0, 0, 0, 1)
		World.Biome.HFIL:
			if kind == SkyColorKind.DAY_TOP: result = Color(1, 0, 0, 1)
			if kind == SkyColorKind.DAY_BOTTOM: result = Color(1, 0.0157, 1, 1)
			if kind == SkyColorKind.SUNSET_TOP: result = Color(1, 0, 1, 1)
			if kind == SkyColorKind.SUNSET_BOTTOM: result = Color(1, 1, 0, 1)
			if kind == SkyColorKind.NIGHT_TOP: result = Color(1, 0, 0, 1)
			if kind == SkyColorKind.NIGHT_BOTTOM: result = Color(0, 0, 0, 1)
	return result
			
func environment_ambient_color(b: World.Biome, time_of_day: float, sun: DirectionalLight3D, moon: DirectionalLight3D) -> Color:
	var daylight := Color(1, 1, 1)
	var sun_direction := sun.to_global( Vector3( 0.0, 0.0, 1.0 )).normalized()
	var sunset_amount := clampf( 0.5 - absf( sun_direction.y ), 0.0, 0.5 ) * 2.0
	daylight = daylight.lerp(Color(0.8, 0.8, 0.8), sunset_amount)
	var night_amount := clampf( -sun_direction.y + 0.7, 0.0, 1.0 )
	daylight = daylight.lerp(Color(0.1, 0.1, 0.1), night_amount)
	
	var day_top_color := sky_color(b, SkyColorKind.DAY_TOP)
	var day_bottom_color := sky_color(b, SkyColorKind.DAY_BOTTOM)
	var sunset_top_color := sky_color(b, SkyColorKind.SUNSET_TOP)
	var sunset_bottom_color := sky_color(b, SkyColorKind.SUNSET_BOTTOM)
	var night_top_color := sky_color(b, SkyColorKind.NIGHT_TOP)
	var night_bottom_color := sky_color(b, SkyColorKind.NIGHT_BOTTOM)
	
	var _eyedir := 0.5
	var _sky_color := day_bottom_color.lerp(day_top_color, _eyedir)
	var _sky_sunset_color := sunset_bottom_color.lerp(sunset_top_color, _eyedir + 0.5)
	_sky_sunset_color = _sky_sunset_color.lerp(sunset_bottom_color, sunset_amount)
	_sky_color = _sky_color.lerp(_sky_sunset_color, sunset_amount)
	var _sky_night_color := night_bottom_color.lerp(night_top_color, _eyedir)
	_sky_color = _sky_color.lerp(_sky_night_color, night_amount)
	
	return _sky_color.lerp(daylight, 0.75)
			
func print_world_environment(env: WorldEnvironment, sun: DirectionalLight3D, moon: DirectionalLight3D) -> void:
	var shader := env.environment.sky.sky_material as ShaderMaterial
	print("shader.set_shader_parameter(prefix + \"day_top_color\", Color", shader.get_shader_parameter("start_day_top_color"), ")")
	print("shader.set_shader_parameter(prefix + \"day_bottom_color\", Color", shader.get_shader_parameter("start_day_bottom_color"), ")")
	print("shader.set_shader_parameter(prefix + \"sunset_top_color\", Color", shader.get_shader_parameter("start_sunset_top_color"), ")")
	print("shader.set_shader_parameter(prefix + \"sunset_bottom_color\", Color", shader.get_shader_parameter("start_sunset_bottom_color"), ")")
	print("shader.set_shader_parameter(prefix + \"night_top_color\", Color", shader.get_shader_parameter("start_night_top_color"), ")")
	print("shader.set_shader_parameter(prefix + \"night_bottom_color\", Color", shader.get_shader_parameter("start_night_bottom_color"), ")")
	print("shader.set_shader_parameter(prefix + \"horizon_color\", Color", shader.get_shader_parameter("start_horizon_color"), ")")
	print("shader.set_shader_parameter(prefix + \"horizon_blur\", ", shader.get_shader_parameter("start_horizon_blur"), ")")
	print("shader.set_shader_parameter(prefix + \"clouds_edge_color\", Color", shader.get_shader_parameter("start_clouds_edge_color"), ")")
	print("shader.set_shader_parameter(prefix + \"clouds_top_color\", Color", shader.get_shader_parameter("start_clouds_top_color"), ")")
	print("shader.set_shader_parameter(prefix + \"clouds_middle_color\", Color", shader.get_shader_parameter("start_clouds_middle_color"), ")")
	print("shader.set_shader_parameter(prefix + \"clouds_bottom_color\", Color", shader.get_shader_parameter("start_clouds_bottom_color"), ")")
	print("shader.set_shader_parameter(prefix + \"clouds_speed\", ", shader.get_shader_parameter("start_clouds_speed"), ")")
	print("shader.set_shader_parameter(prefix + \"clouds_scale\", ", shader.get_shader_parameter("start_clouds_scale"), ")")
	print("shader.set_shader_parameter(prefix + \"clouds_cutoff\", ", shader.get_shader_parameter("start_clouds_cutoff"), ")")
	print("shader.set_shader_parameter(prefix + \"clouds_weight\", ", shader.get_shader_parameter("start_clouds_weight"), ")")
	print("shader.set_shader_parameter(prefix + \"clouds_blur\", ", shader.get_shader_parameter("start_clouds_blur"), ")")
