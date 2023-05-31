class_name Terrain

var blender: NoiseBlender
var chunk_size: float
var radius: float # number of chunks
var subdivide_percent: float
var raycast: RayCast3D
const has_medium = true

var player_coord: Vector2 = Vector2.ZERO
var player_coord_resolution: Dictionary = {}

var biome_shader = preload("res://Worlds/Generator/Terrain/biome_p.gdshader")

var loaded_chunks_location = PackedVector2Array()
var loaded_chunks = []
var medium_chunks_location = PackedVector2Array()
var medium_chunks = []

var base_coords = []

func _init(e: FastNoiseLite, d: FastNoiseLite, t: FastNoiseLite, cs: float = 256, r: float = 3):
	subdivide_percent = 1.0 / 16.0
	blender = NoiseBlender.new(e, d, t)
	chunk_size = cs
	radius = r
	
	
func init_chunks_of_size(chunks: Array, locations: PackedVector2Array, x: float, y: float, cs: float, r: float, subdivide: float) -> Array:
	set_player_coord_using_position(x, y, cs)
	var rad = int(r / 2)
	var result = []
	for w in range(-rad, rad + 1):
		for h in range(-rad, rad + 1):
			var p = Vector2((player_coord.x + w) * cs, (player_coord.y + h) * cs)
			var node = create_chunk_with_size(chunks, locations, p.x, p.y, cs, r, subdivide)
			update_chunk_with_size(node, p.x, p.y, cs, r, subdivide)
			result.append(node)
			
	return result
	
func init_chunks(x: float, y: float) -> Array:
	var result = init_chunks_of_size(loaded_chunks, loaded_chunks_location, x, y, chunk_size, radius, subdivide_percent)
	if has_medium:
		var medium = init_chunks_of_size(medium_chunks, medium_chunks_location,  x, y, chunk_size, radius * radius * 2, subdivide_percent / 1.0)
		result.append_array(medium)
	return result
	
func update_chunks_with_size(chunks: Array, locations: PackedVector2Array, x: float, y: float, cs: float, r: float, subdivide: float) -> Dictionary:
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
			if abs(origin_delta.x) <= int(radius / 2) and abs(origin_delta.y) <= int(radius / 2):
				chunks[i].position.y = -100	
			else:
				chunks[i].position.y = 0

		if should_update:
			removed_locations.append(locations[i])
			updated_locations.append(loc)
			locations[i] = loc
			update_chunk_with_size(chunks[i], loc.x, loc.y, cs, r, subdivide)
			
	return {"removed": removed_locations, "updated": updated_locations}
	
func update_chunks(x: float, y: float) -> Dictionary:
	var high = update_chunks_with_size(loaded_chunks, loaded_chunks_location, x, y, chunk_size, radius, subdivide_percent)
	var removed = high.get("removed", [])
	var updated = high.get("updated", [])
	if has_medium:
		update_chunks_with_size(medium_chunks, medium_chunks_location, x, y, chunk_size, radius * radius * 2, subdivide_percent / 1.0)
	set_player_coord_using_position(x, y, chunk_size)
	return {"removed": removed, "updated": updated}
		
func create_mesh(x: float, y: float, size: float, subdivide: float) -> Array:
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
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = 2000
	var cy: PlaneMesh = PlaneMesh.new()
	cy.size.x = 4
	cy.size.y = 4
	mm.mesh = cy
	var mmi = MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.name = "multimesh"
	
	for i in range(mm.instance_count):
		var pos = Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
		var t = Transform3D(Basis(), pos)
		mm.set_instance_transform(i, t)
		
	return [mi, mmi]
		
func create_chunk_with_size(chunks: Array, locations: PackedVector2Array, x: float, y: float, cs: float, r: float, subdivide: float) -> Node3D:
	var meshes = create_mesh(x, y, cs, subdivide)
	var mi = meshes[0]
	var mmi = meshes[1]

	var node = Node3D.new()
	node.add_child(mi)
	node.add_child(mmi)
	node.position.x = x
	node.position.z = y
	
	if r > radius:
		var coord = convert_position_to_coord(x, y, cs)
		if abs(coord.x) <= int(radius / 2) and abs(coord.y) <= int(radius / 2):
			node.position.y = -100
		else:
			node.position.y = 0

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
	var R = size / float(int(size * subdivide_percent) + 1)
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

func update_chunk_with_size(node: Node3D, x: float, y: float, cs: float, r: float, subdivide: float):
	var mi = node.get_node("mesh")
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
			var p = Vector3(x, 1000, y) + node.position
			var biome = blender.biome(p.x, p.z)
			if biome != World.Biome.GRASSLAND:
				continue
			if randf() < 0.1:
				continue
			raycast.position = p
			raycast.force_raycast_update()
			var pos = raycast.get_collision_point() 
			var t = Transform3D(Basis(), pos - node.position)
#			var pos = Vector3(x, blender.height(p.x, p.z), y)
#			var t = Transform3D(Basis(), pos)
#			t = t.rotated_local(Vector3.UP, randf_range(-PI, PI))
			mm.set_instance_transform(i, t)
			i += 1
			if i >= mm.instance_count:
				overflow = true
				break

#	for j in range(i, mm.instance_count):
#		var t = Transform3D(Basis(), Vector3(0, -1000, 0))
#		mm.set_instance_transform(j, t)
	
#	for i in range(mm.instance_count):
#		var _x = randf_range(-chunk_size / 2, chunk_size / 2)
#		var _z = randf_range(-chunk_size / 2, chunk_size / 2)
#		raycast.position = nav.position + Vector3(_x, 100, _z)
#		raycast.force_raycast_update()
#		var pos = raycast.get_collision_point() 
#		var t = Transform3D(Basis(), pos - nav.position)
#		t = t.rotated_local(Vector3.UP, randf_range(-PI, PI))
#		mm.set_instance_transform(i, t)
	

func set_player_coord_using_position(x: float, y: float, cs: float):
	player_coord = convert_position_to_coord(x, y, cs)
	player_coord_resolution[cs] = player_coord
	
func convert_position_to_coord(x: float, y: float, cs: float) -> Vector2:
	return Vector2(floorf((x + cs / 2) / cs), floorf((y + cs / 2) / cs))

func update_mesh_with_surface_tool(mi: MeshInstance3D, x: float, y: float, size: float):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var step = 8.0
	for X in range(-size / 2.0, size / 2.0, step):
		for Y in range(-size / 2.0, size / 2.0, step):
			# Top Left
			var v = Vector3(X, 0, Y)
			v.y = blender.height(v.x + x, v.z + y)
			st.set_normal(v.normalized())
			st.set_uv(Vector2((X + chunk_size / 2.0) / chunk_size, (Y + chunk_size / 2.0) / chunk_size))
			st.add_vertex(v)
			# Top Right
			v.x += step
			v.y = blender.height(v.x + x, v.z + y)
			st.set_normal(v.normalized())
			st.set_uv(Vector2((X + chunk_size / 2.0) / chunk_size, (Y + chunk_size / 2.0) / chunk_size))
			st.add_vertex(v)
			# Bottom Left
			v.x -= step
			v.z += step
			v.y = blender.height(v.x + x, v.z + y)
			st.set_normal(v.normalized())
			st.set_uv(Vector2((X + chunk_size / 2.0) / chunk_size, (Y + chunk_size / 2.0) / chunk_size))
			st.add_vertex(v)
			
			# Top Right
			v.z -= step
			v.x += step
			v.y = blender.height(v.x + x, v.z + y)
			st.set_normal(v.normalized())
			st.set_uv(Vector2((X + chunk_size / 2.0) / chunk_size, (Y + chunk_size / 2.0) / chunk_size))
			st.add_vertex(v)
			# Bottom Right
			v.z += step
			v.y = blender.height(v.x + x, v.z + y)
			st.set_normal(v.normalized())
			st.set_uv(Vector2((X + chunk_size / 2.0) / chunk_size, (Y + chunk_size / 2.0) / chunk_size))
			st.add_vertex(v)
			# Bottom Left
			v.x -= step
			v.y = blender.height(v.x + x, v.z + y)
			st.set_normal(v.normalized())
			st.set_uv(Vector2((X + chunk_size / 2.0) / chunk_size, (Y + chunk_size / 2.0) / chunk_size))
			st.add_vertex(v)
			
			
	st.generate_normals()
	st.generate_tangents()
	mi.mesh = st.commit()
	var mat = ShaderMaterial.new()
	mat.shader = biome_shader
	mat.set_shader_parameter("texture_width", size)
	mat.set_shader_parameter("texture_depth", size)
	mat.set_shader_parameter("elevation", blender.elevation_texture(x, y, size, size, 1))
	mat.set_shader_parameter("temperature", blender.temperature_texture(x, y, size, size, 1))
	mat.set_shader_parameter("dryness", blender.dryness_texture(x, y, size, size, 1))
	mi.mesh.surface_set_material(0, mat)
	var dist = max(max(abs(x), abs(y)) / size, 1)
	for n in mi.get_children():
		mi.remove_child(n)
	if dist <= 1 or true:
		mi.create_trimesh_collision()
		var body: StaticBody3D = mi.get_child(0)
		body.collision_layer = 1 << 0
