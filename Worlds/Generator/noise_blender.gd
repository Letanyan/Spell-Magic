class_name NoiseBlender

enum Biome { 
	WATER,
	GRASSLAND, TAIGA, FOREST, DESERT, JUNGLE, SAVANNAH, TUNDRA,
	OTHERWORLD, HFIL
}

var elevation_curve: Curve = load("res://Worlds/Generator/Terrain/terrain_elevation_curve.tres")

func color_for_biome(biome: Biome) -> Color:
	match biome:
		Biome.WATER: return Color(0, 0, 1)
		Biome.TAIGA: return Color(0, 1, 1)
		Biome.GRASSLAND: return Color(0, 1, 0)
		Biome.FOREST: return Color(0, 0.5, 0.5)
		Biome.DESERT: return Color(1, 1, 0)
		Biome.JUNGLE: return Color(0, 0.25, 0.25)
		Biome.SAVANNAH: return Color(1, 0.5, 0)
		Biome.TUNDRA: return Color(1, 1, 1)
		Biome.OTHERWORLD: return Color(0, 0, 0)
		Biome.HFIL: return Color(1, 0, 0)
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
	result.width = w
	result.height = h
	result.normalize = false
	return result

func height(x: float, y: float) -> float:
	var e = elevation.get_noise_2d(x, y) / 2 + 0.5
	var result = elevation_curve.sample(e)
	return result * 250

	
func biome(x: float, y: float) -> Biome:
	var e = elevation.get_noise_2d(x, y) / 2 + 0.5
	var d = dryness.get_noise_2d(x, y) / 2 + 0.5
	var t = temperature.get_noise_2d(x, y) / 2 + 0.5
	
	var result = Biome.OTHERWORLD
	if t >= 0.0 and t < 0.1:
		result = Biome.TAIGA
	elif t >= 0.1 and t < 0.3:
		if d >= 0.0 and d < 0.5:
			result = Biome.GRASSLAND
		elif d >= 0.5 and d <= 1.0:
			result = Biome.TAIGA
	elif t >= 0.3 and t < 0.6:
		if d >= 0.0 and d < 0.1:
			result = Biome.FOREST
		elif d >= 0.1 and d < 0.4:
			result = Biome.FOREST
		elif d >= 0.4 and d < 0.7:
			result = Biome.GRASSLAND
		elif d >= 0.7 and d < 0.9:
			result = Biome.GRASSLAND
		elif d >= 0.9 and d <= 1.0:
			result = Biome.DESERT
	elif t >= 0.6 and t < 0.8:
		if d >= 0.0 and d < 0.1:
			result = Biome.JUNGLE
		elif d >= 0.1 and d < 0.4:
			result = Biome.FOREST
		elif d >= 0.4 and d < 0.7:
			result = Biome.GRASSLAND
		elif d >= 0.7 and d < 0.9:
			result = Biome.DESERT
		elif d >= 0.9 and d <= 1.0:
			result = Biome.DESERT
	elif t >= 0.8 and t <= 1.0:
		if d >= 0.0 and d < 0.1:
			result = Biome.JUNGLE
		elif d >= 0.1 and d < 0.4:
			result = Biome.JUNGLE
		elif d >= 0.4 and d < 0.7:
			result = Biome.SAVANNAH
		elif d >= 0.7 and d < 0.9:
			result = Biome.SAVANNAH
		elif d >= 0.9 and d <= 1.0:
			result = Biome.DESERT
			
	if e >= 0.0 and e < 0.01:
		if t >= 0.9 and t <= 1.0:
			result = Biome.HFIL
		else:
			result = Biome.WATER
	elif e >= 0.01 and e < 0.2:
		result = Biome.WATER
	elif e >= 0.99 and e <= 1.0:
		if t >= 0.0 and t < 0.3:
			result = Biome.TUNDRA
		elif t >= 0.3 and t < 0.9:
			result = Biome.TAIGA
		elif t >= 0.9 and t <= 1.0:
			result = Biome.OTHERWORLD
	
	return result
