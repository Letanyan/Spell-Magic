class_name Terrain

var blender: NoiseBlender
var chunk_size: float
var radius: float # number of chunks
var subdivide_percent: float
var raycast: RayCast3D
const has_medium = true
const has_water = false

var player_coord: Vector2 = Vector2.ZERO
var player_coord_resolution: Dictionary = {}

var biome_shader = preload("res://Worlds/Generator/Terrain/biome_p.gdshader")
var water_shader = preload("res://Worlds/SkyBox/water.gdshader")
var water_noise = preload("res://Worlds/SkyBox/water_noise.tres")

var loaded_chunks_location = PackedVector2Array()
var loaded_chunks = []
var medium_chunks_location = PackedVector2Array()
var medium_chunks = []
var water_chunks_location = PackedVector2Array()
var water_chunks = []

var base_coords = []

func _init(e: FastNoiseLite, d: FastNoiseLite, t: FastNoiseLite, cs: float = 256, r: float = 3):
	subdivide_percent = 1.0 / 16.0
	blender = NoiseBlender.new(e, d, t)
	chunk_size = cs
	radius = r
	
	
func init_chunks_of_size(chunks: Array, locations: PackedVector2Array, x: float, y: float, cs: float, r: float, subdivide: float, is_water: bool) -> Array:
	set_player_coord_using_position(x, y, cs)
	var rad = int(r / 2)
	var result = []
	for w in range(-rad, rad + 1):
		for h in range(-rad, rad + 1):
			var p = Vector2((player_coord.x + w) * cs, (player_coord.y + h) * cs)
			var node = create_chunk_with_size(chunks, locations, p.x, p.y, cs, r, subdivide, is_water)
			update_chunk_with_size(node, p.x, p.y, cs, r, subdivide, is_water)
			result.append(node)
			
	return result
	
func init_chunks(x: float, y: float) -> Array:
	var result = init_chunks_of_size(loaded_chunks, loaded_chunks_location, x, y, chunk_size, radius, subdivide_percent, false)
	if has_medium:
		var medium = init_chunks_of_size(medium_chunks, medium_chunks_location,  x, y, chunk_size, radius * radius * 2, subdivide_percent, false)
		result.append_array(medium)
	if has_water:
		var water = init_chunks_of_size(water_chunks, water_chunks_location, x, y, chunk_size, radius * radius * 2, 16.0 / chunk_size, true)
		result.append_array(water)
	return result
	
func update_chunks_with_size(chunks: Array, locations: PackedVector2Array, x: float, y: float, cs: float, r: float, subdivide: float, is_water: bool) -> Dictionary:
	var old_coord = player_coord
	var current_coord = convert_position_to_coord(x, y, cs)
	var delta = current_coord - old_coord
	if delta == Vector2.ZERO:
		return {}
	var removed_locations = []
	var updated_locations = []
	var rad = int(r / 2)
	for i in range(chunks.size()):
		var loc = locations[i]
		var should_update = false
		if delta.x == -1 and loc.x == (old_coord.x + rad) * cs:
			loc.x = (current_coord.x + -rad) * cs
			should_update = true
		if delta.x == 1 and loc.x == (old_coord.x - rad) * cs:
			loc.x = (current_coord.x + rad) * cs
			should_update = true
		if delta.y == -1 and loc.y == (old_coord.y + rad) * cs:
			loc.y = (current_coord.y + -rad) * cs
			should_update = true
		if delta.y == 1 and loc.y == (old_coord.y - rad) * cs:
			loc.y = (current_coord.y + rad) * cs
			should_update = true
			
		if r > radius:
			var origin_delta = current_coord - convert_position_to_coord(loc.x, loc.y, cs)
			if not is_water and abs(origin_delta.x) <= int(radius / 2) and abs(origin_delta.y) <= int(radius / 2):
				chunks[i].position.y = -100	
			else:
				chunks[i].position.y = 0 if not is_water else 400

		if should_update:
			removed_locations.append(locations[i])
			updated_locations.append(loc)
			locations[i] = loc
			update_chunk_with_size(chunks[i], loc.x, loc.y, cs, r, subdivide, is_water)
			
	return {"removed": removed_locations, "updated": updated_locations}
	
func update_chunks(x: float, y: float) -> Dictionary:
	var high = update_chunks_with_size(loaded_chunks, loaded_chunks_location, x, y, chunk_size, radius, subdivide_percent, false)
	var removed = high.get("removed", [])
	var updated = high.get("updated", [])
	if has_medium:
		update_chunks_with_size(medium_chunks, medium_chunks_location, x, y, chunk_size, radius * radius * 2, subdivide_percent / 1.0, false)
	if has_water:
		update_chunks_with_size(water_chunks, water_chunks_location, x, y, chunk_size, radius * radius * 2, 16.0 / chunk_size, true)
	set_player_coord_using_position(x, y, chunk_size)
	return {"removed": removed, "updated": updated}
		
func create_mesh(x: float, y: float, size: float, r: float, subdivide: float) -> Array:
	var mesh = ArrayMesh.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(size, size)
	plane.subdivide_depth = size * subdivide
	plane.subdivide_width = size * subdivide
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane.get_mesh_arrays())
	mesh.surface_set_material(0, ShaderMaterial.new())

	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.name = "mesh"
	
	if r > radius:
		return [mi]
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = 4_500
	var cy = load("res://Models/Grass/grass_01_mesh.tres")
	mm.mesh = cy
	var mmi = MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.name = "multimesh"
	
	for i in range(mm.instance_count):
		var t = Transform3D(Basis(), Vector3.ZERO)
		mm.set_instance_transform(i, t)
		
	return [mi, mmi]
	
func create_water_mesh(x: float, y: float, size: float) -> Array:
	var mesh = ArrayMesh.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(size, size)
	plane.subdivide_depth = 8
	plane.subdivide_width = 8
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane.get_mesh_arrays())
	mesh.surface_set_material(0, ShaderMaterial.new())

	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.name = "mesh"
		
	return [mi]
		
func create_chunk_with_size(chunks: Array, locations: PackedVector2Array, x: float, y: float, cs: float, r: float, subdivide: float, is_water: bool) -> Node3D:
	var node = Node3D.new()
	if not is_water:
		var meshes = create_mesh(x, y, cs, r, subdivide)
		node.add_child(meshes[0])
		if r == radius:
			node.add_child(meshes[1])
	else:
		var meshes = create_water_mesh(x, y, cs)
		node.add_child(meshes[0])

	node.position.x = x
	node.position.z = y
	
	if r > radius:
		var coord = convert_position_to_coord(x, y, cs)
		if not is_water and abs(coord.x) <= int(radius / 2) and abs(coord.y) <= int(radius / 2):
			node.position.y = -100
		else:
			node.position.y = 0 if not is_water else 400

	locations.append(Vector2(x, y))
	chunks.append(node)

	return node

func update_mesh(mi: MeshInstance3D, x: float, y: float, size: float, r: float, subdivide: float):
	var mesh = mi.mesh
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)

	if base_coords.is_empty():
		for i in range(mdt.get_vertex_count()):
			base_coords.append(mdt.get_vertex(i))

	var block = size / float(int(size * subdivide) + 1)
	var bounds = size / 2.0
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(str(x) + ":" + str(y))
	for i in range(mdt.get_vertex_count()):
		var A = mdt.get_vertex(i)
		if not (is_equal_approx(A.x, -bounds) or is_equal_approx(A.x, bounds) or is_equal_approx(A.z, -bounds) or is_equal_approx(A.z, bounds)):
			var v = Vector2(rng.randf() * 2 - 1, rng.randf() * 2 - 1).normalized() * 0.25 * block
			A.x = base_coords[i].x + v.x
			A.z = base_coords[i].z + v.y
		var Ah = blender.height(A.x + x, A.z + y)
		A.y = Ah
		mdt.set_vertex(i, A)

	mesh.clear_surfaces()
	mdt.commit_to_surface(mesh)
	var mat = mesh.surface_get_material(0)
	mat.shader = biome_shader
	var R = size / float(int(size * subdivide_percent))
	var texture_size = size / R
	mat.set_shader_parameter("texture_width", texture_size)
	mat.set_shader_parameter("texture_depth", texture_size)
	mat.set_shader_parameter("temperature", blender.temperature_texture(x / R, y / R, texture_size, texture_size, R))
	mat.set_shader_parameter("dryness", blender.dryness_texture(x / R, y / R, texture_size, texture_size, R))
	for n in mi.get_children():
		mi.remove_child(n)
	if r <= radius:
		mi.create_trimesh_collision()
		var body: StaticBody3D = mi.get_child(0)
		body.collision_layer = 1 << 0
		
func update_water_mesh(mi: MeshInstance3D, x: float, y: float, size: float, r: float, subdivide: float):
	var mesh = mi.mesh
	var mat = mesh.surface_get_material(0)
	mat.shader = water_shader
	mat.set_shader_parameter("noise", water_noise)

func update_chunk_with_size(node: Node3D, x: float, y: float, cs: float, r: float, subdivide: float, is_water: bool):
	var mi = node.get_node("mesh")
	if is_water:
		update_water_mesh(mi, x, y, cs, r, subdivide)
	else:
		update_mesh(mi, x, y, cs, r, subdivide)
	node.position.x = x
	node.position.z = y


func update_environment():
	for i in range(loaded_chunks.size()):
		update_chunk_environment(loaded_chunks[i])

func update_chunk_environment(node: Node3D):
#	place_grass(node)
	pass

func place_grass(node: Node3D):
	var mmi: MultiMeshInstance3D = node.get_node("multimesh")
	var mm: MultiMesh = mmi.multimesh
	
	var i = 0
	seed(0)
	var overflow = false
	for x in range(-chunk_size / 2, chunk_size / 2, 4):
		if overflow:
			break
		for y in range(-chunk_size / 2, chunk_size / 2, 4):
			var p = Vector3(x, 1000, y) + node.position + Vector3(randf() * 4 - 2, 0, randf() * 4 - 2)
			var biome = blender.biome(p.x, p.z)
			if biome != World.Biome.GRASSLAND:
				continue
			raycast.position = p
			raycast.force_raycast_update()
			var pos = raycast.get_collision_point() 
			var t = Transform3D(Basis(), pos - node.position)
			t = t.scaled_local(Vector3(800, 100, 800))
			t = t.rotated_local(Vector3.UP, randf() * 2 * PI)
			mm.set_instance_transform(i, t)
			i += 1
			if i >= mm.instance_count:
				overflow = true
				break
				
	mm.visible_instance_count = i
	

func set_player_coord_using_position(x: float, y: float, cs: float):
	player_coord = convert_position_to_coord(x, y, cs)
	player_coord_resolution[cs] = player_coord
	
func convert_position_to_coord(x: float, y: float, cs: float) -> Vector2:
	return Vector2(floorf((x + cs / 2) / cs), floorf((y + cs / 2) / cs))
