class_name Debug3D

static func draw_sphere(position: Vector3, radius: float = 0.5, color: Color = Color.BLACK, duration: float = 0.0) -> void:
	if GlobalData.is_debug:
		DebugDraw3D.draw_sphere(position, radius, color, duration)
	
static func draw_line(a: Vector3, b: Vector3, color: Color = Color.BLACK, duration: float = 0.0) -> void:
	if GlobalData.is_debug:
		DebugDraw3D.draw_line(a, b, color, duration)
	
static func draw_arrow_ray(origin: Vector3, direction: Vector3, length: float = 0.5, color: Color = Color.BLACK, arrow_size: float = 0.5, is_absolute_size: bool = false, duration: float = 0.0) -> void:
	if GlobalData.is_debug:
		DebugDraw3D.draw_arrow_ray(origin, direction, length, color, arrow_size, is_absolute_size, duration) 
