class_name PathStyle

enum Kind { ORIGIN, CIRCLE, PATH }
enum CoordY { GROUND, ORIGIN }
enum Mover { PHYSICS, ABSOLUTE_XZ, ABSOLUTE }
enum LookAt { VELOCITY, PLAYER }

var kind = Kind.CIRCLE
var min_radius := 5.0
var max_radius := 10.0
var movement_speed := 2.0
var origin := Vector3.ZERO
var path: Pathway = null
var use_player_as_origin: bool
var seed_offset: float
var mover: Mover = Mover.ABSOLUTE_XZ
var coord_y: CoordY = CoordY.GROUND
var lookat: LookAt = LookAt.VELOCITY

func _init(_seed: float, _kind: Kind = Kind.ORIGIN, _origin: Vector3 = Vector3.ZERO):
	kind = _kind
	origin = _origin
	seed_offset = _seed
	use_player_as_origin = false
	
func speed(s: float) -> PathStyle:
	movement_speed = s
	return self
	
func set_origin(o: Vector3) -> PathStyle:
	origin = o
	return self
	
func look_at_player() -> PathStyle:
	lookat = LookAt.PLAYER
	return self
	
func use_physics() -> PathStyle:
	mover = Mover.PHYSICS
	return self
	
func use_absolute() -> PathStyle:
	mover = Mover.ABSOLUTE
	return self
	
func use_absolute_xz() -> PathStyle:
	mover = Mover.ABSOLUTE_XZ
	return self
	
func set_use_player_as_origin(o: bool = true) -> PathStyle:
	use_player_as_origin = o
	return self
	
func align_y_to_origin() -> PathStyle:
	coord_y = CoordY.ORIGIN
	return self
	
func align_y_to_ground() -> PathStyle:
	coord_y = CoordY.GROUND
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
	
func follow_path(pathway: Pathway) -> PathStyle:
	path = pathway
	kind = Kind.PATH
	return self
	
func circle_path(radius: float, h: float) -> PathStyle:
	path = Pathway.new()
	var a := Segment.cubic(Vector3(0, h, radius), Vector3(0, h, -radius), Vector3(radius * 1.5, h, radius), Vector3(radius * 1.5, h, -radius))
	var b := Segment.cubic(Vector3(0, h, -radius), Vector3(0, h, radius), Vector3(radius * -1.5, h, -radius), Vector3(radius * -1.5, h, radius))
	path.append([a, b])
	kind = Kind.PATH
	return self
	
func random_points_in_circle(radius: float, count: int) -> PathStyle:
	path = Pathway.new()
	var p := Vector3(randf() * 2 - 1, 0, randf() * 2 - 1).normalized() * radius
	path.add(Segment.linear(Vector3.ZERO, p))
	for i in range(count - 1):
		var q := Vector3(randf() * 2 - 1, 0, randf() * 2 - 1).normalized() * radius
		path.add(Segment.linear(p, q))
		p = q
	path.add(Segment.linear(p, Vector3.ZERO))
	path.calculate_distance()
	kind = Kind.PATH
	return self
	
func random_points_in_disc(min_radius: float, max_radius: float, count: int) -> PathStyle:
	path = Pathway.new()
	var dist := max_radius - min_radius
	var p := Vector3(randf_range(min_radius, max_radius) * cos(randf_range(-PI, PI)), 0, randf_range(min_radius, max_radius) * sin(randf_range(-PI, PI)))
	path.add(Segment.linear(Vector3.ZERO, p))
	for i in range(count - 1):
		var q := Vector3(randf_range(min_radius, max_radius) * cos(randf_range(-PI, PI)), 0, randf_range(min_radius, max_radius) * sin(randf_range(-PI, PI))).normalized() * (dist + min_radius)
#		var m := (p + q) / 2.0
#		path.add(Segment.quad(p, q, m))
		path.add(Segment.linear(p, q))
		p = q
	path.add(Segment.linear(p, Vector3.ZERO))
	path.calculate_distance()
	kind = Kind.PATH
	return self

func next_position(me: Enemy, player: Player) -> Vector3:
	var t := float(Time.get_unix_time_from_system() + seed_offset * 2 * PI)
	if use_player_as_origin:
		origin = player.position
	match kind:
		Kind.ORIGIN:
			var dist = origin.distance_to(me.position)
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
			var y = next_y_position(me, x, 0, z)
			return Vector3(x, y, z)

		Kind.PATH:
			var dist = fmod(movement_speed * t, path.distance)
			var v = path.position_at_distance(dist) + origin
			var y = next_y_position(me, v.x, v.y - origin.y, v.z)
			return Vector3(v.x, y, v.z)


	return Vector3.ZERO

func next_y_position(me: Enemy, x: float, y: float, z: float) -> float:
	match coord_y:
		CoordY.GROUND: return Navigator.get_world_height(me.get_world_3d().direct_space_state, x, z)
		CoordY.ORIGIN: return Navigator.get_world_height(me.get_world_3d().direct_space_state, x, z) + y
		_: return 0

class Pathway:
	var segments: Array[Segment]
	var distance: float
	
	func _init():
		segments = []
		calculate_distance()
		
	func add(segment: Segment):
		segments.append(segment)
		
	func append(sgmnts: Array[Segment]):
		segments.append_array(sgmnts)
		calculate_distance()
	
	func calculate_distance():
		distance = 0.0
		for s in segments:
			distance += s.distance
			
	func position_at_time(t: float) -> Vector3:
		var dist := t * distance
		return position_at_distance(dist)
			
	func position_at_distance(dist: float) -> Vector3:
		var segment := 0
		var running := 0.0
		for i in range(segments.size()):
			segment = i
			var s = segments[i]
			if running <= dist and dist <= running + s.distance:
				break
			running += s.distance
		dist -= running
		return segments[segment].position_at_distance(dist)

class Segment:
	enum BezierKind { LINEAR, QUAD, CUBIC }
	
	var start: Vector3
	var end: Vector3
	var c1: Vector3
	var c2: Vector3
	var kind: BezierKind
	var distance: float
	
	func _init(s: Vector3, e: Vector3, cc1: Vector3, cc2: Vector3, k: BezierKind, d = null):
		start = s
		end = e
		c1 = cc1
		c2 = cc2
		kind = k
		if d != null:
			distance = d
		else:
			calculate_distance()
	
	static func point(a: Vector3, d: float) -> Segment:
		return Segment.new(a, a, a, a, BezierKind.LINEAR, d)
	
	static func linear(a: Vector3, b: Vector3) -> Segment:
		return Segment.new(a, b, a, b, BezierKind.LINEAR)
	
	static func quad(a: Vector3, b: Vector3, c: Vector3) -> Segment:
		return Segment.new(a, b, c, c, BezierKind.QUAD)
	
	static func cubic(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> Segment:
		return Segment.new(a, b, c, d, BezierKind.CUBIC)
		
	static func arc(radius: float, angle_start: float, angle_end: float, h: float) -> Segment:
		var a := Vector3(radius, h, 0).rotated(Vector3.UP, angle_start)
		var b := Vector3(radius, h, 0).rotated(Vector3.UP, angle_end)
		
		var q1 := a.x * a.x + a.z * a.z
		var q2 := q1 + a.x * b.x + a.z * b.z
		var k2 := (4.0 / 3.0) * (sqrt(2 * q1 * q2) - q2) / (a.x * b.z - a.z * b.x)

		var c := Vector3(a.x - k2 * a.z, h, a.z + k2 * a.x)
		var d := Vector3(b.x + k2 * b.z, h, b.z - k2 * b.x)
		
		return Segment.new(a, b, c, d, BezierKind.CUBIC)
		
	func calculate_distance(interval: float = 0.005):
		if kind == BezierKind.LINEAR:
			distance = end.distance_to(start)
		else:
			var p := start
			distance = 0.0
			var i := interval
			while i <= 1.0:
				var q := position_at_time(i)
				distance += p.distance_to(q)
				p = q
				i += interval
		
	func position_at_time(t: float) -> Vector3:
		match kind:
			BezierKind.LINEAR:
				return lerp(start, end, t)
			BezierKind.QUAD:
				var a: Vector3 = lerp(start, c1, t)
				var b: Vector3 = lerp(c1, end, t)
				return lerp(a, b, t)
			BezierKind.CUBIC:
				var a1: Vector3 = lerp(start, c1, t)
				var b1: Vector3 = lerp(c1, end, t)
				var e1: Vector3 = lerp(a1, b1, t)
				var a2: Vector3 = lerp(c1, c2, t)
				var b2: Vector3 = lerp(c2, end, t)
				var e2: Vector3 = lerp(a2, b2, t)
				return lerp(e1, e2, t)
				
		return Vector3.ZERO
		
	func position_at_distance(dist: float) -> Vector3:
		var t := dist / distance
		return position_at_time(t)
		
		
		
		
		
