class_name Trees
extends Node3D

const leaves_mat = preload("res://Worlds/Generator/Terrain/Trees/tree_leaves.tres")
const trunk_mat = preload("res://Worlds/Generator/Terrain/Trees/tree_trunk.tres")

static func build(rng: RandomNumberGenerator) -> Node3D:
	var trunk := MeshInstance3D.new()
	trunk.mesh = CylinderMesh.new()
	var h := rng.randf_range(4, 10)
	var r := rng.randf_range(h / 8, h / 2)
	(trunk.mesh as CylinderMesh).height = h
	(trunk.mesh as CylinderMesh).top_radius = r
	(trunk.mesh as CylinderMesh).bottom_radius = r
	(trunk.mesh as CylinderMesh).radial_segments = 16
	(trunk.mesh as CylinderMesh).rings = 1
	trunk.mesh.surface_set_material(0, trunk_mat)
	trunk.position.y = h / 2
	
	var s := rng.randf_range(r * 1.75, r * 2)
	var sh := rng.randf_range(s, s * 2)
	var leaves := MeshInstance3D.new()
	leaves.mesh = SphereMesh.new()
	(leaves.mesh as SphereMesh).radius = s
	(leaves.mesh as SphereMesh).height = sh
	(leaves.mesh as SphereMesh).radial_segments = rng.randi_range(8, 16)
	(leaves.mesh as SphereMesh).rings = rng.randi_range(4, 8)
	leaves.mesh.surface_set_material(0, leaves_mat)
	leaves.position.y = h
	
	var body := StaticBody3D.new()
	body.collision_layer = 1 << 9
	
	var box := CollisionShape3D.new()
	box.name = "collision"
	box.shape = CylinderShape3D.new()
	(box.shape as CylinderShape3D).height = h
	(box.shape as CylinderShape3D).radius = r
	body.add_child(box)
	trunk.add_child(body)
	
	var result := Node3D.new()
	result.add_child(trunk)
	result.add_child(leaves)
	
	return result

const pyramid_tree = preload("res://Models/Nature/tree_pyramid.tscn") as PackedScene
const round_tree = preload("res://Models/Nature/tree_round.tscn") as PackedScene
const christmas_tree = preload("res://Models/Nature/tree_christmas.tscn") as PackedScene
const safari_tree = preload("res://Models/Nature/tree_safari.tscn") as PackedScene
const branched_tree = preload("res://Models/Nature/tree_branched.tscn") as PackedScene

var kind: World.Foliage
	
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
	return result
	
func setup(rng: RandomNumberGenerator) -> void:
	var s := rng.randf_range(2, 5)
	(get_node("RootNode") as Node3D).scale = Vector3(s, s, s)
	var r := rng.randf_range(0, 2 * PI)
	(get_node("RootNode") as Node3D).rotate(Vector3.UP, r)
	
	var box := get_node("./static/shape") as CollisionShape3D
	(box.shape as CylinderShape3D).height = 4 * s
	(box.shape as CylinderShape3D).radius = 0.25 * s
	box.position.y = 2 * s
				
func entity_info() -> EntityInfo:
	return EntityInfo.new(EntityInfo.Kind.TREE, position)
	
func update_entity_info(info: EntityInfo) -> bool:
	return false
