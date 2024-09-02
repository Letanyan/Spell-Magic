class_name LoadGameScreen
extends Control

@onready var worlds_list: ItemList = $WorldsList

var filenames: Array[String]
var main_menu_world: MainMenuWorld = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var times := GameSettings.get_world_names()
	for t: Array in times:
		filenames.append(t[0])
		worlds_list.add_item("%s (%s)" % [t[0], GlobalData.get_date_time_string(t[1] as int)])
	

func _on_cancel_pressed() -> void:
	main_menu_world.show_menu_screen(MainMenuWorld.MenuScreenKind.MAIN)
	#get_tree().change_scene_to_file("res://GUI/Main Menu/MainMenu.tscn")

func load_current_item(selected: int) -> void:
	var world_name := filenames[selected]
	var settings := WorldSettings.new(get_viewport())
	settings.read(world_name)
	
	SceneHandler.load_new_scene("res://Worlds/Demo/demo.tscn", "fade_to_black", func(content: DemoWorld) -> void: content.setup(settings))
	
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

func _on_delete_pressed() -> void:
	var list: ItemList = $WorldsList
	var selected := list.get_selected_items()
	if selected.is_empty():
		return
	var filename := filenames[selected[0]] as String
	var popup := PopupDialog.display("Are you sure you want to delete the save '" + filename + "'")
	popup.confirmed.connect(func() -> void:
		var current_selected := list.get_selected_items()
		if current_selected.is_empty():
			return
		OS.move_to_trash(ProjectSettings.globalize_path("user://worlds/%s" % (filename)))
		list.remove_item(current_selected[0])
	)
	get_tree().root.add_child(popup)
