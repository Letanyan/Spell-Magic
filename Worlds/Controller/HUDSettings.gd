class_name HUDSettings

enum KeyDisplay { AUTO, KEYBOARD, CONTROLLER }
enum ThemeKind { FLAT, MONO, COMP, ANA, TRI, TETRA, ELEMENTS }

var hide_wand_mappings: bool = false
var hide_wand_modifier_hints: bool = false
var hide_notifications: bool = false
var hide_status_effects: bool = false
var hide_health_mana: bool = false
var hide_cooldown_timings: bool = false
var hide_stats_view: bool = true
var hide_possible_upgrades: bool = false
var hide_reticule: bool = false
var hide_compass: bool = false
var projectile_indicator_size: float = 1.0
var key_display: KeyDisplay = KeyDisplay.AUTO
var hide_collected_keys_label: bool = false # NOTE: should be hide_objective_label. But, keeping the current name for backwards compatability
var theme_variation: ThemeKind = ThemeKind.MONO
var theme_color: Color = Color(0, 0.533, 0.8)

func save_dict() -> Dictionary:
	return {
		"hide_wand_mappings": hide_wand_mappings, "hide_wand_modifier_hints": hide_wand_modifier_hints,
		"hide_notifications": hide_notifications, "hide_status_effects": hide_status_effects,
		"hide_health_mana": hide_health_mana, "hide_cooldown_timings": hide_cooldown_timings,
		"hide_stats_view": hide_stats_view, "hide_possible_upgrades": hide_possible_upgrades, 
		"hide_reticule": hide_reticule, "projectile_indicator_size": projectile_indicator_size, 
		"key_display": key_display, "hide_collected_keys_label": hide_collected_keys_label, 
		"theme_color": theme_color, "theme_variation": theme_variation, "hide_compass": hide_compass,
	}

func load_dict(dict: Dictionary) -> void:
	hide_wand_mappings = dict.get("hide_wand_mappings", false)
	hide_wand_modifier_hints = dict.get("hide_wand_modifier_hints", false)
	hide_notifications = dict.get("hide_notifications", false)
	hide_status_effects = dict.get("hide_status_effects", false)
	hide_health_mana = dict.get("hide_health_mana", false)
	hide_cooldown_timings = dict.get("hide_cooldown_timings", false)
	hide_stats_view = dict.get("hide_stats_view", true)
	hide_possible_upgrades = dict.get("hide_possible_upgrades", false)
	hide_reticule = dict.get("hide_reticule", false)
	projectile_indicator_size = dict.get("projectile_indicator_size", 1.0)
	key_display = dict.get("key_display", KeyDisplay.AUTO)
	hide_collected_keys_label = dict.get("hide_collected_keys_label", false)
	theme_variation = dict.get("theme_variation", ThemeKind.MONO)
	theme_color = dict.get("theme_color", Color(0, 0.533, 0.8))
	hide_compass = dict.get("hide_compass", false)
