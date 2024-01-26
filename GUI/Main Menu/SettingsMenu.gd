extends Control

@onready var settings_pane: SettingsGUI = $Settings

var main_menu_world: MainMenuWorld = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	settings_pane.world_settings = GlobalData.game_settings.default_world_settings


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_back_pressed() -> void:
	GlobalData.game_settings.save()
	main_menu_world.show_menu_screen(MainMenuWorld.MenuScreenKind.MAIN)
	#get_tree().change_scene_to_file("res://GUI/Main Menu/MainMenu.tscn")
