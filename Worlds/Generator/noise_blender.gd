class_name NoiseBlender
extends RefCounted

const grassland_curve: Curve = preload("res://Worlds/Generator/Terrain/Elevation Curves/grassland.tres")
const forest_curve: Curve = preload("res://Worlds/Generator/Terrain/Elevation Curves/forest.tres")
const taiga_curve: Curve = preload("res://Worlds/Generator/Terrain/Elevation Curves/taiga.tres")
const desert_curve: Curve = preload("res://Worlds/Generator/Terrain/Elevation Curves/desert.tres")
const hfil_curve: Curve = preload("res://Worlds/Generator/Terrain/Elevation Curves/hfil.tres")
const jungle_curve: Curve = preload("res://Worlds/Generator/Terrain/Elevation Curves/jungle.tres")
const otherworld_curve: Curve = preload("res://Worlds/Generator/Terrain/Elevation Curves/otherworld.tres")
const savannah_curve: Curve = preload("res://Worlds/Generator/Terrain/Elevation Curves/savannah.tres")
const tundra_curve: Curve = preload("res://Worlds/Generator/Terrain/Elevation Curves/tundra.tres")

const grassland_grass_height: Curve = preload("res://Worlds/Generator/Terrain/Grass Heights/grassland.tres")
const forest_grass_height: Curve = preload("res://Worlds/Generator/Terrain/Grass Heights/forest.tres")
const taiga_grass_height: Curve = preload("res://Worlds/Generator/Terrain/Grass Heights/taiga.tres")
const desert_grass_height: Curve = preload("res://Worlds/Generator/Terrain/Grass Heights/desert.tres")
const hfil_grass_height: Curve = preload("res://Worlds/Generator/Terrain/Grass Heights/hfil.tres")
const jungle_grass_height: Curve = preload("res://Worlds/Generator/Terrain/Grass Heights/jungle.tres")
const otherworld_grass_height: Curve = preload("res://Worlds/Generator/Terrain/Grass Heights/otherworld.tres")
const savannah_grass_height: Curve = preload("res://Worlds/Generator/Terrain/Grass Heights/savannah.tres")
const tundra_grass_height: Curve = preload("res://Worlds/Generator/Terrain/Grass Heights/tundra.tres")

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
var back: GDNoiseBlender
var biome := World.Biome.GRASSLAND
var color := Color.WHITE
var total_size := 0.0
var sea_level := 0.0
var world_radius := 10000.0

func _init(version: int, s: int) -> void:
	if version == 1:
		version1(s)
	else:
		version1(s) # WARNING: This should always return the latest version
	
func version0(s: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = s
	
	back = GDNoiseBlender.new()
	back.set_elevation_mix_exp(20.0)
	
	var biome_locations := shuffle_biome_locations(rng)
	
	back.add_biome("EQACAAAAAACgQBAAbxKDOg0AAwAAAAAAgD8TAG8SgzoTAM3MzD0IAAAAAIA/AAAAAAAAAACAPwAAAEA/AAAAAAA=", s ^ hash("grassland"), grassland_curve, grassland_grass_height, biome_locations[0], biome_colors[0])
	back.add_biome("EQACAAAAAAAgQRAAAACAPw0ABQAAAAAAAEATAG8SgzsTAM3MzD0IAAAAAAAAAAAAgD8AAACgQAAAAABAAAAAAAA=", s ^ hash("taiga"), taiga_curve, taiga_grass_height, biome_locations[1], biome_colors[1])
	back.add_biome("EQAFAAAAAAAAQBAACtcjPA0AAwAAAAAAIEATAG8SgzsTAArXIzwIAAAAAIA/AOF6lD4AAADwQQAAAAA/AAAAAAA=", s ^ hash("forest"), forest_curve, forest_grass_height, biome_locations[2], biome_colors[2])
	back.add_biome("EQAFAAAAAAAAQBAAzcxMPQ0ABQAAAAAAEEETAKabxDsTAM3MzD0GAAAAAAAAAAAAgD8AKVzLQgDNzMw9AAAAAAA=", s ^ hash("desert"), desert_curve, desert_grass_height, biome_locations[3], biome_colors[3])
	back.add_biome("EADNzMw+DQADAAAAAABwQhMAbxKDOhMACtcjPAgAAAAAAD8AAAAAAAEbAAgAAAAASEI=", s ^ hash("jungle"), jungle_curve, jungle_grass_height, biome_locations[4], biome_colors[4])
	back.add_biome("EgACAAAAAAAAQBAAZmZmPw0ABQAAAAAAgEATALx0kzsTAM3MzD0IAADNzMw9AAAAAD8AAAAAQAAAAIA/AAAAAAA=", s ^ hash("savannah"), savannah_curve, savannah_grass_height, biome_locations[5], biome_colors[5])
	back.add_biome("EQACAAAA16PwPxAAbxKDOg0AAwAAAHE9yj8TAEJg5TsTAArXIzwGAABcj4pBAKRwPUAAAEAcRgBmZqY/AMP1qD8=", s ^ hash("tundra"), tundra_curve, tundra_grass_height, biome_locations[6], biome_colors[6])
	back.add_biome("EgACAAAA16OwQBAAAAAAAA0AAwAAANejAEETAG8SAzwTAM3MzD0GAAEDAHE9yj8AZmZmPwCF61FAAEjhUkEAPQoXwQ==", s ^ hash("otherworld"), otherworld_curve, otherworld_grass_height, biome_locations[7], biome_colors[7])
	back.add_biome("DQACAAAACtevQRMAbxIDPBMACtcjPAgAAQIA4XrUPwAAAIA/", s ^ hash("hfil"), hfil_curve, hfil_grass_height, biome_locations[8], biome_colors[8])
	
	back.set_biome_noise(Globals.encoded_x_noise, s ^ hash("temperatue"), 0)
	back.set_biome_noise(Globals.encoded_y_noise, s ^ hash("moisture"), 1)
	
	sea_level = rng.randf_range(-50.0, 50.0)
	world_radius = rng.randf_range(7_500.0, 10_000.0)
	
func version1(s: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = s
	
	back = GDNoiseBlender.new()
	
	var biome_locations := shuffle_biome_locations(rng)
	
	var elevation_curve := lerpf(20.0, 40.0, rng.randf())
	back.set_elevation_mix_exp(elevation_curve)
	
	back.add_biome("EQACAAAAAACgQBAAbxKDOg0AAwAAAAAAgD8TAG8SgzoTAM3MzD0IAAAAAIA/AAAAAAAAAACAPwAAAEA/AAAAAAA=", s ^ hash("grassland"), grassland_curve, grassland_grass_height, biome_locations[0], biome_colors[0])
	back.add_biome("EQACAAAAAAAgQRAAAACAPw0ABQAAAAAAAEATAG8SgzsTAM3MzD0IAAAAAAAAAAAAgD8AAACgQAAAAABAAAAAAAA=", s ^ hash("taiga"), taiga_curve, taiga_grass_height, biome_locations[1], biome_colors[1])
	back.add_biome("EQAFAAAAAAAAQBAACtcjPA0AAwAAAAAAIEATAG8SgzsTAArXIzwIAAAAAIA/AOF6lD4AAADwQQAAAAA/AAAAAAA=", s ^ hash("forest"), forest_curve, forest_grass_height, biome_locations[2], biome_colors[2])
	back.add_biome("EQAFAAAAAAAAQBAAzcxMPQ0ABQAAAAAAEEETAKabxDsTAM3MzD0GAAAAAAAAAAAAgD8AKVzLQgDNzMw9AAAAAAA=", s ^ hash("desert"), desert_curve, desert_grass_height, biome_locations[3], biome_colors[3])
	back.add_biome("EADNzMw+DQADAAAAAABwQhMAbxKDOhMACtcjPAgAAAAAAD8AAAAAAAEbAAgAAAAASEI=", s ^ hash("jungle"), jungle_curve, jungle_grass_height, biome_locations[4], biome_colors[4])
	back.add_biome("EgACAAAAAAAAQBAAZmZmPw0ABQAAAAAAgEATALx0kzsTAM3MzD0IAADNzMw9AAAAAD8AAAAAQAAAAIA/AAAAAAA=", s ^ hash("savannah"), savannah_curve, savannah_grass_height, biome_locations[5], biome_colors[5])
	back.add_biome("EQACAAAA16PwPxAAbxKDOg0AAwAAAHE9yj8TAEJg5TsTAArXIzwGAABcj4pBAKRwPUAAAEAcRgBmZqY/AMP1qD8=", s ^ hash("tundra"), tundra_curve, tundra_grass_height, biome_locations[6], biome_colors[6])
	back.add_biome("EgACAAAA16OwQBAAAAAAAA0AAwAAANejAEETAG8SAzwTAM3MzD0GAAEDAHE9yj8AZmZmPwCF61FAAEjhUkEAPQoXwQ==", s ^ hash("otherworld"), otherworld_curve, otherworld_grass_height, biome_locations[7], biome_colors[7])
	back.add_biome("DQACAAAAAACAPxMAbxIDPBMACtcjPAgAARAAAAAAPwIA4XrUPwCPwvW9AAAAgD8=", s ^ hash("hfil"), hfil_curve, hfil_grass_height, biome_locations[8], biome_colors[8])
						  
	back.set_biome_noise(Globals.encoded_x_noise, s ^ hash("temperatue"), 0)
	back.set_biome_noise(Globals.encoded_y_noise, s ^ hash("moisture"), 1)
	
	sea_level = rng.randf_range(-50.0, 50.0)
	world_radius = rng.randf_range(6_000.0, 8_000.0)
	
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


func count_biomes(positions: Array[Vector2], summary: Dictionary, should_print: bool = false) -> int:
	var sum := 0
	for pos in positions:
		back.compute_biome_map_stats(pos.x * 256, pos.y * 256, 16, 16, 16)
		var dict := back.get_biomes_map()
		sum += dict.size()
		for p in dict:
			if summary.has(p):
				summary[p] += 1
			else:
				summary[p] = 1
				
	if should_print:
		print("-----------------------------------------")
		for b: int in summary:
			summary[b] /= float(sum)
			print(World.Biome.keys()[b], ": ", summary[b])
		
	return sum
