class_name HUDSettings

var hide_wand_mappings: bool = false
var hide_wand_modifier_hints: bool = false

func save_dict():
	return {
		"hide_wand_mappings": hide_wand_mappings, "hide_wand_modifier_hints": hide_wand_modifier_hints 
	}

func load_dict(dict: Dictionary):
	hide_wand_mappings = dict.get("hide_wand_mappings", false)
	hide_wand_modifier_hints = dict.get("hide_wand_modifier_hints", false)
