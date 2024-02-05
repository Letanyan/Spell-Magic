class_name GraphicsSettings

var scaling_mode := 0
var scaling := 1.0
var sharpness := 0.2


func save_dict():
	return {
		"scaling_mode": scaling_mode, "scaling": scaling, "sharpness": sharpness
	}

func load_dict(dict: Dictionary):
	scaling_mode = dict.get("scaling_mode", 0)
	scaling = dict.get("scaling", 1.0)
	sharpness = dict.get("sharpness", 0.2)
	
	ProjectSettings.set_setting("rendering/scaling_3d/sharpness", sharpness)
	ProjectSettings.set_setting("rendering/scaling_3d/scale", scaling)
	ProjectSettings.set_setting("rendering/scaling_3d/mode", scaling_mode)
	
