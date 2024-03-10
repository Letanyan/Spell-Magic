class_name GameSettings

enum ReadyState { NOT, IN, IS }

var last_world: String
var default_world_settings: WorldSettings

func save():
	var file = FileAccess.open("user://settings.json", FileAccess.WRITE)
	file.store_var({"last_world": last_world, "default_world_settings": default_world_settings.save_dict()})

func read(viewport: Viewport):
	var file = FileAccess.open("user://settings.json", FileAccess.READ)
	var data: Variant
	if file != null:
		data = file.get_var()
	else:
		data = {}
	last_world = data.get("last_world", "")
	
	default_world_settings = WorldSettings.new(viewport)
	default_world_settings.load_dict(data.get("default_world_settings", {})) 
	
