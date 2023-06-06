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

var noise_list: Array[FastNoiseLite] = [
	hfil_noise,
	otherworld_noise,
	tundra_noise,
	savannah_noise,
	jungle_noise,
	desert_noise,
	forest_noise,
	grassland_noise,
	taiga_noise,
]

var curve_list: Array[Curve] = [
	hfil_curve,
	otherworld_curve,
	tundra_curve,
	savannah_curve,
	jungle_curve,
	desert_curve,
	forest_curve,
	grassland_curve,
	taiga_curve,
]

const biome_list: Array[World.Biome] = [
	World.Biome.HFIL,
	World.Biome.OTHERWORLD,
	World.Biome.TUNDRA,
	World.Biome.SAVANNAH,
	World.Biome.JUNGLE,
	World.Biome.DESERT,
	World.Biome.FOREST,
	World.Biome.GRASSLAND,
	World.Biome.TAIGA,
]
const biome_locations: PackedVector2Array = [
	Vector2(1, 1), # hfil
	Vector2(1, 0), # otherworld
	Vector2(0, 0), # tundra
	Vector2(0.75, 0.75), # savannah
	Vector2(0.25, 0.75), # jungle
	Vector2(0.75, 1.0), # desert
	Vector2(0.5, 0.75), # forest
	Vector2(0.5, 0.5), # grassland
	Vector2(0.25, 0.75), # taiga
]
const biome_colors: PackedVector3Array = [
	Vector3(1, 0, 0),
	Vector3(0, 0, 0),
	Vector3(1, 1, 1),
	Vector3(1, 0.5, 0),
	Vector3(0, 0.25, 0.25),
	Vector3(1, 1, 0),
	Vector3(0.282, 0.133, 0.0),
	Vector3(0.16, 0.53, 0.16),
	Vector3(0, 1, 1)
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

func color_for_biome(_biome: World.Biome) -> Color:
	match _biome:
		World.Biome.WATER: return Color(0, 0, 1)
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

func _init(d: FastNoiseLite, t: FastNoiseLite):
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
	
	
func dryness_texture(x: float, y: float, w: float, h: float, scale: float) -> NoiseTexture2D:
	return texture(dryness, x, y, w, h, scale)
	
func temperature_texture(x: float, y: float, w: float, h: float, scale: float) -> NoiseTexture2D:
	return texture(temperature, x, y, w, h, scale)

func texture(noise: FastNoiseLite, x: float, y: float, w: float, h: float, scale: float) -> NoiseTexture2D:
	var result := NoiseTexture2D.new()
	result.noise = noise.duplicate(true)
	result.noise.frequency *= scale
	result.noise.offset.x = x - w / 2
	result.noise.offset.y = y - h / 2
	result.width = int(w + 2)
	result.height = int(h + 2)
	result.normalize = false
	return result

static func parallel_sort_by_values(keys: Array, values: Array) -> Array:
	var swapped = false
	while not swapped:
		swapped = false
		for i in range(keys.size()):
			if values[i - 1] > values[i]:
				var v = values[i - 1]
				values[i - 1] = values[i]
				values[i] = v
				var k = keys[i - 1]
				keys[i - 1] = keys[i]
				keys[i] = k
				swapped = true
				
		if not swapped:
			break
	
	return keys

func height(x: float, y: float) -> float:
	var result := 0.0
	
	compute_biome_distances(x, y)
	
	var X := snappedf(x, 0.0001)
	var Y := snappedf(y, 0.0001)
	
	result += hfil_curve.sample(hfil_noise.get_noise_2d(X, Y) / 2.0 + 0.5) * (1.0 - distances[0] / total_size)
	result += otherworld_curve.sample(otherworld_noise.get_noise_2d(X, Y) / 2.0 + 0.5) * (1.0 - distances[1] / total_size)
	result += tundra_curve.sample(tundra_noise.get_noise_2d(X, Y) / 2.0 + 0.5) * (1.0 - distances[2] / total_size)
	result += savannah_curve.sample(savannah_noise.get_noise_2d(X, Y) / 2.0 + 0.5) * (1.0 - distances[3] / total_size)
	result += jungle_curve.sample(jungle_noise.get_noise_2d(X, Y) / 2.0 + 0.5) * (1.0 - distances[4] / total_size)
	result += desert_curve.sample(desert_noise.get_noise_2d(X, Y) / 2.0 + 0.5) * (1.0 - distances[5] / total_size)
	result += forest_curve.sample(forest_noise.get_noise_2d(X, Y) / 2.0 + 0.5) * (1.0 - distances[6] / total_size)
	result += grassland_curve.sample(grassland_noise.get_noise_2d(X, Y) / 2.0 + 0.5) * (1.0 - distances[7] / total_size)
	result += taiga_curve.sample(taiga_noise.get_noise_2d(X, Y) / 2.0 + 0.5) * (1.0 - distances[8] / total_size)
	
	return result

func compute_biome_distances(x: float, y: float):
	var d := dryness.get_noise_2d(x, y) / 2 + 0.5
	var t := temperature.get_noise_2d(x, y) / 2 + 0.5
	
	var p := Vector2(d, t)
	var min_distance := INF
	var pos := 0
	total_size = 0.0
	var clr := Vector3(1, 1, 1)
	var dist := 0.0
	var c := Vector3.ZERO
	for i in range(biome_locations.size()):
		dist = p.distance_to(biome_locations[i])
		distances[i] = dist
		total_size += dist
		c = lerp(biome_colors[i], Vector3(1, 1, 1), dist)
		if dist <= 1.0:
			clr = clr * c
		if dist < min_distance:
			min_distance = dist
			pos = i
	
	biome = biome_list[pos]
	color = Color(clr.x, clr.y, clr.z)

