class_name MainMenuScreen
extends Control

var main_menu_world: MainMenuWorld = null
@onready var continue_button: Button = $Background/Continue
@onready var new_game_button: Button = $Background/NewGame
@onready var load_button: Button = $Background/Load
@onready var settings_button: Button = $Background/Settings
@onready var quit_button: Button = $Background/Quit

@onready var links_panel: Panel = $Links
@onready var steam_wishlist: Button = $Links/Margin/VBox/SteamWishlist

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	continue_button.disabled = GlobalData.game_settings.last_world == ""
	if GlobalData.is_demo:
		load_button.disabled = true
		load_button.tooltip_text = "Not Available in Demo"
		
	if not GlobalData.is_demo or not Steamworks.is_enabled:
		steam_wishlist.visible = false
		links_panel.size.y = 40
		links_panel.position.y = size.y - 48
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_new_game_pressed() -> void:
	UIAudioPlayer.click()
	if GlobalData.is_demo:
		var godot_path := "user://worlds/Demo World/"
		GlobalData.remove_folder_that_only_has_files(godot_path)
		var settings := WorldSettings.new(get_viewport())
		settings.load_dict(GlobalData.game_settings.default_world_settings.save_dict())
		settings.world_name = "Demo World"
		settings.world_generation_version = -1
		settings.sed = GlobalData.demo_seed
		var rng := RandomNumberGenerator.new()
		rng.seed = settings.sed
		settings.time_of_day = rng.randf_range(0.0, 24.0)
		settings.day_of_the_year = rng.randi_range(1, 365)
		settings.game_mode_settings = GameModeSettings.permadeath()
		settings.upgrade_settings.reset_all_stats_to_default_values()
		settings.upgrade_settings.has_spell_element = UpgradeSettings.HAS_VOID | (1 << randi_range(1, 6))
		if not settings.game_mode_settings.has_flag(GameModeSettings.SHOP_FOR_UPGRADES):
			settings.upgrade_settings.fill_upgrade_slots(false, {})
		settings.last_save_time = Time.get_unix_time_from_system()
		settings.save()
		UIAudioPlayer.crash()
		SceneHandler.load_new_scene("res://Worlds/Demo/demo.tscn", "fade_to_black", func(content: DemoWorld) -> void: content.setup(settings), Quotes.random())
	else:
		main_menu_world.show_menu_screen(MainMenuWorld.MenuScreenKind.NEW)
		#get_tree().change_scene_to_file("res://GUI/Main Menu/NewGame.tscn")


func _on_continue_pressed() -> void:
	UIAudioPlayer.click()
	var world_settings := WorldSettings.new(get_viewport())
	world_settings.read(GlobalData.game_settings.last_world)
	if GlobalData.is_demo:
		world_settings.sed = GlobalData.demo_seed
		world_settings.game_mode_settings = GameModeSettings.permadeath()
	
	SceneHandler.load_new_scene("res://Worlds/Demo/demo.tscn", "fade_to_black", func(content: DemoWorld) -> void: content.setup(world_settings), Quotes.random())
	

func display_loading(is_loading: bool) -> void:
	continue_button.disabled = is_loading
	new_game_button.disabled = is_loading
	load_button.disabled = is_loading
	settings_button.disabled = is_loading
	

func _on_load_pressed() -> void:
	UIAudioPlayer.click()
	main_menu_world.show_menu_screen(MainMenuWorld.MenuScreenKind.LOAD)
	
	#get_tree().change_scene_to_file("res://GUI/Main Menu/LoadGame.tscn")

func _on_settings_pressed() -> void:
	UIAudioPlayer.click()
	main_menu_world.show_menu_screen(MainMenuWorld.MenuScreenKind.SETTINGS)
	#get_tree().change_scene_to_file("res://GUI/Main Menu/SettingsMenu.tscn")
	

func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_discord_pressed() -> void:
	OS.shell_open("https://discord.gg/qWQHPP7YU7")


func _on_steam_wishlist_pressed() -> void:
	Steamworks.show_store()
