class_name ShapeTemplate

enum {
	SPHERE,
	BOX,
	CYLINDER,
	CAPSULE
}

var x: float
var y: float
var z: float
var kind: int
var transform: Transform3D

@warning_ignore("shadowed_variable")
func _init(kind: int, x: float, y: float, z: float, transform: Transform3D) -> void:
	self.kind = kind
	self.x = x
	self.y = y
	self.z = z
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

func make_shape() -> Shape3D:
	var result: Shape3D
	match kind:
		SPHERE: 
			result = SphereShape3D.new()
			(result as SphereShape3D).radius = x / 2.0
		CAPSULE:
			result = CapsuleShape3D.new()
			(result as CapsuleShape3D).radius = x / 2.0
			(result as CapsuleShape3D).height = y
		CYLINDER:
			result = CylinderShape3D.new()
			(result as CylinderShape3D).radius = x / 2.0
			(result as CylinderShape3D).height = y
		BOX:
			result = BoxShape3D.new()
			(result as BoxShape3D).size = Vector3(x, y, z)
	return result
