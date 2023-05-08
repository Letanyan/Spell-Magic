class_name Terrain

var blender: NoiseBlender
var chunk_size: float
var radius: float # number of chunks = radius / chunk_size
var raycast: RayCast3D

var player_coord: Vector2 = Vector2.ZERO

var grass_texture = preload("res://Worlds/Generator/Terrain/grass.tres")
var biome_shader = preload("res://Worlds/Generator/Terrain/biome.gdshader")

var loaded_chunks_location = PackedVector2Array()
var loaded_chunks = []
var medium_map: MeshInstance3D = null
var large_map: MeshInstance3D = null

## r must be an even multiple of cs. `r = cs * 2n for some integer n`
func _init(e: FastNoiseLite, d: FastNoiseLite, t: FastNoiseLite, cs: float = 256, r: float = 1024):
	blender = NoiseBlender.new(e, d, t)
	chunk_size = cs
	radius = r
	
#	var large_chunk = r * 4
#	large_map = create_mesh(0, 0, large_chunk, 0.0005)[0]
#	update_mesh(large_map, 0, 0, large_chunk)
#	large_map.position = Vector3(0, 0, 0)
#	large_map.visible = false
	
#	var medium_chunk = r * 2
#	medium_map = create_mesh(0, 0, medium_chunk, 0.005)[0]
#	update_mesh(medium_map, 0, 0, medium_chunk)
#	medium_map.position = Vector3(0, 0, 0)
#	medium_map.visible = false
	
func switch_detail():
	if large_map.visible:
		large_map.visible = false
		medium_map.visible = true
		for c in loaded_chunks:
			c.visible = false
	elif medium_map.visible:
		large_map.visible = false
		medium_map.visible = false
		for c in loaded_chunks:
			c.visible = true
	else:
		large_map.visible = true
		medium_map.visible = false
		for c in loaded_chunks:
			c.visible = false
	
	
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
	
func update_chunks(x: float, y: float) -> Dictionary:
	var chunk_count = radius / chunk_size
	var old_coord = player_coord
	set_player_coord_using_position(x, y)
	var delta = player_coord - old_coord
	if delta == Vector2.ZERO:
		return {}
	var removed_locations = []
	var updated_locations = []
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
			removed_locations.append(loaded_chunks_location[i])
			updated_locations.append(loc)
			loaded_chunks_location[i] = loc
			update_chunk(loaded_chunks[i], loc.x, loc.y)
			
	return {"removed": removed_locations, "updated": updated_locations}
		
func create_mesh(x: float, y: float, size: float, subdivide: float = 0.05) -> Array:
	var mesh = ArrayMesh.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(size, size)
#	var dist = max(max(abs(x), abs(y)) / chunk_size, 1)
	var dist = 1
	plane.subdivide_depth = size * subdivide
	plane.subdivide_width = size * subdivide
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane.get_mesh_arrays())
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)

	mesh.clear_surfaces()
	mdt.commit_to_surface(mesh)
	var mi = MeshInstance3D.new()
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = biome_shader
	mat.set_shader_parameter("texture_width", size)
	mat.set_shader_parameter("texture_depth", size)
	mesh.surface_set_material(0, mat)
	mi.mesh = mesh
	mi.name = "mesh"
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = 2000
	var cy: PlaneMesh = PlaneMesh.new()
	cy.size.x = 4
	cy.size.y = 4
#	cy.orientation = PlaneMesh.FACE_X
	mm.mesh = cy
	var mmi = MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.name = "multimesh"
	
	for i in range(mm.instance_count):
		var pos = Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
		var t = Transform3D(Basis(), pos)
		mm.set_instance_transform(i, t)
		
	return [mi, mmi]
		
func create_chunk(x: float, y: float) -> NavigationRegion3D:
	var meshes = create_mesh(x, y, chunk_size)
	var mi = meshes[0]
	var mmi = meshes[1]

	var nav = NavigationRegion3D.new()
	nav.add_child(mi)
	nav.add_child(mmi)
	nav.position.x = x
	nav.position.z = y

	loaded_chunks_location.append(Vector2(x, y))
	loaded_chunks.append(nav)

	return nav

func update_mesh(mi: MeshInstance3D, x: float, y: float, size: float):
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
		var Ah = blender.height(A.x + x, A.z + y)
		var Bh = blender.height(B.x + x, B.z + y)
		var Ch = blender.height(C.x + x, C.z + y)
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

	for i in range(mdt.get_vertex_count()):
		var norm = mdt.get_vertex_normal(i).normalized()
		mdt.set_vertex_normal(i, norm)

	mesh.clear_surfaces()
	mdt.commit_to_surface(mesh)
#	var mat = mesh.surface_get_material(0)
	var mat = ShaderMaterial.new()
	mat.shader = biome_shader
	mat.set_shader_parameter("texture_width", size)
	mat.set_shader_parameter("texture_depth", size)
	mat.set_shader_parameter("elevation", blender.elevation_texture(x, y, size, size))
	mat.set_shader_parameter("temperature", blender.temperature_texture(x, y, size, size))
	mat.set_shader_parameter("dryness", blender.dryness_texture(x, y, size, size))
	mat.set_shader_parameter("grass", grass_texture)
	mesh.surface_set_material(0, mat)
#	mi.mesh = mesh
	var dist = max(max(abs(x), abs(y)) / size, 1)
	for n in mi.get_children():
		mi.remove_child(n)
	if dist <= 1 or true:
		mi.create_trimesh_collision()
		var body: StaticBody3D = mi.get_child(0)
		body.collision_layer = 0b1

func update_chunk(nav: NavigationRegion3D, x: float, y: float):
	var mi = nav.get_node("mesh")
	var mesh = mi.mesh
	update_mesh(mi, x, y, chunk_size)
				
	var nav_mesh = NavigationMesh.new()
	nav_mesh.create_from_mesh(mesh)
	nav.navigation_mesh = nav_mesh
	nav.position.x = x
	nav.position.z = y
#	nav.position.y = max(abs(x), abs(y)) / chunk_size * 8

	return nav

func update_environment():
	for i in range(loaded_chunks.size()):
		update_chunk_environment(loaded_chunks[i])

func update_chunk_environment(nav: NavigationRegion3D):
#	place_grass(nav)
	pass

func place_grass(nav: NavigationRegion3D):
	var mmi: MultiMeshInstance3D = nav.get_node("multimesh")
	var mm: MultiMesh = mmi.multimesh
	
	var i = 0
	seed(0)
	var overflow = false
	for x in range(-chunk_size / 2, chunk_size / 2, 4):
		if overflow:
			break
		for y in range(-chunk_size / 2, chunk_size / 2, 4):
			var p = Vector3(x, 1000, y) + nav.position
			var biome = blender.biome(p.x, p.z)
			if biome != NoiseBlender.Biome.GRASSLAND:
				continue
			if randf() < 0.1:
				continue
			raycast.position = p
			raycast.force_raycast_update()
			var pos = raycast.get_collision_point() 
			var t = Transform3D(Basis(), pos - nav.position)
#			var pos = Vector3(x, blender.height(p.x, p.z), y)
#			var t = Transform3D(Basis(), pos)
#			t = t.rotated_local(Vector3.UP, randf_range(-PI, PI))
			mm.set_instance_transform(i, t)
			i += 1
			if i > mm.instance_count:
				overflow = true
				break

	for j in range(i, mm.instance_count):
		var t = Transform3D(Basis(), Vector3(0, -1000, 0))
		mm.set_instance_transform(j, t)
	
#	for i in range(mm.instance_count):
#		var _x = randf_range(-chunk_size / 2, chunk_size / 2)
#		var _z = randf_range(-chunk_size / 2, chunk_size / 2)
#		raycast.position = nav.position + Vector3(_x, 100, _z)
#		raycast.force_raycast_update()
#		var pos = raycast.get_collision_point() 
#		var t = Transform3D(Basis(), pos - nav.position)
#		t = t.rotated_local(Vector3.UP, randf_range(-PI, PI))
#		mm.set_instance_transform(i, t)
	

func set_player_coord_using_position(x: float, y: float):
	player_coord = convert_position_to_coord(x, y)
	
func convert_position_to_coord(x: float, y: float) -> Vector2:
	return Vector2(floorf((x + chunk_size / 2) / chunk_size), floorf((y + chunk_size / 2) / chunk_size))
