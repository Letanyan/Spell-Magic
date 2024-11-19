class_name CameraSettings

var fov := 75
var distance := 5.0
var auto_distance := true
var render_distance := 4000.0


func save_dict() -> Dictionary:
	return {
		"fov": fov, "distance": distance, "auto_distance": auto_distance,
		"render_distance": render_distance,
	}

func load_dict(dict: Dictionary) -> void:
	fov = dict.get("fov", 75.0)
	distance = dict.get("distance", 5.0)
	auto_distance = dict.get("auto_distance", true)
	render_distance = dict.get("render_distance", 4000.0)
