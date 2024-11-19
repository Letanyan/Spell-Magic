class_name Chunker

var back: GDChunker

var biome_shader := preload("res://Worlds/Generator/Terrain/biome_p.gdshader") as Shader
var water_shader := preload("res://Worlds/SkyBox/water.gdshader") as Shader
var water_noise := preload("res://Worlds/SkyBox/water_noise.tres") as NoiseTexture2D
var water_ripples_noise := preload("res://Worlds/SkyBox/ripples_noise.tres") as NoiseTexture2D
var noise_texture := preload("res://Worlds/Generator/Terrain/noise_texture.tres") as NoiseTexture2D

func _init(_chunk_width: float, chunk_resolution: float, blender: NoiseBlender, lods: Array[int], find_bound_coords: bool) -> void:
	back = GDChunker.new()
	back.init(_chunk_width, chunk_resolution, blender.sea_level, blender.back, lods, find_bound_coords)
	back.set_biome_shader(biome_shader)
	back.set_water_shader(water_shader)
	back.set_water_noise(water_noise)
	back.set_water_ripples_noise(water_ripples_noise)
	back.set_noise_texture(noise_texture)
	
func deinit() -> void:
	back.deinit()
	
func get_noise_scale() -> float:
	return back.get_noise_scale()
	
func get_chunk_vertices() -> PackedVector3Array:
	return back.get_chunk_vertices()
	
var track_biomes_upto_lod: int: 
	get: return back.get_track_biomes_upto_lod()
var chunk_lods: Dictionary: 
	get: return back.get_chunk_lods()
var chunk_width: float: 
	get: return back.get_chunk_width()
var player_coord: Vector2i:
	get: return back.get_player_coord()

func update_environment(x: float, z: float) -> void:
	back.update_environment(x, z)
	
func terrain_normal(x: float, z: float) -> Dictionary:
	return back.terrain_normal(x, z)
	
func update_chunks(x: float, z: float) -> void:
	back.update_chunks(x, z)
	
func init_chunks(x: float, z: float) -> void:
	back.init_chunks(x, z)
	
func update_chunks_in_queue(start: int, limit: int) -> Dictionary:
	return back.update_chunks_in_queue(start, limit)
	
func has_chunks_to_update() -> bool:
	return back.has_chunks_to_update()
	
func set_world(world: Node3D) -> void:
	back.set_world(world)

func get_max_height_position() -> Vector3:
	return back.get_max_height_position()
	
func get_min_height_position() -> Vector3:
	return back.get_min_height_position()
	
func group_spawn_points(coord: Vector2i, spacing: float) -> Dictionary:
	return back.group_spawn_points(coord, spacing)
