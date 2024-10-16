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
