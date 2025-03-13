class_name Vec3

static func xy(v: Vector2) -> Vector3: return Vector3(v.x, v.y, 0)
static func xz(v: Vector2) -> Vector3: return Vector3(v.x, 0, v.y)
static func yz(v: Vector2) -> Vector3: return Vector3(0, v.x, v.y)

static func yx(v: Vector2) -> Vector3: return Vector3(v.y, v.x, 0)
static func zx(v: Vector2) -> Vector3: return Vector3(v.y, 0, v.x)
static func zy(v: Vector2) -> Vector3: return Vector3(0, v.y, v.x)

static func a(v: float) -> Vector3: return Vector3(v, v, v)
static func x(v: float) -> Vector3: return Vector3(v, 0, 0)
static func y(v: float) -> Vector3: return Vector3(0, v, 0)
static func z(v: float) -> Vector3: return Vector3(0, 0, v)

static func xyz(v: Vector4) -> Vector3: return Vector3(v.x, v.y, v.z)

static func xz_y(vxz: Vector3, vy: float) -> Vector3:
	return Vector3(vxz.x, vy, vxz.z)
	
static func xz__y(vxz: Vector2, vy: float) -> Vector3:
	return Vector3(vxz.x, vy, vxz.y)

static func polar(radius: float, angle: float, height: float = 0.0) -> Vector3:
	return Vector3(radius, 0, 0).rotated(Vector3.UP, angle) + Vec3.y(height)

static func max(v: Vector3) -> float:
	return maxf(v.x, maxf(v.y, v.z))

static func volume(vec: Vector3) -> float:
	return vec.x * vec.y * vec.z
