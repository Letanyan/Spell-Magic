class_name CameraSettings

var fov := 75


func save_dict():
	return {
		"fov": fov
	}

func load_dict(dict: Dictionary):
	fov = dict.get("fov", 75.0)
