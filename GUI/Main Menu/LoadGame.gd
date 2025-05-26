class_name LoadGameScreen
extends Control

@onready var worlds_list: ItemList = $WorldsList

@onready var local_button: Button = $Local
@onready var shared_button: Button = $Shared
@onready var delete_button: Button = $Delete
@onready var edit_button: Button = $Edit

var is_showing_local: bool = true
var filenames: Array[String]
var main_menu_world: MainMenuWorld = null
var shared_worlds: Array[Dictionary] = []
var shared_worlds_page: int = 0
var filenames_with_times: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	filenames_with_times = GameSettings.get_world_names()
	for t: Array in filenames_with_times:
		filenames.append(t[0])
		worlds_list.add_item("%s (%s)" % [t[0], GlobalData.get_date_time_string(t[1] as int)])
	HttpLevels.got_levels.connect(func(data: Array, page: int) -> void:
		if shared_worlds_page != page:
			shared_worlds.append_array(data)
			shared_worlds_page = page
			update_list_items()
	)
	HttpLevels.got_level.connect(func(id: int, data: Dictionary) -> void:
		var settings := WorldSettings.new(get_viewport())
		settings.game_mode_settings.load_dict(data.get("settings", {}) as Dictionary)
		SceneHandler.load_new_scene("res://Worlds/LevelEditor/LevelEditor.tscn", "fade_to_black", func(content: LevelEditor) -> void: content.setup(settings, data), Quotes.random())
	)
	
func update_list_items() -> void:
	worlds_list.clear()
	if is_showing_local:
		for t: Array in filenames_with_times:
			worlds_list.add_item("%s (%s)" % [t[0], GlobalData.get_date_time_string(t[1] as int)])
	else:
		for t: Dictionary in shared_worlds:
			var n := t.get("Name", "???") as String
			var u := t.get("UserName", "???") as String
			worlds_list.add_item("%s (%s)" % [n, u])

func _on_cancel_pressed() -> void:
	main_menu_world.show_menu_screen(MainMenuWorld.MenuScreenKind.MAIN)
	UIAudioPlayer.click()
	#get_tree().change_scene_to_file("res://GUI/Main Menu/MainMenu.tscn")

func load_current_item(selected: int, in_editing_mode: bool) -> void:
	if is_showing_local:
		var world_name := filenames[selected]
		var settings := WorldSettings.new(get_viewport())
		settings.read(world_name)
		
		if settings.is_level_editor:
			settings.is_editing_level = in_editing_mode
			SceneHandler.load_new_scene("res://Worlds/LevelEditor/LevelEditor.tscn", "fade_to_black", func(content: LevelEditor) -> void: content.setup(settings, {}), Quotes.random())
		else:
			SceneHandler.load_new_scene("res://Worlds/Demo/demo.tscn", "fade_to_black", func(content: DemoWorld) -> void: content.setup(settings), Quotes.random())
	else:
		var world := shared_worlds[selected]
		HttpLevels.get_level(world.get("Id", -1) as int)
		# TODO: show loading

func _on_load_pressed() -> void:
	var list: ItemList = $WorldsList
	UIAudioPlayer.click()
	var selected := list.get_selected_items()
	if selected.is_empty():
		return
	load_current_item(selected[0], false)
	
func _on_load_editor_pressed() -> void:
	var list: ItemList = $WorldsList
	UIAudioPlayer.click()
	var selected := list.get_selected_items()
	if selected.is_empty():
		return
	load_current_item(selected[0], true)
	
	
func _on_worlds_list_item_activated(index: int) -> void:
	load_current_item(index, false)
	
func _on_worlds_list_item_selected(index: int) -> void:
	if is_showing_local:
		var list: ItemList = $WorldsList
		var load_editor: Button = $Edit
		load_editor.disabled = true
		var selected := list.get_selected_items()
		if selected.is_empty():
			return
		var world_name := filenames[selected[0]]
		var settings := WorldSettings.new(get_viewport())
		settings.read(world_name)
		load_editor.disabled = not settings.is_level_editor

func _on_delete_pressed() -> void:
	var list: ItemList = $WorldsList
	UIAudioPlayer.click()
	var selected := list.get_selected_items()
	if selected.is_empty():
		return
	var filename := filenames[selected[0]] as String
	var popup := PopupDialog.display("Are you sure you want to delete the save '" + filename + "'")
	popup.confirmed.connect(func() -> void:
		var current_selected := list.get_selected_items()
		if current_selected.is_empty():
			return
		UIAudioPlayer.delete()
		OS.move_to_trash(ProjectSettings.globalize_path("user://worlds/%s" % (filename)))
		list.remove_item(current_selected[0])
	)
	popup.cancelled.connect(func() -> void: UIAudioPlayer.click())
	popup.show_in_root(self)


func _on_local_toggled(toggled_on: bool) -> void:
	local_button.set_pressed_no_signal(toggled_on)
	shared_button.set_pressed_no_signal(not toggled_on)
	is_showing_local = toggled_on
	delete_button.disabled = not is_showing_local
	edit_button.disabled = not is_showing_local
	update_list_items()

func _on_shared_toggled(toggled_on: bool) -> void:
	local_button.set_pressed_no_signal(not toggled_on)
	shared_button.set_pressed_no_signal(toggled_on)
	is_showing_local = not toggled_on
	delete_button.disabled = is_showing_local
	edit_button.disabled = is_showing_local
	if shared_worlds_page == 0:
		HttpLevels.get_levels(shared_worlds_page)
		# TODO: show loading
