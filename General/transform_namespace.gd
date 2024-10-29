class_name T

const I = Transform3D.IDENTITY

static func affine_inverse() -> Transform3D: return I.affine_inverse()
static func interpolate_with(xform: Transform3D, weight: float) -> Transform3D: return I.interpolate_with(xform, weight)
static func inverse() -> Transform3D: return I.inverse()
static func is_equal_approx(xform: Transform3D) -> bool: return I.is_equal_approx(xform)
static func is_finite() -> bool: return I.is_finite()
static func looking_at(target: Vector3, up: Vector3 = Vector3(0, 1, 0), use_model_front: bool = false) -> Transform3D: return I.looking_at(target, up, use_model_front)
static func orthonormalized() -> Transform3D: return I.orthonormalized()
static func rotated(axis: Vector3, angle: float) -> Transform3D: return I.rotated(axis, angle)
static func rotated_local(axis: Vector3, angle: float) -> Transform3D: return I.rotated_local(axis, angle)
static func scaled(scale: Vector3) -> Transform3D: return I.scaled(scale)
static func scaled_local(scale: Vector3) -> Transform3D: return I.scaled_local(scale)
static func translated(offset: Vector3) -> Transform3D: return I.translated(offset)
static func translated_local(offset: Vector3) -> Transform3D: return I.translated_local(offset)
