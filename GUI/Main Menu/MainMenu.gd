extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Continue.disabled = GlobalData.game_settings.last_world == ""
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://GUI/Main Menu/NewGame.tscn")


func _on_continue_pressed() -> void:
	var world_settings := WorldSettings.new()
	world_settings.read(GlobalData.game_settings.last_world)
	
	var demo = load("res://Worlds/Demo/demo.tscn").instantiate()
	demo.setup(world_settings)
	
	var current = get_tree().current_scene
	get_tree().root.add_child(demo)
	current.call_deferred("free")
	get_tree().current_scene = demo


func _on_load_pressed() -> void:
	get_tree().change_scene_to_file("res://GUI/Main Menu/LoadGame.tscn")


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://GUI/Main Menu/SettingsMenu.tscn")
