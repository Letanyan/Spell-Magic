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
	var result = NoiseTexture2D.new()
	result.noise = noise.duplicate(true)
	result.noise.frequency *= scale
	result.noise.offset.x = x - w / 2
	result.noise.offset.y = y - h / 2
	result.width = w + 2
	result.height = h + 2
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
	compute_biome_distances(x, y)
	
	var noise_list = {
		World.Biome.GRASSLAND: grassland_noise,
		World.Biome.FOREST: forest_noise,
		World.Biome.TAIGA: taiga_noise,
		World.Biome.DESERT: desert_noise,
		World.Biome.HFIL: hfil_noise,
		World.Biome.JUNGLE: jungle_noise,
		World.Biome.OTHERWORLD: otherworld_noise,
		World.Biome.SAVANNAH: savannah_noise,
		World.Biome.TUNDRA: tundra_noise
	}
	
	var curve_list = {
		World.Biome.GRASSLAND: grassland_curve,
		World.Biome.FOREST: forest_curve,
		World.Biome.TAIGA: taiga_curve,
		World.Biome.DESERT: desert_curve,
		World.Biome.HFIL: hfil_curve,
		World.Biome.JUNGLE: jungle_curve,
		World.Biome.OTHERWORLD: otherworld_curve,
		World.Biome.SAVANNAH: savannah_curve,
		World.Biome.TUNDRA: tundra_curve
	}
	
	var result = 0.0
	
	var dict = compute_biome_distances(x, y)
	var total_size = dict["total"]
	for b in distances:
		var e = noise_list[b].get_noise_2d(snapped(x, 0.0001), snapped(y, 0.0001)) / 2 + 0.5
		var curve = curve_list[b]
		result += curve.sample(e) * (1.0 - distances[b] / total_size)
	
	return result

const biome_list = [
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
const biome_locations = [
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
const biome_colors = [
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
var distances = {
	World.Biome.HFIL: 0.0,
	World.Biome.OTHERWORLD: 0.0,
	World.Biome.TUNDRA: 0.0,
	World.Biome.SAVANNAH: 0.0,
	World.Biome.JUNGLE: 0.0,
	World.Biome.DESERT: 0.0,
	World.Biome.FOREST: 0.0,
	World.Biome.GRASSLAND: 0.0,
	World.Biome.TAIGA: 0.0,
}

func compute_biome_distances(x: float, y: float) -> Dictionary:
	var d := dryness.get_noise_2d(x, y) / 2 + 0.5
	var t := temperature.get_noise_2d(x, y) / 2 + 0.5
	
	var p := Vector2(d, t)
	var min_distance := INF
	var pos := 0
	var total := 0.0
	var color := Vector3(1, 1, 1)
	for i in range(biome_locations.size()):
		var q = biome_locations[i]
		var dist := p.distance_to(q)
		distances[biome_list[i]] = dist
		total += dist
		var c = lerp(biome_colors[i], Vector3(1, 1, 1), dist)
		if dist <= 1.0:
			color = color * c
		if dist < min_distance:
			min_distance = dist
			pos = i
	
	var clr = Color(color.x, color.y, color.z)
	return {"distances": distances, "biome": biome_list[pos], "total": total, "color": clr}
	
func biome(x: float, y: float) -> World.Biome:
	return compute_biome_distances(x, y)["biome"]

