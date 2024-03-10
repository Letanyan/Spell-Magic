extends Control

var dir: DirAccess
var filenames: Array
var main_menu_world: MainMenuWorld = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	dir = DirAccess.open("user://")
	if not dir.dir_exists("worlds"):
		dir.make_dir("worlds")
	dir.change_dir("worlds")
	var worlds := dir.get_directories()
	var times := []
	for world in worlds:
		var f := FileAccess.get_modified_time("user://worlds/%s/settings.json" % world)
		times.append([world, f])
		
	times.sort_custom(func(a, b): return a[1] > b[1])	
		
	for t in times:
		filenames.append(t[0])
		$WorldsList.add_item("%s (%s)" % [t[0], Time.get_datetime_string_from_unix_time(t[1], true)])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_cancel_pressed() -> void:
	main_menu_world.show_menu_screen(MainMenuWorld.MenuScreenKind.MAIN)
	#get_tree().change_scene_to_file("res://GUI/Main Menu/MainMenu.tscn")

func load_current_item(selected: int) -> void:
	var world_name = filenames[selected]
	var settings := WorldSettings.new(get_viewport())
	settings.read(world_name)
	
	SceneHandler.load_new_scene("res://Worlds/Demo/demo.tscn", "fade_to_black", func(content): content.setup(settings))
	
	#var demo = load("res://Worlds/Demo/demo.tscn").instantiate()
	#demo.setup(settings)
	#
	#var current = get_tree().current_scene
	#get_tree().root.add_child(demo)
	#current.call_deferred("free")
	#get_tree().current_scene = demo

func _on_load_pressed() -> void:
	var list: ItemList = $WorldsList
	var selected := list.get_selected_items()
	if selected.is_empty():
		return
	load_current_item(selected[0])
	
func _on_worlds_list_item_activated(index: int) -> void:
	load_current_item(index)
