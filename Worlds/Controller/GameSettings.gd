class_name GameSettings

var last_world: String

func save():
	var file = FileAccess.open("user://settings.json", FileAccess.WRITE)
	file.store_var({"last_world": last_world})

func read():
	var file = FileAccess.open("user://settings.json", FileAccess.READ)
	var data: Variant
	if file != null:
		data = file.get_var()
	else:
		data = {}
	last_world = data.get("last_world", "")
	
