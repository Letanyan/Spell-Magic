class_name Vec2

static func xy(v: Vector3) -> Vector2: return Vector2(v.x, v.y)
static func xz(v: Vector3) -> Vector2: return Vector2(v.x, v.z)

static func yx(v: Vector3) -> Vector2: return Vector2(v.y, v.x)
static func zx(v: Vector3) -> Vector2: return Vector2(v.z, v.x)

static func yz(v: Vector3) -> Vector2: return Vector2(v.y, v.z)
static func zy(v: Vector3) -> Vector2: return Vector2(v.z, v.y)

static func a(v: float) -> Vector2: return Vector2(v, v)
static func x(v: float) -> Vector2: return Vector2(v, 0)
static func y(v: float) -> Vector2: return Vector2(0, v)
