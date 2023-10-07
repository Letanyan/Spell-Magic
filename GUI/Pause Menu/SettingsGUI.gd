class_name SettingsGUI
extends Control

var world_settings: WorldSettings:
	set(value):
		world_settings = value
		update_controls()

signal settings_changed(settings: WorldSettings)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_controls():
	$Tabs/HUD/HideWandMappings.button_pressed = world_settings.hud_settings.hide_wand_mappings
	$Tabs/HUD/HideWandModifierHints.button_pressed = world_settings.hud_settings.hide_wand_modifier_hints
	$Tabs/HUD/HideNotifications.button_pressed = world_settings.hud_settings.hide_notifications
	$Tabs/HUD/HideStatusEffects.button_pressed = world_settings.hud_settings.hide_status_effects
	$Tabs/HUD/HideHealthAndMana.button_pressed = world_settings.hud_settings.hide_health_mana
	$Tabs/HUD/HideCooldownTimings.button_pressed = world_settings.hud_settings.hide_cooldown_timings
	$Tabs/HUD/HideStatsView.button_pressed = world_settings.hud_settings.hide_stats_view

func _on_hide_wand_mappings_toggled(button_pressed: bool) -> void:
	world_settings.hud_settings.hide_wand_mappings = button_pressed
	settings_changed.emit(world_settings)


func _on_hide_wand_modifier_hints_toggled(button_pressed: bool) -> void:
	world_settings.hud_settings.hide_wand_modifier_hints = button_pressed
	settings_changed.emit(world_settings)


func _on_hide_notifications_toggled(button_pressed: bool) -> void:
	world_settings.hud_settings.hide_notifications = button_pressed
	settings_changed.emit(world_settings)


func _on_hide_status_effects_toggled(button_pressed: bool) -> void:
	world_settings.hud_settings.hide_status_effects = button_pressed
	settings_changed.emit(world_settings)


func _on_hide_health_and_mana_toggled(button_pressed: bool) -> void:
	world_settings.hud_settings.hide_health_mana = button_pressed
	settings_changed.emit(world_settings)


func _on_hide_cooldown_timings_toggled(button_pressed: bool) -> void:
	world_settings.hud_settings.hide_cooldown_timings = button_pressed
	settings_changed.emit(world_settings)


func _on_hide_stats_view_toggled(button_pressed: bool) -> void:
	world_settings.hud_settings.hide_stats_view = button_pressed
	settings_changed.emit(world_settings)
