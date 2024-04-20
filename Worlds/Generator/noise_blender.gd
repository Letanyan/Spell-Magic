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

const grassland_audio: AudioStream = preload("res://Audio/biome/grassland.mp3")
const forest_audio: AudioStream = preload("res://Audio/biome/forest.mp3")
const lake_audio: AudioStream = preload("res://Audio/biome/lake.mp3")

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
const biome_locations: PackedVector2Array = [
	Vector2(0.5, 0.5), # grassland
	Vector2(0.25, 0.75), # taiga
	Vector2(0.5, 0.75), # forest
	Vector2(0.75, 1.0), # desert
	Vector2(0.25, 0.75), # jungle
	Vector2(0.75, 0.75), # savannah
	Vector2(0, 0), # tundra
	Vector2(1, 0), # otherworld
	Vector2(1, 1), # hfil
]
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

var dryness: FastNoiseLite
var temperature: FastNoiseLite
var back: GDNoiseBlender

func _init(d: FastNoiseLite, t: FastNoiseLite, s: int) -> void:
	dryness = d
	temperature = t
	
	grassland_noise.frequency = 0.0005
	jungle_noise.frequency = 0.0005
	desert_noise.frequency = 0.0005
	forest_noise.frequency = 0.0005
	hfil_noise.frequency = 0.0005
	otherworld_noise.frequency = 0.0005
	savannah_noise.frequency = 0.0005
	taiga_noise.frequency = 0.0005
	tundra_noise.frequency = 0.0005
	
	grassland_noise.seed = s
	taiga_noise.seed = s
	forest_noise.seed = s
	desert_noise.seed = s
	jungle_noise.seed = s
	savannah_noise.seed = s
	tundra_noise.seed = s
	otherworld_noise.seed = s
	hfil_noise.seed = s
	
	back = GDNoiseBlender.new()
	back.add_biome(grassland_noise, grassland_curve, biome_locations[0], biome_colors[0])
	back.add_biome(taiga_noise, taiga_curve, biome_locations[1], biome_colors[1])
	back.add_biome(forest_noise, forest_curve, biome_locations[2], biome_colors[2])
	back.add_biome(desert_noise, desert_curve, biome_locations[3], biome_colors[3])
	back.add_biome(jungle_noise, jungle_curve, biome_locations[4], biome_colors[4])
	back.add_biome(savannah_noise, savannah_curve, biome_locations[5], biome_colors[5])
	back.add_biome(tundra_noise, tundra_curve, biome_locations[6], biome_colors[6])
	back.add_biome(otherworld_noise, otherworld_curve, biome_locations[7], biome_colors[7])
	back.add_biome(hfil_noise, hfil_curve, biome_locations[8], biome_colors[8])
	
	back.set_dryness(d)
	back.set_temperature(t)
	
func dryness_texture(x: float, y: float, w: float, h: float, scale: float) -> NoiseTexture2D:
	return texture(dryness, x, y, w, h, scale)
	
func temperature_texture(x: float, y: float, w: float, h: float, scale: float) -> NoiseTexture2D:
	return texture(temperature, x, y, w, h, scale)

func texture(noise: FastNoiseLite, x: float, y: float, w: float, h: float, scale: float) -> NoiseTexture2D:
	var result := NoiseTexture2D.new()
	result.noise = noise.duplicate(true)
	(result.noise as FastNoiseLite).frequency *= scale
	(result.noise as FastNoiseLite).offset.x = x - w / 2.0
	(result.noise as FastNoiseLite).offset.y = y - h / 2.0
	result.width = int(w + 2)
	result.height = int(h + 2)
	result.normalize = false
	return result

func height(x: float, y: float) -> float:
	#return Globals.sea_level() + 100.0
	return back.height(x, y)
	#var result := 0.0
#
	#compute_biome_distances(x, y)
#
	#var X := snappedf(x, 0.0001)
	#var Y := snappedf(y, 0.0001)
#
	#result += hfil_curve.sample(hfil_noise.get_noise_2d(X, Y) / 2.0 + 0.5) * (1.0 - distances[0] / total_size)
	#result += otherworld_curve.sample(otherworld_noise.get_noise_2d(X, Y) / 2.0 + 0.5) * (1.0 - distances[1] / total_size)
	#result += tundra_curve.sample(tundra_noise.get_noise_2d(X, Y) / 2.0 + 0.5) * (1.0 - distances[2] / total_size)
	#result += savannah_curve.sample(savannah_noise.get_noise_2d(X, Y) / 2.0 + 0.5) * (1.0 - distances[3] / total_size)
	#result += jungle_curve.sample(jungle_noise.get_noise_2d(X, Y) / 2.0 + 0.5) * (1.0 - distances[4] / total_size)
	#result += desert_curve.sample(desert_noise.get_noise_2d(X, Y) / 2.0 + 0.5) * (1.0 - distances[5] / total_size)
	#result += forest_curve.sample(forest_noise.get_noise_2d(X, Y) / 2.0 + 0.5) * (1.0 - distances[6] / total_size)
	#result += grassland_curve.sample(grassland_noise.get_noise_2d(X, Y) / 2.0 + 0.5) * (1.0 - distances[7] / total_size)
	#result += taiga_curve.sample(taiga_noise.get_noise_2d(X, Y) / 2.0 + 0.5) * (1.0 - distances[8] / total_size)
#
	#return result

func compute_biome_distances(x: float, y: float) -> void:
	back.compute_biome_stats(x, y)
	biome = (back.get_biome() + 1) as World.Biome
	color = back.get_color()
	distances = back.get_distances()
	total_size = back.get_total_distance()
	#var d := dryness.get_noise_2d(x, y) / 2.0 + 0.5
	#var t := temperature.get_noise_2d(x, y) / 2.0 + 0.5
	#
	#var p := Vector2(d, t)
	#var min_distance := INF
	#var pos := 0
	#total_size = 0.0
	#var clr := Vector3(1, 1, 1)
	#var dist := 0.0
	#var c := Vector3.ZERO
	#for i in range(biome_locations.size()):
		#dist = p.distance_to(biome_locations[i])
		#distances[i] = dist * dist
		#total_size += dist
		#c = lerp(biome_colors[i], Vector3(1, 1, 1), dist)
		#if dist <= 1.0:
			#clr = clr * c
		#if dist < min_distance:
			#min_distance = dist
			#pos = i
#
	#biome = biome_list[pos]
	#color = Color(clr.x, clr.y, clr.z)
	
func compute_biome(x: float, y: float) -> World.Biome:
	var d := dryness.get_noise_2d(x, y) / 2.0 + 0.5
	var t := temperature.get_noise_2d(x, y) / 2.0 + 0.5
	
	var p := Vector2(d, t)
	var min_distance := INF
	var pos := 0
	var dist := 0.0
	for i in range(biome_locations.size()):
		dist = p.distance_to(biome_locations[i])
		if dist < min_distance:
			min_distance = dist
			pos = i

	return biome_list[pos]
	

func grass_height(b: World.Biome, x: float, y: float) -> float:
	var n := noise_list[b].get_noise_2d(x, y) / 2.0 + 0.5
	var e := curve_list[b].sample(n) / curve_list[b].max_value
	var s := smoothstep(0.25, 1.0, e)
	if s == 0:
		return snapped(e * 4, 0.1)
	else:
		return 0.5 + s

static func audio_for_biome(b: World.Biome) -> AudioStream:
	match b:
		World.Biome.WATER: return lake_audio
		World.Biome.TAIGA: return lake_audio
		World.Biome.GRASSLAND: return grassland_audio
		World.Biome.FOREST: return forest_audio
		World.Biome.DESERT: return lake_audio
		World.Biome.JUNGLE: return lake_audio
		World.Biome.SAVANNAH: return lake_audio
		World.Biome.TUNDRA: return lake_audio
		World.Biome.OTHERWORLD: return lake_audio
		World.Biome.HFIL: return lake_audio
		_: return lake_audio
		
static func walking_audio_for_biome(b: World.Biome) -> AudioStream:
	match b:
		World.Biome.WATER: return grassland_walking
		World.Biome.TAIGA: return grassland_walking
		World.Biome.GRASSLAND: return grassland_walking
		World.Biome.FOREST: return grassland_walking
		World.Biome.DESERT: return grassland_walking
		World.Biome.JUNGLE: return grassland_walking
		World.Biome.SAVANNAH: return grassland_walking
		World.Biome.TUNDRA: return grassland_walking
		World.Biome.OTHERWORLD: return grassland_walking
		World.Biome.HFIL: return grassland_walking
		_: return grassland_walking
