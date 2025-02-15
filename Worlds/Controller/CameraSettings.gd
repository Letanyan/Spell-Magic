class_name CameraSettings

var fov := 75
var distance := 5.0
var auto_distance := true
var render_distance := 4000.0
var panning_speed_x := 1.0
var panning_speed_y := 1.0


func save_dict() -> Dictionary:
	return {
		"fov": fov, "distance": distance, "auto_distance": auto_distance,
		"render_distance": render_distance, "panning_speed_x": panning_speed_x,
		"panning_speed_y": panning_speed_y,
	}

func load_dict(dict: Dictionary) -> void:
	fov = dict.get("fov", 75.0)
	distance = dict.get("distance", 5.0)
	auto_distance = dict.get("auto_distance", true)
	render_distance = dict.get("render_distance", 4000.0)
	panning_speed_x = dict.get("panning_speed_x", 1.0)
	panning_speed_y = dict.get("panning_speed_y", 1.0)

func panning_speed() -> Vector2:
	return Vector2(panning_speed_x, panning_speed_y)
