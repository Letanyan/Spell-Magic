class_name PathStyle

enum Kind { ORIGIN, CIRCLE, CIRCLE_PLAYER }
var kind = Kind.CIRCLE
var path_radius = 5.0
var origin = Vector3.ZERO
var blender: NoiseBlender

func _init(_blender: NoiseBlender, _kind: Kind = Kind.ORIGIN, _origin: Vector3 = Vector3.ZERO):
	kind = _kind
	origin = _origin
	blender = _blender
	
func circle(center: Vector3, radius: float) -> PathStyle:
	kind = Kind.CIRCLE
	origin = center
	path_radius = radius
	return self
	
func circle_player(radius: float) -> PathStyle:
	kind = Kind.CIRCLE_PLAYER
	path_radius = radius
	return self
	
func towards_origin(origin: Vector3) -> PathStyle:
	kind = Kind.ORIGIN
	self.origin = origin
	return self

func next_position(player: Player) -> Vector3:
	var t = Time.get_ticks_msec()
	match kind:
		Kind.CIRCLE:
			var x = cos(t / 1000 / PI) * path_radius + origin.x
			var z = sin(t / 1000 / PI) * path_radius + origin.z
			var y = blender.height(x, z)
			return Vector3(x, y, z)
		Kind.CIRCLE_PLAYER:
			var x = cos(t / 1000 / PI) * path_radius + player.position.x
			var z = sin(t / 1000 / PI) * path_radius + player.position.z
			var y = blender.height(x, z)
			return Vector3(x, y, z)
			
		Kind.ORIGIN:
			return origin
			
	return Vector3.ZERO
