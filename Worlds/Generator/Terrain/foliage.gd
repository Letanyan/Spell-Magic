class_name Foliage

const HIDEY = -1000
var T_HIDEY := T.I.translated(Vec3.y(HIDEY))

const lod0_meshes = {
	World.Foliage.TREE_PYRAMID: preload("res://Models/Nature/tree_pyramid.mesh") as ArrayMesh,
	World.Foliage.TREE_ROUND: preload("res://Models/Nature/tree_round.mesh") as ArrayMesh,
	World.Foliage.TREE_CHRISTMAS: preload("res://Models/Nature/tree_christmas.mesh") as ArrayMesh,
	World.Foliage.TREE_SAFARI: preload("res://Models/Nature/tree_safari.mesh") as ArrayMesh,
	World.Foliage.TREE_BRANCHED: preload("res://Models/Nature/tree_branched.mesh") as ArrayMesh,
	World.Foliage.ROCK_EGG: preload("res://Models/Nature/rock_egg.mesh") as ArrayMesh,
	World.Foliage.ROCK_FLATTOP: preload("res://Models/Nature/rock_flattop.mesh") as ArrayMesh,
	World.Foliage.ROCK_OVERHANG: preload("res://Models/Nature/rock_overhang.mesh") as ArrayMesh,
	World.Foliage.ROCK_SQUASHED: preload("res://Models/Nature/rock_squashed.mesh") as ArrayMesh,
	World.Foliage.ROCK_TALL: preload("res://Models/Nature/rock_tall.mesh") as ArrayMesh,
	World.Foliage.BUSH_ROUND: preload("res://Models/Nature/bush_round.mesh") as ArrayMesh,
	World.Foliage.BUSH_SPROUT: preload("res://Models/Nature/bush_sprout.mesh") as ArrayMesh,
	World.Foliage.BUSH_TALL: preload("res://Models/Nature/bush_tall.mesh") as ArrayMesh,
	World.Foliage.FLOWERS_SUN2: preload("res://Models/Nature/flowers_sun2.mesh") as ArrayMesh,
	World.Foliage.FLOWERS_SUN3: preload("res://Models/Nature/flowers_sun3.mesh") as ArrayMesh,
	World.Foliage.GRASS_REED: preload("res://Models/Nature/grass_reed.mesh") as ArrayMesh,
	World.Foliage.GRASS_SHRUB: preload("res://Models/Nature/grass_shrub.mesh") as ArrayMesh,
	World.Foliage.MUSHROOM_BULB: preload("res://Models/Nature/mushroom_bulb.mesh") as ArrayMesh,
	World.Foliage.MUSHROOM_POINTED: preload("res://Models/Nature/mushroom_pointed.mesh") as ArrayMesh,
} 

const lod1_meshes = {
	World.Foliage.TREE_PYRAMID: preload("res://Models/Nature/tree_pyramid_lod1.mesh") as ArrayMesh,
	World.Foliage.TREE_ROUND: preload("res://Models/Nature/tree_round_lod1.mesh") as ArrayMesh,
	World.Foliage.TREE_CHRISTMAS: preload("res://Models/Nature/tree_christmas_lod1.mesh") as ArrayMesh,
	World.Foliage.TREE_SAFARI: preload("res://Models/Nature/tree_safari_lod1.mesh") as ArrayMesh,
	World.Foliage.TREE_BRANCHED: preload("res://Models/Nature/tree_branched_lod1.mesh") as ArrayMesh,
	World.Foliage.ROCK_EGG: preload("res://Models/Nature/rock_egg.mesh") as ArrayMesh,
	World.Foliage.ROCK_FLATTOP: preload("res://Models/Nature/rock_flattop.mesh") as ArrayMesh,
	World.Foliage.ROCK_OVERHANG: preload("res://Models/Nature/rock_overhang.mesh") as ArrayMesh,
	World.Foliage.ROCK_SQUASHED: preload("res://Models/Nature/rock_squashed.mesh") as ArrayMesh,
	World.Foliage.ROCK_TALL: preload("res://Models/Nature/rock_tall.mesh") as ArrayMesh,
	World.Foliage.BUSH_ROUND: preload("res://Models/Nature/bush_round_lod1.mesh") as ArrayMesh,
	World.Foliage.BUSH_SPROUT: preload("res://Models/Nature/bush_sprout_lod1.mesh") as ArrayMesh,
	World.Foliage.BUSH_TALL: preload("res://Models/Nature/bush_tall_lod1.mesh") as ArrayMesh,
	World.Foliage.FLOWERS_SUN2: preload("res://Models/Nature/flowers_sun2_lod1.mesh") as ArrayMesh,
	World.Foliage.FLOWERS_SUN3: preload("res://Models/Nature/flowers_sun3_lod1.mesh") as ArrayMesh,
	World.Foliage.GRASS_REED: preload("res://Models/Nature/grass_reed_lod1.mesh") as ArrayMesh,
	World.Foliage.GRASS_SHRUB: preload("res://Models/Nature/grass_shrub_lod1.mesh") as ArrayMesh,
	World.Foliage.MUSHROOM_BULB: preload("res://Models/Nature/mushroom_bulb_lod1.mesh") as ArrayMesh,
	World.Foliage.MUSHROOM_POINTED: preload("res://Models/Nature/mushroom_pointed_lod1.mesh") as ArrayMesh,
} 

var multi_meshes: Array[MultiMeshInstance3D] = [] ## [World.Foliage]MultMeshInstance3D
var static_bodies: Array[EntityManager.EntityBuffer] = [] ## [World.Foliage]EntityManager.EntityBuffer
var slot_markings: Array[PackedByteArray] = [] ## [World.Foliage]PackedByteArray
var opened_slots: Array[EntityManager.EntityBuffer] = [] ## [World.Foliage]EntityManager.EntityBuffer
var transforms: Array[Array] = [] ## [World.Foliage][]Transform3D
var static_body_map: Dictionary = {} ## [Vector2i]StaticBody3D

func _init(lod_level: int) -> void:
	var alloc_static_body := func(shape_template: Shape3D) -> Callable:
		var fn := func() -> StaticBody3D:
			var result := StaticBody3D.new()
			result.collision_layer = Globals.Layer.OBJECT
			var shape := CollisionShape3D.new()
			shape.shape = shape_template
			shape.name = "shape"
			shape.disabled = true
			result.add_child(shape)
			return result
		return fn
	var deinit_static_body := func(body: StaticBody3D) -> void:
		var shape := body.get_node("shape") as CollisionShape3D
		shape.disabled = true
	
	var all_meshes := lod0_meshes
	if lod_level == 1:
		all_meshes = lod1_meshes
	
	const INS_COUNT := 1000
	for kind: World.Foliage in World.Foliage.values():
		if kind == World.Foliage.NONE: continue
		
		var multi_mesh := MultiMesh.new()
		multi_mesh.mesh = all_meshes[kind]
		var multi_mesh_ins := MultiMeshInstance3D.new()
		multi_mesh_ins.multimesh = multi_mesh
		multi_mesh.visible_instance_count = -1
		multi_meshes.append(multi_mesh_ins)
		
		multi_mesh.use_colors = true
		multi_mesh.use_custom_data = false
		multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
		multi_mesh.instance_count = INS_COUNT
		
		var markings := PackedByteArray([])
		markings.resize(multi_mesh.instance_count)
		var transforms_array: Array[Transform3D] = []
		transforms_array.resize(INS_COUNT)
		transforms_array.fill(T_HIDEY)
		for i in INS_COUNT:
			multi_mesh.set_instance_transform(i, T_HIDEY); 
			markings.set(i, 0)
		slot_markings.append(markings)
		opened_slots.append(EntityManager.EntityBuffer.new(20, func() -> int: return -1, func(item: int) -> void: pass))
		transforms.append(transforms_array)
		
		@warning_ignore("unsafe_call_argument")
		static_bodies.append(EntityManager.EntityBuffer.new(8, alloc_static_body.call((base_shapes[kind] as ShapeTemplate).make_shape()), deinit_static_body, World.Foliage.keys()[kind]))
	
	
func add_all_meshes(node: Node3D) -> void:
	for mesh in multi_meshes:
		node.add_child(mesh)

func make(kind: World.Foliage) -> int:
	var result := -1
	@warning_ignore("unsafe_method_access")
	if not opened_slots[kind].is_empty():
		@warning_ignore("unsafe_method_access")
		var index := opened_slots[kind].pop_back() as int
		slot_markings[kind][index] = 1
		result = index
	else:
		var markings := slot_markings[kind] as PackedByteArray
		for i in markings.size():
			if markings[i] == 0:
				slot_markings[kind][i] = 1
				result = i
				break
	@warning_ignore("unsafe_method_access")
	if opened_slots[kind].is_empty() and result < slot_markings[kind].size() - 1 and slot_markings[kind][result + 1] == 0:
		@warning_ignore("unsafe_method_access")
		opened_slots[kind].append(result + 1)
	return result
		
func remove(kind: World.Foliage, index: int) -> void:
	if index > 1000:
		print("hm")
	multi_meshes[kind].multimesh.set_instance_transform(index, T_HIDEY)
	transforms[kind][index] = T_HIDEY
	slot_markings[kind][index] = 0
	@warning_ignore("unsafe_method_access")
	opened_slots[kind].append(index)
	
	
func setup(kind: World.Foliage, index: int, position: Vector3, rng: RandomNumberGenerator, biome: World.Biome) -> void:
	var s := rng.randf_range(2, 5) * mesh_scales[kind] as float
	if biome == World.Biome.JUNGLE and World.Foliage.TREE_BRANCHED == kind:
		s *= rng.randf_range(5, 10)
		
	var transform := T.I
	
	var result := transform.scaled(Vector3(s, s, s))
	var r := rng.randf_range(0, 2 * PI)
	result = result.rotated(Vector3.UP, r)
	result = result.translated(position)
	
	multi_meshes[kind].multimesh.set_instance_transform(index, result)
	transforms[kind][index] = result
		
func set_albedo_blend(kind: World.Foliage, index: int, color: Color) -> void:
	multi_meshes[kind].multimesh.set_instance_color(index, color)
	
func get_transform(kind: World.Foliage, index: int) -> Transform3D:
	return transforms[kind][index]
		
func make_static_body(g: Vector2i) -> StaticBody3D:
	var body: StaticBody3D = static_bodies[g.x].get_entity()
	var base := get_transform(g.x, g.y)
	var off := base_shapes[g.x] as ShapeTemplate
	var shape := body.get_node("shape") as CollisionShape3D
	static_body_map[g] = body
	body.transform = base.scaled_local(Vec3.a(1.0 / mesh_scales[g.x] as float))
	shape.transform = off.transform.orthonormalized()
	return body
		
func free_static_body(g: Vector2i) -> void:
	if not static_body_map.has(g):
		return
	var body := static_body_map[g] as StaticBody3D
	static_bodies[g.x].free_entity(body)
	static_body_map.erase(g)
		
func get_collision_shape(g: Vector2i) -> CollisionShape3D:
	var body := static_body_map.get(g, null) as StaticBody3D
	if body == null:
		return null
	var shape := body.get_node("shape") as CollisionShape3D
	return shape
	
func get_scaled_shape_length(g: Vector2i, t: Transform3D) -> float:
	var shape := base_shapes[g.x] as ShapeTemplate
	var scale := t.basis.get_scale().x
	return shape.size.length() * scale
				
static var base_shapes := {
	World.Foliage.BUSH_ROUND: ShapeTemplate.capsule(0.65, 1.5, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.314))),
	World.Foliage.BUSH_SPROUT: ShapeTemplate.cylinder(0.5, 0.9, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.252))),
	World.Foliage.BUSH_TALL: ShapeTemplate.capsule(0.55, 1.2, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.214))),
	World.Foliage.FLOWERS_SUN2: ShapeTemplate.sphere(0.5, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.469))),
	World.Foliage.FLOWERS_SUN3: ShapeTemplate.sphere(0.5, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.495))),
	World.Foliage.GRASS_REED: ShapeTemplate.sphere(0.5, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.496))),
	World.Foliage.GRASS_SHRUB: ShapeTemplate.sphere(0.5, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.484))),
	World.Foliage.MUSHROOM_BULB: ShapeTemplate.cylinder(0.8, 0.3, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.429))),
	World.Foliage.MUSHROOM_POINTED: ShapeTemplate.capsule(0.35, 1.0, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.428))),
	World.Foliage.ROCK_EGG: ShapeTemplate.capsule(1.2, 3.2, Transform3D(Basis(Quaternion(0, 0, 0.627, 0.779)), Vector3(0.07, 0.691, 0.079))),
	World.Foliage.ROCK_FLATTOP: ShapeTemplate.cylinder(1.5, 1.5, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vector3(-0.048, 0.474, 0.023))),
	World.Foliage.ROCK_OVERHANG: ShapeTemplate.cylinder(1.6, 1.25, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vector3(0.026, 0.366, 0))),
	World.Foliage.ROCK_SQUASHED: ShapeTemplate.cylinder(1.4, 1.3, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vector3(-0.005, 0.4, 0.039))),
	World.Foliage.ROCK_TALL: ShapeTemplate.capsule(1.2, 2.8, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vector3(-0.073, 0.906, 0.016))),
	World.Foliage.TREE_BRANCHED: ShapeTemplate.cylinder(4.0, 0.4, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(2))),
	World.Foliage.TREE_CHRISTMAS: ShapeTemplate.cylinder(4.0, 0.3, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(2))),
	World.Foliage.TREE_PYRAMID: ShapeTemplate.cylinder(4.0, 0.3, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(2))),
	World.Foliage.TREE_ROUND: ShapeTemplate.cylinder(4.0, 0.3, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(2))),
	World.Foliage.TREE_SAFARI: ShapeTemplate.cylinder(4.0, 0.3, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(2))),	
}

const mesh_scales = {
	World.Foliage.BUSH_ROUND: 2.0,
	World.Foliage.BUSH_SPROUT: 1.0,
	World.Foliage.BUSH_TALL: 1.0,
	World.Foliage.FLOWERS_SUN2: 2.5,
	World.Foliage.FLOWERS_SUN3: 2.5,
	World.Foliage.GRASS_REED: 4.0,
	World.Foliage.GRASS_SHRUB: 2.75,
	World.Foliage.MUSHROOM_BULB: 2.5,
	World.Foliage.MUSHROOM_POINTED: 4,
	World.Foliage.ROCK_EGG: 1.0,
	World.Foliage.ROCK_FLATTOP: 10.0,
	World.Foliage.ROCK_OVERHANG: 3.0,
	World.Foliage.ROCK_SQUASHED: 15.0,
	World.Foliage.ROCK_TALL: 2.0,
	World.Foliage.TREE_BRANCHED: 1.0,
	World.Foliage.TREE_CHRISTMAS: 1.0,
	World.Foliage.TREE_PYRAMID: 1.0,
	World.Foliage.TREE_ROUND: 1.0,
	World.Foliage.TREE_SAFARI: 1.0,
}
