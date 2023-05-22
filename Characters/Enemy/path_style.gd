class_name PathStyle

enum Kind { ORIGIN, CIRCLE, RAND_CIRCLE }
enum Mover { PHYSICS, ABSOLUTE_XZ, ABSOLUTE }

var kind = Kind.CIRCLE
var min_radius = 5.0
var max_radius = 10.0
var movement_speed = 2.0
var origin = Vector3.ZERO
var use_player_as_origin: bool
var seed_offset: float
var mover: Mover = Mover.ABSOLUTE_XZ

func _init(_seed: float, _kind: Kind = Kind.ORIGIN, _origin: Vector3 = Vector3.ZERO):
	kind = _kind
	origin = _origin
	seed_offset = _seed
	use_player_as_origin = false
	
func speed(s: float) -> PathStyle:
	movement_speed = s
	return self
	
func use_physics() -> PathStyle:
	mover = Mover.PHYSICS
	return self
	
func use_absolute() -> PathStyle:
	mover = Mover.ABSOLUTE
	return self
	
func circle(center: Vector3, radius: float) -> PathStyle:
	kind = Kind.CIRCLE
	use_player_as_origin = false
	origin = center
	min_radius = radius
	max_radius = radius
	return self
	
func circle_player(radius: float) -> PathStyle:
	kind = Kind.CIRCLE
	use_player_as_origin = true
	min_radius = radius
	max_radius = radius
	return self
	
func towards(center: Vector3, mn: float = 0, mx: float = mn) -> PathStyle:
	kind = Kind.ORIGIN
	min_radius = mn
	max_radius = mx
	origin = center
	use_player_as_origin = false
	return self
	
func towards_player(mn: float, mx: float) -> PathStyle:
	min_radius = mn
	max_radius = mx
	kind = Kind.ORIGIN
	use_player_as_origin = true
	return self
	
func rand_circle(center: Vector3, radius: float) -> PathStyle:
	kind = Kind.RAND_CIRCLE
	origin = center
	min_radius = radius
	use_player_as_origin = false
	return self
	
func rand_circle_player(radius: float) -> PathStyle:
	kind = Kind.RAND_CIRCLE
	min_radius = radius
	use_player_as_origin = true
	return self

func next_position(me: Enemy, player: Player) -> Vector3:
	var t = float(Time.get_unix_time_from_system() + seed_offset * 2 * PI)
	if use_player_as_origin:
		origin = player.position
	match kind:
		Kind.ORIGIN:
			var dist = sqrt(origin.distance_squared_to(me.position))
			if dist > max_radius:
				return origin.lerp(me.position, max_radius / dist)
			elif dist < min_radius:
				return origin.lerp(me.position, min_radius / dist)
			else:
				return me.position
		
		Kind.CIRCLE:
			var lap = t * (movement_speed / min_radius)
			var x = cos(lap) * min_radius + origin.x
			var z = sin(lap) * min_radius + origin.z
			var y = Navigator.get_world_height(me.get_world_3d().direct_space_state, x, z)
			return Vector3(x, y, z)

		Kind.RAND_CIRCLE:
			# FIXME: Use `t mod movement_speed` to clamp rand seed so we can wait for `distance / movement_speed` amount 
			# of time before generating a new position.
			var v = Vector2(1, 0)
			v = v.rotated(randf() * 2 * PI)
			var x = origin.x + v.x * min_radius
			var z = origin.z + v.y * min_radius
			var y = Navigator.get_world_height(me.get_world_3d().direct_space_state, x, z)
			return Vector3(x, y, z)


	return Vector3.ZERO
