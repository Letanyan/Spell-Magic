class_name Foliage

const HIDEY = -1000
var T_HIDEY := T.I.translated(Vec3.y(HIDEY))

const lod0_meshes = {
	World.Foliage.TREE_PYRAMID: preload("res://Models/Nature/Tree/tree_pyramid.mesh") as ArrayMesh,
	World.Foliage.TREE_ROUND: preload("res://Models/Nature/Tree/tree_round.mesh") as ArrayMesh,
	World.Foliage.TREE_CHRISTMAS: preload("res://Models/Nature/Tree/tree_christmas.mesh") as ArrayMesh,
	World.Foliage.TREE_SAFARI: preload("res://Models/Nature/Tree/tree_safari.mesh") as ArrayMesh,
	World.Foliage.TREE_BRANCHED: preload("res://Models/Nature/Tree/tree_branched.mesh") as ArrayMesh,
	World.Foliage.TREE_PALM: preload("res://Models/Nature/Tree/tree_palm.mesh") as ArrayMesh,
	World.Foliage.TREE_PINE: preload("res://Models/Nature/Tree/tree_pine.mesh") as ArrayMesh,
	World.Foliage.TREE_SAFARI2: preload("res://Models/Nature/Tree/tree_safari2.mesh") as ArrayMesh,
	World.Foliage.ROCK_EGG: preload("res://Models/Nature/Rock/rock_egg.mesh") as ArrayMesh,
	World.Foliage.ROCK_FLATTOP: preload("res://Models/Nature/Rock/rock_flattop.mesh") as ArrayMesh,
	World.Foliage.ROCK_OVERHANG: preload("res://Models/Nature/Rock/rock_overhang.mesh") as ArrayMesh,
	World.Foliage.ROCK_SQUASHED: preload("res://Models/Nature/Rock/rock_squashed.mesh") as ArrayMesh,
	World.Foliage.ROCK_TALL: preload("res://Models/Nature/Rock/rock_tall.mesh") as ArrayMesh,
	World.Foliage.BUSH_ROUND: preload("res://Models/Nature/Bush/bush_round.mesh") as ArrayMesh,
	World.Foliage.BUSH_SPROUT: preload("res://Models/Nature/Bush/bush_sprout.mesh") as ArrayMesh,
	World.Foliage.BUSH_TALL: preload("res://Models/Nature/Bush/bush_tall.mesh") as ArrayMesh,
	World.Foliage.FLOWERS_SUN2: preload("res://Models/Nature/Flowers/flowers_sun2.mesh") as ArrayMesh,
	World.Foliage.FLOWERS_SUN3: preload("res://Models/Nature/Flowers/flowers_sun3.mesh") as ArrayMesh,
	World.Foliage.GRASS_REED: preload("res://Models/Nature/Grass/grass_reed.mesh") as ArrayMesh,
	World.Foliage.GRASS_SHRUB: preload("res://Models/Nature/Grass/grass_shrub.mesh") as ArrayMesh,
	World.Foliage.MUSHROOM_BULB: preload("res://Models/Nature/Mushroom/mushroom_bulb.mesh") as ArrayMesh,
	World.Foliage.MUSHROOM_POINTED: preload("res://Models/Nature/Mushroom/mushroom_pointed.mesh") as ArrayMesh,
} 

const lod1_meshes = {
	World.Foliage.TREE_PYRAMID: preload("res://Models/Nature/Tree/tree_pyramid_lod1.mesh") as ArrayMesh,
	World.Foliage.TREE_ROUND: preload("res://Models/Nature/Tree/tree_round_lod1.mesh") as ArrayMesh,
	World.Foliage.TREE_CHRISTMAS: preload("res://Models/Nature/Tree/tree_christmas_lod1.mesh") as ArrayMesh,
	World.Foliage.TREE_SAFARI: preload("res://Models/Nature/Tree/tree_safari_lod1.mesh") as ArrayMesh,
	World.Foliage.TREE_BRANCHED: preload("res://Models/Nature/Tree/tree_branched_lod1.mesh") as ArrayMesh,
	World.Foliage.TREE_PALM: preload("res://Models/Nature/Tree/tree_palm.mesh") as ArrayMesh,
	World.Foliage.TREE_PINE: preload("res://Models/Nature/Tree/tree_pine.mesh") as ArrayMesh,
	World.Foliage.TREE_SAFARI2: preload("res://Models/Nature/Tree/tree_safari2.mesh") as ArrayMesh,
	World.Foliage.ROCK_EGG: preload("res://Models/Nature/Rock/rock_egg.mesh") as ArrayMesh,
	World.Foliage.ROCK_FLATTOP: preload("res://Models/Nature/Rock/rock_flattop.mesh") as ArrayMesh,
	World.Foliage.ROCK_OVERHANG: preload("res://Models/Nature/Rock/rock_overhang.mesh") as ArrayMesh,
	World.Foliage.ROCK_SQUASHED: preload("res://Models/Nature/Rock/rock_squashed.mesh") as ArrayMesh,
	World.Foliage.ROCK_TALL: preload("res://Models/Nature/Rock/rock_tall.mesh") as ArrayMesh,
	World.Foliage.BUSH_ROUND: preload("res://Models/Nature/Bush/bush_round_lod1.mesh") as ArrayMesh,
	World.Foliage.BUSH_SPROUT: preload("res://Models/Nature/Bush/bush_sprout_lod1.mesh") as ArrayMesh,
	World.Foliage.BUSH_TALL: preload("res://Models/Nature/Bush/bush_tall_lod1.mesh") as ArrayMesh,
	World.Foliage.FLOWERS_SUN2: preload("res://Models/Nature/Flowers/flowers_sun2_lod1.mesh") as ArrayMesh,
	World.Foliage.FLOWERS_SUN3: preload("res://Models/Nature/Flowers/flowers_sun3_lod1.mesh") as ArrayMesh,
	World.Foliage.GRASS_REED: preload("res://Models/Nature/Grass/grass_reed_lod1.mesh") as ArrayMesh,
	World.Foliage.GRASS_SHRUB: preload("res://Models/Nature/Grass/grass_shrub_lod1.mesh") as ArrayMesh,
	World.Foliage.MUSHROOM_BULB: preload("res://Models/Nature/Mushroom/mushroom_bulb_lod1.mesh") as ArrayMesh,
	World.Foliage.MUSHROOM_POINTED: preload("res://Models/Nature/Mushroom/mushroom_pointed_lod1.mesh") as ArrayMesh,
} 

var multi_meshes: Array[MultiMeshInstance3D] = [] ## [World.Foliage]MultMeshInstance3D
var static_bodies: Array[EntityManager.EntityBuffer] = [] ## [World.Foliage]EntityManager.EntityBuffer
var slot_markings: Array[PackedByteArray] = [] ## [World.Foliage]PackedByteArray
var opened_slots: Array[EntityManager.EntityBuffer] = [] ## [World.Foliage]EntityManager.EntityBuffer
var transforms: Array[Array] = [] ## [World.Foliage][]Transform3D
var static_body_map: Dictionary = {} ## [Vector2i]StaticBody3D
var mesh_scaled_shape: PackedFloat32Array = PackedFloat32Array([])

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
		
		if base_shapes[kind].kind == ShapeTemplate.NONE:
			static_bodies.append(EntityManager.EntityBuffer.new(0, func() -> void: pass, func(body: StaticBody3D) -> void: pass, ""))
		else:
			@warning_ignore("unsafe_call_argument")
			static_bodies.append(EntityManager.EntityBuffer.new(8, alloc_static_body.call((base_shapes[kind] as ShapeTemplate).make_shape()), deinit_static_body, World.Foliage.keys()[kind]))
		
		mesh_scaled_shape.append(mesh_transforms[kind].basis.get_scale().inverse().x * base_shapes[kind].size.length())
	
	
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
	
	
func setup(kind: World.Foliage, index: int, position: Vector3, seedling: int, biome: World.Biome, config: Dictionary) -> void:
	var mesh_transform := mesh_transforms[kind] as Transform3D
	var scur := Globals.Ref.new(seedling)
	var s := config.get("scale", 1.0) as float
		
	#var transform := mesh_transform.scaled(Vec3.a(s))
	
	var result := mesh_transform.scaled(Vec3.a(s))
	var r := Rand.randf_range(scur, 0, TAU)
	result = result.rotated(Vector3.UP, r)
	result = result.translated(position)
	
	multi_meshes[kind].multimesh.set_instance_transform(index, result)
	transforms[kind][index] = result
		
func set_albedo_blend(kind: World.Foliage, index: int, color: Color) -> void:
	multi_meshes[kind].multimesh.set_instance_color(index, color)
	
func get_transform(kind: World.Foliage, index: int) -> Transform3D:
	return transforms[kind][index]
	
func uses_static_body(g: Vector2i) -> bool:
	return base_shapes[g.x].kind != ShapeTemplate.NONE
		
func make_static_body(g: Vector2i) -> StaticBody3D:
	var body: StaticBody3D = static_bodies[g.x].get_entity()
	var base := get_transform(g.x, g.y)
	var off := base_shapes[g.x]
	var shape := body.get_node("shape") as CollisionShape3D
	static_body_map[g] = body
	var mesh_transform := mesh_transforms[g.x]
	body.transform = T.scaled_local(base.basis.get_scale() * mesh_transform.basis.get_scale().inverse()).translated(base.origin)
	shape.transform = off.transform.orthonormalized()
	return body
		
func free_static_body(g: Vector2i) -> void:
	if base_shapes[g.x].kind == ShapeTemplate.NONE or not static_body_map.has(g):
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
	return mesh_scaled_shape[g.x] * t.basis.get_scale().x
				
static var base_shapes: Array[ShapeTemplate] = [
	ShapeTemplate.cylinder(4.0, 0.3, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(2))), # World.Foliage.TREE_PYRAMID
	ShapeTemplate.cylinder(4.0, 0.3, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(2))), # World.Foliage.TREE_ROUND
	ShapeTemplate.cylinder(4.0, 0.3, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(2))), # World.Foliage.TREE_CHRISTMAS
	ShapeTemplate.cylinder(4.0, 0.3, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(2))), # World.Foliage.TREE_SAFARI
	ShapeTemplate.cylinder(4.0, 0.4, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(2))), # World.Foliage.TREE_BRANCHED
	ShapeTemplate.cylinder(3.7, 0.15, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(1.85))), # World.Foliage.TREE_PALM
	ShapeTemplate.capsule(0.75, 3.0, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(1.25))), # World.Foliage.TREE_PINE
	ShapeTemplate.capsule(0.5, 2.0, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(1.0))), # World.Foliage.TREE_SAFARI2
	ShapeTemplate.capsule(1.2, 3.2, Transform3D(Basis(Quaternion(0, 0, 0.627, 0.779)), Vector3(0.07, 0.691, 0.079))), # World.Foliage.ROCK_EGG
	ShapeTemplate.cylinder(1.5, 1.5, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vector3(-0.048, 0.474, 0.023))), # World.Foliage.ROCK_FLATTOP
	ShapeTemplate.cylinder(1.6, 1.25, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vector3(0.026, 0.366, 0))), # World.Foliage.ROCK_OVERHANG
	ShapeTemplate.cylinder(1.4, 1.3, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vector3(-0.005, 0.4, 0.039))), # World.Foliage.ROCK_SQUASHED
	ShapeTemplate.capsule(1.2, 2.8, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vector3(-0.073, 0.906, 0.016))), # World.Foliage.ROCK_TALL
	ShapeTemplate.capsule(0.65, 1.5, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.314))), # World.Foliage.BUSH_ROUND
	ShapeTemplate.none(), #ShapeTemplate.cylinder(0.5, 0.9, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.252))), # World.Foliage.BUSH_SPROUT
	ShapeTemplate.capsule(0.55, 1.2, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.214))), # World.Foliage.BUSH_TALL
	ShapeTemplate.none(), #ShapeTemplate.sphere(0.5, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.469))), # World.Foliage.FLOWERS_SUN2
	ShapeTemplate.none(), #ShapeTemplate.sphere(0.5, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.495))), # World.Foliage.FLOWERS_SUN3
	ShapeTemplate.none(), #ShapeTemplate.sphere(0.5, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.496))), # World.Foliage.GRASS_REED
	ShapeTemplate.none(), #ShapeTemplate.sphere(0.5, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.484))), # World.Foliage.GRASS_SHRUB
	ShapeTemplate.cylinder(0.8, 0.3, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.429))), # World.Foliage.MUSHROOM_BULB
	ShapeTemplate.capsule(0.35, 1.0, Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0.428))), # World.Foliage.MUSHROOM_POINTED
]

static var mesh_transforms: Array[Transform3D] = [
	Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0)).scaled(Vec3.a(1.0)), # World.Foliage.TREE_PYRAMID
	Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0)).scaled(Vec3.a(1.0)), # World.Foliage.TREE_ROUND
	Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0)).scaled(Vec3.a(1.0)), # World.Foliage.TREE_CHRISTMAS
	Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0)).scaled(Vec3.a(1.0)), # World.Foliage.TREE_SAFARI
	Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0)).scaled(Vec3.a(1.0)), # World.Foliage.TREE_BRANCHED
	Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0)).scaled(Vec3.a(1.0)), # World.Foliage.TREE_PALM
	Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0)).scaled(Vec3.a(1.0)), # World.Foliage.TREE_PINE
	Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0)).scaled(Vec3.a(1.0)), # World.Foliage.TREE_SAFARI2
	Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0)).scaled(Vec3.a(1.0)), # World.Foliage.ROCK_EGG
	Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0)).scaled(Vec3.a(10.0)), # World.Foliage.ROCK_FLATTOP
	Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0)).scaled(Vec3.a(3.0)), # World.Foliage.ROCK_OVERHANG
	Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0)).scaled(Vec3.a(15.0)), # World.Foliage.ROCK_SQUASHED
	Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0)).scaled(Vec3.a(2.0)), # World.Foliage.ROCK_TALL
	Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0)).scaled(Vec3.a(2.0)), # World.Foliage.BUSH_ROUND
	Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0)).scaled(Vec3.a(1.0)), # World.Foliage.BUSH_SPROUT
	Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0)).scaled(Vec3.a(1.0)), # World.Foliage.BUSH_TALL
	Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0)).scaled(Vec3.a(2.5)), # World.Foliage.FLOWERS_SUN2
	Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0)).scaled(Vec3.a(2.5)), # World.Foliage.FLOWERS_SUN3
	Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0)).scaled(Vec3.a(4.0)), # World.Foliage.GRASS_REED
	Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0)).scaled(Vec3.a(2.75)), # World.Foliage.GRASS_SHRUB
	Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0)).scaled(Vec3.a(2.5)), # World.Foliage.MUSHROOM_BULB
	Transform3D(Basis(Quaternion(0, 0, 0, 1)), Vec3.y(0)).scaled(Vec3.a(4.0)), # World.Foliage.MUSHROOM_POINTED
]
