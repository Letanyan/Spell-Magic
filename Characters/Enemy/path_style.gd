class_name PathStyle

enum CoordY { GROUND, ORIGIN, GROUND_AND_AIR, GROUND_AND_DIRT }
enum Mover { PHYSICS, ABSOLUTE }
enum LookAt { VELOCITY, PLAYER }
enum OriginKind { ABSOLUTE, PLAYER, ME }

var const_movement_speed: float
var origin := Vector3.ZERO
var path: Pathway = null
var origin_kind: OriginKind
var seed_offset: float
var mover: Mover = Mover.ABSOLUTE
var coord_y: CoordY = CoordY.GROUND
var lookat: LookAt = LookAt.VELOCITY
var last_t: float = 0.0
var stored_loops: int = 0
var is_done_uses_path_segements: bool = false
var last_path_segment_index: int = 0
var time_offset: float = 0.0

var me_start_position = null # used to store entity position (Vec3) at start of movement

# (theta, radius, min_margin, max_margin) pair to describe offset from player. +theta is ccw from 
# straight of player view. -theta is cw from player view. radius is distance away
# from player. (min|max)_margin are the radi of disc with center (theta, radius)
var player_vision_offset: Vector4 = Vector4.ZERO
var use_player_camera_as_vision: bool = false # if false use player body orientation else camera

func _init(_seed: float = randf(), _origin: Vector3 = Vector3.ZERO):
	origin = _origin
	seed_offset = _seed
	origin_kind = OriginKind.ABSOLUTE
	if _seed == 0.0:
		time_offset = Time.get_unix_time_from_system()
	
func speed(s: float) -> PathStyle:
	const_movement_speed = s
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
	
func set_use_player_as_origin(o: bool = true) -> PathStyle:
	origin_kind = OriginKind.PLAYER if o else OriginKind.ABSOLUTE
	if o:
		origin = Vector3.ZERO
	return self
	
func set_use_me_as_origin(o: bool = true) -> PathStyle:
	origin_kind = OriginKind.ME if o else OriginKind.ABSOLUTE
	if o:
		origin = Vector3.ZERO
	return self
	
func set_player_body_vision_as_origin(a: float, r: float, min_m: float = 0.0, max_m: float = min_m) -> PathStyle:
	use_player_camera_as_vision = false
	player_vision_offset = Vector4(a, r, min_m, max_m) 
	return self
	
func set_player_cam_vision_as_origin(a: float, r: float, min_m: float = 0.0, max_m: float = min_m) -> PathStyle:
	use_player_camera_as_vision = true
	player_vision_offset = Vector4(a, r, min_m, max_m) 
	return self
	
func set_is_done_uses_path_segments(d: bool = true) -> PathStyle:
	is_done_uses_path_segements = d
	return self
	
func align_y_to_origin() -> PathStyle:
	coord_y = CoordY.ORIGIN
	return self
	
func align_y_to_ground() -> PathStyle:
	coord_y = CoordY.GROUND
	return self
	
func align_y_to_ground_and_air() -> PathStyle:
	coord_y = CoordY.GROUND_AND_AIR
	return self
	
func align_y_to_ground_and_dirt() -> PathStyle:
	coord_y = CoordY.GROUND_AND_DIRT
	return self
	
func circle(center: Vector3, radius: float, h: float = 0.0) -> PathStyle:
	path = Pathway.new()
	var a := Segment.cubic(Vector3(0, h, radius), Vector3(0, h, -radius), Vector3(radius * 1.5, h, radius), Vector3(radius * 1.5, h, -radius))
	var b := Segment.cubic(Vector3(0, h, -radius), Vector3(0, h, radius), Vector3(radius * -1.5, h, -radius), Vector3(radius * -1.5, h, radius))
	path.append_with_speed([a, b], [const_movement_speed, const_movement_speed], [Easing.linear, Easing.linear])
	origin = center
	origin_kind = OriginKind.ABSOLUTE
	return self
	
func circle_player(radius: float, h: float = 0.0) -> PathStyle:
	origin_kind = OriginKind.PLAYER
	origin = Vector3.ZERO
	path = Pathway.new()
	var a := Segment.cubic(Vector3(0, h, radius), Vector3(0, h, -radius), Vector3(radius * 1.5, h, radius), Vector3(radius * 1.5, h, -radius))
	var b := Segment.cubic(Vector3(0, h, -radius), Vector3(0, h, radius), Vector3(radius * -1.5, h, -radius), Vector3(radius * -1.5, h, radius))
	path.append_with_speed([a, b], [const_movement_speed, const_movement_speed], [Easing.linear, Easing.linear])
	return self
	
func towards_player(mn: float, mx: float) -> PathStyle:
	use_player_camera_as_vision = false
	player_vision_offset = Vector4(0.0, 0.0, mn, mx)
	origin_kind = OriginKind.PLAYER
	origin = Vector3.ZERO
	path = Pathway.empty()
	return self
	
func follow_path(pathway: Pathway) -> PathStyle:
	path = pathway
	return self
	
func random_points_in_circle(radius: float, count: int) -> PathStyle:
	path = Pathway.new()
	var p := Vector3(randf() * 2 - 1, 0, randf() * 2 - 1).normalized() * radius
	path.add_with_speed(Segment.linear(Vector3.ZERO, p), const_movement_speed, Easing.linear)
	for i in range(count - 1):
		var q := Vector3(randf() * 2 - 1, 0, randf() * 2 - 1).normalized() * radius
		path.add_with_speed(Segment.linear(p, q), const_movement_speed, Easing.linear)
		p = q
	path.add_with_speed(Segment.linear(p, Vector3.ZERO), const_movement_speed, Easing.linear)
	return self
	
func random_points_in_disc(min_r: float, max_r: float, count: int) -> PathStyle:
	path = Pathway.new()
	var p := Vector3(randf_range(min_r, max_r) * cos(randf_range(-PI, PI)), 0, randf_range(min_r, max_r) * sin(randf_range(-PI, PI)))
	path.add_with_speed(Segment.linear(Vector3.ZERO, p), const_movement_speed, Easing.linear)
	for i in range(count - 1):
		var q := Vector3(randf_range(min_r, max_r) * cos(randf_range(-PI, PI)), 0, randf_range(min_r, max_r) * sin(randf_range(-PI, PI)))
#		var m := (p + q) / 2.0
#		path.add(Segment.quad(p, q, m))
		path.add_with_speed(Segment.linear(p, q), const_movement_speed, Easing.linear)
		p = q
	path.add_with_speed(Segment.linear(p, Vector3.ZERO), const_movement_speed, Easing.linear)
	return self
	
func movement_speed(time_override: float = NAN) -> float:
	var t: float
	if is_nan(time_override):
		t = float(Time.get_unix_time_from_system() - time_offset + seed_offset * 2 * PI)
	else:
		t = time_override
	var duration = fmod(t, path.total_duration)
	var index = Globals.Ref.new(0)
	path.position_at_time(duration, index)
	var result := path.movement_speed[index.data]
	return result if not is_zero_approx(result) else const_movement_speed
	

func next_position(me: Enemy, player: Player, is_done: Globals.Ref = null, time_override: float = NAN) -> Vector3:
	var t: float
	if is_nan(time_override):
		t = float(Time.get_unix_time_from_system() - time_offset + seed_offset * 2 * PI)
	else:
		t = time_override
	var old_t = last_t
	last_t = t
	if is_done:
		is_done.data = false
	if me_start_position == null:
		me_start_position = me.position
	var temp_origin := origin
	if origin_kind == OriginKind.PLAYER:
		temp_origin += player.position
	elif origin_kind == OriginKind.ME:
		temp_origin += me_start_position
	if player_vision_offset:
		var rot: float = player.get_node("CamPivot" if use_player_camera_as_vision else "Pivot").rotation.y
		var off: Vector3 = Vector3(0, 0, -player_vision_offset.y).rotated(Vector3.UP, rot + player_vision_offset.x)
		var rel_off := off + player.position
		var dist := me.position.distance_to(rel_off)
		if dist > player_vision_offset.w + 0.1:
			off = rel_off.lerp(me.position, player_vision_offset.w / dist) - player.position
		elif dist < player_vision_offset.z + 0.1:
			off = rel_off.lerp(me.position, player_vision_offset.z / dist) - player.position
		temp_origin += off
	
	
	var duration: float 
	if is_nan(time_override):
		duration = fmod(t, path.total_duration)
	else:
		duration = clamp(t, 0, path.total_duration)
	var index = Globals.Ref.new(0)
	var v = path.position_at_time(duration, index) + temp_origin
	
	if fmod(t, path.total_duration) < fmod(old_t, path.total_duration):
		me_start_position = null
		if is_done:
			is_done.data = true
		stored_loops += 1
		
	var y = next_y_position(me, v.x, v.y - temp_origin.y, v.z)
	return Vector3(v.x, y, v.z)

func next_y_position(me: Enemy, x: float, y: float, z: float) -> float:
	match coord_y:
		CoordY.GROUND: return Navigator.get_world_height(me.get_world_3d().direct_space_state, x, z)
		CoordY.GROUND_AND_DIRT: 
			var g := Navigator.get_world_height(me.get_world_3d().direct_space_state, x, z)
			if y > 0:
				return g
			else:
				return g + y
		CoordY.GROUND_AND_AIR: 
			var g := Navigator.get_world_height(me.get_world_3d().direct_space_state, x, z)
			if y < 0:
				return g
			else:
				return g + y
		CoordY.ORIGIN: return Navigator.get_world_height(me.get_world_3d().direct_space_state, x, z) + y
		_: return 0

class Pathway:
	# TODO: add interface for creating pathways similar to drawing API's
	# such move_to, line_to, arc etc
	
	var segments: Array[Segment]
	
	# represents the total time a segment is traversed for. used in conjunction
	# with `speed_modifier` to change the speed which a segment is traversed 
	var durations: Array[float]
	
	# each segment represents a  graph from [0,1] and returns a value in range[0,1] in the y component
	# this modifier changes the rate at which its corrosponding segment is traversed
	var path_modifiers: Array[Segment] 
	
	var distance: float
	var total_duration: float
	var movement_speed: Array[float]
	
	func _init(_segments: Array[Segment] = [], _durations: Array[float] = [], _path_modifiers: Array[Segment] = []):
		assert(_segments.size() == _path_modifiers.size(), "segment array must be the same size as speed array")
		assert(_durations.size() == _path_modifiers.size(), "duration array must be the same size as speed array")
		segments = _segments
		durations = _durations
		path_modifiers = _path_modifiers
		for i in range(_segments.size()):
			movement_speed.append(_segments[i].distance / _durations[i])
		calculate_distance()
		calculate_total_duration()
		
	static func empty() -> Pathway:
		var a := Segment.linear(Vector3.ZERO, Vector3.ZERO)
		return Pathway.new([a], [1], [Easing.linear])
		
	static func init_with_speed(_segments: Array[Segment], _speeds: Array[float], _path_modifiers: Array[Segment]) -> Pathway:
		var result := Pathway.new()
		result.append_with_speed(_segments, _speeds, _path_modifiers)
		return result
		
	func add(segment: Segment, duration: float, modifier: Segment):
		segments.append(segment)
		durations.append(duration)
		path_modifiers.append(modifier)
		movement_speed.append(segment.distance / duration)
		calculate_distance()
		calculate_total_duration()
		
	func add_with_speed(segment: Segment, speed: float, modifier: Segment):
		segments.append(segment)
		durations.append(segment.duration_using_speed(speed))
		path_modifiers.append(modifier)
		movement_speed.append(speed)
		calculate_distance()
		calculate_total_duration()
		
	func append(_segments: Array[Segment], _durations: Array[float], _path_modifiers: Array[Segment]):
		assert(_segments.size() == _path_modifiers.size(), "segment array must be the same size as speed array")
		assert(_durations.size() == _path_modifiers.size(), "duration array must be the same size as speed array")
		segments.append_array(_segments)
		durations.append_array(_durations)
		path_modifiers.append_array(_path_modifiers)
		for i in range(_segments.size()):
			movement_speed.append(_segments[i].distance / _durations[i])
		calculate_distance()
		calculate_total_duration()
		
	func append_with_speed(_segments: Array[Segment], _speeds: Array[float], _path_modifiers: Array[Segment]):
		assert(_segments.size() == _path_modifiers.size(), "segment array must be the same size as speed array")
		assert(_speeds.size() == _path_modifiers.size(), "speeds array must be the same size as speed array")
		segments.append_array(_segments)
		path_modifiers.append_array(_path_modifiers)
		for i in range(_segments.size()):
			var segment = _segments[i]
			var speed = _speeds[i]
			var duration := segment.duration_using_speed(speed)
			durations.append(duration)
			movement_speed.append(speed)
		calculate_distance()
		calculate_total_duration()
	
	func calculate_distance():
		distance = 0.0
		for s in segments:
			distance += s.distance
			
	func calculate_total_duration():
		total_duration = 0.0
		for t in durations:
			total_duration += t
			
	func position_at_time(t: float, index: Globals.Ref = null) -> Vector3:
		var running := 0.0
		var segment := 0
		for i in range(durations.size()):
			segment = i
			var ti = durations[i]
			if running <= t and t < running + ti:
				break
			running += ti
		t -= running
		if index:
			index.data = segment
			
		var ratio = t / durations[segment]
		var modifier = path_modifiers[segment].position_at_time(ratio).y
		return segments[segment].position_at_time(modifier)
			
	func position_at_distance(dist: float, index: Globals.Ref = null) -> Vector3:
		var segment := 0
		var running := 0.0
		for i in range(segments.size()):
			segment = i
			var s = segments[i]
			if running <= dist and dist <= running + s.distance:
				break
			running += s.distance
		dist -= running
		if index:
			index.data = segment
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
		
	static func easing(x1: float, y1: float, x2: float, y2: float) -> Segment:
		return Segment.cubic(Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(x1, y1, 0), Vector3(x2, y2, 0))
		
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
		
	func duration_using_speed(s: float) -> float:
		return distance / s
		
class Easing:
	static var linear := Segment.linear(Vector3(0, 0, 0), Vector3(0, 1, 0))
	
	static var in_sine := Segment.easing(0.12, 0, 0.39, 0)
	static var out_sine := Segment.easing(0.61, 1, 0.88, 1)
	static var in_out_sine := Segment.easing(0.37, 0, 0.63, 1)
	
	static var in_quad := Segment.easing(0.11, 0, 0.5, 0)
	static var out_quad := Segment.easing(0.5, 1, 0.89, 1)
	static var in_out_quad := Segment.easing(0.45, 0, 0.55, 1)
	
	static var in_cubic := Segment.easing(0.32, 0, 0.67, 0)
	static var out_cubic := Segment.easing(0.33, 1, 0.68, 1)
	static var in_out_cubic := Segment.easing(0.65, 0, 0.35, 1)
	
	static var in_quart := Segment.easing(0.5, 0, 0.75, 0)
	static var out_quart := Segment.easing(0.25, 1, 0.5, 1)
	static var in_out_quart := Segment.easing(0.76, 0, 0.24, 1)
	
	static var in_quint := Segment.easing(0.64, 0, 0.78, 0)
	static var out_quint := Segment.easing(0.22, 1, 0.36, 1)
	static var in_out_quint := Segment.easing(0.83, 0, 0.17, 1)
	
	static var in_expo := Segment.easing(0.7, 0, 0.84, 0)
	static var out_expo := Segment.easing(0.16, 1, 0.3, 1)
	static var in_out_expo := Segment.easing(0.87, 0, 0.13, 1)
	
	static var in_circ := Segment.easing(0.55, 0, 1, 0.45)
	static var out_circ := Segment.easing(0, 0.55, 0.45, 1)
	static var in_out_circ := Segment.easing(0.85, 0, 0.15, 1)
	
	static var in_back := Segment.easing(0.36, 0, 0.66, -0.56)
	static var out_back := Segment.easing(0.34, 1.56, 0.64, 1)
	static var in_out_back := Segment.easing(0.68, -0.6, 0.32, 1.6)
		
		
		
