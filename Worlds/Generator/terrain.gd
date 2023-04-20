class_name Terrain

var elevation: FastNoiseLite
var dryness: FastNoiseLite
var temperature: FastNoiseLite
var chunk_size: float
var radius: float # number of chunks = radius / chunk_size

var player_coord: Vector2

#var biome_mat = preload("res://Worlds/Plane/biome.tres")
var biome_shader = preload("res://Worlds/Demo/height.gdshader")

var loaded_chunks_location = PackedVector2Array()
var loaded_chunks = []

## r must be an even multiple of cs. `r = cs * 2n for some integer n`
func _init(e: FastNoiseLite, d: FastNoiseLite, t: FastNoiseLite, cs: float = 128, r: float = 1024):
	elevation = e
	dryness = d
	temperature = t
	chunk_size = cs
	radius = r
	
func build_chunk_at(x: float, y: float) -> NavigationRegion3D:
	var full_time = Time.get_ticks_msec()
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

	var h_time = Time.get_ticks_msec()
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
	print("vertex height build: ", (Time.get_ticks_msec() - h_time) / 1000.0)

	for i in range(mdt.get_vertex_count()):
		var norm = mdt.get_vertex_normal(i).normalized()
		collision_points.append(mdt.get_vertex(i))
		mdt.set_vertex_normal(i, norm)

	mesh.clear_surfaces()
	mdt.commit_to_surface(mesh)
	var mi = MeshInstance3D.new()
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = biome_shader
	mat.set_shader_parameter("texture_width", chunk_size)
	mat.set_shader_parameter("texture_depth", chunk_size)
	mat.set_shader_parameter("texture_x", chunk_size / 2 - x)
	mat.set_shader_parameter("texture_y", chunk_size / 2 - y)
	mat.set_shader_parameter("elevation", noise_texture(elevation, x, y, chunk_size, chunk_size))
	mat.set_shader_parameter("temperature", noise_texture(temperature, x, y, chunk_size, chunk_size))
	mat.set_shader_parameter("dryness", noise_texture(dryness, x, y, chunk_size, chunk_size))
	mesh.surface_set_material(0, mat)
	mi.mesh = mesh
	var s_time = Time.get_ticks_msec()
	mi.create_trimesh_collision()
	print("surfaces build: ", (Time.get_ticks_msec() - s_time) / 1000.0)

	var nav_mesh = NavigationMesh.new()
	nav_mesh.create_from_mesh(mesh)
	var nav = NavigationRegion3D.new()
	nav.navigation_mesh = nav_mesh
#	nav.bake_navigation_mesh(true)
	nav.add_child(mi)
	nav.position.x = x
	nav.position.z = y

	loaded_chunks_location.append(Vector2(x, y))
	loaded_chunks.append(nav)

	print("Full time: ", (Time.get_ticks_msec() - full_time) / 1000.0)
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
			if loaded_chunks_location.find(p) == -1:
#				var nav = build_chunk_at(p.x, p.y)
				var nav = create_chunk(p.x, p.y)
				update_chunk(nav, p.x, p.y)
				result.append(nav)
			elif should_unload_chunks:
				already_loaded.append(p)
		
	if should_unload_chunks:
		var to_free = []
		for p in loaded_chunks_location:
			var loc = already_loaded.find(p)
			if loc != -1:
				var i = loaded_chunks_location.find(p)
				loaded_chunks.remove_at(i)
				loaded_chunks_location.remove_at(i)
	
	return result
	
func init_chunks(x: float, y: float) -> Array:
	var chunk_count = radius / chunk_size
	set_player_coord_using_position(x, y)
	var rad = chunk_count / 2
	var result = []
	for w in range(-rad, rad + 1):
		for h in range(-rad, rad + 1):
			var p = Vector2((player_coord.x + w) * chunk_size, (player_coord.y + h) * chunk_size)
			var nav = create_chunk(p.x, p.y)
			update_chunk(nav, p.x, p.y)
			result.append(nav)
	return result
	
func update_chunks(x: float, y: float):
	var chunk_count = radius / chunk_size
	var old_coord = player_coord
	set_player_coord_using_position(x, y)
	var delta = player_coord - old_coord
	if delta == Vector2.ZERO:
		return
	var rad = chunk_count / 2
	for i in range(loaded_chunks.size()):
		var loc = loaded_chunks_location[i]
		var should_update = false
		if delta.x == -1 and loc.x == (old_coord.x + rad) * chunk_size:
			loc.x = (player_coord.x + -rad) * chunk_size
			should_update = true
		if delta.x == 1 and loc.x == (old_coord.x - rad) * chunk_size:
			loc.x = (player_coord.x + rad) * chunk_size
			should_update = true
		if delta.y == -1 and loc.y == (old_coord.y + rad) * chunk_size:
			loc.y = (player_coord.y + -rad) * chunk_size
			should_update = true
		if delta.y == 1 and loc.y == (old_coord.y - rad) * chunk_size:
			loc.y = (player_coord.y + rad) * chunk_size
			should_update = true
			
		if should_update:
			loaded_chunks_location[i] = loc
			update_chunk(loaded_chunks[i], loc.x, loc.y)
			
	for i in range(loaded_chunks.size()):
		var loc = loaded_chunks_location[i]
		var chunk = loaded_chunks[i]
		
func create_chunk(x: float, y: float) -> NavigationRegion3D:
	var mesh = ArrayMesh.new()
	var plane = PlaneMesh.new()
	var collision_points = PackedVector3Array()
	plane.size = Vector2(chunk_size, chunk_size)
	plane.subdivide_depth = chunk_size * 0.05
	plane.subdivide_width = chunk_size * 0.05
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane.get_mesh_arrays())
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)

	mesh.clear_surfaces()
	mdt.commit_to_surface(mesh)
	var mi = MeshInstance3D.new()
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = biome_shader
	mat.set_shader_parameter("texture_x", chunk_size / 2 - x)
	mat.set_shader_parameter("texture_y", chunk_size / 2 - y)
	mat.set_shader_parameter("texture_width", chunk_size)
	mat.set_shader_parameter("texture_depth", chunk_size)
	mesh.surface_set_material(0, mat)
	mi.mesh = mesh

	var nav = NavigationRegion3D.new()
	mi.name = "mesh"
	nav.add_child(mi)
	nav.position.x = x
	nav.position.z = y

	loaded_chunks_location.append(Vector2(x, y))
	loaded_chunks.append(nav)

	return nav

func update_chunk(nav: NavigationRegion3D, x: float, y: float):
	var mi: = nav.get_node("mesh")
	var mesh = mi.mesh
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)

	for i in range(mdt.get_vertex_count()):
		mdt.set_vertex_normal(i, Vector3.ZERO)

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
		mdt.set_vertex_normal(i, norm)

	mesh.clear_surfaces()
	mdt.commit_to_surface(mesh)
#	var mat = mesh.surface_get_material(0)
	var mat = ShaderMaterial.new()
	mat.shader = biome_shader
	mat.set_shader_parameter("texture_width", chunk_size)
	mat.set_shader_parameter("texture_depth", chunk_size)
	mat.set_shader_parameter("texture_x", chunk_size / 2 - x)
	mat.set_shader_parameter("texture_y", chunk_size / 2 - y)
	mat.set_shader_parameter("elevation", noise_texture(elevation, x, y, chunk_size, chunk_size))
	mat.set_shader_parameter("temperature", noise_texture(temperature, x, y, chunk_size, chunk_size))
	mat.set_shader_parameter("dryness", noise_texture(dryness, x, y, chunk_size, chunk_size))
	mesh.surface_set_material(0, mat)
#	mi.mesh = mesh
	for n in mi.get_children():
		mi.remove_child(n)
	mi.create_trimesh_collision()
	
	var nav_mesh = NavigationMesh.new()
	nav_mesh.create_from_mesh(mesh)
	nav.navigation_mesh = nav_mesh
	nav.position.x = x
	nav.position.z = y

	return nav
	
func noise_texture(noise: FastNoiseLite, x: int, y: int, w: int, h: int) -> NoiseTexture2D:
	var result = NoiseTexture2D.new()
	result.noise = FastNoiseLite.new()
	result.noise.noise_type = noise.noise_type
	result.noise.seed = noise.seed
	result.noise.frequency = noise.frequency
	
	result.noise.fractal_type = noise.fractal_type
	result.noise.fractal_octaves = noise.fractal_octaves
	result.noise.fractal_lacunarity = noise.fractal_lacunarity
	result.noise.fractal_gain = noise.fractal_gain
	result.noise.fractal_weighted_strength = noise.fractal_weighted_strength
	
	result.noise.domain_warp_enabled = noise.domain_warp_enabled
	result.noise.domain_warp_type = noise.domain_warp_type
	result.noise.domain_warp_amplitude = noise.domain_warp_amplitude
	result.noise.domain_warp_frequency = noise.domain_warp_frequency
	result.noise.domain_warp_fractal_type = noise.domain_warp_fractal_type
	result.noise.domain_warp_fractal_octaves = noise.domain_warp_fractal_octaves
	result.noise.domain_warp_fractal_lacunarity = noise.domain_warp_fractal_lacunarity
	result.noise.domain_warp_fractal_gain = noise.domain_warp_fractal_gain
	
	result.noise.cellular_return_type = noise.cellular_return_type
	result.noise.cellular_distance_function = noise.cellular_distance_function
	result.noise.cellular_jitter = noise.cellular_jitter
	
	result.noise.offset.x = x
	result.noise.offset.y = y
	result.width = w
	result.height = h
#	result.seamless = true
	result.normalize = false
	result.in_3d_space = true
	return result
	
func height(X: float, Y: float, x: float, y: float) -> float:
	elevation.offset.x = X
	elevation.offset.y = Y
	return elevation.get_noise_2d(x, y) ** 2 * 250.0

func set_player_coord_using_position(x: float, y: float):
	player_coord = Vector2(floorf((x + chunk_size / 2) / chunk_size), floorf((y + chunk_size / 2) / chunk_size))
	
