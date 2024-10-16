class_name Foliage
extends Node3D

static var base_size := PackedVector3Array([])
static var base_position := PackedVector3Array([])

const pyramid_tree = preload("res://Models/Nature/tree_pyramid.tscn") as PackedScene
const round_tree = preload("res://Models/Nature/tree_round.tscn") as PackedScene
const christmas_tree = preload("res://Models/Nature/tree_christmas.tscn") as PackedScene
const safari_tree = preload("res://Models/Nature/tree_safari.tscn") as PackedScene
const branched_tree = preload("res://Models/Nature/tree_branched.tscn") as PackedScene

const egg_rock = preload("res://Models/Nature/rock_egg.tscn") as PackedScene
const flattop_rock = preload("res://Models/Nature/rock_flattop.tscn") as PackedScene
const overhang_rock = preload("res://Models/Nature/rock_overhang.tscn") as PackedScene
const squashed_rock = preload("res://Models/Nature/rock_squashed.tscn") as PackedScene
const tall_rock = preload("res://Models/Nature/rock_tall.tscn") as PackedScene

var kind: World.Foliage
var scale_store: float = 1.0
	
static func make(_kind: World.Foliage) -> Foliage:
	var result: Foliage
	match _kind:
		World.Foliage.TREE_PYRAMID: result = pyramid_tree.instantiate()
		World.Foliage.TREE_ROUND: result = round_tree.instantiate()
		World.Foliage.TREE_CHRISTMAS: result = christmas_tree.instantiate()
		World.Foliage.TREE_SAFARI: result = safari_tree.instantiate()
		World.Foliage.TREE_BRANCHED: result = branched_tree.instantiate()
		World.Foliage.ROCK_EGG: result = egg_rock.instantiate()
		World.Foliage.ROCK_FLATTOP: result = flattop_rock.instantiate()
		World.Foliage.ROCK_OVERHANG: result = overhang_rock.instantiate()
		World.Foliage.ROCK_SQUASHED: result = squashed_rock.instantiate()
		World.Foliage.ROCK_TALL: result = tall_rock.instantiate()
		_: result = round_tree.instantiate()
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
		s *= 10
	
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
		
				
