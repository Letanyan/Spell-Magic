class_name Segment

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
