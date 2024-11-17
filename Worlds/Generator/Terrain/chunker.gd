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
var chunks := {} ## [Vector2i(coord)]MeshInstance
var height_maps := {} ## [Vector2i(coord)]HeightMapShape3D

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
		#var count := 1 << (value << 1)
		for row in range(-value, value):
			for col in range(-value, value):
				var coord := Vector2i(col, row)
				if vertex_indices.has(coord):
					continue
				vertex_indices[coord] = level
				var chunk := create_mesh(chunk_width, res)
				chunk.position = Vec3.xz(convert_coord_to_position(col, row))
				chunks[coord] = chunk
				var map := create_height_map_shape(chunk_width, res)
				height_maps[coord] = map
				if level == 0:
					var body := create_static_body(chunk_width, res, map)
					chunk.add_child(body)
				update_chunk(chunk, chunk.position.x, chunk.position.z, res)
				
		#res *= 0.5
		level += 1
	
func create_mesh(size: float, res: float) -> MeshInstance3D:
	var mesh := ArrayMesh.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	var subdivide := subdivisions(res)
	plane.subdivide_depth = subdivide
	plane.subdivide_width = subdivide
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane.get_mesh_arrays())
	#mesh.surface_set_material(0, ShaderMaterial.new())
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(randf(), randf(), randf())
	mesh.surface_set_material(0, mat)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.name = "mesh"
	return mi
	
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
	
func update_chunk(mi: MeshInstance3D, x: float, z: float, res: float, scale: float = 1.0) -> void:
	#auto mesh = (ArrayMesh*)*mi->get_mesh();
	#auto mesh_data = mi->get_mesh()->surface_get_arrays(0);
	#auto vertices = (PackedVector3Array)mesh_data[Mesh::ArrayType::ARRAY_VERTEX];
	#if (chunk_vertices.is_empty()) {
		#auto positions = (PackedVector3Array)mesh_data[Mesh::ArrayType::ARRAY_VERTEX];
		#for (int i = 0; i < positions.size(); i++) {
			#chunk_vertices.append(positions[i]);
		#}
	#}
	var mesh := mi.mesh as ArrayMesh
	var mesh_data := mesh.surface_get_arrays(0)
	var vertices := mesh_data[Mesh.ArrayType.ARRAY_VERTEX] as PackedVector3Array

	#auto R = size / (float)((int)(size * subdivide));
	#auto texture_size = size / R;
	var subdivide := subdivisions(res)
	var R := chunk_width / (subdivide + 1)
	
	#print(R, " ~ ", chunk_width / float(floori(chunk_width * res) - 1))
 
	#auto W = texture_size + 2;
	#auto X = x / R - W / 2.0 + (x / R / R);
	#auto Y = y / R - W / 2.0 + (y / R / R);
	#X = UtilityFunctions::snappedf(X, 0.0001);
	#Y = UtilityFunctions::snappedf(Y, 0.0001);
	var W := subdivide + 2
	#var X := x / R - W / 2.0 + (x / R / R)
	#var Z := z / R - W / 2.0 + (z / R / R)
	#var r := chunk_width / (subdivide + 1)
	var X := x / R - W / 2.0 #+ (x / r / r)
	var Z := z / R - W / 2.0 #+ (z / r / r)
	X = snappedf(X, 1.0000)
	Z = snappedf(Z, 1.0000)
	
	#print(x, " / ", R, " - ", W, " / 2.0 + ", "(", x, " / ", R,  " / ", R, ")")
	#print("(", x, ", ", z, ") => ", "(", X, ", ", Z, ") -> (", X+W, ", ", Z+W, ")")
	# -512 / 32 - 9 / 2.0 + (-512 / 32 / 32)
	# -256 / 32 - 9 / 2.0 + (-256 / 32 / 32)
	#    0 / 32 - 9 / 2.0 + (   0 / 32 / 32)
	#  256 / 32 - 9 / 2.0 + ( 256 / 32 / 32)
	#  512 / 32 - 9 / 2.0 + ( 512 / 32 / 32)
	
	# (-512, -1024) => (-21   , -37.5) -> (-12  , -28.5)
	# (-256, -1024) => (-12.75, -37.5) -> (-3.75, -28.5)
	# (   0, -1024) => (-4.5  , -37.5) -> (4.5  , -28.5)
	# ( 256, -1024) => ( 3.75 , -37.5) -> (12.75, -28.5)
	# ( 512, -1024) => ( 12   , -37.5) -> (21   , -28.5)

	#auto biome_x_texture = blender->biome_texture(X, Y, W, W, R, 0);
	#auto biome_y_texture = blender->biome_texture(X, Y, W, W, R, 1);
	var biome_x_texture := blender.back.biome_texture(X, Z, W, W, R, 0)
	var biome_z_texture := blender.back.biome_texture(X, Z, W, W, R, 1)

	#auto A = Vector3();
	#auto ys = blender->height_map(X, Y, W, W, R);
	#auto w = (size_t)W;
	var A := Vector3.ZERO
	var ys := blender.back.height_map(X, Z, W, W, R)
	var w := floori(W)
	var S := 0.0001
	if mi.has_node("static"):
	#if ((r <= radius || index == lciMED) && mi->has_node("static")) {
		#auto static_body = mi->get_node<StaticBody3D>("static");
		#auto collision_shape = static_body->get_node<CollisionShape3D>("collision");
		#auto hmap = (HeightMapShape3D*)*collision_shape->get_shape();
		#auto array = PackedFloat32Array();
		#array.resize(hmap->get_map_data().size());
		#auto coord = convert_position_to_coord(x, y, chunk_size);
		#auto manhattan = UtilityFunctions::maxf(UtilityFunctions::absf(coord.x - player_coord.x), UtilityFunctions::absf(coord.y - player_coord.y));
		#auto is_central = manhattan < 1;
		var static_body := mi.get_node("static") as StaticBody3D
		var collision_shape := static_body.get_node("collision") as CollisionShape3D
		var hmap := collision_shape.shape as HeightMapShape3D
		var array := PackedFloat32Array()
		array.resize(hmap.map_data.size())
		#var coord := convert_position_to_coord(x, z)
		
		for i in vertices.size():
		#for (int i = 0; i < vertices.size(); i++) {
			#A = vertices[i];
			#size_t row = i / w;
			#size_t col = i % w;
			#size_t j = w * (w - row - 1) + (w - col - 1);
			#A.y = ys[j];
			#vertices[i].y = ys[j];
			#array.set(i, A.y / collision_shape->get_scale().y);
			A = vertices[i]
			var row := i / w
			var col := i % w
			var j := w * (w - row - 1) + (w - col - 1)
			A.y = snappedf(ys[j], S)
			vertices[i].y = snappedf(ys[j], S)
			array.set(i, A.y / collision_shape.scale.y)
 			
			#if (find_bound_coords) {
				#if (A.y > max_height_position.y && is_central && abs(A.x) < size * 0.9 && abs(A.z) < size * 0.9) {
					#max_height_position = Vector3(A.x + x, A.y, A.z + y);
				#}
				#if (A.y < min_height_position.y) {
					#min_height_position = Vector3(A.x + x, A.y, A.z + y);
				#}
			#}
		#}
		hmap.map_data = array
		#hmap->set_map_data(array);
	else:
	#} else {
		for i in vertices.size():
		#for (int i = 0; i < vertices.size(); i++) {
			#A = vertices[i];
			#size_t r = i / w;
			#size_t c = i % w;
			#size_t j = w * (w - r - 1) + (w - c - 1);
			#A.y = ys[j];
			#vertices[i].y = ys[j];
			A = vertices[i]
			var row := i / w
			var col := i % w
			var j := w * (w - row - 1) + (w - col - 1)
			A.y = snappedf(ys[j], S)
			vertices[i].y = snappedf(ys[j], S)
			#if (find_bound_coords) {
				#if (A.y < min_height_position.y) {
					#min_height_position = Vector3(A.x + x, A.y, A.z + y);
				#}
			#}
		#}
	#}
	
	#mesh->clear_surfaces();
	#mesh_data[Mesh::ArrayType::ARRAY_VERTEX] = vertices;
	#mesh->add_surface_from_arrays(Mesh::PrimitiveType::PRIMITIVE_TRIANGLES, mesh_data);
	#mesh->surface_set_material(0, new ShaderMaterial());
	mesh.clear_surfaces()
	mesh_data[Mesh.ArrayType.ARRAY_VERTEX] = vertices
	mesh.add_surface_from_arrays(Mesh.PrimitiveType.PRIMITIVE_TRIANGLES, mesh_data)
	mesh.surface_set_material(0, ShaderMaterial.new())
	
	#auto mat = (ShaderMaterial*)*mesh->surface_get_material(0);
	#mat->set_shader(biome_shader);
	#mat->set_shader_parameter("texture_width", texture_size);
	#mat->set_shader_parameter("texture_depth", texture_size);
	#mat->set_shader_parameter("biome_x", biome_x_texture);
	#mat->set_shader_parameter("biome_y", biome_y_texture);
	#mat->set_shader_parameter("noise", noise_texture);
	#mat->set_shader_parameter("locations", blender->locations);
	var mat := mesh.surface_get_material(0) as ShaderMaterial
	mat.shader = biome_shader
	mat.set_shader_parameter("texture_width", W)
	mat.set_shader_parameter("texture_depth", W)
	mat.set_shader_parameter("biome_x", biome_x_texture)
	mat.set_shader_parameter("biome_y", biome_z_texture)
	mat.set_shader_parameter("noise", noise_texture)
	mat.set_shader_parameter("locations", blender.back.get_locations())
	
	
func convert_position_to_coord(x: float, z: float) -> Vector2i:
	return Vector2i(floori(x / chunk_width), floori(z / chunk_width))
	
func convert_coord_to_position(x: float, z: float) -> Vector2:
	return Vector2(x * chunk_width, z * chunk_width)

func subdivisions(res: float) -> int:
	return floori(chunk_width * res) - 1
