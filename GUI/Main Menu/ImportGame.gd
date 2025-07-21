class_name ImportGame
extends Control

@onready var worlds_list: ItemList = $Background/WorldsList
@onready var search_option: OptionButton = $Background/SearchOption
@onready var search_edit: LineEdit = $Background/SearchEdit

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
	HttpLevels.got_level.connect(func(id: int, data: Dictionary, level: Dictionary) -> void:
		var settings := WorldSettings.new(get_viewport())
		settings.game_mode_settings.load_dict(data.get("settings", {}) as Dictionary)
		settings.world_name = data.get("name", Rand.id(8, Time.get_ticks_usec())) + " (" + data.get("username", Rand.id(8, Time.get_ticks_usec())) + ")"
		settings.is_shared_online = id
		settings.online_vote = level.get("UserVote", 0)
		settings.player_position = data.get("base_position", Vector3(0, 1000.95, 0)) as Vector3
		data["current_enemies"] = []
		data["current_flags"] = []
		settings.save()
		HttpLevels.add_level_user_data(id)
		SceneHandler.load_new_scene("res://Worlds/LevelEditor/LevelEditor.tscn", "fade_to_black", func(content: LevelEditor) -> void: content.setup(settings, data), Quotes.random())
	)
	if shared_worlds_page == 0:
		can_check_for_shared_worlds = false
		HttpLevels.get_levels(shared_worlds_page, "", HttpLevels.SearchKind.NONE)

func update_list_items() -> void:
	worlds_list.clear()
	for t: Dictionary in shared_worlds:
		var n := t.get("Name", "???") as String
		var u := t.get("UserName", "???") as String
		var v := t.get("Votes", 0) as int
		var p := t.get("Playtime", 0.0) as float
		worlds_list.add_item("%s - %s [%d] (%dm)" % [n, u, v, int(p / 60.0)])
		
func load_current_item(selected: int, in_editing_mode: bool) -> void:
	var world := shared_worlds[selected]
	HttpLevels.get_level(world.get("Id", -1) as int)
	# TODO: show loading

func _on_worlds_list_gui_input(event: InputEvent) -> void:
	var scroll := worlds_list.get_v_scroll_bar()
	if can_check_for_shared_worlds and (scroll.value + scroll.page) > scroll.max_value * 0.75:
		can_check_for_shared_worlds = false
		if search_option.selected == 0: # world name
			HttpLevels.get_levels(shared_worlds_page, search_edit.text, HttpLevels.SearchKind.NAME)
		elif search_option.selected == 1:
			HttpLevels.get_levels(shared_worlds_page, search_edit.text, HttpLevels.SearchKind.USER)


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

func search() -> void:
	shared_worlds.clear()
	worlds_list.clear()
	shared_worlds_page = 0
	can_check_for_shared_worlds = false
	if search_option.selected == 0: # world name
		HttpLevels.get_levels(shared_worlds_page, search_edit.text, HttpLevels.SearchKind.NAME)
	elif search_option.selected == 1:
		HttpLevels.get_levels(shared_worlds_page, search_edit.text, HttpLevels.SearchKind.USER)
	# TODO: show loading

func _on_search_button_pressed() -> void:
	search()

func _on_search_edit_text_submitted(new_text: String) -> void:
	search()
