class_name Trees
extends Node3D

const leaves_mat = preload("res://Worlds/Generator/Terrain/Trees/tree_leaves.tres")
const trunk_mat = preload("res://Worlds/Generator/Terrain/Trees/tree_trunk.tres")

static var base_size := PackedVector3Array([])

const pyramid_tree = preload("res://Models/Nature/tree_pyramid.tscn") as PackedScene
const round_tree = preload("res://Models/Nature/tree_round.tscn") as PackedScene
const christmas_tree = preload("res://Models/Nature/tree_christmas.tscn") as PackedScene
const safari_tree = preload("res://Models/Nature/tree_safari.tscn") as PackedScene
const branched_tree = preload("res://Models/Nature/tree_branched.tscn") as PackedScene

var kind: World.Foliage
var scale_store: float = 1.0
	
static func make(_kind: World.Foliage) -> Trees:
	var result: Trees
	match _kind:
		World.Foliage.TREE_PYRAMID: result = pyramid_tree.instantiate()
		World.Foliage.TREE_ROUND: result = round_tree.instantiate()
		World.Foliage.TREE_CHRISTMAS: result = christmas_tree.instantiate()
		World.Foliage.TREE_SAFARI: result = safari_tree.instantiate()
		World.Foliage.TREE_BRANCHED: result = branched_tree.instantiate()
		_: result = round_tree.instantiate()
	result.kind = _kind
	if base_size.size() <= _kind:
		while base_size.size() < (_kind + 1):
			base_size.append(Vector3.ZERO)
		base_size[_kind] = Navigator.shape_bounds((result.get_node("./static/shape") as CollisionShape3D).shape)
	elif base_size[_kind] == Vector3.ZERO:
		base_size[_kind] = Navigator.shape_bounds((result.get_node("./static/shape") as CollisionShape3D).shape)
	return result
	
func setup(rng: RandomNumberGenerator) -> void:
	var s := rng.randf_range(2, 5)
	(get_node("RootNode") as Node3D).scale = Vector3(s, s, s)
	var r := rng.randf_range(0, 2 * PI)
	(get_node("RootNode") as Node3D).rotate(Vector3.UP, r)
	
	var box := get_node("./static/shape") as CollisionShape3D
	(box.shape as CylinderShape3D).height = base_size[kind].y * s
	(box.shape as CylinderShape3D).radius = base_size[kind].x * s
	box.position.y = (base_size[kind].y * s) / 4.0
				
func entity_info() -> EntityInfo:
	return EntityInfo.new(EntityInfo.Kind.TREE, position)
	
func update_entity_info(info: EntityInfo) -> bool:
	return false
