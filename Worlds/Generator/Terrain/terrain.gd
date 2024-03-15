class_name Terrain

var blender: NoiseBlender
var chunk_size: float
var radius: float # number of chunks
var subdivide_percent: float

var grass_size: float

const has_medium = true
const has_water = true
var has_grass := true

var ignore_physics := false

var medium_chunk_width: float 

var player_position: Vector2 = Vector2.ZERO
var player_coord: Vector2 = Vector2.ZERO

var biome_shader := preload("res://Worlds/Generator/Terrain/biome_p.gdshader")
var water_shader := preload("res://Worlds/SkyBox/water.gdshader")
var water_noise := preload("res://Worlds/SkyBox/water_noise.tres")
var water_ripples_noise := preload("res://Worlds/SkyBox/ripples_noise.tres")

var loaded_chunks_location := PackedVector2Array()
var loaded_chunks: Array[Node3D] = []
var medium_chunks_location := PackedVector2Array()
var medium_chunks: Array[Node3D] = []
var water_chunks_location := PackedVector2Array()
var water_chunks: Array[Node3D] = []

var grass_mesh: MultiMeshInstance3D
var grass_coords: PackedVector3Array = []

var base_coords: PackedVector3Array = []

func _init(d: FastNoiseLite, t: FastNoiseLite, s: int, cs: float = 256, r: float = 3, subdivide: float = 1.0 / 16.0):
	subdivide_percent = subdivide
	blender = NoiseBlender.new(d, t, s)
	chunk_size = cs
	grass_size = cs * 0.5
	radius = r
	
	
func init_chunks_of_size(chunks: Array, locations: PackedVector2Array, x: float, y: float, cs: float, r: float, subdivide: float, is_water: bool) -> Array[Node3D]:
	set_player_coord_using_position(x, y, cs)
	var rad := int(r / 2)
	var result: Array[Node3D] = []
	for w in range(-rad, rad + 1):
		for h in range(-rad, rad + 1):
			var p := Vector2((player_coord.x + w) * cs, (player_coord.y + h) * cs)
			var node := create_chunk_with_size(chunks, locations, p.x, p.y, cs, r, subdivide, is_water)
			update_chunk_with_size(node, p.x, p.y, cs, r, subdivide, is_water)
			result.append(node)
			
	return result
	
func init_chunks(x: float, y: float) -> Array[Node3D]:
	var result := init_chunks_of_size(loaded_chunks, loaded_chunks_location, x, y, chunk_size, radius, subdivide_percent, false)
	medium_chunk_width = radius * radius * 4
	if has_medium:
		var medium := init_chunks_of_size(medium_chunks, medium_chunks_location,  x, y, chunk_size, medium_chunk_width, subdivide_percent, false)
		result.append_array(medium)
	if has_water:
		var water := init_chunks_of_size(water_chunks, water_chunks_location, x, y, chunk_size, radius * radius * 2, 16.0 / chunk_size, true)
		result.append_array(water)
	if has_grass:
		var gm := MultiMesh.new()
		gm.transform_format = MultiMesh.TRANSFORM_3D
		gm.use_custom_data = true
		#gm.instance_count = 262_094
		gm.instance_count = 32_175
		gm.visible_instance_count = 0
		gm.mesh = load("res://Models/Grass/grassface.tres")
		grass_mesh = MultiMeshInstance3D.new()
		grass_mesh.multimesh = gm
		grass_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		result.append(grass_mesh)
	return result
	
func update_chunks_with_size(chunks: Array, locations: PackedVector2Array, x: float, y: float, cs: float, r: float, subdivide: float, is_water: bool) -> Dictionary:
	var old_coord := player_coord
	var current_coord := convert_position_to_coord(x, y, cs)
	var delta := current_coord - old_coord
	if delta == Vector2.ZERO:
		return {}
	var removed_locations: PackedVector2Array = []
	var updated_locations: PackedVector2Array = []
	var rad := int(r / 2)
	var should_update := false
	var loc := Vector2.ZERO
	var origin_delta := Vector2.ZERO
	var should_exclude_update: bool = false
	for i in range(chunks.size()):
		loc = locations[i]
		should_update = false
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

		should_exclude_update = false			
		if r > radius:
			origin_delta = current_coord - convert_position_to_coord(loc.x, loc.y, cs)
			if not is_water and abs(origin_delta.x) <= int(radius / 2) and abs(origin_delta.y) <= int(radius / 2):
				should_exclude_update = true
				chunks[i].position.y = -100	
			else:
				chunks[i].position.y = 0.0 if not is_water else Globals.sea_level()

		if should_update:
			removed_locations.append(locations[i])
			updated_locations.append(loc)
			locations[i] = loc
			if not should_exclude_update:
				update_chunk_with_size(chunks[i], loc.x, loc.y, cs, r, subdivide, is_water)
			
	return {"removed": removed_locations, "updated": updated_locations}
	
func update_chunks(x: float, y: float) -> Dictionary:
	var high := update_chunks_with_size(loaded_chunks, loaded_chunks_location, x, y, chunk_size, radius, subdivide_percent, false)
	var removed: PackedVector2Array = high.get("removed", [])
	var updated: PackedVector2Array = high.get("updated", [])
	if has_medium:
		update_chunks_with_size(medium_chunks, medium_chunks_location, x, y, chunk_size, medium_chunk_width, subdivide_percent / 1.0, false)
	if has_water:
		update_chunks_with_size(water_chunks, water_chunks_location, x, y, chunk_size, radius * radius * 2, 16.0 / chunk_size, true)
	set_player_coord_using_position(x, y, chunk_size)
	return {"removed": removed, "updated": updated}
		
func create_mesh(x: float, y: float, size: float, r: float, subdivide: float) -> MeshInstance3D:
	var mesh := ArrayMesh.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	var subs := int(size * subdivide)
	plane.subdivide_depth = subs
	plane.subdivide_width = subs
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane.get_mesh_arrays())
	mesh.surface_set_material(0, ShaderMaterial.new())

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.name = "mesh"
	
	if r <= radius:
		var static_body := StaticBody3D.new()
		static_body.name = "static"
		var collision_shape := CollisionShape3D.new()
		var hmap := HeightMapShape3D.new()
		hmap.map_width = subs + 2
		hmap.map_depth = subs + 2
		collision_shape.shape = hmap  # ConcavePolygonShape3D.new()
		collision_shape.name = "collision"
		collision_shape.scale = Vector3(size / (subs + 1.0), size / (subs + 1.0), size / (subs + 1.0))
		collision_shape.rotate_y(PI)
		static_body.add_child(collision_shape)
		mi.add_child(static_body)
	
	return mi
	
func create_water_mesh(x: float, y: float, size: float) -> MeshInstance3D:
	var mesh := ArrayMesh.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	plane.subdivide_depth = 8
	plane.subdivide_width = 8
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane.get_mesh_arrays())
	mesh.surface_set_material(0, ShaderMaterial.new())

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.name = "mesh"
		
	return mi
		
func create_chunk_with_size(chunks: Array, locations: PackedVector2Array, x: float, y: float, cs: float, r: float, subdivide: float, is_water: bool) -> Node3D:
	var node := Node3D.new()
	if not is_water:
		node.add_child(create_mesh(x, y, cs, r, subdivide))
	else:
		node.add_child(create_water_mesh(x, y, cs))

	node.position.x = x
	node.position.z = y
	
	if r > radius:
		var coord := convert_position_to_coord(x, y, cs)
		if not is_water and abs(coord.x) <= int(radius / 2) and abs(coord.y) <= int(radius / 2):
			node.position.y = -100
		else:
			node.position.y = 0.0 if not is_water else Globals.sea_level()

	locations.append(Vector2(x, y))
	chunks.append(node)

	return node

func update_mesh(mi: MeshInstance3D, x: float, y: float, size: float, r: float, subdivide: float):
	var mesh := mi.mesh
	var mdt := MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)
	
	var R := size / float(int(size * subdivide_percent))
	var texture_size := size / R
	var temperature_texture: NoiseTexture2D = blender.temperature_texture(x / R, y / R, texture_size, texture_size, R)
	var dryness_texture: NoiseTexture2D = blender.dryness_texture(x / R, y / R, texture_size, texture_size, R)

	if base_coords.is_empty():
		for i in range(mdt.get_vertex_count()):
			base_coords.append(mdt.get_vertex(i))

	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(x) + ":" + str(y))
	var A := Vector3.ZERO
	for i in range(mdt.get_vertex_count()):
		A = mdt.get_vertex(i)
		A.y = blender.height(A.x + x, A.z + y)
		mdt.set_vertex(i, A)
	
	if r <= radius and mi.has_node("static"):
		var static_body := mi.get_node("static")
		var collision_shape := static_body.get_node("collision")
		var hmap: HeightMapShape3D = collision_shape.shape as HeightMapShape3D
		var array := PackedFloat32Array()
		array.resize(hmap.map_data.size())
		for i in range(mdt.get_vertex_count()):
			var value := mdt.get_vertex(i)
			array.set(i, value.y / collision_shape.scale.y)
		hmap.map_data = array
		
	mesh.clear_surfaces()
	mdt.commit_to_surface(mesh)
	var mat := mesh.surface_get_material(0)
	mat.shader = biome_shader
	mat.set_shader_parameter("texture_width", texture_size)
	mat.set_shader_parameter("texture_depth", texture_size)
	mat.set_shader_parameter("temperature", temperature_texture)
	mat.set_shader_parameter("dryness", dryness_texture)
		
func update_water_mesh(mi: MeshInstance3D, x: float, y: float, size: float, r: float, subdivide: float):
	var mesh := mi.mesh
	var mat := mesh.surface_get_material(0)
	mat.shader = water_shader
	mat.set_shader_parameter("noise", water_noise)
	mat.set_shader_parameter("ripples", water_ripples_noise)

func update_chunk_with_size(node: Node3D, x: float, y: float, cs: float, r: float, subdivide: float, is_water: bool):
	var mi := node.get_node("mesh")
	if is_water:
		update_water_mesh(mi, x, y, cs, r, subdivide)
	else:
		update_mesh(mi, x, y, cs, r, subdivide)
	node.position.x = x
	node.position.z = y


func update_environment(x: float, y: float):
	var old_position := player_position
	player_position = Vector2(x, y)
	var delta := player_position - old_position
	place_grass(Vector2(grass_size * sign(delta.x) * 2, grass_size * sign(delta.y) * 2))

func update_chunk_environment(node: Node3D):
	pass

func place_grass(delta: Vector2):
	if not has_grass:
		return
	var ignore_delta := false
	if grass_coords.is_empty():
		init_grass()
		ignore_delta = true
	
	var mm: MultiMesh = grass_mesh.multimesh
	var no_hit := Ptr.new(false)
	var t := Transform3D(Basis(), Vector3.ZERO)
	t = t.scaled_local(Vector3(1, 1, 1) * 200)
	var nt := t
	var horz := false
	var vert := false
	var pos := Vector3.ZERO
	var p := Vector3.ZERO
	var whn := Vector3.ZERO
	var wh := 0.0
	var clr := Color.WHITE
	for i in range(mm.visible_instance_count):
		pos = grass_coords[i]
		horz = pos.x > player_position.x + grass_size or pos.x < player_position.x - grass_size
		vert = pos.z > player_position.y + grass_size or pos.z < player_position.y - grass_size
		
		if horz or vert or ignore_delta:
			p.x = pos.x + delta.x * (1 if horz else 0)
			p.z = pos.z + delta.y * (1 if vert else 0)
			blender.compute_biome_distances(p.x, p.z)
			no_hit.data = false
			var normal_height = Navigator.get_world_normal_height(grass_mesh.get_world_3d().direct_space_state, p.x, p.z, no_hit)
			wh = normal_height.get("position", Vector3.ZERO).y
			whn = normal_height.get("normal", Vector3.ZERO)
			if no_hit.data or wh < Globals.sea_level() or whn.distance_to(Vector3.UP) > 1 / sqrt(2.0):
				p.y = -10000
			else:
				p.y = wh
			clr = blender.color
			clr.a = p.z
			mm.set_instance_custom_data(i, clr)
			grass_coords[i] = p
			nt = t
			if no_hit.data == false and whn:
				var new_y = whn.normalized()
				nt.basis.y = new_y
				nt.basis.x = -nt.basis.z.cross(new_y)
				nt.basis = nt.basis.orthonormalized()
				nt = nt.rotated_local(Vector3.UP, randf() * 2 * PI)
				var h = blender.grass_height(blender.biome, -p.x, -p.y)
				if h == 0:
					p.y = -10000
				nt = nt.scaled_local(Vector3(1, h, 1) * 200)
			mm.set_instance_transform(i, nt.translated(p))
		
	
func init_grass():
	if not has_grass:
		return
	var mm: MultiMesh = grass_mesh.multimesh
	var i := 0
	seed(0)
	const R := 4
	for _X in range(-grass_size, grass_size + 1, R * 2):
		for y in range(-grass_size, grass_size + 1, R):
			@warning_ignore("integer_division")
			var x = _X + (1 if (y / R) % 2 == 0 else 0) * R + player_position.x
			@warning_ignore("narrowing_conversion")
			y += player_position.y
			for r in range(0, R + 1, 2):
				var a := 0.0
				while a < PI * 2:
					a += PI / 4.0 * (1.0 / (floor(r / 4.0) + 1))
					var nx := cos(a) * r + float(x)
					var ny := sin(a) * r + float(y)
					var is_top_left := Geometry2D.is_point_in_circle(Vector2(nx, ny), Vector2(x - R, y - R), R)
					var is_top_right := Geometry2D.is_point_in_circle(Vector2(nx, ny), Vector2(x + R, y - R), R)					
					if (is_top_left or is_top_right):
						continue
					var p := Vector3(nx, 1000, ny) + Vector3(randf() - 0.5, 0, randf() - 0.5)
					grass_coords.append(p)
					i += 1
					if r == 0:
						break
						
	mm.visible_instance_count = i

func set_player_coord_using_position(x: float, y: float, cs: float):
	player_coord = convert_position_to_coord(x, y, cs)
	
func convert_position_to_coord(x: float, y: float, cs: float) -> Vector2:
	return Vector2(floorf((x + cs / 2) / cs), floorf((y + cs / 2) / cs))
