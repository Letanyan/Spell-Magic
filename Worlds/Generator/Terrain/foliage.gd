class_name Foliage
extends Node3D

static var base_size := PackedVector3Array([])
static var base_position := PackedVector3Array([])

const tree_pyramid = preload("res://Models/Nature/tree_pyramid.tscn") as PackedScene
const tree_round = preload("res://Models/Nature/tree_round.tscn") as PackedScene
const tree_christmas = preload("res://Models/Nature/tree_christmas.tscn") as PackedScene
const tree_safari = preload("res://Models/Nature/tree_safari.tscn") as PackedScene
const tree_branched = preload("res://Models/Nature/tree_branched.tscn") as PackedScene

const rock_egg = preload("res://Models/Nature/rock_egg.tscn") as PackedScene
const rock_flattop = preload("res://Models/Nature/rock_flattop.tscn") as PackedScene
const rock_overhang = preload("res://Models/Nature/rock_overhang.tscn") as PackedScene
const rock_squashed = preload("res://Models/Nature/rock_squashed.tscn") as PackedScene
const rock_tall = preload("res://Models/Nature/rock_tall.tscn") as PackedScene

const bush_round = preload("res://Models/Nature/bush_round.tscn") as PackedScene
const bush_sprout = preload("res://Models/Nature/bush_sprout.tscn") as PackedScene
const bush_tall = preload("res://Models/Nature/bush_tall.tscn") as PackedScene
const flowers_sun2 = preload("res://Models/Nature/flowers_sun2.tscn") as PackedScene
const flowers_sun3 = preload("res://Models/Nature/flowers_sun3.tscn") as PackedScene
const grass_reed = preload("res://Models/Nature/grass_reed.tscn") as PackedScene
const grass_shrub = preload("res://Models/Nature/grass_shrub.tscn") as PackedScene
const mushroom_bulb = preload("res://Models/Nature/mushroom_bulb.tscn") as PackedScene
const mushroom_pointed = preload("res://Models/Nature/mushroom_pointed.tscn") as PackedScene

var kind: World.Foliage
var collision_is_active: bool = true
	
static func make(_kind: World.Foliage) -> Foliage:
	var result: Foliage
	match _kind:
		World.Foliage.TREE_PYRAMID: result = tree_pyramid.instantiate()
		World.Foliage.TREE_ROUND: result = tree_round.instantiate()
		World.Foliage.TREE_CHRISTMAS: result = tree_christmas.instantiate()
		World.Foliage.TREE_SAFARI: result = tree_safari.instantiate()
		World.Foliage.TREE_BRANCHED: result = tree_branched.instantiate()
		World.Foliage.ROCK_EGG: result = rock_egg.instantiate()
		World.Foliage.ROCK_FLATTOP: result = rock_flattop.instantiate()
		World.Foliage.ROCK_OVERHANG: result = rock_overhang.instantiate()
		World.Foliage.ROCK_SQUASHED: result = rock_squashed.instantiate()
		World.Foliage.ROCK_TALL: result = rock_tall.instantiate()
		World.Foliage.BUSH_ROUND: result = bush_round.instantiate(); result.collision_is_active = false;
		World.Foliage.BUSH_SPROUT: result = bush_sprout.instantiate(); result.collision_is_active = false;
		World.Foliage.BUSH_TALL: result = bush_tall.instantiate(); result.collision_is_active = false;
		World.Foliage.FLOWERS_SUN2: result = flowers_sun2.instantiate(); result.collision_is_active = false;
		World.Foliage.FLOWERS_SUN3: result = flowers_sun3.instantiate(); result.collision_is_active = false;
		World.Foliage.GRASS_REED: result = grass_reed.instantiate(); result.collision_is_active = false;
		World.Foliage.GRASS_SHRUB: result = grass_shrub.instantiate(); result.collision_is_active = false;
		World.Foliage.MUSHROOM_BULB: result = mushroom_bulb.instantiate(); result.collision_is_active = false;
		World.Foliage.MUSHROOM_POINTED: result = mushroom_pointed.instantiate(); result.collision_is_active = false;
		_: result = tree_round.instantiate(); push_error("no such enum for foliage")
	result.kind = _kind
	if base_size.size() <= _kind:
		while base_size.size() < (_kind + 1):
			base_size.append(Vector3.ZERO)
			base_position.append(Vector3.ZERO)
		base_size[_kind] = Navigator.shape_bounds((result.get_node("./static/shape") as CollisionShape3D).shape)
		base_position[_kind] = (result.get_node("./static/shape") as CollisionShape3D).position
	elif base_size[_kind] == Vector3.ZERO:
		base_size[_kind] = Navigator.shape_bounds((result.get_node("./static/shape") as CollisionShape3D).shape)
		base_position[_kind] = (result.get_node("./static/shape") as CollisionShape3D).position
	
	return result
	
func setup(rng: RandomNumberGenerator, biome: World.Biome) -> void:
	var s := rng.randf_range(2, 5)
	if biome == World.Biome.JUNGLE and World.Foliage.TREE_BRANCHED == kind:
		s *= rng.randf_range(5, 10)
	
	(get_node("MeshNode") as Node3D).scale = Vector3(s, s, s)
	var r := rng.randf_range(0, 2 * PI)
	(get_node("MeshNode") as Node3D).rotation.y = r
	
	var box := get_node("./static/shape") as CollisionShape3D
	if box.shape is CylinderShape3D:
		box.scale = Vec3.a(s)
		box.position.y = base_position[kind].y * s
		box.rotation.y = r
	elif box.shape is BoxShape3D:
		box.scale = Vec3.a(s)
		box.position.y = base_position[kind].y * s
		box.rotation.y = r
	elif box.shape is CapsuleShape3D:
		box.scale = Vec3.a(s)
		box.position.y = base_position[kind].y * s
		box.rotation.y = r
	elif box.shape is SphereShape3D:
		box.scale = Vec3.a(s)
		box.position.y = base_position[kind].y * s
		box.rotation.y = r
		
	collision_is_active = maxf(base_size[kind].x, maxf(base_size[kind].y, base_size[kind].z)) * s > 1.0
		
func set_albedo_blend(color: Color) -> void:
	var m := get_node("MeshNode/mesh") as MeshInstance3D
	var shader := m.mesh.surface_get_material(0) as ShaderMaterial
	var brown_color := color.lerp(Color(0.5, 0.25, 0), 0.5)
	shader.set_shader_parameter("nature_mat_green_blend", color)
	shader.set_shader_parameter("nature_mat_brown_blend", brown_color)
	
	if has_node("MeshNode/mesh_1"):
		var m1 := get_node("MeshNode/mesh_1") as MeshInstance3D
		shader = m1.mesh.surface_get_material(0) as ShaderMaterial
		shader.set_shader_parameter("nature_mat_green_blend", color)
		shader.set_shader_parameter("nature_mat_brown_blend", brown_color)
				
