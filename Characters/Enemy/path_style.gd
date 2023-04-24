class_name PathStyle

enum Kind { ORIGIN, CIRCLE, CIRCLE_PLAYER, FOLLOW }
var kind = Kind.CIRCLE
var min_radius = 5.0
var max_radius = 10.0
var movement_speed = 2.0
var origin = Vector3.ZERO
var blender: NoiseBlender
var seed_offset: int

func _init(_blender: NoiseBlender, _seed: int, _kind: Kind = Kind.ORIGIN, _origin: Vector3 = Vector3.ZERO):
	kind = _kind
	origin = _origin
	blender = _blender
	seed_offset = _seed
	
func circle(center: Vector3, radius: float) -> PathStyle:
	kind = Kind.CIRCLE
	origin = center
	min_radius = radius
	max_radius = radius
	return self
	
func circle_player(radius: float) -> PathStyle:
	kind = Kind.CIRCLE_PLAYER
	min_radius = radius
	max_radius = radius
	return self
	
func follow_player(mn: float, mx: float) -> PathStyle:
	min_radius = mn
	max_radius = mx
	kind = Kind.FOLLOW
	return self
	
func towards_origin(_origin: Vector3) -> PathStyle:
	kind = Kind.ORIGIN
	origin = _origin
	return self

func next_position(me: Enemy, player: Player) -> Vector3:
	var t = float(Time.get_ticks_msec() + seed_offset)
	match kind:
		Kind.CIRCLE:
			var x = cos(t / 1000 / PI) * min_radius + origin.x
			var z = sin(t / 1000 / PI) * min_radius + origin.z
			var y = blender.height(x, z)
			return Vector3(x, y, z)
		Kind.CIRCLE_PLAYER:
			var x = cos(t / 1000 / PI) * min_radius + player.position.x
			var z = sin(t / 1000 / PI) * min_radius + player.position.z
			var y = blender.height(x, z)
			return Vector3(x, y, z)
			
		Kind.FOLLOW:
			var dist = sqrt(player.position.distance_squared_to(me.position))
			if dist > max_radius:
				return player.position.lerp(me.position, max_radius / dist)
			elif dist < min_radius:
				return player.position.lerp(me.position, min_radius / dist)
			
		Kind.ORIGIN:
			return origin
			
	return Vector3.ZERO
