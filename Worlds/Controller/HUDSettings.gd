class_name HUDSettings

var hide_wand_mappings: bool = false

func save_dict():
	return {
		"hide_wand_mappings": hide_wand_mappings 
	}

func load_dict(dict: Dictionary):
	hide_wand_mappings = dict.get("hide_wand_mappings", false)
