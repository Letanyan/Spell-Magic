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
var scale_store: float = 1.0
	
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
		World.Foliage.BUSH_ROUND: result = bush_round.instantiate()
		World.Foliage.BUSH_SPROUT: result = bush_sprout.instantiate()
		World.Foliage.BUSH_TALL: result = bush_tall.instantiate()
		World.Foliage.FLOWERS_SUN2: result = flowers_sun2.instantiate()
		World.Foliage.FLOWERS_SUN3: result = flowers_sun3.instantiate()
		World.Foliage.GRASS_REED: result = grass_reed.instantiate()
		World.Foliage.GRASS_SHRUB: result = grass_shrub.instantiate()
		World.Foliage.MUSHROOM_BULB: result = mushroom_bulb.instantiate()
		World.Foliage.MUSHROOM_POINTED: result = mushroom_pointed.instantiate()
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
	if biome == World.Biome.JUNGLE:
		s *= rng.randf_range(5, 10)
	
	(get_node("MeshNode") as Node3D).scale = Vector3(s, s, s)
	var r := rng.randf_range(0, 2 * PI)
	(get_node("MeshNode") as Node3D).rotation.y = r
	
	var box := get_node("./static/shape") as CollisionShape3D
	if box.shape is CylinderShape3D:
		(box.shape as CylinderShape3D).height = base_size[kind].y * s
		(box.shape as CylinderShape3D).radius = base_size[kind].x * s / 2.0
		box.position.y = base_position[kind].y * s
		box.rotation.y = r
	elif box.shape is BoxShape3D:
		(box.shape as BoxShape3D).size = base_size[kind] * s
		box.position.y = base_position[kind].y * s
		box.rotation.y = r
	elif box.shape is CapsuleShape3D:
		(box.shape as CapsuleShape3D).height = base_size[kind].y * s
		(box.shape as CapsuleShape3D).radius = base_size[kind].x * s / 2.0
		box.position.y = base_position[kind].y * s
		box.rotation.y = r
	elif box.shape is SphereShape3D:
		(box.shape as SphereShape3D).radius = base_size[kind].x * s / 2.0
		box.position.y = base_position[kind].y * s
		box.rotation.y = r
		
		
				
