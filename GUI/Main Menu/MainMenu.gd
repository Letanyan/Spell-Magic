class_name MainMenuScreen
extends Control

var main_menu_world: MainMenuWorld = null
@onready var continue_button: Button = $Continue
@onready var new_game_button: Button = $NewGame
@onready var load_button: Button = $Load
@onready var settings_button: Button = $Settings
@onready var quit_button: Button = $Quit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	continue_button.disabled = GlobalData.game_settings.last_world == ""
	if GlobalData.is_demo:
		load_button.disabled = true
		load_button.tooltip_text = "Not Available in Demo"
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_new_game_pressed() -> void:
	UIAudioPlayer.click()
	if GlobalData.is_demo:
		var settings := WorldSettings.new(get_viewport())
		settings.load_dict(GlobalData.game_settings.default_world_settings.save_dict())
		settings.world_name = "Demo World"
		settings.world_generation_version = -1
		settings.sed = 17312391
		var rng := RandomNumberGenerator.new()
		rng.seed = settings.sed
		settings.time_of_day = rng.randf_range(0.0, 24.0)
		settings.day_of_the_year = rng.randi_range(1, 365)
		settings.game_mode_settings = GameModeSettings.hardcore_mode()
		settings.game_mode_settings.flags = GameModeSettings.DISALLOW_SPELL_EDITING
		var temp_upgrades := UpgradeSettings.new()
		temp_upgrades.reset_all_stats_to_default_values()
		temp_upgrades.has_spell_element = UpgradeSettings.HAS_VOID | (1 << randi_range(1, 6))
		settings.upgrade_settings.load_dict(temp_upgrades.save_dict())
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
