class_name ShapeTemplate

enum {
	NONE,
	SPHERE,
	BOX,
	CYLINDER,
	CAPSULE
}

var size: Vector3
var kind: int
var transform: Transform3D

@warning_ignore("shadowed_variable")
func _init(kind: int, x: float, y: float, z: float, transform: Transform3D) -> void:
	self.kind = kind
	self.size = Vector3(x, y, z)
	self.transform = transform

@warning_ignore("shadowed_variable")
static func sphere(radius: float, transform: Transform3D) -> ShapeTemplate:
	return ShapeTemplate.new(SPHERE, radius * 2.0, radius * 2.0, radius * 2.0, transform)
	
@warning_ignore("shadowed_variable")
static func box(x: float, y: float, z: float, transform: Transform3D) -> ShapeTemplate:
	return ShapeTemplate.new(BOX, x, y, z, transform)
	
@warning_ignore("shadowed_variable")
static func cylinder(height: float, radius: float, transform: Transform3D) -> ShapeTemplate:
	return ShapeTemplate.new(CYLINDER, radius * 2.0, height, radius * 2.0, transform)
	
@warning_ignore("shadowed_variable")
static func capsule(radius: float, height: float, transform: Transform3D) -> ShapeTemplate:
	return ShapeTemplate.new(CAPSULE, radius * 2.0, height, radius * 2.0, transform)
	
static func none() -> ShapeTemplate:
	return ShapeTemplate.new(NONE, 0, 0, 0, T.I)

func make_shape() -> Shape3D:
	var result: Shape3D
	match kind:
		NONE:
			result = SphereShape3D.new()
			(result as SphereShape3D).radius = 0.1
		SPHERE: 
			result = SphereShape3D.new()
			(result as SphereShape3D).radius = size.x / 2.0
		CAPSULE:
			result = CapsuleShape3D.new()
			(result as CapsuleShape3D).radius = size.x / 2.0
			(result as CapsuleShape3D).height = size.y
		CYLINDER:
			result = CylinderShape3D.new()
			(result as CylinderShape3D).radius = size.x / 2.0
			(result as CylinderShape3D).height = size.y
		BOX:
			result = BoxShape3D.new()
			(result as BoxShape3D).size = size
	return result
