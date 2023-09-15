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

func _on_hide_wand_mappings_toggled(button_pressed: bool) -> void:
	world_settings.hud_settings.hide_wand_mappings = button_pressed
	settings_changed.emit(world_settings)
