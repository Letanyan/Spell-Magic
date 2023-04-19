class_name Terrain

var elevation: FastNoiseLite
var dryness: FastNoiseLite
var temperature: FastNoiseLite
var chunk_size: float
var radius: float # number of chunks = radius / chunk_size

var biome_mat = preload("res://Worlds/Plane/biome.tres")

var loaded_chunks_location = []
var loaded_chunks = []

func _init(e: FastNoiseLite, d: FastNoiseLite, t: FastNoiseLite, cs: float = 128, r: float = 1024):
	elevation = e
	dryness = d
	temperature = t
	chunk_size = cs
	radius = r
	
func build_chunk_at(x: float, y: float) -> NavigationRegion3D:
	var mesh = ArrayMesh.new()
	var plane = PlaneMesh.new()
	var collision_points = PackedVector3Array()
	plane.size = Vector2(chunk_size, chunk_size)
	plane.subdivide_depth = chunk_size * 0.05
	plane.subdivide_width = chunk_size * 0.05
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane.get_mesh_arrays())
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)
	
	for i in range(mdt.get_vertex_count()):
		mdt.set_vertex_normal(i, Vector3.ZERO)
	
	var red = Color(1, 0, 0)
	var blue = Color(0, 0, 1)
	
	for i in range(mdt.get_face_count()):
		var a = mdt.get_face_vertex(i, 0)
		var b = mdt.get_face_vertex(i, 1)
		var c = mdt.get_face_vertex(i, 2)
		var A = mdt.get_vertex(a)
		var B = mdt.get_vertex(b)
		var C = mdt.get_vertex(c)
		var Ah = height(x, y, A.x, A.z)
		var Bh = height(x, y, B.x, B.z)
		var Ch = height(x, y, C.x, C.z)
		A.y = Ah
		B.y = Bh
		C.y = Ch
		var face_norm = (C - A).cross(B - A).normalized()
		
		var Av = mdt.get_vertex_normal(a)
		var Bv = mdt.get_vertex_normal(b)
		var Cv = mdt.get_vertex_normal(c)
		
		mdt.set_vertex_normal(a, Av + face_norm)
		mdt.set_vertex_normal(b, Bv + face_norm)
		mdt.set_vertex_normal(c, Cv + face_norm)
		
		mdt.set_vertex(a, A)
		mdt.set_vertex(b, B)
		mdt.set_vertex(c, C)
		
		mdt.set_vertex_uv(a, Vector2.ZERO)
		mdt.set_vertex_uv(b, Vector2.ZERO)
		mdt.set_vertex_uv(c, Vector2.ZERO)
			
	for i in range(mdt.get_vertex_count()):
		var norm = mdt.get_vertex_normal(i).normalized()
		collision_points.append(mdt.get_vertex(i))
		mdt.set_vertex_normal(i, norm)
			
	mesh.clear_surfaces()
	mdt.commit_to_surface(mesh)
	var mi = MeshInstance3D.new()
	#var mat = StandardMaterial3D.new()
	#mat.albedo_color = Color(1, 0, 0)
	biome_mat.set_shader_parameter("texture_width", chunk_size)
	biome_mat.set_shader_parameter("texture_depth", chunk_size)
	biome_mat.set_shader_parameter("elevation", noise_texture(elevation, x, y, chunk_size, chunk_size))
	biome_mat.set_shader_parameter("temperature", noise_texture(temperature, x, y, chunk_size, chunk_size))
	biome_mat.set_shader_parameter("dryness", noise_texture(dryness, x, y, chunk_size, chunk_size))
	mesh.surface_set_material(0, biome_mat)
	mi.mesh = mesh
	mi.create_trimesh_collision()
	
	var nav_mesh = NavigationMesh.new()
	nav_mesh.create_from_mesh(mesh)
	var nav = NavigationRegion3D.new()
	nav.navigation_mesh = nav_mesh
	nav.add_child(mi)
	nav.bake_navigation_mesh(true)
	nav.position.x = x
	nav.position.z = y
	
	loaded_chunks_location.append(Vector2(x, y))
	loaded_chunks.append(nav)
	
	return nav
	
func find_chunks_to_load_from_position(x: float, y: float, should_unload_chunks: bool = true) -> Array:
	var chunk_count = radius / chunk_size
	var ox = floorf(x / chunk_size)
	var oy = floorf(y / chunk_size)
	
	var result = []
	var already_loaded = []
	var rad = chunk_count / 2
	for w in range(-rad, rad + 1):
		for h in range(-rad, rad + 1):
			var p = Vector2((ox + w) * chunk_size, (oy + h) * chunk_size)
			if loaded_chunks.find(p) == -1:
				var nav = build_chunk_at(p.x, p.y)
				result.append(nav)
			elif should_unload_chunks:
				already_loaded.append(p)
	
	if should_unload_chunks:
		for p in already_loaded:
			var loc = loaded_chunks_location.find(p)
			if loc != -1:
				var nav = loaded_chunks[loc]
				nav.queue_free()
				loaded_chunks_location.remove_at(loc)	
				loaded_chunks.remove_at(loc)
	
	return result
		
	
func noise_texture(noise: FastNoiseLite, x: int, y: int, w: int, h: int) -> NoiseTexture2D:
	var result = NoiseTexture2D.new()
	result.noise = noise
	result.noise.offset.x = x
	result.noise.offset.y = y
	result.width = w
	result.height = h
	result.seamless = true
	return result
	
func height(X: float, Y: float, x: float, y: float) -> float:
	elevation.offset.x = X
	elevation.offset.y = Y
	return elevation.get_noise_2d(x, y) * 50.0
