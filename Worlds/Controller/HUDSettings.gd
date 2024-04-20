class_name HUDSettings

var hide_wand_mappings: bool = false
var hide_wand_modifier_hints: bool = false
var hide_notifications: bool = false
var hide_status_effects: bool = false
var hide_health_mana: bool = false
var hide_cooldown_timings: bool = false
var hide_stats_view: bool = true

func save_dict() -> Dictionary:
	return {
		"hide_wand_mappings": hide_wand_mappings, "hide_wand_modifier_hints": hide_wand_modifier_hints,
		"hide_notifications": hide_notifications, "hide_status_effects": hide_status_effects,
		"hide_health_mana": hide_health_mana, "hide_cooldown_timings": hide_cooldown_timings,
		"hide_stats_view": hide_stats_view
	}

func load_dict(dict: Dictionary) -> void:
	hide_wand_mappings = dict.get("hide_wand_mappings", false)
	hide_wand_modifier_hints = dict.get("hide_wand_modifier_hints", false)
	hide_notifications = dict.get("hide_notifications", false)
	hide_status_effects = dict.get("hide_status_effects", false)
	hide_health_mana = dict.get("hide_health_mana", false)
	hide_cooldown_timings = dict.get("hide_cooldown_timings", false)
	hide_stats_view = dict.get("hide_stats_view", true)
