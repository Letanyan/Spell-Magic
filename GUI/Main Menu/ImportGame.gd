class_name ImportGame
extends Control

@onready var worlds_list: ItemList = $Background/WorldsList

var main_menu_world: MainMenuWorld = null

var shared_worlds: Array[Dictionary] = []
var shared_worlds_page: int = 0
var can_check_for_shared_worlds := true

func _ready() -> void:
	HttpLevels.got_levels.connect(func(data: Array, page: int) -> void:
		if shared_worlds_page != page:
			shared_worlds.append_array(data)
			shared_worlds_page = page
			update_list_items()
			can_check_for_shared_worlds = true
	)
	HttpLevels.got_level.connect(func(id: int, data: Dictionary) -> void:
		var settings := WorldSettings.new(get_viewport())
		settings.game_mode_settings.load_dict(data.get("settings", {}) as Dictionary)
		settings.world_name = data.get("name", Rand.id(8, Time.get_ticks_usec())) + " (" + data.get("username", Rand.id(8, Time.get_ticks_usec())) + ")"
		SceneHandler.load_new_scene("res://Worlds/LevelEditor/LevelEditor.tscn", "fade_to_black", func(content: LevelEditor) -> void: content.setup(settings, data), Quotes.random())
	)
	if shared_worlds_page == 0:
		can_check_for_shared_worlds = false
		HttpLevels.get_levels(shared_worlds_page)

func update_list_items() -> void:
	worlds_list.clear()
	for t: Dictionary in shared_worlds:
		var n := t.get("Name", "???") as String
		var u := t.get("UserName", "???") as String
		worlds_list.add_item("%s (%s)" % [n, u])
		
func load_current_item(selected: int, in_editing_mode: bool) -> void:
	var world := shared_worlds[selected]
	HttpLevels.get_level(world.get("Id", -1) as int)
	# TODO: show loading

func _on_worlds_list_gui_input(event: InputEvent) -> void:
	var scroll := worlds_list.get_v_scroll_bar()
	if can_check_for_shared_worlds and (scroll.value + scroll.page) > scroll.max_value * 0.75:
		can_check_for_shared_worlds = false
		HttpLevels.get_levels(shared_worlds_page)


func _on_worlds_list_item_activated(index: int) -> void:
	load_current_item(index, false)


func _on_import_pressed() -> void:
	UIAudioPlayer.click()
	var selected := worlds_list.get_selected_items()
	if selected.is_empty():
		return
	load_current_item(selected[0], false)
	# TODO: show loading


func _on_cancel_pressed() -> void:
	main_menu_world.show_menu_screen(MainMenuWorld.MenuScreenKind.MAIN)
	UIAudioPlayer.click()
