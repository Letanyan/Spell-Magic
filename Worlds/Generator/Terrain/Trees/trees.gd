class_name Trees

const leaves_mat = preload("res://Worlds/Generator/Terrain/Trees/tree_leaves.tres")
const trunk_mat = preload("res://Worlds/Generator/Terrain/Trees/tree_trunk.tres")

static func build(rng: RandomNumberGenerator) -> Node3D:
	var trunk = MeshInstance3D.new()
	trunk.mesh = CylinderMesh.new()
	var h = rng.randf_range(4, 10)
	var r = rng.randf_range(h / 8, h / 2)
	trunk.mesh.height = h
	trunk.mesh.top_radius = r
	trunk.mesh.bottom_radius = r
	trunk.mesh.radial_segments = 16
	trunk.mesh.rings = 1
	trunk.mesh.surface_set_material(0, trunk_mat)
	trunk.position.y = h / 2
	
	var s = rng.randf_range(r * 1.75, r * 2)
	var sh = rng.randf_range(s, s * 2)
	var leaves = MeshInstance3D.new()
	leaves.mesh = SphereMesh.new()
	leaves.mesh.radius = s
	leaves.mesh.height = sh
	leaves.mesh.radial_segments = rng.randf_range(8, 16)
	leaves.mesh.rings = rng.randf_range(4, 8)
	leaves.mesh.surface_set_material(0, leaves_mat)
	leaves.position.y = h
	
	var body = StaticBody3D.new()
	body.collision_layer = 1 << 9
	
	var box = CollisionShape3D.new()
	box.name = "collision"
	box.shape = CylinderShape3D.new()
	box.shape.height = h
	box.shape.radius = r
	body.add_child(box)
	trunk.add_child(body)
	
	var result = Node3D.new()
	result.add_child(trunk)
	result.add_child(leaves)
	
	return result
	
enum Kind {
	PYRAMID, ROUND
}

const pyramid_tree = preload("res://Models/Nature/Tree_Pyramid.fbx")
const round_tree = preload("res://Models/Nature/Tree_Round.fbx")
	
static func make(kind: Kind, rng: RandomNumberGenerator) -> Node3D:
	var result: Node3D
	match kind:
		Kind.PYRAMID: result = pyramid_tree.instantiate()
		Kind.ROUND: result = round_tree.instantiate()
		
	var s = rng.randf_range(2, 5)
	result.scale = Vector3(s, s, s)
	var r = rng.randf_range(0, 2 * PI)
	result.rotate(Vector3.UP, r)
		
	return result
				
