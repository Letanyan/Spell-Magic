class_name Pathway
	
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
	
func position_at_time_with_transform(t: float, transform: Transform3D, index: Globals.Ref = null) -> Vector3:
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
	return (segments[segment] as Segment).position_at_time_with_transform(modifier, transform)
	
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
	
func apply_transform(transform: Transform3D) -> Pathway:
	for segment in segments:
		segment.apply_transform(transform)
	calculate_distance()
	calculate_total_duration()
	return self
	
func move_to(start: Vector3) -> Pathway:
	cursor = start
	return self
	
func wait(d: float, point: Vector3 = cursor) -> Pathway:
	add(Segment.point(point, d), d, Easing.linear)
	return self
	
func line_to(end: Vector3, speed: float, m: Segment = Easing.linear) -> Pathway:
	add_with_speed(Segment.linear(cursor, end), speed, m)
	cursor = end
	return self
	
func cubic_to(end: Vector3, c1: Vector3, c2: Vector3, speed: float, m: Segment = Easing.linear) -> Pathway:
	add_with_speed(Segment.cubic(cursor, end, c1, c2), speed, m)
	cursor = end
	return self
	
func quad_to(end: Vector3, c1: Vector3, speed: float, m: Segment = Easing.linear) -> Pathway:
	add_with_speed(Segment.quad(cursor, end, c1), speed, m)
	cursor = end
	return self
	
func arc_to(end: Vector3, clockwise: bool, speed: float, m: Segment = Easing.linear) -> Pathway:
	add_with_speed(Segment.arc_between_of_points(cursor, end), speed, m)
	cursor = end
	return self
	
func sample_points(count: int) -> PackedVector3Array:
	var result := PackedVector3Array([])
	var t := 0.0
	var step := total_duration / float(count)
	var index := Globals.Ref.new(0)
	var i := 0
	while i < count:
		var p := position_at_time_with_transform(t, Transform3D.IDENTITY, index)
		result.append(p)
		t += step
		i += 1
	return result
	
func sample_points_xz(count: int) -> PackedVector2Array:
	var result := PackedVector2Array([])
	var points := sample_points(count)
	for p in points:
		result.append(Vector2(p.x, p.z))
	return result
	
func circle(radius: float, h: float, s: float, m: Segment = Easing.linear) -> Pathway:
	var a := Segment.cubic(Vector3(0, h, radius)+cursor, Vector3(0, h, -radius)+cursor, Vector3(radius * 1.5, h, radius)+cursor, Vector3(radius * 1.5, h, -radius)+cursor)
	var b := Segment.cubic(Vector3(0, h, -radius)+cursor, Vector3(0, h, radius)+cursor, Vector3(radius * -1.5, h, -radius)+cursor, Vector3(radius * -1.5, h, radius)+cursor)
	add_with_speed(a, s, m)
	add_with_speed(b, s, m)
	return self
	
func random_points_in_disc(speed: float, min_r: float, max_r: float, h: float, count: int, m: Segment = Easing.linear, rng: RandomNumberGenerator = null) -> Pathway:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.seed = Time.get_ticks_usec()
	var p := Vector3(rng.randf() * 2.0 - 1.0, h, rng.randf() * 2.0 - 1.0) * rng.randf_range(min_r, max_r) + Vector3(0, h, 0) + cursor
	add_with_speed(Segment.linear(cursor, p), speed, m)
	for i in range(count - 1):
		var q := Vector3(rng.randf() * 2.0 - 1.0, 0, rng.randf() * 2.0 - 1.0).normalized() * rng.randf_range(min_r, max_r) + Vector3(0, h, 0) + cursor
		add_with_speed(Segment.linear(p, q), speed, m)
		p = q
	add_with_speed(Segment.linear(p, cursor), speed, m)
	return self
	
func random_points_in_sphere(speed: float, min_r: float, max_r: float, count: int, m: Segment = Easing.linear, rng: RandomNumberGenerator = null) -> Pathway:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.seed = Time.get_ticks_usec()
	var p := Vector3(rng.randf(), rng.randf(), rng.randf()).normalized() * randf_range(min_r, max_r) + cursor
	add_with_speed(Segment.linear(cursor, p), speed, m)
	for i in range(count - 1):
		var q := Vector3(rng.randf(), rng.randf(), rng.randf()).normalized() * randf_range(min_r, max_r) + cursor
		add_with_speed(Segment.linear(p, q), speed, m)
		p = q
	add_with_speed(Segment.linear(p, cursor), speed, m)
	return self
	
func ngon(speed: float, sides: int, radius: float, m: Segment = Easing.linear, rng: RandomNumberGenerator = null) -> Pathway:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.seed = Time.get_ticks_usec()
	var angle_step := (2.0 * PI) / sides
	var p := Vector3(radius, 0.0, 0.0)
	move_to(p)
	for i in range(sides):
		p = p.rotated(Vector3.UP, angle_step)
		line_to(p, speed, m)
	return self
	
func to_and_back(speed: float, to: Vector3, m: Segment = Easing.linear) -> Pathway:
	var o := cursor
	line_to(to, speed, m)
	line_to(o, speed, m)
	return self

func from_to_and_back(speed: float, from: Vector3, to: Vector3, m: Segment = Easing.linear) -> Pathway:
	move_to(from)
	line_to(to, speed, m)
	line_to(from, speed, m)
	return self
