class_name Chunker

var biome_shader := preload("res://Worlds/Generator/Terrain/biome_p.gdshader") as Shader
var water_shader := preload("res://Worlds/SkyBox/water.gdshader") as Shader
var water_noise := preload("res://Worlds/SkyBox/water_noise.tres") as NoiseTexture2D
var water_ripples_noise := preload("res://Worlds/SkyBox/ripples_noise.tres") as NoiseTexture2D
var noise_texture := preload("res://Worlds/Generator/Terrain/noise_texture.tres") as NoiseTexture2D

# keys are the LOD level. 1 << (value << 1) - (sum of all previous number of chunks) represents the number of chunks for this LOD level
var lod_levels := {}
var blender: NoiseBlender

var vertex_indices := {} ## [Vector2i(coord)]int(LOD)
var chunk_rids := {} ## [Vector2i(coord)]RID(instance)
var mesh_rids := {} ## [Vector2i(coord)]RID(mesh)
var mats := {} ## [Vector2i(coord)]ShaderMaterial
var chunk_positions := {} ## [Vector2i(coord)]Vector2
var bodies := {} ## [Vector2i(coord)]StaticBody
var height_maps := {} ## [Vector2i(coord)]HeightMapShape3D

var find_bound_coords: bool = false
var min_height_position := Vector3.ZERO
var max_height_position := Vector3.ZERO

var player_position := Vector2.ZERO
var player_coord := Vector2i.ZERO

var chunk_width: float
var chunk_resolution: float

func _init(_chunk_width: float, _chunk_resolution: float, _blender: NoiseBlender, lods: Array[int]) -> void:
	var level := 0
	chunk_width = _chunk_width
	chunk_resolution = _chunk_resolution
	blender = _blender
	var res := chunk_resolution
	for value in lods:
		lod_levels[level] = value
		
		print(level, ": res: ", res, " subdiv: ", res * chunk_width)
		for row in range(-value, value):
			for col in range(-value, value):
				var coord := Vector2i(col, row)
				if vertex_indices.has(coord):
					continue
				vertex_indices[coord] = level
				var chunk := create_mesh(chunk_width, res)
				var position := convert_coord_to_position(col, row)
				chunk_rids[coord] = chunk[0]
				mesh_rids[coord] = chunk[1]
				var shader_mat := ShaderMaterial.new()
				shader_mat.shader = biome_shader
				mats[coord] = shader_mat
				chunk_positions[coord] = position
				var map := create_height_map_shape(chunk_width, res)
				height_maps[coord] = map
				if level == 0:
					var body := create_static_body(chunk_width, res, map)
					bodies[coord] = body
				update_chunk(coord, position.x, position.y, res)
				
		res *= 0.5
		level += 1
		
func deinit() -> void:
	for rid: RID in chunk_rids.values(): RenderingServer.free_rid(rid) 
	for rid: RID in mesh_rids.values(): RenderingServer.free_rid(rid) 
		
func set_world(world: World3D) -> void:
	for coord: Vector2i in chunk_rids:
		var rid := chunk_rids[coord] as RID
		RenderingServer.instance_set_scenario(rid, world.scenario)
	
func create_mesh(size: float, res: float) -> Array[RID]:
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	var subdivide := subdivisions(res)
	plane.subdivide_depth = subdivide
	plane.subdivide_width = subdivide
	var mesh := RenderingServer.mesh_create()
	RenderingServer.mesh_add_surface_from_arrays(mesh, RenderingServer.PRIMITIVE_TRIANGLES, plane.get_mesh_arrays())
	var rid := RenderingServer.instance_create()
	RenderingServer.instance_set_base(rid, mesh)
	return [rid, mesh]
	
func create_height_map_shape(size: float, res: float) -> HeightMapShape3D:
	var subdivide := subdivisions(res)
	var map := HeightMapShape3D.new()
	map.map_width = subdivide + 2
	map.map_depth = subdivide + 2
	return map
	
func create_static_body(size: float, res: float, map: HeightMapShape3D) -> StaticBody3D:
	var subdivide := subdivisions(res)
	var body := StaticBody3D.new()
	body.name = "static"
	var collision := CollisionShape3D.new()
	collision.shape = map
	collision.name = "collision"
	collision.scale = Vec3.a(size / (subdivide + 1.0))
	collision.rotate_y(PI) # maybe we can remove this
	body.add_child(collision)
	return body
	
func update_chunk(coord: Vector2i, x: float, z: float, res: float) -> void:
	var mesh := mesh_rids[coord] as RID
	var mesh_data := RenderingServer.mesh_surface_get_arrays(mesh, 0)
	var vertices := mesh_data[Mesh.ArrayType.ARRAY_VERTEX] as PackedVector3Array
	var subdivide := subdivisions(res)
	var R := chunk_width / (subdivide + 1)
	var W := subdivide + 2
	var X := x / R - W / 2.0
	var Z := z / R - W / 2.0
	X = snappedf(X, 1.0000)
	Z = snappedf(Z, 1.0000)
	
	var biome_x_texture := blender.back.biome_texture(X, Z, W, W, R, 0)
	var biome_z_texture := blender.back.biome_texture(X, Z, W, W, R, 1)

	var A := Vector3.ZERO
	var ys := blender.back.height_map(X, Z, W, W, R)
	var w := floori(W)
	var S := 0.0001
	if bodies.has(coord):
		var static_body := bodies[coord] as StaticBody3D
		var collision_shape := static_body.get_node("collision") as CollisionShape3D
		var hmap := collision_shape.shape as HeightMapShape3D
		var array := PackedFloat32Array()
		array.resize(hmap.map_data.size())
		var manhattan := maxf(absf(coord.x - player_coord.x), absf(coord.y - player_coord.y))
		var is_central := manhattan < 1
		
		for i in vertices.size():
			A = vertices[i]
			@warning_ignore("integer_division")
			var row := i / w
			var col := i % w
			var j := w * (w - row - 1) + (w - col - 1)
			A.y = snappedf(ys[j], S)
			vertices[i].y = snappedf(ys[j], S)
			array.set(i, A.y / collision_shape.scale.y)
 			
			if find_bound_coords:
				if A.y > max_height_position.y and is_central and absf(A.x) < chunk_width * 0.9 and absf(A.z) < chunk_width * 0.9:
					max_height_position = Vector3(A.x + x, A.y, A.z + z)
				if A.y < min_height_position.y:
					min_height_position = Vector3(A.x + x, A.y, A.z + z)
		
		hmap.map_data = array
	else:
		for i in vertices.size():
			A = vertices[i]
			@warning_ignore("integer_division")
			var row := i / w
			var col := i % w
			var j := w * (w - row - 1) + (w - col - 1)
			A.y = snappedf(ys[j], S)
			vertices[i].y = snappedf(ys[j], S)
			if find_bound_coords:
				if A.y < min_height_position.y:
					min_height_position = Vector3(A.x + x, A.y, A.z + z)
	
	
	RenderingServer.mesh_clear(mesh)
	mesh_data[Mesh.ArrayType.ARRAY_VERTEX] = vertices
	RenderingServer.mesh_add_surface_from_arrays(mesh, RenderingServer.PRIMITIVE_TRIANGLES, mesh_data)
	
	var mat := mats[coord] as ShaderMaterial
	mat.set_shader_parameter("texture_width", W)
	mat.set_shader_parameter("texture_depth", W)
	mat.set_shader_parameter("biome_x", biome_x_texture)
	mat.set_shader_parameter("biome_y", biome_z_texture)
	mat.set_shader_parameter("noise", noise_texture)
	mat.set_shader_parameter("locations", blender.back.get_locations())
	RenderingServer.mesh_surface_set_material(mesh, 0, mat)
	
	RenderingServer.instance_set_transform(chunk_rids[coord] as RID, T.I.translated(Vector3(x, 0, z)))
	
	
func convert_position_to_coord(x: float, z: float) -> Vector2i:
	return Vector2i(floori(x / chunk_width), floori(z / chunk_width))
	
func convert_coord_to_position(x: float, z: float) -> Vector2:
	return Vector2(x * chunk_width, z * chunk_width)

func subdivisions(res: float) -> int:
	return floori(chunk_width * res) - 1
