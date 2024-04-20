class_name CameraSettings

var fov := 75


func save_dict() -> Dictionary:
	return {
		"fov": fov
	}

func load_dict(dict: Dictionary) -> void:
	fov = dict.get("fov", 75.0)
