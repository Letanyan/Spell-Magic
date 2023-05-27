class_name NoiseBlender

var elevation_curve: Curve = load("res://Worlds/Generator/Terrain/terrain_elevation_curve.tres")

const grassland_curve: Curve = preload("res://Worlds/Generator/Terrain/Elevation Curves/grassland.tres")
const forest_curve: Curve = preload("res://Worlds/Generator/Terrain/Elevation Curves/forest.tres")
const taiga_curve: Curve = preload("res://Worlds/Generator/Terrain/Elevation Curves/taiga.tres")

const flat_curve: Curve = preload("res://Worlds/Generator/Terrain/Elevation Curves/flat.tres")

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

var elevation: FastNoiseLite
var dryness: FastNoiseLite
var temperature: FastNoiseLite

func _init(e: FastNoiseLite, d: FastNoiseLite, t: FastNoiseLite):
	elevation = e
	dryness = d
	temperature = t

func elevation_texture(x: float, y: float, w: float, h: float) -> NoiseTexture2D:
	return texture(elevation, x, y, w, h)
	
func dryness_texture(x: float, y: float, w: float, h: float) -> NoiseTexture2D:
	return texture(dryness, x, y, w, h)
	
func temperature_texture(x: float, y: float, w: float, h: float) -> NoiseTexture2D:
	return texture(temperature, x, y, w, h)

func texture(noise: FastNoiseLite, x: float, y: float, w: float, h: float) -> NoiseTexture2D:
	var result = NoiseTexture2D.new()
	result.noise = noise.duplicate(true)
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
	var e = elevation.get_noise_2d(snapped(x, 0.0001), snapped(y, 0.0001)) / 2 + 0.5
	
	var biomes = biome_distances(x, y)
	var distances = biomes["distances"]
	
	var curve_list = {
		World.Biome.GRASSLAND: grassland_curve,
		World.Biome.FOREST: forest_curve,
		World.Biome.TAIGA: taiga_curve,
	}
	
	var result = 0.0
	var total_size = biomes["total"]
	for b in distances:
		var curve = curve_list.get(b, flat_curve)
		result += curve.sample(e) * (1.0 - distances[b] / total_size)
	
#	for biome in distances:
#		var curve = curve_list.get(biome, flat_curve)
#		result += curve.sample(e) * (1.0 - distances[biome] / total_size)
	
	return result

func biome_distances(x: float, y: float) -> Dictionary:
	var d := dryness.get_noise_2d(x, y) / 2 + 0.5
	var t := temperature.get_noise_2d(x, y) / 2 + 0.5
	
	var hfil := Vector2(1, 1)
	var otherworld := Vector2(1, 0)
	var tundra := Vector2(0, 0)
	var savannah := Vector2(0.75, 0.75)
	var jungle := Vector2(0.25, 0.75)
	var desert := Vector2(0.75, 1.0)
	var forest := Vector2(0.5, 0.75)
	var grassland := Vector2(0.5, 0.5)
	var taiga := Vector2(0.25, 0.75)
	
	var biome_list = [
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
	var biome_locations = [
		hfil,
		otherworld,
		tundra,
		savannah,
		jungle,
		desert,
		forest,
		grassland,
		taiga,
	]
	var p := Vector2(d, t)
	var min_distance := INF
	var pos := 0
	var distances = {}
	var total := 0.0
	for i in range(biome_locations.size()):
		var q = biome_locations[i]
		var dist := p.distance_to(q)
		distances[biome_list[i]] = dist
		total += dist
		if dist < min_distance:
			min_distance = dist
			pos = i
	
	return {"distances": distances, "biome": biome_list[pos], "total": total}
	
func biome(x: float, y: float) -> World.Biome:
	return biome_distances(x, y)["biome"]
	
func biome_p(x: float, y: float) -> World.Biome:
	var e = elevation.get_noise_2d(x, y) / 2 + 0.5
	var d = dryness.get_noise_2d(x, y) / 2 + 0.5
	var t = temperature.get_noise_2d(x, y) / 2 + 0.5
	
	var result = World.Biome.OTHERWORLD
	if t >= 0.0 and t < 0.1:
		result = World.Biome.TAIGA
	elif t >= 0.1 and t < 0.3:
		if d >= 0.0 and d < 0.5:
			result = World.Biome.GRASSLAND
		elif d >= 0.5 and d <= 1.0:
			result = World.Biome.TAIGA
	elif t >= 0.3 and t < 0.6:
		if d >= 0.0 and d < 0.1:
			result = World.Biome.FOREST
		elif d >= 0.1 and d < 0.4:
			result = World.Biome.FOREST
		elif d >= 0.4 and d < 0.7:
			result = World.Biome.GRASSLAND
		elif d >= 0.7 and d < 0.9:
			result = World.Biome.GRASSLAND
		elif d >= 0.9 and d <= 1.0:
			result = World.Biome.DESERT
	elif t >= 0.6 and t < 0.8:
		if d >= 0.0 and d < 0.1:
			result = World.Biome.JUNGLE
		elif d >= 0.1 and d < 0.4:
			result = World.Biome.FOREST
		elif d >= 0.4 and d < 0.7:
			result = World.Biome.GRASSLAND
		elif d >= 0.7 and d < 0.9:
			result = World.Biome.DESERT
		elif d >= 0.9 and d <= 1.0:
			result = World.Biome.DESERT
	elif t >= 0.8 and t <= 1.0:
		if d >= 0.0 and d < 0.1:
			result = World.Biome.JUNGLE
		elif d >= 0.1 and d < 0.4:
			result = World.Biome.JUNGLE
		elif d >= 0.4 and d < 0.7:
			result = World.Biome.SAVANNAH
		elif d >= 0.7 and d < 0.9:
			result = World.Biome.SAVANNAH
		elif d >= 0.9 and d <= 1.0:
			result = World.Biome.DESERT
			
	if e >= 0.0 and e < 0.01:
		if t >= 0.9 and t <= 1.0:
			result = World.Biome.HFIL
		else:
			result = World.Biome.WATER
	elif e >= 0.01 and e < 0.2:
		result = World.Biome.WATER
	elif e >= 0.99 and e <= 1.0:
		if t >= 0.0 and t < 0.3:
			result = World.Biome.TUNDRA
		elif t >= 0.3 and t < 0.9:
			result = World.Biome.TAIGA
		elif t >= 0.9 and t <= 1.0:
			result = World.Biome.OTHERWORLD
	
	return result
