class_name Terrain

var backing: GDTerrain
var height_map_scale: float

var biome_shader := preload("res://Worlds/Generator/Terrain/biome_p.gdshader") as Shader
var water_shader := preload("res://Worlds/SkyBox/water.gdshader") as Shader
var water_noise := preload("res://Worlds/SkyBox/water_noise.tres") as NoiseTexture2D
var water_ripples_noise := preload("res://Worlds/SkyBox/ripples_noise.tres") as NoiseTexture2D
var noise_texture := preload("res://Worlds/Generator/Terrain/noise_texture.tres") as NoiseTexture2D

func _init(b: NoiseBlender, cs: float = 256, gs: float = cs * 0.5, r: float = 3, subdivide: float = 1.0 / 16.0, mcw: float = 18, find_bound_coords: bool = false) -> void:
	backing = GDTerrain.new()
	backing.init(b.back, cs, gs, r, subdivide, mcw, find_bound_coords)
	backing.set_biome_shader(biome_shader)
	backing.set_water_shader(water_shader)
	backing.set_water_noise(water_noise)
	backing.set_water_ripples_noise(water_ripples_noise)
	backing.set_sea_level(b.sea_level)
	backing.set_noise_texture(noise_texture)
	height_map_scale = cs / (cs * subdivide + 1.0)
	
func init_chunks_of_size(chunks: Array, index: int, x: float, y: float, cs: float, r: float, subdivide: float) -> Array[Node3D]:
	return backing.init_chunks_of_size(chunks, index, x, y, cs, r, subdivide)
	
func init_chunks(x: float, y: float) -> Array[Node3D]:
	return backing.init_chunks(x, y, load("res://Models/Grass/grassface.tres") as Mesh)
	
func update_chunks_with_size(chunks: Array[Node3D], index: int, x: float, y: float, cs: float, r: float, subdivide: float) -> Dictionary:
	return backing.update_chunks_with_size(chunks, index, x, y, cs, r, subdivide)
	
func update_chunks(x: float, y: float) -> Dictionary:
	# FIXME: speed up
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

func update_chunk_with_size(node: Node3D, index: int, chunk_index: int, x: float, y: float, cs: float, r: float, subdivide: float) -> void:
	return backing.update_chunk_with_size(node, index, chunk_index, x, y, cs, r, subdivide)

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

func get_chunk_vertices() -> PackedVector3Array:
	return backing.get_chunk_vertices()
	
func get_biomes_map(index: Vector2) -> PackedInt64Array:
	return backing.get_biomes_map(index)

func get_noise_scale() -> float:
	return backing.get_noise_scale()

# Vector4 return: xyz = normal at point xz, w = y value height at point xz
func height_at_position(collision: CollisionShape3D, x: float, z: float) -> Vector4:
	return backing.height_at_position(collision, x, z)
	
func terrain_normal(x: float, z: float) -> Dictionary:
	var result := {}
	backing.terrain_normal(x, z, result)
	return result
	
func get_loaded_chunks() -> Array[Node3D]:
	return backing.get_loaded_chunks()

# xyz = normal of triangle, w = y value height at x,z parameters
static func _height_at_position(collision: CollisionShape3D, x: float, z: float) -> Vector4:
	var hmap := collision.shape as HeightMapShape3D
	var scale := collision.scale.x
	
	var w := (hmap.map_width - 1) * scale
	var d := (hmap.map_depth - 1) * scale
	
	# top-left corner of map
	var base_x := collision.global_position.x - w / 2.0
	var base_z := collision.global_position.z - d / 2.0
	
	# top-left and bottom-right row and col coordinates 
	var c0 := floorf((x - base_x) / scale)
	var r0 := floorf((z - base_z) / scale)
	var c1 := ceilf((x - base_x) / scale)
	var r1 := ceilf((z - base_z) / scale)
	
	# if we are on a vertex move up/down for a coord
	if c0 == c1:
		if c1 < hmap.map_width - 1: 
			c1 += 1
		else:
			c0 -= 1
	if r0 == r1: 
		if r1 < hmap.map_depth - 1: 
			r1 += 1
		else:
			r0 -= 1
	
	# if outside bounds return NAN
	if c0 < 0 or c0 >= hmap.map_width or c1 < 0 or c1 >= hmap.map_width:
		return Vector4(NAN, NAN, NAN, NAN)
	if r0 < 0 or r0 >= hmap.map_depth or r1 < 0 or r1 >= hmap.map_depth:
		return Vector4(NAN, NAN, NAN, NAN)
	
	# convert (x, z) world coords that are passed in to the function into local space
	var tX := (x - base_x) - w / 2.0
	var tZ := (z - base_z) - d / 2.0
		
	# top-left and bottom-right coords in local space
	var x0 := c0 * scale - w / 2.0
	var x1 := c1 * scale - w / 2.0
	var z0 := r0 * scale - d / 2.0
	var z1 := r1 * scale - d / 2.0
	
	# find the 3 points that form the triangle (x,z) pas through
	var s := Vector2(tX, tZ)
	var s1 := Vector2(x0, z1)
	var s2 := Vector2(x1, z0)
	var s8 := Vector2(x0, z0)
	var s9 := Vector2(x1, z1)
	var is_low_point := s8.distance_squared_to(s) < s9.distance_squared_to(s)
	var s0 := s8 if is_low_point else s9
		
	# find the heights of the triangle
	var yB := hmap.map_data[c0 + r1 * hmap.map_width]
	var yC := hmap.map_data[c1 + r0 * hmap.map_width]
	var yA := hmap.map_data[c0 + r0 * hmap.map_width] if is_low_point else hmap.map_data[c1 + r1 * hmap.map_width]
	
	# build the final 3D triangle with scaled y's 
	var p0 := Vector3(s0.x, yA * scale, s0.y)
	var p1 := Vector3(s1.x, yB * scale, s1.y)
	var p2 := Vector3(s2.x, yC * scale, s2.y)
	
	#DebugDraw3D.draw_sphere(collision.global_position + p0, 0.2, Color.RED, 5)
	#DebugDraw3D.draw_sphere(collision.global_position + p1, 0.2, Color.RED, 5)
	#DebugDraw3D.draw_sphere(collision.global_position + p2, 0.2, Color.RED, 5)
	
	# normal for the plane of the triangle defined by the equation [dot(p-p0,N)] where p is some point
	var N := (p1 - p0).cross(p2 - p0)
	
	# ray cast line defined as a parametric equation [q0 + t * (q1 - q0)]
	var q0 := Vector3(s.x, 5000, s.y)
	var q1 := Vector3(s.x, -5000, s.y)
	
	# found by inserting the ray cast line into the plane equation
	#      dot(q0 + t*(q1-q0) - p0, N) = 0
	# =>   dot(q0-p0,N) + t dot(q1-q0,N) = 0
	# =>   t = -dot(q0-p0,N)/dot(q1-q0,N)
	var t := -(q0-p0).dot(N) / (q1-q0).dot(N)
	
	# plug t back into the parametric line equation
	var y := q0.lerp(q1, t).y
	
	N = N.normalized() * (1.0 if is_low_point else -1.0)
	return Vector4(N.x, N.y, N.z, y)
