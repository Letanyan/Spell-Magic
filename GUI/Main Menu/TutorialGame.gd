class_name TutorialGame
extends Control

@onready var tutorials_list: ItemList = $Background/TutorialList

var filenames: Array[String]
var main_menu_world: MainMenuWorld = null

func _ready() -> void:
	filenames = GameSettings.get_tutorial_names()
	for filename in filenames:
		tutorials_list.add_item(filename)

func _on_back_pressed() -> void:
	main_menu_world.show_menu_screen(MainMenuWorld.MenuScreenKind.MAIN)
	UIAudioPlayer.click()

func load_current_item(selected: int, in_editing_mode: bool) -> void:
	var world_name := filenames[selected]
	var settings := WorldSettings.new(get_viewport())
	settings.read(world_name)
	
	if settings.is_level_editor:
		settings.is_editing_level = in_editing_mode
		SceneHandler.load_new_scene("res://Worlds/LevelEditor/LevelEditor.tscn", "fade_to_black", func(content: LevelEditor) -> void: content.setup(settings, {}), Quotes.random())
	else:
		SceneHandler.load_new_scene("res://Worlds/Demo/demo.tscn", "fade_to_black", func(content: DemoWorld) -> void: content.setup(settings), Quotes.random())	
	

func _on_start_pressed() -> void:
	var list: ItemList = $Background/TutorialList
	UIAudioPlayer.click()
	var selected := list.get_selected_items()
	if selected.is_empty():
		return
	load_current_item(selected[0], false)


func _on_tutorial_list_item_activated(index: int) -> void:
	load_current_item(index, false)
