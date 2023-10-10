class_name SettingsGUI
extends Control

@onready var hide_wand_mappings := $Tabs/HUD/HideWandMappings
@onready var hide_wand_modifier_hints := $Tabs/HUD/HideWandModifierHints
@onready var hide_notifications := $Tabs/HUD/HideNotifications
@onready var hide_status_effects := $Tabs/HUD/HideStatusEffects
@onready var hide_health_and_mana := $Tabs/HUD/HideHealthAndMana
@onready var hide_cooldown_timings := $Tabs/HUD/HideCooldownTimings
@onready var hide_stats_view := $Tabs/HUD/HideStatsView

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
	
	$"Tabs/Camera/FOV Label/Slider".value = int(world_settings.camera_settings.fov)
	$"Tabs/Camera/FOV Label/Value".text = str(int(world_settings.camera_settings.fov))

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

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not has_focus():
		return
		
	var direction := VelocityMovement.get_input_strength("pan_left", "pan_right", "pan_forward", "pan_back")
	
	if hide_wand_mappings.has_focus():
		if direction.y > 0:
			hide_wand_modifier_hints.grab_focus()
	elif hide_wand_modifier_hints.has_focus():
		if direction.y > 0:
			hide_notifications.grab_focus()
		if direction.y < 0:
			hide_wand_mappings.grab_focus()
	elif hide_notifications.has_focus():
		if direction.y > 0:
			hide_status_effects.grab_focus()
		if direction.y < 0:
			hide_wand_modifier_hints.grab_focus()
	elif hide_status_effects.has_focus():
		if direction.y > 0:
			hide_health_and_mana.grab_focus()
		if direction.y < 0:
			hide_notifications.grab_focus()
	elif hide_health_and_mana.has_focus():
		if direction.y > 0:
			hide_cooldown_timings.grab_focus()
		if direction.y < 0:
			hide_status_effects.grab_focus()
	elif hide_cooldown_timings.has_focus():
		if direction.y > 0:
			hide_stats_view.grab_focus()
		if direction.y < 0:
			hide_health_and_mana.grab_focus()
	elif hide_stats_view.has_focus():
		if direction.y < 0:
			hide_cooldown_timings.grab_focus()


func _on_slider_value_changed(value: float) -> void:
	world_settings.camera_settings.fov = int(value)
	$"Tabs/Camera/FOV Label/Value".text = str(int(value))
	settings_changed.emit(world_settings)
