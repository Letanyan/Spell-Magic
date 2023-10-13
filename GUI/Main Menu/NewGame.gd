extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_cancel_pressed() -> void:
	get_tree().change_scene_to_file("res://GUI/Main Menu/MainMenu.tscn")


func _on_create_pressed() -> void:
	var settings := WorldSettings.new()
	settings.load_dict(GlobalData.game_settings.default_world_settings.save_dict())
	settings.world_name = $SaveName.text
	settings.sed = hash($Seed.text)

	var demo = load("res://Worlds/Demo/demo.tscn").instantiate()
	demo.setup(settings)
	
	var current = get_tree().current_scene
	get_tree().root.add_child(demo)
	current.call_deferred("free")
	get_tree().current_scene = demo
