class_name PathStyle

enum CoordY { GROUND, ORIGIN, GROUND_AND_AIR, GROUND_AND_DIRT, AIR, GROUND_AND_JUMP }
enum Mover { PHYSICS, ABSOLUTE }
enum LookAt { VELOCITY, PLAYER, PLAYER_XZ }
enum OriginKind { ABSOLUTE, PLAYER, ME, VISION }
enum PlayerVisionAngle { CAMERA, BODY_ROTATION }

enum InitialPositionCanUpdate {
	ON_GROUND = 1 << 0,
	UNDERGROUND = 1 << 1,
	IN_AIR = 1 << 2,
	AT_INTERCHANGE = 1 << 3,
	WHEN_LOOP = 1 << 4,
	
	ON_GROUND_AND_UNDER = 0b011,
	ON_GROUND_AND_AIR = 0b101,
	UNDERGROUND_AND_AIR = 0b110,
	ALWAYS = 0b1111,
	NEVER = 0b0
}

var origin := Vector3.ZERO
var path: Pathway = null
var origin_kind: OriginKind
var rng: RandomNumberGenerator
var mover: Mover = Mover.ABSOLUTE
var coord_y: CoordY = CoordY.GROUND
var lookat: LookAt = LookAt.VELOCITY
var stored_loops: int = 0
var loop_count_start: int = 0
var last_path_segment_index: int = 0
var time: float = NAN
var old_position: Vector4 = Vector4.ZERO
var old_origin: Vector3 = Vector3.ZERO
var is_on_path: bool = false

var when_initial_position_can_update: int = InitialPositionCanUpdate.ALWAYS
var can_update_initial_position_now: bool = true

var me_start_position: Variant = null # used to store entity position (Vec3) at start of movement

var previous_path_index: int = -1 # previous path index used to update `player_start_position`
var player_start_position: Variant = null # used to store entity position (Vec3) at start of movement for each path
var player_start_vision_rotation: Variant = null # used to store entity rotation (float) at start of movement for each path

# (theta, radius, min_margin, max_margin) pair to describe offset from player. +theta is ccw from 
# straight of player view. -theta is cw from player view. radius is distance away
# from player. (min|max)_margin are the radi of disc with center (theta, radius)
var player_vision_offset: Vector4 = Vector4.ZERO
var player_vision_angle: PlayerVisionAngle = PlayerVisionAngle.BODY_ROTATION

func _init(_seed: int = randi(), _origin: Vector3 = Vector3.ZERO) -> void:
	origin = _origin
	rng = RandomNumberGenerator.new()
	rng.seed = _seed
	origin_kind = OriginKind.ABSOLUTE
	path = Pathway.empty()
	
func reset() -> void:
	time = NAN
	previous_path_index = -1
	player_start_position = null
	player_start_vision_rotation = null
	me_start_position = null
	stored_loops = loop_count_start
		
static func still_path() -> PathStyle:
	var result := PathStyle.new()
	result.use_absolute()
	result.set_use_me_as_origin()
	result.align_y_to_origin()
	result.path = Pathway.empty()
	return result
	
func set_origin(o: Vector3) -> PathStyle:
	origin = o
	return self
	
func look_at_player() -> PathStyle:
	lookat = LookAt.PLAYER
	return self
	
func look_at_direction() -> PathStyle:
	lookat = LookAt.VELOCITY
	return self
	
func look_at_player_xz() -> PathStyle:
	lookat = LookAt.PLAYER_XZ
	return self
	
func use_physics() -> PathStyle:
	mover = Mover.PHYSICS
	return self
	
func use_absolute() -> PathStyle:
	mover = Mover.ABSOLUTE
	return self
	
func set_initial_position_can_update(can_update: InitialPositionCanUpdate = InitialPositionCanUpdate.ALWAYS) -> PathStyle:
	when_initial_position_can_update = can_update
	return self

func set_use_absolute_origin(o: Vector3) -> PathStyle:
	origin_kind = OriginKind.ABSOLUTE
	origin = o
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
	
func set_player_body_rotation_as_vision_angle(a: float, r: float, min_m: float = 0.0, max_m: float = min_m) -> PathStyle:
	player_vision_angle = PlayerVisionAngle.BODY_ROTATION
	player_vision_offset = Vector4(a, r, min_m, max_m)
	origin_kind = OriginKind.VISION
	origin = Vector3.ZERO
	return self
	
func set_player_camera_as_vision_angle(a: float, r: float, min_m: float = 0.0, max_m: float = min_m) -> PathStyle:
	player_vision_angle = PlayerVisionAngle.CAMERA
	player_vision_offset = Vector4(a, r, min_m, max_m)
	origin_kind = OriginKind.VISION
	origin = Vector3.ZERO
	return self
	
## movement is allowed above and below ground
func align_y_to_origin() -> PathStyle:
	coord_y = CoordY.ORIGIN
	return self
	
## movement is fixed to ground
func align_y_to_ground() -> PathStyle:
	coord_y = CoordY.GROUND
	return self
	
## movement is allowed on ground or above ground
func align_y_to_ground_and_air() -> PathStyle:
	coord_y = CoordY.GROUND_AND_AIR
	return self
	
## movement is allowed on ground or below ground
func align_y_to_ground_and_dirt() -> PathStyle:
	coord_y = CoordY.GROUND_AND_DIRT
	return self
	
## movement is allowed above ground (flying)
func align_y_to_air() -> PathStyle:
	coord_y = CoordY.AIR
	return self
	
## movement is allowed above ground (flying)
func align_y_to_ground_and_jump() -> PathStyle:
	coord_y = CoordY.GROUND_AND_JUMP
	return self
	
func towards_player(speed: float, mn: float, mx: float) -> PathStyle:
	player_vision_angle = PlayerVisionAngle.BODY_ROTATION
	player_vision_offset = Vector4(0.0, 0.0, mn, mx)
	origin_kind = OriginKind.VISION
	origin = Vector3.ZERO
	path = Pathway.empty(speed)
	return self
	
func follow_path(pathway: Pathway) -> PathStyle:
	path = pathway
	return self
	
func transform_path(transform: Variant) -> PathStyle:
	if transform is Transform3D:
		path.apply_transform(transform as Transform3D)
	elif transform is Array[Transform3D]:
		for t: Transform3D in (transform as Array):
			path.apply_transform(t)
	else:
		push_error("Expected Transform3D/Array[Transform3D] for transform_path")
	return self
	
# xyz = position, w = speed
func next_position(delta: float, me: Node3D, player: Variant, is_done: Globals.Ref = null) -> Vector4:
	if is_nan(time):
		time = 0.0
	else:
		time += delta
	if is_done:
		is_done.data = false
	if me_start_position == null:
		me_start_position = me.position
		if me is Enemy:
			me_start_position.y -= (me as Enemy).bounds.y / 2.0
	if player_start_position == null:
		if player is Player:
			player_start_position = (player as Player).position
			player_start_position.y -= (player as Player).bounds.y / 2.0
		elif player is Vector3:
			player_start_position = player
	if origin_kind == OriginKind.VISION and player_start_vision_rotation == null:
		if player is Player:
			if player_vision_angle == PlayerVisionAngle.CAMERA:
				player_start_vision_rotation = ((player as Player).get_node("CamPivot") as Node3D).rotation.y
			elif player_vision_angle == PlayerVisionAngle.BODY_ROTATION:
				player_start_vision_rotation = ((player as Player).get_node("Pivot") as Node3D).rotation.y
		else:
			player_start_vision_rotation = 0.0
	var temp_origin := origin
	if origin_kind == OriginKind.PLAYER or origin_kind == OriginKind.VISION:
		temp_origin += player_start_position
	elif origin_kind == OriginKind.ME:
		temp_origin += me_start_position
	
	if origin_kind == OriginKind.VISION:
		var off: Vector3 = Vector3(0, 0, -player_vision_offset.y).rotated(Vector3.UP, player_start_vision_rotation as float + player_vision_offset.x)
		var rel_off := off + (player_start_position as Vector3)
		var dist := me.position.distance_to(rel_off)
		if dist > player_vision_offset.w + 0.1:
			off = rel_off.lerp(me.position, player_vision_offset.w / dist) - player_start_position
		elif dist < player_vision_offset.z + 0.1:
			off = rel_off.lerp(me.position, player_vision_offset.z / dist) - player_start_position
		temp_origin += off
		
	var time_was_up := false
	# don't use positions to determine completion as we might get stuck if time near total_duration
	if time > path.total_duration: #and me.position.is_equal_approx(Vector3(v.x, y, v.z)):
		if can_update_initial_position_now or (when_initial_position_can_update & InitialPositionCanUpdate.AT_INTERCHANGE != 0):
			me_start_position = null
		time_was_up = true
		time = time - path.total_duration
		if is_done:
			is_done.data = true
		stored_loops += 1
	
	var duration := clampf(time, 0, path.total_duration)
	var index := Globals.Ref.new(0)
	var psvr := 0.0 if player_start_vision_rotation == null else player_start_vision_rotation as float
	var v := path.position_at_time_with_rotation(duration, -psvr, index) + temp_origin
	var y := next_y_position(me, v.x, v.y - temp_origin.y, v.z)
	#print(y, " = ", v.y, " - ", temp_origin.y)
	if time_was_up and (when_initial_position_can_update & InitialPositionCanUpdate.WHEN_LOOP != 0):
		player_start_vision_rotation = null
		player_start_position = null
	if previous_path_index != index.data or is_zero_approx(time) or (player is Player and player.position != player_start_position) or (player is Vector3 and player != player_start_position):
		if can_update_initial_position_now or (when_initial_position_can_update & InitialPositionCanUpdate.AT_INTERCHANGE != 0):
			player_start_vision_rotation = null
			player_start_position = null
		previous_path_index = index.data
		
	is_on_path = Vector3(old_position.x, old_position.y, old_position.z).is_equal_approx(me.position) and old_origin.distance_to(temp_origin) < 0.1
	old_position = Vector4(v.x, y, v.z, path.speed_at_time(time, delta, is_on_path))
	old_origin = temp_origin
	
	return old_position

func next_y_position(me: Node3D, x: float, y: float, z: float) -> float:
	var me_y := 0.0
	if me is Enemy:
		me_y = (me as Enemy).bounds.y
	elif me is TargetShape:
		me_y = (me as TargetShape).bounds.y
		
	var result := 0.0
	var actual_y := y
	var g := Navigator.get_world_height(me.get_world_3d().direct_space_state, x, z) + me_y / 2.0
	match coord_y:
		CoordY.GROUND:
			result = g
			actual_y = 0.0
		CoordY.GROUND_AND_DIRT:
			if y > 0:
				result = g
				actual_y = 0.0
			else:
				result = g + y
		CoordY.GROUND_AND_AIR, CoordY.GROUND_AND_JUMP:
			if y < 0:
				result = g
				actual_y = 0.0
			else:
				result = g + y
		CoordY.ORIGIN: 
			result = g + y 
		CoordY.AIR:
			if y <= me_y / 2.0:
				result = g + me_y / 2.0
				actual_y = me_y / 2.0
			else:
				result = g + y

	if actual_y > 0.001:
		can_update_initial_position_now = when_initial_position_can_update & InitialPositionCanUpdate.IN_AIR != 0
	elif actual_y < -0.001:
		can_update_initial_position_now = when_initial_position_can_update & InitialPositionCanUpdate.UNDERGROUND != 0
	else:
		can_update_initial_position_now = when_initial_position_can_update & InitialPositionCanUpdate.ON_GROUND != 0
		
	return result

class Pathway:
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
	
	var cursor: Vector3 = Vector3.ZERO
	
	func _init(_segments: Array[Segment] = [], _durations: Array[float] = [], _path_modifiers: Array[Segment] = []) -> void:
		assert(_segments.size() == _path_modifiers.size(), "segment array must be the same size as speed array")
		assert(_durations.size() == _path_modifiers.size(), "duration array must be the same size as speed array")
		segments = _segments
		durations = _durations
		path_modifiers = _path_modifiers
		for i in range(_segments.size()):
			movement_speed.append(_segments[i].distance / _durations[i])
		calculate_distance()
		calculate_total_duration()
		
	static func empty(default_speed: float = 0.0, default_duration: float = 1.0) -> Pathway:
		var a := Segment.linear(Vector3.ZERO, Vector3.ZERO)
		var result := Pathway.new([a], [default_duration], [Easing.linear])
		result.movement_speed[0] = default_speed
		return result
		
	static func init_with_speed(_segments: Array[Segment], _speeds: Array[float], _path_modifiers: Array[Segment]) -> Pathway:
		var result := Pathway.new()
		result.append_with_speed(_segments, _speeds, _path_modifiers)
		return result
		
	func add(segment: Segment, duration: float, modifier: Segment) -> void:
		assert(duration != 0.0, "duration can not be zero")
		segments.append(segment)
		durations.append(duration)
		path_modifiers.append(modifier)
		movement_speed.append(segment.distance / duration)
		calculate_distance()
		calculate_total_duration()
		
	func add_with_speed(segment: Segment, speed: float, modifier: Segment) -> void:
		segments.append(segment)
		durations.append(segment.duration_using_speed(speed))
		path_modifiers.append(modifier)
		movement_speed.append(speed)
		calculate_distance()
		calculate_total_duration()
		
	func append(_segments: Array[Segment], _durations: Array[float], _path_modifiers: Array[Segment]) -> void:
		assert(_segments.size() == _path_modifiers.size(), "segment array must be the same size as speed array")
		assert(_durations.size() == _path_modifiers.size(), "duration array must be the same size as speed array")
		segments.append_array(_segments)
		durations.append_array(_durations)
		path_modifiers.append_array(_path_modifiers)
		for i in range(_segments.size()):
			assert(_durations[i] != 0.0, "duration can not be zero")
			movement_speed.append(_segments[i].distance / _durations[i])
		calculate_distance()
		calculate_total_duration()
		
	func append_with_speed(_segments: Array[Segment], _speeds: Array[float], _path_modifiers: Array[Segment]) -> void:
		assert(_segments.size() == _path_modifiers.size(), "segment array must be the same size as speed array")
		assert(_speeds.size() == _path_modifiers.size(), "speeds array must be the same size as speed array")
		segments.append_array(_segments)
		path_modifiers.append_array(_path_modifiers)
		for i in range(_segments.size()):
			var segment := _segments[i]
			var speed := _speeds[i]
			var duration := segment.duration_using_speed(speed)
			assert(duration != 0.0, "duration can not be zero")
			durations.append(duration)
			movement_speed.append(speed)
		calculate_distance()
		calculate_total_duration()
	
	func calculate_distance() -> void:
		distance = 0.0
		for s in segments:
			distance += s.distance
			
	func calculate_total_duration() -> void:
		total_duration = 0.0
		for t in durations:
			total_duration += t
			
	func position_at_time(t: float, index: Globals.Ref = null) -> Vector3:
		var running := 0.0
		var segment := 0
		for i in range(durations.size()):
			segment = i
			var ti := durations[i]
			if running <= t and t < running + ti:
				break
			running += ti
		t -= running
		if index:
			index.data = segment
			
		var ratio := t / durations[segment]
		var modifier := (path_modifiers[segment] as Segment).position_at_time(ratio).y
		return (segments[segment] as Segment).position_at_time(modifier)
		
	func position_at_time_with_rotation(t: float, angle: float, index: Globals.Ref = null) -> Vector3:
		var running := 0.0
		var segment := 0
		for i in range(durations.size()):
			segment = i
			var ti := durations[i]
			if t < running + ti or is_equal_approx(t, running + ti):
				break
			running += ti
		t -= running
		if index:
			index.data = segment
			
		var ratio := t / durations[segment]
		var modifier := (path_modifiers[segment] as Segment).position_at_time(ratio).y
		return (segments[segment] as Segment).position_at_time_with_rotation(modifier, angle)
		
	func speed_at_time(t: float, delta: float, use_relative_speed: float, index: Globals.Ref = null) -> float:
		var running := 0.0
		var segment := 0
		for i in range(durations.size()):
			segment = i
			var ti := durations[i]
			if t < running + ti or is_equal_approx(t, running + ti):
				break
			running += ti
		t -= running
		if index:
			index.data = segment
			
		if use_relative_speed and delta > 0:
			var change_in_t := delta / durations[segment]
			var ratio := t / durations[segment]
			var modifier := path_modifiers[segment]
			# we use absolute here because the direction is maintained in the position calculation
			var rate_of_change := absf(modifier.position_at_time(ratio - change_in_t).y - modifier.position_at_time(ratio).y) / change_in_t
			return movement_speed[segment] * max(rate_of_change, 0.1)
		else:
			return movement_speed[segment]			
			
	func position_at_distance(dist: float, index: Globals.Ref = null) -> Vector3:
		var segment := 0
		var running := 0.0
		for i in range(segments.size()):
			segment = i
			var s := segments[i]
			if running <= dist and dist <= running + s.distance:
				break
			running += s.distance
		dist -= running
		if index:
			index.data = segment
		return segments[segment].position_at_distance(dist)
		
	func apply_transform(transform: Transform3D) -> void:
		for segment in segments:
			segment.apply_transform(transform)
		calculate_distance()
		calculate_total_duration()
		
	func move_to(start: Vector3) -> Pathway:
		cursor = start
		return self
		
	func wait(d: float) -> Pathway:
		add(Segment.point(cursor, d), d, Easing.linear)
		return self
		
	func line_to(end: Vector3, d: float, m: Segment = Easing.linear) -> Pathway:
		add(Segment.linear(cursor, end), d, m)
		cursor = end
		return self
		
	func cubic_to(end: Vector3, c1: Vector3, c2: Vector3, d: float, m: Segment = Easing.linear) -> Pathway:
		add(Segment.cubic(cursor, end, c1, c2), d, m)
		cursor = end
		return self
		
	func quad_to(end: Vector3, c1: Vector3, d: float, m: Segment = Easing.linear) -> Pathway:
		add(Segment.quad(cursor, end, c1), d, m)
		cursor = end
		return self
		
	func line_with_speed_to(end: Vector3, s: float, m: Segment = Easing.linear) -> Pathway:
		add_with_speed(Segment.linear(cursor, end), s, m)
		cursor = end
		return self
		
	func cubic_with_speed_to(end: Vector3, c1: Vector3, c2: Vector3, s: float, m: Segment = Easing.linear) -> Pathway:
		add_with_speed(Segment.cubic(cursor, end, c1, c2), s, m)
		cursor = end
		return self
		
	func quad_with_speed_to(end: Vector3, c1: Vector3, s: float, m: Segment = Easing.linear) -> Pathway:
		add_with_speed(Segment.quad(cursor, end, c1), s, m)
		cursor = end
		return self
		
	func arc_to(end: Vector3, clockwise: bool, dur: float, m: Segment = Easing.linear) -> Pathway:
		add(Segment.arc_between_of_points(cursor, end), dur, m)
		cursor = end
		return self
		
	func arc_with_speed_to(end: Vector3, clockwise: bool, s: float, m: Segment = Easing.linear) -> Pathway:
		add_with_speed(Segment.arc_between_of_points(cursor, end), s, m)
		cursor = end
		return self
		
	func circle(radius: float, h: float, dur: float, m: Segment = Easing.linear) -> Pathway:
		var a := Segment.cubic(Vector3(0, h, radius)+cursor, Vector3(0, h, -radius)+cursor, Vector3(radius * 1.5, h, radius)+cursor, Vector3(radius * 1.5, h, -radius)+cursor)
		var b := Segment.cubic(Vector3(0, h, -radius)+cursor, Vector3(0, h, radius)+cursor, Vector3(radius * -1.5, h, -radius)+cursor, Vector3(radius * -1.5, h, radius)+cursor)
		add(a, dur / 2.0, m)
		add(b, dur / 2.0, m)
		return self
		
	func circle_with_speed(radius: float, h: float, s: float, m: Segment = Easing.linear) -> Pathway:
		var a := Segment.cubic(Vector3(0, h, radius)+cursor, Vector3(0, h, -radius)+cursor, Vector3(radius * 1.5, h, radius)+cursor, Vector3(radius * 1.5, h, -radius)+cursor)
		var b := Segment.cubic(Vector3(0, h, -radius)+cursor, Vector3(0, h, radius)+cursor, Vector3(radius * -1.5, h, -radius)+cursor, Vector3(radius * -1.5, h, radius)+cursor)
		add_with_speed(a, s, m)
		add_with_speed(b, s, m)
		return self
		
	func random_points_in_disc(speed: float, min_r: float, max_r: float, h: float, count: int, m: Segment = Easing.linear, rng: RandomNumberGenerator = null) -> Pathway:
		if rng == null:
			rng = RandomNumberGenerator.new()
			rng.seed = Time.get_ticks_usec()
		var p := Vector3(rng.randf() * 2.0 - 1.0, h, rng.randf() * 2.0 - 1.0) * rng.randf_range(min_r, max_r) + Vector3(0, h, 0)
		add_with_speed(Segment.linear(cursor, p), speed, m)
		for i in range(count - 1):
			var q := Vector3(rng.randf() * 2.0 - 1.0, 0, rng.randf() * 2.0 - 1.0).normalized() * rng.randf_range(min_r, max_r) + Vector3(0, h, 0)
			add_with_speed(Segment.linear(p, q), speed, m)
			p = q
		add_with_speed(Segment.linear(p, cursor), speed, m)
		return self
		
	func random_points_in_sphere(speed: float, min_r: float, max_r: float, count: int, m: Segment = Easing.linear, rng: RandomNumberGenerator = null) -> Pathway:
		if rng == null:
			rng = RandomNumberGenerator.new()
			rng.seed = Time.get_ticks_usec()
		var p := Vector3(rng.randf(), rng.randf(), rng.randf()).normalized() * randf_range(min_r, max_r)
		add_with_speed(Segment.linear(cursor, p), speed, m)
		for i in range(count - 1):
			var q := Vector3(rng.randf(), rng.randf(), rng.randf()).normalized() * randf_range(min_r, max_r)
			add_with_speed(Segment.linear(p, q), speed, m)
			p = q
		add_with_speed(Segment.linear(p, cursor), speed, m)
		return self
		

class Segment:
	enum BezierKind { LINEAR, QUAD, CUBIC }
	
	var start: Vector3
	var end: Vector3
	var c1: Vector3
	var c2: Vector3
	var kind: BezierKind
	var distance: float
	
	func _init(s: Vector3, e: Vector3, cc1: Vector3, cc2: Vector3, k: BezierKind, d: Variant = null) -> void:
		start = s
		end = e
		c1 = cc1
		c2 = cc2
		kind = k
		if d != null:
			distance = d
		else:
			calculate_distance()
	
	# we must provide a distance for speed and duration calculations used later
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
		
	static func arc_between_of_points(a: Vector3, b: Vector3) -> Segment:
		var q1 := a.x * a.x + a.z * a.z
		var q2 := q1 + a.x * b.x + a.z * b.z
		var k2 := (4.0 / 3.0) * (sqrt(2 * q1 * q2) - q2) / (a.x * b.z - a.z * b.x)

		var c := Vector3(a.x - k2 * a.z, lerpf(a.y, b.y, 0.33), a.z + k2 * a.x)
		var d := Vector3(b.x + k2 * b.z, lerpf(a.y, b.y, 0.66), b.z - k2 * b.x)
		
		return Segment.new(a, b, c, d, BezierKind.CUBIC)
		
	func calculate_distance(interval: float = 0.005) -> void:
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
		
	func position_at_time_with_rotation(t: float, angle: float) -> Vector3:
		var mat := Transform3D.IDENTITY.rotated(Vector3.UP, angle)
		match kind:
			BezierKind.LINEAR:
				return lerp(mat * start, mat * end, t)
			BezierKind.QUAD:
				var s := mat * start
				var i1 := mat * c1
				var e := mat * end
				var a: Vector3 = lerp(s, i1, t)
				var b: Vector3 = lerp(i1, e, t)
				return lerp(a, b, t)
			BezierKind.CUBIC:
				var s := mat * start
				var i1 := mat * c1
				var i2 := mat * c2
				var e := mat * end
				var a1: Vector3 = lerp(s, i1, t)
				var b1: Vector3 = lerp(i1, e, t)
				var e1: Vector3 = lerp(a1, b1, t)
				var a2: Vector3 = lerp(i1, i2, t)
				var b2: Vector3 = lerp(i2, e, t)
				var e2: Vector3 = lerp(a2, b2, t)
				return lerp(e1, e2, t)
				
		return Vector3.ZERO
		
	func position_at_distance(dist: float) -> Vector3:
		var t := dist / distance
		return position_at_time(t)
		
	func duration_using_speed(s: float) -> float:
		return distance / s
		
	func apply_transform(transform: Transform3D) -> void:
		var mat := transform
		match kind:
			BezierKind.LINEAR:
				start = mat * start
				end = mat * end
			BezierKind.QUAD:
				start = mat * start
				end = mat * end
				c1 = mat * c1
			BezierKind.CUBIC:
				start = mat * start
				end = mat * end
				c1 = mat * c1
				c2 = mat * c2
		calculate_distance()
		
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
