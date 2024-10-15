class_name Terrain

var backing: GDTerrain

var biome_shader := preload("res://Worlds/Generator/Terrain/biome_p.gdshader") as Shader
var water_shader := preload("res://Worlds/SkyBox/water.gdshader") as Shader
var water_noise := preload("res://Worlds/SkyBox/water_noise.tres") as NoiseTexture2D
var water_ripples_noise := preload("res://Worlds/SkyBox/ripples_noise.tres") as NoiseTexture2D
var noise_texture := preload("res://Worlds/Generator/Terrain/noise_texture.tres") as NoiseTexture2D

func _init(b: NoiseBlender, cs: float = 256, gs: float = cs * 0.5, r: float = 3, subdivide: float = 1.0 / 16.0, mcw: float = 18) -> void:
	backing = GDTerrain.new()
	backing.init(b.back, cs, gs, r, subdivide, mcw)
	backing.set_biome_shader(biome_shader)
	backing.set_water_shader(water_shader)
	backing.set_water_noise(water_noise)
	backing.set_water_ripples_noise(water_ripples_noise)
	backing.set_sea_level(Globals.sea_level())
	backing.set_noise_texture(noise_texture)
	
func init_chunks_of_size(chunks: Array, locations: PackedVector2Array, x: float, y: float, cs: float, r: float, subdivide: float, is_water: bool) -> Array[Node3D]:
	return backing.init_chunks_of_size(chunks, locations, x, y, cs, r, subdivide, is_water)
	
func init_chunks(x: float, y: float) -> Array[Node3D]:
	return backing.init_chunks(x, y, load("res://Models/Grass/grassface.tres") as Mesh)
	
func update_chunks_with_size(chunks: Array[Node3D], index: int, x: float, y: float, cs: float, r: float, subdivide: float, is_water: bool) -> Dictionary:
	return backing.update_chunks_with_size(chunks, index, x, y, cs, r, subdivide, is_water)
	
func update_chunks(x: float, y: float) -> Dictionary:
	return backing.update_chunks(x, y)
		
func create_mesh(x: float, y: float, size: float, r: float, subdivide: float) -> MeshInstance3D:
	return backing.create_mesh(x, y, size, r, subdivide)
	
func create_water_mesh(x: float, y: float, size: float) -> MeshInstance3D:
	return backing.create_water_mesh(x, y, size)
		
func create_chunk_with_size(chunks: Array, locations: PackedVector2Array, x: float, y: float, cs: float, r: float, subdivide: float, is_water: bool) -> Node3D:
	return backing.create_chunk_with_size(chunks, locations, x, y, cs, r, subdivide, is_water)

func update_mesh(mi: MeshInstance3D, x: float, y: float, size: float, r: float, subdivide: float) -> void:
	return backing.update_mesh(mi, x, y, size, r, subdivide)
		
func update_water_mesh(mi: MeshInstance3D, x: float, y: float, size: float, r: float, subdivide: float) -> void:
	return backing.update_water_mesh(mi, x, y, size, r, subdivide)

func update_chunk_with_size(node: Node3D, x: float, y: float, cs: float, r: float, subdivide: float, is_water: bool) -> void:
	return backing.update_chunk_with_size(node, x, y, cs, r, subdivide, is_water)

func update_environment(x: float, y: float) -> void:
	return backing.update_environment(x, y)

func update_chunk_environment(node: Node3D) -> void:
	backing.update_chunk_environment(node)

func place_grass(delta: Vector2) -> void:
	backing.place_grass(delta)
	
func init_grass() -> void:
	backing.init_grass()

func hide_water(y: float, force_update: bool) -> void:
	push_warning("hide_water does nothing. Uncomment the below line for the effect to take place.")
	#backing.hide_water(y, force_update)

func set_player_coord_using_position(x: float, y: float, cs: float) -> void:
	backing.set_player_coord_using_position(x, y, cs)
	
func convert_position_to_coord(x: float, y: float, cs: float) -> Vector2:
	return backing.convert_position_to_coord(x, y, cs)
