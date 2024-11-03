class_name NoiseBlender

const grassland_curve: Curve = preload("res://Worlds/Generator/Terrain/Elevation Curves/grassland.tres")
const forest_curve: Curve = preload("res://Worlds/Generator/Terrain/Elevation Curves/forest.tres")
const taiga_curve: Curve = preload("res://Worlds/Generator/Terrain/Elevation Curves/taiga.tres")
const desert_curve: Curve = preload("res://Worlds/Generator/Terrain/Elevation Curves/desert.tres")
const hfil_curve: Curve = preload("res://Worlds/Generator/Terrain/Elevation Curves/hfil.tres")
const jungle_curve: Curve = preload("res://Worlds/Generator/Terrain/Elevation Curves/jungle.tres")
const otherworld_curve: Curve = preload("res://Worlds/Generator/Terrain/Elevation Curves/otherworld.tres")
const savannah_curve: Curve = preload("res://Worlds/Generator/Terrain/Elevation Curves/savannah.tres")
const tundra_curve: Curve = preload("res://Worlds/Generator/Terrain/Elevation Curves/tundra.tres")

var grassland_noise: FastNoiseLite = preload("res://Worlds/Generator/Terrain/Elevation Noise/grassland.tres")
var jungle_noise: FastNoiseLite = preload("res://Worlds/Generator/Terrain/Elevation Noise/jungle.tres")
var desert_noise: FastNoiseLite = preload("res://Worlds/Generator/Terrain/Elevation Noise/desert.tres")
var forest_noise: FastNoiseLite = preload("res://Worlds/Generator/Terrain/Elevation Noise/forest.tres")
var hfil_noise: FastNoiseLite = preload("res://Worlds/Generator/Terrain/Elevation Noise/hfil.tres")
var otherworld_noise: FastNoiseLite = preload("res://Worlds/Generator/Terrain/Elevation Noise/otherworld.tres")
var savannah_noise: FastNoiseLite = preload("res://Worlds/Generator/Terrain/Elevation Noise/savannah.tres")
var taiga_noise: FastNoiseLite = preload("res://Worlds/Generator/Terrain/Elevation Noise/taiga.tres")
var tundra_noise: FastNoiseLite = preload("res://Worlds/Generator/Terrain/Elevation Noise/tundra.tres")

const grassland_walking: AudioStream = preload("res://Audio/walking/grassland.mp3")

"""
	WATER,
	GRASSLAND, TAIGA, FOREST, DESERT, JUNGLE, SAVANNAH, TUNDRA,
	OTHERWORLD, HFIL
"""

var noise_list: Array[FastNoiseLite] = [
	grassland_noise, # padding for water
	grassland_noise,
	taiga_noise,
	forest_noise,
	desert_noise,
	jungle_noise,
	savannah_noise,
	tundra_noise,
	otherworld_noise,
	hfil_noise,
]

var curve_list: Array[Curve] = [
	grassland_curve, # padding for water
	grassland_curve,
	taiga_curve,
	forest_curve,
	desert_curve,
	jungle_curve,
	savannah_curve,
	tundra_curve,
	otherworld_curve,
	hfil_curve,
]

const biome_list: Array[World.Biome] = [
	World.Biome.GRASSLAND,
	World.Biome.TAIGA,
	World.Biome.FOREST,
	World.Biome.DESERT,
	World.Biome.JUNGLE,
	World.Biome.SAVANNAH,
	World.Biome.TUNDRA,
	World.Biome.OTHERWORLD,
	World.Biome.HFIL,
]
# x=temperature/elevation(0=hot,1=cold)[e.i. valleys(hot) upto mountain top(cold)] y=wetness(0=moist,1=dry) 
#var biome_locations: PackedVector2Array = [
	#Vector2(0.50, 0.50), # grassland
	#Vector2(0.75, 0.00), # taiga
	#Vector2(0.50, 0.25), # forest
	#Vector2(0.25, 0.75), # desert
	#Vector2(0.25, 0.25), # jungle
	#Vector2(0.25, 0.50), # savannah
	#Vector2(1.00, 0.50), # tundra
	#Vector2(1.00, 0.00), # otherworld
	#Vector2(0.00, 1.00)  # hfil
#]
const biome_colors: PackedVector3Array = [
	Vector3(0.23, 0.83, 0.23),
	Vector3(0, 1, 1),
	Vector3(0.55, 0.28, 0.0),
	Vector3(1, 1, 0),
	Vector3(0, 0.4, 0.0),
	Vector3(1, 0.5, 0),
	Vector3(1, 1, 1),
	Vector3(0, 0, 0),
	Vector3(1, 0, 0),
]
var distances: PackedFloat64Array = [
	0.0,
	0.0,
	0.0,
	0.0,
	0.0,
	0.0,
	0.0,
	0.0,
	0.0,
]
var biome := World.Biome.GRASSLAND
var color := Color.WHITE
var total_size := 0.0
var sea_level := 0.0

static func color_for_biome(_biome: World.Biome) -> Color:
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

var back: GDNoiseBlender

static func make(version: int, s: int) -> NoiseBlender:
	if version == 1:
		return NoiseBlender.version1(s)
		
	return NoiseBlender.version1(s) # WARNING: This should always return the latest version
	
static func version0(s: int) -> NoiseBlender:
	var result := NoiseBlender.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = s
	
	result.back = GDNoiseBlender.new()
	result.back.set_elevation_mix_exp(20.0)
	
	var biome_locations := result.shuffle_biome_locations(rng)
	
	result.back.add_biome("EQACAAAAAACgQBAAbxKDOg0AAwAAAAAAgD8TAG8SgzoTAM3MzD0IAAAAAIA/AAAAAAAAAACAPwAAAEA/AAAAAAA=", s ^ hash("grassland"), grassland_curve, biome_locations[0], biome_colors[0])
	result.back.add_biome("EQACAAAAAAAgQRAAAACAPw0ABQAAAAAAAEATAG8SgzsTAM3MzD0IAAAAAAAAAAAAgD8AAACgQAAAAABAAAAAAAA=", s ^ hash("taiga"), taiga_curve, biome_locations[1], biome_colors[1])
	result.back.add_biome("EQAFAAAAAAAAQBAACtcjPA0AAwAAAAAAIEATAG8SgzsTAArXIzwIAAAAAIA/AOF6lD4AAADwQQAAAAA/AAAAAAA=", s ^ hash("forest"), forest_curve, biome_locations[2], biome_colors[2])
	result.back.add_biome("EQAFAAAAAAAAQBAAzcxMPQ0ABQAAAAAAEEETAKabxDsTAM3MzD0GAAAAAAAAAAAAgD8AKVzLQgDNzMw9AAAAAAA=", s ^ hash("desert"), desert_curve, biome_locations[3], biome_colors[3])
	result.back.add_biome("EADNzMw+DQADAAAAAABwQhMAbxKDOhMACtcjPAgAAAAAAD8AAAAAAAEbAAgAAAAASEI=", s ^ hash("jungle"), jungle_curve, biome_locations[4], biome_colors[4])
	result.back.add_biome("EgACAAAAAAAAQBAAZmZmPw0ABQAAAAAAgEATALx0kzsTAM3MzD0IAADNzMw9AAAAAD8AAAAAQAAAAIA/AAAAAAA=", s ^ hash("savannah"), savannah_curve, biome_locations[5], biome_colors[5])
	result.back.add_biome("EQACAAAA16PwPxAAbxKDOg0AAwAAAHE9yj8TAEJg5TsTAArXIzwGAABcj4pBAKRwPUAAAEAcRgBmZqY/AMP1qD8=", s ^ hash("tundra"), tundra_curve, biome_locations[6], biome_colors[6])
	result.back.add_biome("EgACAAAA16OwQBAAAAAAAA0AAwAAANejAEETAG8SAzwTAM3MzD0GAAEDAHE9yj8AZmZmPwCF61FAAEjhUkEAPQoXwQ==", s ^ hash("otherworld"), otherworld_curve, biome_locations[7], biome_colors[7])
	result.back.add_biome("DQACAAAACtevQRMAbxIDPBMACtcjPAgAAQIA4XrUPwAAAIA/", s ^ hash("hfil"), hfil_curve, biome_locations[8], biome_colors[8])
	
	result.back.set_biome_noise(Globals.encoded_x_noise, s ^ hash("temperatue"), 0)
	result.back.set_biome_noise(Globals.encoded_y_noise, s ^ hash("moisture"), 1)
	
	result.sea_level = rng.randf_range(-50.0, 250.0)
	
	return result
	
static func version1(s: int) -> NoiseBlender:
	var result := NoiseBlender.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = s
	
	result.back = GDNoiseBlender.new()
	
	var biome_locations := result.shuffle_biome_locations(rng)
	
	var elevation_curve := lerpf(20.0, 40.0, rng.randf())
	result.back.set_elevation_mix_exp(elevation_curve)
	
	result.back.add_biome("EQACAAAAAACgQBAAbxKDOg0AAwAAAAAAgD8TAG8SgzoTAM3MzD0IAAAAAIA/AAAAAAAAAACAPwAAAEA/AAAAAAA=", s ^ hash("grassland"), grassland_curve, biome_locations[0], biome_colors[0])
	result.back.add_biome("EQACAAAAAAAgQRAAAACAPw0ABQAAAAAAAEATAG8SgzsTAM3MzD0IAAAAAAAAAAAAgD8AAACgQAAAAABAAAAAAAA=", s ^ hash("taiga"), taiga_curve, biome_locations[1], biome_colors[1])
	result.back.add_biome("EQAFAAAAAAAAQBAACtcjPA0AAwAAAAAAIEATAG8SgzsTAArXIzwIAAAAAIA/AOF6lD4AAADwQQAAAAA/AAAAAAA=", s ^ hash("forest"), forest_curve, biome_locations[2], biome_colors[2])
	result.back.add_biome("EQAFAAAAAAAAQBAAzcxMPQ0ABQAAAAAAEEETAKabxDsTAM3MzD0GAAAAAAAAAAAAgD8AKVzLQgDNzMw9AAAAAAA=", s ^ hash("desert"), desert_curve, biome_locations[3], biome_colors[3])
	result.back.add_biome("EADNzMw+DQADAAAAAABwQhMAbxKDOhMACtcjPAgAAAAAAD8AAAAAAAEbAAgAAAAASEI=", s ^ hash("jungle"), jungle_curve, biome_locations[4], biome_colors[4])
	result.back.add_biome("EgACAAAAAAAAQBAAZmZmPw0ABQAAAAAAgEATALx0kzsTAM3MzD0IAADNzMw9AAAAAD8AAAAAQAAAAIA/AAAAAAA=", s ^ hash("savannah"), savannah_curve, biome_locations[5], biome_colors[5])
	result.back.add_biome("EQACAAAA16PwPxAAbxKDOg0AAwAAAHE9yj8TAEJg5TsTAArXIzwGAABcj4pBAKRwPUAAAEAcRgBmZqY/AMP1qD8=", s ^ hash("tundra"), tundra_curve, biome_locations[6], biome_colors[6])
	result.back.add_biome("EgACAAAA16OwQBAAAAAAAA0AAwAAANejAEETAG8SAzwTAM3MzD0GAAEDAHE9yj8AZmZmPwCF61FAAEjhUkEAPQoXwQ==", s ^ hash("otherworld"), otherworld_curve, biome_locations[7], biome_colors[7])
	result.back.add_biome("DQACAAAAAACAPxMAbxIDPBMACtcjPAgAARAAAAAAPwIA4XrUPwCPwvW9AAAAgD8=", s ^ hash("hfil"), hfil_curve, biome_locations[8], biome_colors[8])
						  
	result.back.set_biome_noise(Globals.encoded_x_noise, s ^ hash("temperatue"), 0)
	result.back.set_biome_noise(Globals.encoded_y_noise, s ^ hash("moisture"), 1)
	
	result.sea_level = rng.randf_range(-50.0, 250.0)
	
	return result
	
func texture(noise: FastNoiseLite, x: float, y: float, w: float, h: float, scale: float) -> NoiseTexture2D:
	return back.texture(noise, x, y, w, h, scale)

func compute_biome_distances(x: float, y: float, scale: float) -> void:
	back.compute_biome_stats(x, y, scale)
	biome = biome_list[back.get_biome()]
	color = back.get_color()
	distances = back.get_distances()
	total_size = back.get_total_distance()
	

func grass_height(b: World.Biome, x: float, y: float) -> float:
	return back.grass_height(b, x, y)
		
func shuffle_biome_locations(rng: RandomNumberGenerator) -> PackedVector2Array:
	var result := PackedVector2Array([])
	var source: Array[Vector2] = [
		Vector2(0.00, 1.00), Vector2(0.25, 1.00), Vector2(0.50, 1.00), Vector2(0.75, 1.00), Vector2(1.00, 1.00),
		Vector2(0.00, 0.75), Vector2(0.25, 0.75), Vector2(0.50, 0.75), Vector2(0.75, 0.75), Vector2(1.00, 0.75),
		Vector2(0.00, 0.50), Vector2(0.25, 0.50), Vector2(0.50, 0.50), Vector2(0.75, 0.50), Vector2(1.00, 0.50),
		Vector2(0.00, 0.25), Vector2(0.25, 0.25), Vector2(0.50, 0.25), Vector2(0.75, 0.25), Vector2(1.00, 0.25),
		Vector2(0.00, 0.00), Vector2(0.25, 0.00), Vector2(0.50, 0.00), Vector2(0.75, 0.00), Vector2(1.00, 0.00),
	]
	for i in biome_colors.size():
		var j := rng.randi_range(0, source.size() - 1)
		result.append(source[j])
		source.remove_at(j)
	return result
		

static func audio_for_biome(b: World.Biome) -> String:
	match b:
		World.Biome.WATER: return "Lake"
		World.Biome.TAIGA: return "Lake"
		World.Biome.GRASSLAND: return "Grassland"
		World.Biome.FOREST: return "Forest"
		World.Biome.DESERT: return "Lake"
		World.Biome.JUNGLE: return "Lake"
		World.Biome.SAVANNAH: return "Lake"
		World.Biome.TUNDRA: return "Lake"
		World.Biome.OTHERWORLD: return "Lake"
		World.Biome.HFIL: return "Lake"
		_: return "Lake"
		
static func walking_audio_for_biome(b: World.Biome) -> String:
	match b:
		World.Biome.WATER: return "Water"
		World.Biome.TAIGA: return "Grassland"
		World.Biome.GRASSLAND: return "Grassland"
		World.Biome.FOREST: return "Forest"
		World.Biome.DESERT: return "Grassland"
		World.Biome.JUNGLE: return "Grassland"
		World.Biome.SAVANNAH: return "Grassland"
		World.Biome.TUNDRA: return "Grassland"
		World.Biome.OTHERWORLD: return "Grassland"
		World.Biome.HFIL: return "Grassland"
		_: return "empty"

static func update_world_environment(env: WorldEnvironment, sun: DirectionalLight3D, moon: DirectionalLight3D, b: World.Biome, is_start: bool) -> void:
	var prefix := "start_" if is_start else "final_"
	var shader := env.environment.sky.sky_material as ShaderMaterial
	match b:
		World.Biome.GRASSLAND:
			shader.set_shader_parameter(prefix + "day_top_color", Color(0.1, 0.6, 1, 1))
			shader.set_shader_parameter(prefix + "day_bottom_color", Color(0.43, 1, 0.8195, 1))
			shader.set_shader_parameter(prefix + "sunset_top_color", Color(0.7085, 0.47, 1, 1))
			shader.set_shader_parameter(prefix + "sunset_bottom_color", Color(1, 0.3667, 0.24, 1))
			shader.set_shader_parameter(prefix + "night_top_color", Color(0.02, 0, 0.039, 1))
			shader.set_shader_parameter(prefix + "night_bottom_color", Color(0.0819, 0.2411, 0.39, 1))
			shader.set_shader_parameter(prefix + "horizon_color", Color(0, 0.702, 0.8, 1))
			shader.set_shader_parameter(prefix + "horizon_blur", 0.05)
			shader.set_shader_parameter(prefix + "clouds_edge_color", Color(0.941, 0.961, 1, 1))
			shader.set_shader_parameter(prefix + "clouds_top_color", Color(1, 1, 1, 1))
			shader.set_shader_parameter(prefix + "clouds_middle_color", Color(0.922, 0.922, 0.98, 1))
			shader.set_shader_parameter(prefix + "clouds_bottom_color", Color(0.831, 0.831, 0.941, 1))
			shader.set_shader_parameter(prefix + "clouds_speed", 1.0)
			shader.set_shader_parameter(prefix + "clouds_scale", 2.2)
			shader.set_shader_parameter(prefix + "clouds_cutoff", 0.6)
			shader.set_shader_parameter(prefix + "clouds_weight", 0)
			shader.set_shader_parameter(prefix + "clouds_blur", 0.27)
		World.Biome.FOREST:
			shader.set_shader_parameter(prefix + "day_top_color", Color(0, 0.3725, 1, 1))
			shader.set_shader_parameter(prefix + "day_bottom_color", Color(0.4627, 1, 0.4275, 1))
			shader.set_shader_parameter(prefix + "sunset_top_color", Color(0.702, 0.749, 1, 1))
			shader.set_shader_parameter(prefix + "sunset_bottom_color", Color(1, 0.9176, 0.2353, 1))
			shader.set_shader_parameter(prefix + "night_top_color", Color(0.02, 0, 0.04, 1))
			shader.set_shader_parameter(prefix + "night_bottom_color", Color(0.102, 0.4824, 0.2, 1))
			shader.set_shader_parameter(prefix + "horizon_color", Color(0, 0.7, 0.8, 1))
			shader.set_shader_parameter(prefix + "horizon_blur", 0.05000000074506)
			shader.set_shader_parameter(prefix + "clouds_edge_color", Color(0.8, 0.8, 0.98, 1))
			shader.set_shader_parameter(prefix + "clouds_top_color", Color(1, 1, 1, 1))
			shader.set_shader_parameter(prefix + "clouds_middle_color", Color(0.92, 0.92, 0.98, 1))
			shader.set_shader_parameter(prefix + "clouds_bottom_color", Color(0.83, 0.83, 0.94, 1))
			shader.set_shader_parameter(prefix + "clouds_speed", 1.0)
			shader.set_shader_parameter(prefix + "clouds_scale", 2.2)
			shader.set_shader_parameter(prefix + "clouds_cutoff", 0.3)
			shader.set_shader_parameter(prefix + "clouds_weight", 0)
			shader.set_shader_parameter(prefix + "clouds_blur", 0.25)
		World.Biome.TAIGA:
			shader.set_shader_parameter(prefix + "day_top_color", Color(0.05, 0, 1, 1))
			shader.set_shader_parameter(prefix + "day_bottom_color", Color(0, 0.8367, 0.9796, 1))
			shader.set_shader_parameter(prefix + "sunset_top_color", Color(0.66, 0.9377, 1, 1))
			shader.set_shader_parameter(prefix + "sunset_bottom_color", Color(1, 0.35, 0.5992, 1))
			shader.set_shader_parameter(prefix + "night_top_color", Color(0.02, 0, 0.04, 1))
			shader.set_shader_parameter(prefix + "night_bottom_color", Color(0.1034, 0.1636, 0.22, 1))
			shader.set_shader_parameter(prefix + "horizon_color", Color(0, 0.7, 0.8, 1))
			shader.set_shader_parameter(prefix + "horizon_blur", 0.05000000074506)
			shader.set_shader_parameter(prefix + "clouds_edge_color", Color(0.8, 0.8, 0.98, 1))
			shader.set_shader_parameter(prefix + "clouds_top_color", Color(1, 1, 1, 1))
			shader.set_shader_parameter(prefix + "clouds_middle_color", Color(0.92, 0.92, 0.98, 1))
			shader.set_shader_parameter(prefix + "clouds_bottom_color", Color(0.83, 0.83, 0.94, 1))
			shader.set_shader_parameter(prefix + "clouds_speed", 0.999999977648)
			shader.set_shader_parameter(prefix + "clouds_scale", 2.27999994903744)
			shader.set_shader_parameter(prefix + "clouds_cutoff", 0.43999999016512)
			shader.set_shader_parameter(prefix + "clouds_weight", 0)
			shader.set_shader_parameter(prefix + "clouds_blur", 0.78999998234192)
		World.Biome.JUNGLE:
			shader.set_shader_parameter(prefix + "day_top_color", Color(0, 0.53, 0.1943, 1))
			shader.set_shader_parameter(prefix + "day_bottom_color", Color(0, 0.63, 0.567, 1))
			shader.set_shader_parameter(prefix + "sunset_top_color", Color(0.5553, 0.42, 1, 1))
			shader.set_shader_parameter(prefix + "sunset_bottom_color", Color(0.368, 0.48, 0, 1))
			shader.set_shader_parameter(prefix + "night_top_color", Color(0.02, 0, 0.04, 1))
			shader.set_shader_parameter(prefix + "night_bottom_color", Color(0.1269, 0.27, 0.2175, 1))
			shader.set_shader_parameter(prefix + "horizon_color", Color(0, 0.7, 0.8, 1))
			shader.set_shader_parameter(prefix + "horizon_blur", 0.05000000074506)
			shader.set_shader_parameter(prefix + "clouds_edge_color", Color(0.8, 0.8, 0.98, 1))
			shader.set_shader_parameter(prefix + "clouds_top_color", Color(1, 1, 1, 1))
			shader.set_shader_parameter(prefix + "clouds_middle_color", Color(0.92, 0.92, 0.98, 1))
			shader.set_shader_parameter(prefix + "clouds_bottom_color", Color(0.83, 0.83, 0.94, 1))
			shader.set_shader_parameter(prefix + "clouds_speed", 0.999999977648)
			shader.set_shader_parameter(prefix + "clouds_scale", 2.27999994903744)
			shader.set_shader_parameter(prefix + "clouds_cutoff", 0.43999999016512)
			shader.set_shader_parameter(prefix + "clouds_weight", 0.3999999910592)
			shader.set_shader_parameter(prefix + "clouds_blur", 0)
		World.Biome.DESERT:
			shader.set_shader_parameter(prefix + "day_top_color", Color(0, 0.4833, 1, 1))
			shader.set_shader_parameter(prefix + "day_bottom_color", Color(0, 0.9333, 1, 1))
			shader.set_shader_parameter(prefix + "sunset_top_color", Color(0.3667, 0, 1, 1))
			shader.set_shader_parameter(prefix + "sunset_bottom_color", Color(1, 0.7, 0, 1))
			shader.set_shader_parameter(prefix + "night_top_color", Color(0, 0.136, 0.34, 1))
			shader.set_shader_parameter(prefix + "night_bottom_color", Color(0.2162, 0.4031, 0.46, 1))
			shader.set_shader_parameter(prefix + "horizon_color", Color(0, 0.7, 0.8, 1))
			shader.set_shader_parameter(prefix + "horizon_blur", 0.05000000074506)
			shader.set_shader_parameter(prefix + "clouds_edge_color", Color(0.8, 0.8, 0.98, 1))
			shader.set_shader_parameter(prefix + "clouds_top_color", Color(1, 1, 1, 1))
			shader.set_shader_parameter(prefix + "clouds_middle_color", Color(0.92, 0.92, 0.98, 1))
			shader.set_shader_parameter(prefix + "clouds_bottom_color", Color(0.83, 0.83, 0.94, 1))
			shader.set_shader_parameter(prefix + "clouds_speed", 0.73999998345952)
			shader.set_shader_parameter(prefix + "clouds_scale", 3.999999910592)
			shader.set_shader_parameter(prefix + "clouds_cutoff", 0.15999999642368)
			shader.set_shader_parameter(prefix + "clouds_weight", 0)
			shader.set_shader_parameter(prefix + "clouds_blur", 0.999999977648)
			
		World.Biome.SAVANNAH:
			shader.set_shader_parameter(prefix + "day_top_color", Color(0.27, 0.562, 1, 1))
			shader.set_shader_parameter(prefix + "day_bottom_color", Color(0.81, 0.9683, 1, 1))
			shader.set_shader_parameter(prefix + "sunset_top_color", Color(1, 0.35, 0, 1))
			shader.set_shader_parameter(prefix + "sunset_bottom_color", Color(1, 0.55, 0, 1))
			shader.set_shader_parameter(prefix + "night_top_color", Color(0, 0.216, 0.54, 1))
			shader.set_shader_parameter(prefix + "night_bottom_color", Color(0, 0, 0, 1))
			shader.set_shader_parameter(prefix + "horizon_color", Color(0, 0.7, 0.8, 1))
			shader.set_shader_parameter(prefix + "horizon_blur", 0.05)
			shader.set_shader_parameter(prefix + "clouds_edge_color", Color(0.8, 0.8, 0.98, 1))
			shader.set_shader_parameter(prefix + "clouds_top_color", Color(1, 1, 1, 1))
			shader.set_shader_parameter(prefix + "clouds_middle_color", Color(0.92, 0.92, 0.98, 1))
			shader.set_shader_parameter(prefix + "clouds_bottom_color", Color(0.83, 0.83, 0.94, 1))
			shader.set_shader_parameter(prefix + "clouds_speed", 2.0499999541784)
			shader.set_shader_parameter(prefix + "clouds_scale", 1.30999997071888)
			shader.set_shader_parameter(prefix + "clouds_cutoff", 0.6999999843536)
			shader.set_shader_parameter(prefix + "clouds_weight", 0)
			shader.set_shader_parameter(prefix + "clouds_blur", 0)
			
		World.Biome.TUNDRA:
			shader.set_shader_parameter(prefix + "day_top_color", Color(0.51, 0.706, 1, 1))
			shader.set_shader_parameter(prefix + "day_bottom_color", Color(1, 1, 1, 1))
			shader.set_shader_parameter(prefix + "sunset_top_color", Color(0.7958, 0.51, 1, 1))
			shader.set_shader_parameter(prefix + "sunset_bottom_color", Color(1, 0.7795, 0.51, 1))
			shader.set_shader_parameter(prefix + "night_top_color", Color(0, 0.12, 0.3, 1))
			shader.set_shader_parameter(prefix + "night_bottom_color", Color(0.2444, 0.4557, 0.52, 1))
			shader.set_shader_parameter(prefix + "horizon_color", Color(0, 0.7, 0.8, 1))
			shader.set_shader_parameter(prefix + "horizon_blur", 0.05)
			shader.set_shader_parameter(prefix + "clouds_edge_color", Color(0.8, 0.8, 0.98, 1))
			shader.set_shader_parameter(prefix + "clouds_top_color", Color(1, 1, 1, 1))
			shader.set_shader_parameter(prefix + "clouds_middle_color", Color(0.92, 0.92, 0.98, 1))
			shader.set_shader_parameter(prefix + "clouds_bottom_color", Color(0.83, 0.83, 0.94, 1))
			shader.set_shader_parameter(prefix + "clouds_speed", 5.86999986879376)
			shader.set_shader_parameter(prefix + "clouds_scale", 3.999999910592)
			shader.set_shader_parameter(prefix + "clouds_cutoff", 0.6499999854712)
			shader.set_shader_parameter(prefix + "clouds_weight", 0)
			shader.set_shader_parameter(prefix + "clouds_blur", 0)
			
		World.Biome.OTHERWORLD:
			shader.set_shader_parameter(prefix + "day_top_color", Color(0, 1, 1, 1))
			shader.set_shader_parameter(prefix + "day_bottom_color", Color(0, 0.0167, 1, 1))
			shader.set_shader_parameter(prefix + "sunset_top_color", Color(0, 0, 1, 1))
			shader.set_shader_parameter(prefix + "sunset_bottom_color", Color(1, 0, 1, 1))
			shader.set_shader_parameter(prefix + "night_top_color", Color(0, 0, 1, 1))
			shader.set_shader_parameter(prefix + "night_bottom_color", Color(0, 0, 0, 1))
			shader.set_shader_parameter(prefix + "horizon_color", Color(0, 0.7, 0.8, 1))
			shader.set_shader_parameter(prefix + "horizon_blur", 0.05)
			shader.set_shader_parameter(prefix + "clouds_edge_color", Color(0.8, 0.8, 0.98, 1))
			shader.set_shader_parameter(prefix + "clouds_top_color", Color(1, 1, 1, 1))
			shader.set_shader_parameter(prefix + "clouds_middle_color", Color(0.92, 0.92, 0.98, 1))
			shader.set_shader_parameter(prefix + "clouds_bottom_color", Color(0.83, 0.83, 0.94, 1))
			shader.set_shader_parameter(prefix + "clouds_speed", 19.99999955296)
			shader.set_shader_parameter(prefix + "clouds_scale", 0.43999999016512)
			shader.set_shader_parameter(prefix + "clouds_cutoff", 0.31999999284736)
			shader.set_shader_parameter(prefix + "clouds_weight", 0)
			shader.set_shader_parameter(prefix + "clouds_blur", 0.999999977648)
			
		World.Biome.HFIL:
			shader.set_shader_parameter(prefix + "day_top_color", Color(1, 0, 0, 1))
			shader.set_shader_parameter(prefix + "day_bottom_color", Color(1, 0.0157, 1, 1))
			shader.set_shader_parameter(prefix + "sunset_top_color", Color(1, 0, 1, 1))
			shader.set_shader_parameter(prefix + "sunset_bottom_color", Color(1, 1, 0, 1))
			shader.set_shader_parameter(prefix + "night_top_color", Color(1, 0, 0, 1))
			shader.set_shader_parameter(prefix + "night_bottom_color", Color(0, 0, 0, 1))
			shader.set_shader_parameter(prefix + "horizon_color", Color(0, 0.7, 0.8, 1))
			shader.set_shader_parameter(prefix + "horizon_blur", 0.05)
			shader.set_shader_parameter(prefix + "clouds_edge_color", Color(0.8, 0.8, 0.98, 1))
			shader.set_shader_parameter(prefix + "clouds_top_color", Color(1, 1, 1, 1))
			shader.set_shader_parameter(prefix + "clouds_middle_color", Color(0.92, 0.92, 0.98, 1))
			shader.set_shader_parameter(prefix + "clouds_bottom_color", Color(0.83, 0.83, 0.94, 1))
			shader.set_shader_parameter(prefix + "clouds_speed", 0)
			shader.set_shader_parameter(prefix + "clouds_scale", 3.999999910592)
			shader.set_shader_parameter(prefix + "clouds_cutoff", 0.499999988824)
			shader.set_shader_parameter(prefix + "clouds_weight", 0.999999977648)
			shader.set_shader_parameter(prefix + "clouds_blur", 0.61999998614176)
			
		_:
			shader.set_shader_parameter(prefix + "day_top_color", Color(0.102, 0.594, 1))
			shader.set_shader_parameter(prefix + "day_bottom_color", Color(0.4, 0.3, 0.557))
			shader.set_shader_parameter(prefix + "sunset_top_color", Color(0.702, 0.449, 0.737))
			shader.set_shader_parameter(prefix + "sunset_bottom_color", Color(0.718, 0.175, 0.384))
			shader.set_shader_parameter(prefix + "night_top_color", Color(0.02, 0.637, 0.039))
			shader.set_shader_parameter(prefix + "night_bottom_color", Color(0, 0.684, 0.169))
			shader.set_shader_parameter(prefix + "horizon_color", Color(0.333, 0.139, 0.349))
			shader.set_shader_parameter(prefix + "horizon_blur", 0.05)
			shader.set_shader_parameter(prefix + "clouds_edge_color", Color(0.941, 0.961, 1))
			shader.set_shader_parameter(prefix + "clouds_top_color", Color(1, 1, 1))
			shader.set_shader_parameter(prefix + "clouds_middle_color", Color(0.922, 0.922, 0.98))
			shader.set_shader_parameter(prefix + "clouds_bottom_color", Color(0.831, 0.831, 0.941))
			shader.set_shader_parameter(prefix + "clouds_speed", 1.0)
			shader.set_shader_parameter(prefix + "clouds_scale", 2.2)
			shader.set_shader_parameter(prefix + "clouds_cutoff", 0.3)
			shader.set_shader_parameter(prefix + "clouds_weight", 0)
			shader.set_shader_parameter(prefix + "clouds_blur", 0.25)
			
static func environment_ambient_color(time_of_day: float, sun: DirectionalLight3D, moon: DirectionalLight3D) -> Color:
	var result := Color(1, 1, 1)
	
	var sunset_amount := clampf( 0.5 - absf( sun.rotation.y ), 0.0, 0.5 ) * 2.0
	result = result.lerp(Color(0.5, 0.5, 0.5), sunset_amount)
	
	var night_amount := clampf( -sun.rotation.y + 0.7, 0.0, 1.0 )
	result = result.lerp(Color(0, 0, 0), night_amount)
	
	return result
			
static func print_world_environment(env: WorldEnvironment, sun: DirectionalLight3D, moon: DirectionalLight3D) -> void:
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

func count_biomes(positions: Array[Vector2]) -> void:
	var summary := {}
	for pos in positions:
		back.compute_biome_map_stats(pos.x * 256, pos.y * 256, 16, 16, 16)
		var dict := back.get_biomes_map()
		for p in dict:
			if summary.has(p):
				summary[p] += 1
			else:
				summary[p] = 0
				
	print("-----------------------------------------")
	for b: int in summary:
		print(World.Biome.keys()[b + 1], ": ", summary[b])
