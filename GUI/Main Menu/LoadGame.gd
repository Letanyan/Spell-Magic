extends Control

var dir: DirAccess

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	dir = DirAccess.open("user://")
	if not dir.dir_exists("worlds"):
		dir.make_dir("worlds")
	dir.change_dir("worlds")
	var worlds := dir.get_directories()
	for world in worlds:
		$WorldsList.add_item(world)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_cancel_pressed() -> void:
	get_tree().change_scene_to_file("res://GUI/Menu/MainMenu.tscn")


func _on_load_pressed() -> void:
	var list: ItemList = $WorldsList
	var selected := list.get_selected_items()
	if selected.is_empty():
		return
	
	var world_name = list.get_item_text(selected[0])
	var settings := WorldSettings.new()
	settings.read(world_name)
	var demo = load("res://Worlds/Demo/demo.tscn").instantiate()
	demo.setup(settings)
	
	var current = get_tree().current_scene
	get_tree().root.add_child(demo)
	current.call_deferred("free")
	get_tree().current_scene = demo
	
	
