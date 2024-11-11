class_name ShapeTemplate

enum {
	SPHERE,
	CUBE,
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

@warning_ignore("shadowed_variable")
static func sphere(radius: float, transform: Transform3D) -> ShapeTemplate:
	return ShapeTemplate.new(SPHERE, radius, radius, radius, transform)
	
@warning_ignore("shadowed_variable")
static func cube(x: float, y: float, z: float, transform: Transform3D) -> ShapeTemplate:
	return ShapeTemplate.new(CUBE, x, y, z, transform)
	
@warning_ignore("shadowed_variable")
static func cylinder(radius: float, height: float, transform: Transform3D) -> ShapeTemplate:
	return ShapeTemplate.new(CYLINDER, radius, height, radius, transform)
	
@warning_ignore("shadowed_variable")
static func capsule(radius: float, height: float, transform: Transform3D) -> ShapeTemplate:
	return ShapeTemplate.new(CAPSULE, radius, height, radius, transform)
