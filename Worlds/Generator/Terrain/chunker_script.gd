class_name ChunkerScript

var biome_shader := preload("res://Worlds/Generator/Terrain/biome_p.gdshader") as Shader
var water_shader := preload("res://Worlds/SkyBox/water.gdshader") as Shader
var water_noise := preload("res://Worlds/SkyBox/water_noise.tres") as NoiseTexture2D
var water_ripples_noise := preload("res://Worlds/SkyBox/ripples_noise.tres") as NoiseTexture2D
var noise_texture := preload("res://Worlds/Generator/Terrain/noise_texture.tres") as NoiseTexture2D

# keys are the LOD level. 1 << (value << 1) - (sum of all previous number of chunks) represents the number of chunks for this LOD level
var lod_levels: Array[int]
var track_biomes_upto_lod: int # lods below will have full hi-res biome maps
var blender: NoiseBlender

var chunk_lods := {} ## [Vector2i(coord)]int(LOD)
var chunk_rids := {} ## [Vector2i(coord)]RID(instance)
var mesh_rids := {} ## [Vector2i(coord)]RID(mesh)
var mats := {} ## [Vector2i(coord)]ShaderMaterial
var water_chunk_rids := {} ## [Vector2i(coord)]RID(instance)
var water_mesh_rids := {} ## [Vector2i(coord)]RID(mesh)
var water_mats := {} ## [Vector2i(coord)]ShaderMaterial
var chunk_positions := {} ## [Vector2i(coord)]Vector2
var bodies := {} ## [Vector2i(coord)]StaticBody
var height_maps := {} ## [Vector2i(coord)]HeightMapShape3D
var biome_maps := {} ## [Vector2i(coord)]PackedInt32Array(biome)

var find_bound_coords: bool
var min_height_position: Vector3
var max_height_position: Vector3
var chunk_vertices: PackedVector3Array

var player_coord: Vector2i
var chunk_update_queue: RingBuffer

var chunk_width: float
var chunk_resolution: float
var sea_level: float

func _init(_chunk_width: float, _chunk_resolution: float, _sea_level: float, _blender: NoiseBlender, lods: Array[int], _find_bound_coords: bool) -> void:
	chunk_width = _chunk_width
	chunk_resolution = _chunk_resolution
	sea_level = _sea_level
	lod_levels = lods
	blender = _blender
	find_bound_coords = _find_bound_coords
	track_biomes_upto_lod = 2
	
	min_height_position = Vector3.ZERO
	max_height_position = Vector3.ZERO
	chunk_vertices = PackedVector3Array([])
	player_coord = Vector2i.ZERO
	chunk_update_queue = RingBuffer.new()
	
func init_chunks(x: float, z: float) -> void:
	player_coord = convert_position_to_coord(x, z)
	var level := 0
	var res := chunk_resolution
	for value in lod_levels:
		print(level, ": res: ", res, " subdiv: ", res * chunk_width, "(", -value, ", ", value - 1, ")")
		for row in range(-value + player_coord.y, value + player_coord.y):
			for col in range(-value + player_coord.x, value + player_coord.x):
				var coord := Vector2i(col, row)
				if chunk_lods.has(coord):
					continue
				chunk_lods[coord] = level
				var chunk := create_mesh(chunk_width, res)
				var position := convert_coord_to_position(col, row)
				chunk_rids[coord] = chunk[0]
				mesh_rids[coord] = chunk[1]
				var shader_mat := ShaderMaterial.new()
				shader_mat.shader = biome_shader
				mats[coord] = shader_mat
				
				var water_chunk := create_mesh(chunk_width, res * 0.5)
				water_chunk_rids[coord] = water_chunk[0]
				water_mesh_rids[coord] = water_chunk[1]
				var water_shader_mat := ShaderMaterial.new()
				water_shader_mat.shader = water_shader
				water_mats[coord] = water_shader_mat
				water_shader_mat.set_shader_parameter("noise", water_noise)
				water_shader_mat.set_shader_parameter("water_ripples_noise", water_ripples_noise)
				RenderingServer.mesh_surface_set_material(water_chunk[1], 0, water_shader_mat)
				
				chunk_positions[coord] = position
				var map := create_height_map_shape(chunk_width, chunk_resolution if level < track_biomes_upto_lod else res)
				height_maps[coord] = map
				if level == 0:
					var body := create_static_body(chunk_width, chunk_resolution, map)
					bodies[coord] = body
				update_chunk(coord, coord, res, player_coord)
				update_water_chunk(coord, coord)
				
		res *= 0.5
		level += 1
		
func deinit() -> void:
	for rid: RID in chunk_rids.values(): RenderingServer.free_rid(rid) 
	for rid: RID in mesh_rids.values(): RenderingServer.free_rid(rid) 
	for rid: RID in water_chunk_rids.values(): RenderingServer.free_rid(rid) 
	for rid: RID in water_mesh_rids.values(): RenderingServer.free_rid(rid) 
		
func set_world(world: Node3D) -> void:
	for coord: Vector2i in chunk_rids:
		var rid := chunk_rids[coord] as RID
		RenderingServer.instance_set_scenario(rid, world.get_world_3d().scenario)
		var wid := water_chunk_rids[coord] as RID
		RenderingServer.instance_set_scenario(wid, world.get_world_3d().scenario)
		if bodies.has(coord):
			var body := bodies[coord] as StaticBody3D
			world.add_child(body)
	
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
	
func update_chunk(coord: Vector2i, new_coord: Vector2i, res: float, saved_player_coord: Vector2i) -> void:
	var mesh := mesh_rids[coord] as RID
	var mesh_data := RenderingServer.mesh_surface_get_arrays(mesh, 0)
	var vertices := mesh_data[Mesh.ArrayType.ARRAY_VERTEX] as PackedVector3Array
	if chunk_vertices.is_empty() and chunk_lods[coord] == 0:
		for i in vertices.size():
			chunk_vertices.append(vertices[i])
	var subdivide := subdivisions(res)
	var R := chunk_width / (subdivide + 1)
	var W := subdivide + 2
	var x := new_coord.x * chunk_width
	var z := new_coord.y * chunk_width
	var X := x / R - W / 2.0
	var Z := z / R - W / 2.0
	X = snappedf(X, 1.0000)
	Z = snappedf(Z, 1.0000)
	
	var biome_x_texture := blender.back.biome_texture(X, Z, W, W, R, 0)
	var biome_z_texture := blender.back.biome_texture(X, Z, W, W, R, 1)

	var A := Vector3.ZERO
	var ys := blender.back.height_map(X, Z, W, W, R)
	var yss := PackedFloat32Array([])
	var lod := chunk_lods[coord] as int
	#if not biome_maps.has(new_coord) or (biome_maps[new_coord] as PackedInt32Array).is_empty():
	if lod == 0:
		biome_maps[coord] = blender.back.get_biomes_map()
	elif lod < track_biomes_upto_lod:
		var newS := subdivisions(resoultion(0))
		var newR := chunk_width / (newS + 1)
		var newW := newS + 2
		var newX := x / newR - newW / 2.0
		var newZ := z / newR - newW / 2.0
		newX = snappedf(newX, 1.0)
		newZ = snappedf(newZ, 1.0)
		yss = blender.back.height_map(newX, newZ, newW, newW, newR)
		biome_maps[coord] = blender.back.get_biomes_map()
	else:
		biome_maps[coord] = PackedInt32Array([])
	var w := floori(W)
	var S := 0.0001
	var pos := convert_coord_to_position(new_coord.x, new_coord.y)
	var hmap := height_maps[coord] as HeightMapShape3D
	var hmap_scale := height_map_scale(lod)
	var array := PackedFloat32Array()
	array.resize(hmap.map_data.size())
	var manhattan := maxf(absf(coord.x - saved_player_coord.x), absf(coord.y - saved_player_coord.y))
	var is_central := manhattan < 1
	
	var edges := edges_part_of_transition(coord, new_coord, saved_player_coord)
	var is_internal_chunk := lod < lod_levels.size() - 1
	for i in vertices.size():
		A = vertices[i]
		@warning_ignore("integer_division")
		var row := i / w
		var col := i % w
		
		if (row == 0 and edges.y == 1) or (row == w - 1 and edges.y == -1):
			if col % 2 == 1 and is_internal_chunk:
				var oj := w * (w - row - 1) + (w - (col - 1) - 1)
				var nj := w * (w - row - 1) + (w - (col + 1) - 1)
				A.y = snappedf((ys[oj] + ys[nj]) / 2.0, S)
			else:
				var j := w * (w - row - 1) + (w - col - 1)
				A.y = snappedf(ys[j], S)
		elif (col == 0 and edges.x == 1) or (col == w - 1 and edges.x == -1):
			if row % 2 == 1 and is_internal_chunk:
				var oj := w * (w - (row - 1) - 1) + (w - col - 1)
				var nj := w * (w - (row + 1) - 1) + (w - col - 1)
				A.y = snappedf((ys[oj] + ys[nj]) / 2.0, S)
			else:
				var j := w * (w - row - 1) + (w - col - 1)
				A.y = snappedf(ys[j], S)
		else:
			var j := w * (w - row - 1) + (w - col - 1)
			A.y = snappedf(ys[j], S)

		vertices[i].y = A.y
		if lod == 0 or not (lod < track_biomes_upto_lod):
			array.set(i, A.y / hmap_scale)
		if find_bound_coords:
			if A.y > max_height_position.y and is_central and absf(A.x) < chunk_width * 0.9 and absf(A.z) < chunk_width * 0.9:
				max_height_position = Vector3(A.x + x, A.y, A.z + z)
			if A.y < min_height_position.y:
				min_height_position = Vector3(A.x + x, A.y, A.z + z)
	
	if lod != 0 and lod < track_biomes_upto_lod:
		hmap_scale = height_map_scale(0)
		var newS := subdivisions(resoultion(0))
		w = newS + 2
		for i in array.size():
			@warning_ignore("integer_division")
			var row := i / w
			var col := i % w
			var j := w * (w - row - 1) + (w - col - 1)
			array.set(i, snappedf(yss[j], S) / hmap_scale)
	
	hmap.map_data = array
	
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
	
	chunk_positions[coord] = pos
	if bodies.has(coord):
		var body := bodies[coord] as StaticBody3D
		body.position = Vector3(pos.x, 0, pos.y)
	
	var rid := chunk_rids[coord] as RID
	RenderingServer.instance_set_transform(rid, T.I.translated(Vector3(x, 0, z)))
	
func update_water_chunk(coord: Vector2i, new_coord: Vector2i) -> void:
	var x := new_coord.x * chunk_width
	var z := new_coord.y * chunk_width
	var rid := water_chunk_rids[coord] as RID
	RenderingServer.instance_set_transform(rid, T.I.translated(Vector3(x, sea_level, z)))
	
func has_chunks_to_update() -> bool:
	return not chunk_update_queue.is_empty()
	
func update_chunks_in_queue(start: int, limit: int) -> Dictionary:
	var updated: Array[Vector4i] = []
	var removed: Array[Vector4i] = []
	var duration := Time.get_ticks_msec() - start
	var index := 0
	
	while duration < limit and index < chunk_update_queue.size():
		var params := chunk_update_queue.pop_front() as Dictionary
		index += 1
		var coord0 := params["coord0"] as Vector2i
		var coord1 := params["coord1"] as Vector2i
		var res0 := params["res0"] as float
		var saved_player_coord := params["saved_player_coord"] as Vector2i
		update_chunk(coord0, coord1, res0, saved_player_coord)
		update_water_chunk(coord0, coord1)
		
		if params.has("res1"):
			var res1 := params["res1"] as float
			update_chunk(coord1, coord0, res1, saved_player_coord)
			update_water_chunk(coord1, coord0)
			updated.append(Vector4i(coord1.x, coord1.y, roundi(chunk_resolution / res0 - 1), roundi(chunk_resolution / res1 - 1)))
			removed.append(Vector4i(coord0.x, coord0.y, roundi(chunk_resolution / res0 - 1), roundi(chunk_resolution / res1 - 1)))
			updated.append(Vector4i(coord0.x, coord0.y, roundi(chunk_resolution / res1 - 1), roundi(chunk_resolution / res0 - 1)))
			removed.append(Vector4i(coord1.x, coord1.y, roundi(chunk_resolution / res1 - 1), roundi(chunk_resolution / res0 - 1)))
			var delta := params["delta"] as Vector2i
			update_chunk(coord0 + delta, coord0 + delta, resoultion(chunk_lods[coord0 + delta] as int), saved_player_coord)
			update_chunk(coord1 - delta, coord1 - delta, resoultion(chunk_lods[coord0 + delta] as int), saved_player_coord)
			swap_keys(chunk_lods, coord0, coord1)
			swap_keys(chunk_rids, coord0, coord1)
			swap_keys(mesh_rids, coord0, coord1)
			swap_keys(mats, coord0, coord1)
			swap_keys(chunk_positions, coord0, coord1)
			if bodies.has(coord0) and bodies.has(coord1):
				swap_keys(bodies, coord0, coord1)
			elif bodies.has(coord0):
				move_key(bodies, coord0, coord1)
			elif bodies.has(coord1):
				move_key(bodies, coord1, coord0)
			swap_keys(height_maps, coord0, coord1)
			swap_keys(biome_maps, coord0, coord1)
		else:
			updated.append(Vector4i(coord1.x, coord1.y, roundi(chunk_resolution / res0 - 1), -1))
			removed.append(Vector4i(coord0.x, coord0.y, roundi(chunk_resolution / res0 - 1), -1))
			move_key(chunk_lods, coord0, coord1)
			move_key(chunk_rids, coord0, coord1)
			move_key(mesh_rids, coord0, coord1)
			move_key(mats, coord0, coord1)
			move_key(chunk_positions, coord0, coord1)
			if bodies.has(coord0):
				move_key(bodies, coord0, coord1)
			move_key(height_maps, coord0, coord1)
			move_key(biome_maps, coord0, coord1)
		
		duration = Time.get_ticks_msec() - start
		
	return {"updated": updated, "removed": removed}	
	
func swap_keys(dict: Dictionary, key0: Variant, key1: Variant) -> void:
	var temp: Variant = dict[key0]
	dict[key0] = dict[key1]
	dict[key1] = temp
	
func move_key(dict: Dictionary, from: Variant, to: Variant) -> void:
	dict[to] = dict[from]
	dict.erase(from)
	
func update_chunks(x: float, z: float) -> Array[Vector2i]:
	var old_coord := player_coord
	var current_coord := convert_position_to_coord(x, z)
	var delta := current_coord - old_coord
	var result: Array[Vector2i] = []
	if delta == Vector2i():
		return result
		
	if delta.length() > 1:
		delta.y = 0
		
	result.append_array(update_chunks_impl(delta))	
	player_coord += delta
	return result
		
func update_chunks_impl(delta: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for lod in lod_levels.size():
		var to_flip := edges_at_direction(lod, delta * -1)
		var into := edges_at_direction(lod, delta)
		for i in to_flip.size():
			if lod < track_biomes_upto_lod:
				result.append(to_flip[i])
			if lod + 1 < lod_levels.size():
				var dict := {"coord0": to_flip[i], "coord1": into[i] + delta, "res0": resoultion(lod) , "res1": resoultion(lod + 1), "delta": delta, "saved_player_coord": player_coord + delta}
				if lod + 1 < track_biomes_upto_lod:
					result.append(into[i] + delta)
				chunk_update_queue.append(dict)
			else:
				var dict := {"coord0": to_flip[i], "coord1": into[i] + delta, "res0": resoultion(lod), "saved_player_coord": player_coord + delta}
				chunk_update_queue.append(dict)
	return result
	
func edges_at_direction(lod: int, direction: Vector2i) -> Array[Vector2i]:
	var value := lod_levels[lod] as int
	var result: Array[Vector2i] = []
	if direction.x == -1:
		for i in range(-value, value): result.append(Vector2i(-value + player_coord.x, i + player_coord.y))
	if direction.x == 1:
		for i in range(-value, value): result.append(Vector2i(value - 1 + player_coord.x, i + player_coord.y))
	if direction.y == -1:
		for i in range(-value, value): result.append(Vector2i(i + player_coord.x, -value + player_coord.y))
	if direction.y == 1:
		for i in range(-value, value): result.append(Vector2i(i + player_coord.x, value - 1 + player_coord.y))
	return result
	
func edges_part_of_transition(old_coord: Vector2i, new_coord: Vector2i, saved_player_coord: Vector2i) -> Vector2i:
	var lod := chunk_lods[old_coord] as int
	var value := lod_levels[lod] as int
	var result := Vector2i.ZERO
	if new_coord.x == -value + saved_player_coord.x:
		result.x = -1
	elif new_coord.x == value - 1 + saved_player_coord.x:
		result.x = 1
	if new_coord.y == -value + saved_player_coord.y:
		result.y = -1
	elif new_coord.y == value - 1 + saved_player_coord.y:
		result.y = 1
	return result
	
func convert_position_to_coord(x: float, z: float) -> Vector2i:
	return Vector2i(floori((x + chunk_width / 2.0) / chunk_width), floori((z + chunk_width / 2.0) / chunk_width))
	
func convert_coord_to_position(x: float, z: float) -> Vector2:
	return Vector2(x * chunk_width, z * chunk_width)

func subdivisions(res: float) -> int:
	return floori(chunk_width * res) - 1

func resoultion(lod: int) -> float:
	return chunk_resolution / pow(2, lod)
	
func height_map_scale(lod: int) -> float:
	return chunk_width / (subdivisions(resoultion(lod)) + 1.0)
	
func get_max_height_position() -> Vector3:
	return max_height_position
	
func get_min_height_position() -> Vector3:
	return min_height_position

# xyz = normal of triangle, w = y value height at x,z parameters
func height_at_position(coord: Vector2i, x: float, z: float) -> Vector4:
	if not height_maps.has(coord):
		return Vector4(NAN, NAN, NAN, NAN)
	var hmap := height_maps[coord] as HeightMapShape3D
	var lod := chunk_lods[coord] as int
	var scale := height_map_scale(0 if lod < track_biomes_upto_lod else lod)
	var pos := chunk_positions[coord] as Vector2
	
	var w := (hmap.map_width - 1) * scale
	var d := (hmap.map_depth - 1) * scale
	
	# top-left corner of map
	var base_x := pos.x - w / 2.0
	var base_z := pos.y - d / 2.0
	
	# top-left and bottom-right row and col coordinates 
	#var c0 := floorf((x - base_x) / scale)
	#var r0 := floorf((z - base_z) / scale)
	#var c1 := ceilf((x - base_x) / scale)
	#var r1 := ceilf((z - base_z) / scale)
	# *** Subtract from the width/depth because of noise texture mapping
	var c0 := floorf((w - (x - base_x)) / scale)
	var r0 := floorf((d - (z - base_z)) / scale)
	var c1 := ceilf((w - (x - base_x)) / scale)
	var r1 := ceilf((d - (z - base_z)) / scale)
	
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
	#var tX := (x - base_x) - w / 2.0
	#var tZ := (z - base_z) - d / 2.0
	# *** Subtract from the width/depth because of noise texture mapping
	var tX := (w - (x - base_x)) - w / 2.0
	var tZ := (d - (z - base_z)) - d / 2.0
		
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

func terrain_normal(x: float, z: float) -> Dictionary:
	var coord := convert_position_to_coord(x, z)
	var V := height_at_position(coord, x, z)
	var result := {}
	if V.is_finite():
		result["position"] = Vector3(x, V.w, z)
		result["normal"] = Vector3(V.x, V.y, V.z)
	return result
	
func get_noise_scale() -> float:
	return chunk_width / (subdivisions(resoultion(0)) + 1)

func group_spawn_points(coord: Vector2i, spacing: float) -> Dictionary:
	var areas: Array[Array] = []
	var biomes: Array[int] = []
	var points: Array[Vector2] = []
	var b := 0
	var offsetv := coord * chunk_width
	var biome_map := biome_maps[coord] as PackedInt32Array
	var scale := height_map_scale(chunk_lods[coord] as int)
	var point_offset := Vector2(scale * 0.5, scale * 0.5)
	var found_subsets: Array[int] = []	
	
	for vidx in chunk_vertices.size():
		var vp := chunk_vertices[vidx]
		var p := -Vector2(vp.x, vp.z) + point_offset + offsetv
		points.append(p)
		var biome := biome_map[b]
		found_subsets.clear()
		
		for i in areas.size():
			if biomes[i] == biome and GDTerrain.contains_neighbour_point(areas[i], p, spacing):
				found_subsets.append(i)
		
		if found_subsets.is_empty():
			var n: Array[Vector2] = []
			n.append(p)
			areas.append(n)
			biomes.append(biome)
		elif found_subsets.size() == 1:
			areas[found_subsets[0]].append(p)
		else:
			found_subsets.sort_custom(func(a: int, b: int) -> bool: return a > b)
			var new_pack: Array[Vector2] = []
			for sidx in found_subsets.size():
				var subset := found_subsets[sidx]
				new_pack.append_array(areas[subset])
				areas.remove_at(subset)
				biomes.remove_at(subset)
			areas.append(new_pack)
			biomes.append(biome)
		b += 1
		
	var result := {"points": areas, "biomes": biomes}
	return result

func update_environment(x: float, z: float) -> void:
	pass
