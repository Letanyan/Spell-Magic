class_name AudioSettings

var master := 0.0
var bg := 0.0
var sfx := 0.0


func save_dict():
	return {
		"master": master, "bg": bg, "sfx": sfx,
	}

func load_dict(dict: Dictionary):
	update_master(dict.get("master", 0.0))
	update_bg(dict.get("bg", 0.0))
	update_sfx(dict.get("sfx", 0.0))

func update_master(value: float):
	master = value
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))
	
func update_bg(value: float):
	bg = value
	var bus := AudioServer.get_bus_index("BG")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))
	
func update_sfx(value: float):
	sfx = value
	var bus := AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))
