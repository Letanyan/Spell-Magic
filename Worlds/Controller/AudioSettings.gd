class_name AudioSettings

var master := 0.7
var bg := 1.0
var sfx := 1.0


func save_dict() -> Dictionary:
	return {
		"master": master, "bg": bg, "sfx": sfx,
	}

func load_dict(dict: Dictionary) -> void:
	update_master(dict.get("master", 0.7) as float)
	update_bg(dict.get("bg", 1.0) as float)
	update_sfx(dict.get("sfx", 1.0) as float)

func update_master(value: float) -> void:
	master = value
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))
	
func update_bg(value: float) -> void:
	bg = value
	var bus := AudioServer.get_bus_index("BG")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))
	
func update_sfx(value: float) -> void:
	sfx = value
	var bus := AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))
