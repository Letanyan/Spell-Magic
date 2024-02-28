extends Control

var main_menu_world: MainMenuWorld = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Continue.disabled = GlobalData.game_settings.last_world == ""
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_new_game_pressed() -> void:
	main_menu_world.show_menu_screen(MainMenuWorld.MenuScreenKind.NEW)
	#get_tree().change_scene_to_file("res://GUI/Main Menu/NewGame.tscn")


func _on_continue_pressed() -> void:
	var world_settings := WorldSettings.new()
	world_settings.read(GlobalData.game_settings.last_world)
	
	SceneHandler.load_new_scene("res://Worlds/Demo/demo.tscn", "fade_to_black")
	SceneHandler.content_finished_loading.connect(func(content): content.setup(world_settings))
	
	#var demo = load("res://Worlds/Demo/demo.tscn").instantiate()
	#demo.setup(world_settings)
	#
	#var current = get_tree().current_scene
	#get_tree().root.add_child(demo)
	#current.call_deferred("free")
	#get_tree().current_scene = demo
	

func display_loading(is_loading: bool):
	$Continue.disabled = is_loading
	$NewGame.disabled = is_loading
	$Load.disabled = is_loading
	$Settings.disabled = is_loading
	

func _on_load_pressed() -> void:
	main_menu_world.show_menu_screen(MainMenuWorld.MenuScreenKind.LOAD)
	#get_tree().change_scene_to_file("res://GUI/Main Menu/LoadGame.tscn")

func _on_settings_pressed() -> void:
	main_menu_world.show_menu_screen(MainMenuWorld.MenuScreenKind.SETTINGS)
	#get_tree().change_scene_to_file("res://GUI/Main Menu/SettingsMenu.tscn")
	
