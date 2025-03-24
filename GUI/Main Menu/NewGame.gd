class_name NewGameScreen
extends Control

@onready var background: Panel = $Background

@onready var save_name: LineEdit = $SaveName
var name_generator: NameGenerator
@onready var random_name: Button = $RandomName
@onready var use_seed: Button = $UseSeed
@onready var use_save_file: Button = $UseSaveFile
@onready var use_normal: Button = $UseNormal
@onready var use_hardcore: Button = $UseHardcore
@onready var seed_edit: LineEdit = $Seed
@onready var worlds_list: ItemList = $WorldsList
@onready var generation_version_label: Label = $WorldGenerationVersion
@onready var generator_version: OptionButton = $WorldGenerationVersion/GeneratorVersion

@onready var permadeath: Button = $Permadeath
@onready var respawn: Button = $Respawn
@onready var sandbox: Button = $Sandbox

@onready var respawn_options: VBoxContainer = $RespawnOptions
@onready var game_options: VBoxContainer = $GameOptions

@onready var health_slider: HSlider = $StartingUpgradesPanel/Health/Slider
@onready var attack_slider: HSlider = $StartingUpgradesPanel/Attack/Slider
@onready var defence_slider: HSlider = $StartingUpgradesPanel/Defence/Slider
@onready var mana_slider: HSlider = $StartingUpgradesPanel/Mana/Slider
@onready var velocity_slider: HSlider = $StartingUpgradesPanel/Velocity/Slider
@onready var spell_count_slider: HSlider = $StartingUpgradesPanel/SpellCount/Slider
@onready var T_slider: HSlider = $StartingUpgradesPanel/T/Slider
@onready var r_slider: HSlider = $StartingUpgradesPanel/r/Slider
@onready var P_slider: HSlider = $StartingUpgradesPanel/P/Slider
@onready var N_slider: HSlider = $StartingUpgradesPanel/N/Slider
@onready var S_slider: HSlider = $StartingUpgradesPanel/S/Slider
@onready var auto_mana_slider: HSlider = $StartingUpgradesPanel/AutoMana/Slider
@onready var coins_slider: HSlider = $StartingUpgradesPanel/Coins/Slider

@onready var health_value: Label = $StartingUpgradesPanel/Health/Value
@onready var attack_value: Label = $StartingUpgradesPanel/Attack/Value
@onready var defence_value: Label = $StartingUpgradesPanel/Defence/Value
@onready var mana_value: Label = $StartingUpgradesPanel/Mana/Value
@onready var velocity_value: Label = $StartingUpgradesPanel/Velocity/Value
@onready var spell_count_value: Label = $StartingUpgradesPanel/SpellCount/Value
@onready var T_value: Label = $StartingUpgradesPanel/T/Value
@onready var r_value: Label = $StartingUpgradesPanel/r/Value
@onready var P_value: Label = $StartingUpgradesPanel/P/Value
@onready var N_value: Label = $StartingUpgradesPanel/N/Value
@onready var S_value: Label = $StartingUpgradesPanel/S/Value
@onready var auto_mana_value: Label = $StartingUpgradesPanel/AutoMana/Value
@onready var coins_value: Label = $StartingUpgradesPanel/Coins/Value


@onready var spell_elements_fire: Button = $StartingUpgradesPanel/SpellElements/Fire
@onready var spell_elements_water: Button = $StartingUpgradesPanel/SpellElements/Water
@onready var spell_elements_rock: Button = $StartingUpgradesPanel/SpellElements/Rock
@onready var spell_elements_air: Button = $StartingUpgradesPanel/SpellElements/Air
@onready var spell_elements_ice: Button = $StartingUpgradesPanel/SpellElements/Ice
@onready var spell_elements_electric: Button = $StartingUpgradesPanel/SpellElements/Electric

@onready var chain_methods_chain_at_start: Button = $StartingUpgradesPanel/ChainMethods/ChainAtStart
@onready var chain_methods_chain_at_end: Button = $StartingUpgradesPanel/ChainMethods/ChainAtEnd
@onready var chain_methods_chain_on_hit: Button = $StartingUpgradesPanel/ChainMethods/ChainOnHit

@onready var starting_upgrades: Button = $StartingUpgrades
@onready var starting_upgrades_panel: Panel = $StartingUpgradesPanel

@onready var game_mode_description_panel: Panel = $GameModeDescriptionPanel
@onready var game_mode_description: Label = $GameModeDescriptionPanel/GameModeDescription

@onready var difficulty_value: OptionButton = $StartingUpgradesPanel/Difficulty/Value


var game_mode: GameModeSettings.GameMode = GameModeSettings.GameMode.RESPAWN
var game_flags: int = GameModeSettings.RESPAWN_WITH_UPGRADES

var upgrades: UpgradeSettings

var main_menu_world: MainMenuWorld = null

var world_data: Array = []

# TODO: add more game modes. Things like: 
# - Artifacts Only: No upgrades only artifacts
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UIAudioPlayer.silence = true
	upgrades = UpgradeSettings.new()
	upgrades.reset_all_stats_to_default_values()
	
	health_slider.min_value = upgrades.level_health
	attack_slider.min_value = upgrades.level_attack
	defence_slider.min_value = upgrades.level_defence
	mana_slider.min_value = upgrades.level_mana
	velocity_slider.min_value = upgrades.level_v
	spell_count_slider.min_value = upgrades.level_spells_in_book
	T_slider.min_value = upgrades.level_T
	r_slider.min_value = upgrades.level_r
	P_slider.min_value = upgrades.level_P
	N_slider.min_value = upgrades.level_N
	S_slider.min_value = upgrades.level_running_speed
	auto_mana_slider.min_value = upgrades.level_mana_regen
	coins_slider.min_value = 0
	
	health_slider.max_value = upgrades.level_max_health
	attack_slider.max_value = upgrades.level_max_attack
	defence_slider.max_value = upgrades.level_max_defence
	mana_slider.max_value = upgrades.level_max_mana
	velocity_slider.max_value = upgrades.level_max_v
	spell_count_slider.max_value = upgrades.level_max_spells_in_book
	T_slider.max_value = upgrades.level_max_T
	r_slider.max_value = upgrades.level_max_r
	P_slider.max_value = upgrades.level_max_P
	N_slider.max_value = upgrades.level_max_N
	S_slider.max_value = upgrades.level_max_running_speed
	auto_mana_slider.max_value = upgrades.level_max_mana_regen
	coins_slider.max_value = 100_000
	
	_on_health_value_changed(upgrades.level_health)
	_on_attack_value_changed(upgrades.level_attack)
	_on_defence_value_changed(upgrades.level_defence)
	_on_mana_value_changed(upgrades.level_mana)
	_on_velocity_value_changed(upgrades.level_v)
	_on_spell_count_value_changed(upgrades.level_spells_in_book)
	_on_T_value_changed(upgrades.level_T)
	_on_r_value_changed(upgrades.level_r)
	_on_P_value_changed(upgrades.level_P)
	_on_N_value_changed(upgrades.level_N)
	_on_S_value_changed(upgrades.level_running_speed)
	_on_auto_mana_slider_value_changed(upgrades.level_mana_regen)
	_on_coins_slider_value_changed(upgrades.currency)
	
	spell_elements_fire.button_pressed = upgrades.check_if_has_spell_element(Spell.Element.FIRE)
	spell_elements_water.button_pressed = upgrades.check_if_has_spell_element(Spell.Element.WATER)
	spell_elements_rock.button_pressed = upgrades.check_if_has_spell_element(Spell.Element.ROCK)
	spell_elements_air.button_pressed = upgrades.check_if_has_spell_element(Spell.Element.AIR)
	spell_elements_ice.button_pressed = upgrades.check_if_has_spell_element(Spell.Element.AIR)
	spell_elements_electric.button_pressed = upgrades.check_if_has_spell_element(Spell.Element.ELECTRIC)
	
	chain_methods_chain_at_start.button_pressed = upgrades.check_if_has_chain_method(Spell.ChainCastKind.START)
	chain_methods_chain_at_end.button_pressed = upgrades.check_if_has_chain_method(Spell.ChainCastKind.END)
	chain_methods_chain_on_hit.button_pressed = upgrades.check_if_has_chain_method(Spell.ChainCastKind.HIT)
	
	world_data = GameSettings.get_world_names()
	for t: Array in world_data:
		worlds_list.add_item("%s (%s)" % [t[0], GlobalData.get_date_time_string(t[1] as int)])
		
	use_save_file.disabled = world_data.is_empty()
		
	name_generator = NameGenerator.new()
	name_generator.initial()
		
	_on_use_hardcore_toggled(true)
	UIAudioPlayer.silence = false


func _on_cancel_pressed() -> void:
	main_menu_world.show_menu_screen(MainMenuWorld.MenuScreenKind.MAIN)
	#get_tree().change_scene_to_file("res://GUI/Main Menu/MainMenu.tscn")
	
func world_name_exists(world_name: String) -> bool:
	for t: Array in world_data:
		if world_name == t[0]:
			return true
	return false
	
func _on_worlds_list_item_activated(index: int) -> void:
	if worlds_list.get_selected_items().is_empty():
		return
	if save_name.text.is_empty():
		var popup := PopupDialog.display("Please provide a save name", "Okay", "")
		popup.cancelled.connect(func() -> void: UIAudioPlayer.click())
		popup.confirmed.connect(func() -> void: UIAudioPlayer.click())
		popup.show_in_root(self)
		return
	if world_name_exists(save_name.text):
		var popup := PopupDialog.display("Save name '%s' already exists. Please provide a unique save name." % save_name.text, "Okay", "")
		popup.cancelled.connect(func() -> void: UIAudioPlayer.click())
		popup.confirmed.connect(func() -> void: UIAudioPlayer.click())
		popup.show_in_root(self)
		return
	var selected_world_name := world_data[index][0] as String
	var settings := WorldSettings.new(get_viewport())
	settings.read(selected_world_name)
	settings.world_name = save_name.text
	settings.last_save_time = Time.get_unix_time_from_system()
	settings.save()
	SceneHandler.load_new_scene("res://Worlds/Demo/demo.tscn", "fade_to_black", func(content: DemoWorld) -> void: content.setup(settings), Quotes.random())

func _on_create_pressed() -> void:
	if save_name.text.is_empty():
		var popup := PopupDialog.display("Please provide a save name", "Okay", "")
		popup.cancelled.connect(func() -> void: UIAudioPlayer.click())
		popup.confirmed.connect(func() -> void: UIAudioPlayer.click())
		popup.show_in_root(self)
		return
	if world_name_exists(save_name.text):
		var popup := PopupDialog.display("Save name '%s' already exists. Please provide a unique save name." % save_name.text, "Okay", "")
		popup.cancelled.connect(func() -> void: UIAudioPlayer.click())
		popup.confirmed.connect(func() -> void: UIAudioPlayer.click())
		popup.show_in_root(self)
		return
	
	if use_seed.button_pressed:
		# FIXME: game crashed when setting custom T value
		var settings := WorldSettings.new(get_viewport())
		settings.load_dict(GlobalData.game_settings.default_world_settings.save_dict())
		settings.world_name = save_name.text
		settings.world_generation_version = generator_version.selected + 1
		if seed_edit.text.is_valid_int():
			settings.sed = seed_edit.text.to_int()
		elif not seed_edit.text.is_empty():
			settings.sed = hash(seed_edit.text)
		else:
			settings.sed = int(Time.get_unix_time_from_system())
		var rng := RandomNumberGenerator.new()
		rng.seed = settings.sed
		settings.time_of_day = rng.randf_range(0.0, 24.0)
		settings.day_of_the_year = rng.randi_range(1, 365)
		settings.difficulty_level = difficulty_value.get_item_id(difficulty_value.selected)
		
		settings.game_mode_settings.mode = game_mode
		match game_mode:
			GameModeSettings.GameMode.RESPAWN:
				settings.game_mode_settings.flags = game_flags
		
		
		settings.upgrade_settings.load_dict(upgrades.save_dict())
		if not settings.game_mode_settings.has_flag(GameModeSettings.SHOP_FOR_UPGRADES):
			settings.upgrade_settings.fill_upgrade_slots(false, {})
		settings.last_save_time = Time.get_unix_time_from_system()
		settings.save()
		UIAudioPlayer.crash()
		SceneHandler.load_new_scene("res://Worlds/Demo/demo.tscn", "fade_to_black", func(content: DemoWorld) -> void: content.setup(settings), Quotes.random())
	elif use_save_file.button_pressed:
		if worlds_list.get_selected_items().is_empty():
			return
		var selected_world_name := world_data[worlds_list.get_selected_items()[0]][0] as String
		var settings := WorldSettings.new(get_viewport())
		settings.read(selected_world_name)
		settings.world_name = save_name.text
		settings.last_save_time = Time.get_unix_time_from_system()
		settings.save()
		UIAudioPlayer.click()
		SceneHandler.load_new_scene("res://Worlds/Demo/demo.tscn", "fade_to_black", func(content: DemoWorld) -> void: content.setup(settings), Quotes.random())
	elif use_normal.button_pressed:
		var settings := WorldSettings.new(get_viewport())
		settings.load_dict(GlobalData.game_settings.default_world_settings.save_dict())
		settings.world_name = save_name.text
		settings.world_generation_version = generator_version.selected + 1
		settings.sed = Time.get_ticks_usec()
		var rng := RandomNumberGenerator.new()
		rng.seed = settings.sed
		settings.time_of_day = rng.randf_range(0.0, 24.0)
		settings.day_of_the_year = rng.randi_range(1, 365)
		settings.game_mode_settings = GameModeSettings.normal_mode()
		settings.difficulty_level = 2
		var temp_upgrades := UpgradeSettings.new()
		temp_upgrades.reset_all_stats_to_default_values()
		settings.upgrade_settings.load_dict(temp_upgrades.save_dict())
		settings.upgrade_settings.fill_upgrade_slots(false, {})
		settings.last_save_time = Time.get_unix_time_from_system()
		settings.save()
		UIAudioPlayer.crash()
		SceneHandler.load_new_scene("res://Worlds/Demo/demo.tscn", "fade_to_black", func(content: DemoWorld) -> void: content.setup(settings), Quotes.random())
	elif use_hardcore.button_pressed:
		var settings := WorldSettings.new(get_viewport())
		settings.load_dict(GlobalData.game_settings.default_world_settings.save_dict())
		settings.world_name = save_name.text
		settings.world_generation_version = generator_version.selected + 1
		settings.sed = Time.get_ticks_usec()
		var rng := RandomNumberGenerator.new()
		rng.seed = settings.sed
		settings.time_of_day = rng.randf_range(0.0, 24.0)
		settings.day_of_the_year = rng.randi_range(1, 365)
		settings.game_mode_settings = GameModeSettings.hardcore_mode()
		settings.game_mode_settings.flags = game_flags & GameModeSettings.DISALLOW_SPELL_EDITING
		settings.difficulty_level = 2
		var temp_upgrades := UpgradeSettings.new()
		temp_upgrades.reset_all_stats_to_default_values()
		temp_upgrades.has_spell_element = UpgradeSettings.HAS_VOID | (1 << rng.randi_range(1, 6))
		settings.upgrade_settings.load_dict(temp_upgrades.save_dict())
		settings.upgrade_settings.fill_upgrade_slots(false, {})
		settings.last_save_time = Time.get_unix_time_from_system()
		settings.save()
		UIAudioPlayer.crash()
		SceneHandler.load_new_scene("res://Worlds/Demo/demo.tscn", "fade_to_black", func(content: DemoWorld) -> void: content.setup(settings), Quotes.random())


func _on_permadeath_toggled(button_pressed: bool) -> void:
	UIAudioPlayer.check(button_pressed)
	respawn.set_pressed_no_signal(not button_pressed)
	sandbox.set_pressed_no_signal(not button_pressed)
	game_mode = GameModeSettings.GameMode.PERMADEATH
	respawn_options.visible = false
	game_options.visible = true


func _on_respawn_toggled(button_pressed: bool) -> void:
	UIAudioPlayer.check(button_pressed)
	permadeath.set_pressed_no_signal(not button_pressed)
	sandbox.set_pressed_no_signal(not button_pressed)
	game_mode = GameModeSettings.GameMode.RESPAWN
	respawn_options.visible = true
	game_options.visible = true


func _on_sandbox_toggled(button_pressed: bool) -> void:
	UIAudioPlayer.check(button_pressed)
	respawn.set_pressed_no_signal(not button_pressed)
	permadeath.set_pressed_no_signal(not button_pressed)
	game_mode = GameModeSettings.GameMode.SANDBOX
	respawn_options.visible = false
	game_options.visible = false


func _on_upgrades_toggled(button_pressed: bool) -> void:
	UIAudioPlayer.check(button_pressed)
	if button_pressed:
		game_flags |= GameModeSettings.RESPAWN_WITH_UPGRADES
	else:
		game_flags &= ~GameModeSettings.RESPAWN_WITH_UPGRADES


func _on_artifacts_toggled(button_pressed: bool) -> void:
	UIAudioPlayer.check(button_pressed)
	if button_pressed:
		game_flags |= GameModeSettings.RESPAWN_WITH_ARTIFACTS
	else:
		game_flags &= ~GameModeSettings.RESPAWN_WITH_ARTIFACTS


func _on_spells_toggled(button_pressed: bool) -> void:
	UIAudioPlayer.check(button_pressed)
	if button_pressed:
		game_flags |= GameModeSettings.RESPAWN_WITH_SPELLS_AND_WANDS
	else:
		game_flags &= ~GameModeSettings.RESPAWN_WITH_SPELLS_AND_WANDS
		
func _on_coins_toggled(toggled_on: bool) -> void:
	UIAudioPlayer.check(toggled_on)
	if toggled_on:
		game_flags |= GameModeSettings.RESPAWN_WITH_COINS
	else:
		game_flags &= ~GameModeSettings.RESPAWN_WITH_COINS
		
func _on_spell_editing_toggled(toggled_on: bool) -> void:
	UIAudioPlayer.check(toggled_on)
	if toggled_on:
		game_flags |= GameModeSettings.DISALLOW_SPELL_EDITING
	else:
		game_flags &= ~GameModeSettings.DISALLOW_SPELL_EDITING
		
func _on_shop_toggled(toggled_on: bool) -> void:
	UIAudioPlayer.check(toggled_on)
	if toggled_on:
		game_flags |= GameModeSettings.SHOP_FOR_UPGRADES
	else:
		game_flags &= ~GameModeSettings.SHOP_FOR_UPGRADES	


func _on_health_value_changed(value: float) -> void:
	upgrades.level_health = ceili(value)
	UIAudioPlayer.switch()
	health_value.text = str(upgrades.max_health())
	
func _on_defence_value_changed(value: float) -> void:
	upgrades.level_defence = ceili(value)
	UIAudioPlayer.switch()
	defence_value.text = str(upgrades.max_defence())


func _on_attack_value_changed(value: float) -> void:
	upgrades.level_attack = ceili(value)
	UIAudioPlayer.switch()
	attack_value.text = str(upgrades.max_attack())


func _on_mana_value_changed(value: float) -> void:
	upgrades.level_mana = ceili(value)
	UIAudioPlayer.switch()
	mana_value.text = str(upgrades.max_mana())


func _on_velocity_value_changed(value: float) -> void:
	upgrades.level_v = ceili(value)
	UIAudioPlayer.switch()
	velocity_value.text = "%.1f" % upgrades.max_v()


func _on_spell_count_value_changed(value: float) -> void:
	upgrades.level_spells_in_book = ceili(value)
	UIAudioPlayer.switch()
	spell_count_value.text = str(upgrades.max_spells_in_book())

func _on_auto_mana_slider_value_changed(value: float) -> void:
	upgrades.level_mana_regen = ceili(value)
	UIAudioPlayer.switch()
	auto_mana_value.text = "%.1f" % upgrades.max_mana_regen()


func _on_T_value_changed(value: float) -> void:
	upgrades.level_T = ceili(value)
	UIAudioPlayer.switch()
	T_value.text = str(upgrades.max_T())


func _on_r_value_changed(value: float) -> void:
	upgrades.level_r = ceili(value)
	UIAudioPlayer.switch()
	r_value.text = "%.1f" % upgrades.max_r()


func _on_P_value_changed(value: float) -> void:
	upgrades.level_P = ceili(value)
	UIAudioPlayer.switch()
	P_value.text = str(upgrades.max_P())


func _on_N_value_changed(value: float) -> void:
	upgrades.level_N = ceili(value)
	UIAudioPlayer.switch()
	N_value.text = str(upgrades.max_N())
	
func _on_coins_slider_value_changed(value: float) -> void:
	upgrades.currency = int(value)
	UIAudioPlayer.switch()
	coins_value.text = str(int(value))

func _on_fire_toggled(button_pressed: bool) -> void:
	UIAudioPlayer.check(button_pressed)
	if button_pressed:
		upgrades.has_spell_element |= UpgradeSettings.HAS_FIRE
	else:
		upgrades.has_spell_element &= ~UpgradeSettings.HAS_FIRE


func _on_water_toggled(button_pressed: bool) -> void:
	UIAudioPlayer.check(button_pressed)
	if button_pressed:
		upgrades.has_spell_element |= UpgradeSettings.HAS_WATER
	else:
		upgrades.has_spell_element &= ~UpgradeSettings.HAS_WATER


func _on_rock_toggled(button_pressed: bool) -> void:
	UIAudioPlayer.check(button_pressed)
	if button_pressed:
		upgrades.has_spell_element |= UpgradeSettings.HAS_ROCK
	else:
		upgrades.has_spell_element &= ~UpgradeSettings.HAS_ROCK


func _on_air_toggled(button_pressed: bool) -> void:
	UIAudioPlayer.check(button_pressed)
	if button_pressed:
		upgrades.has_spell_element |= UpgradeSettings.HAS_AIR
	else:
		upgrades.has_spell_element &= ~UpgradeSettings.HAS_AIR


func _on_ice_toggled(button_pressed: bool) -> void:
	UIAudioPlayer.check(button_pressed)
	if button_pressed:
		upgrades.has_spell_element |= UpgradeSettings.HAS_ICE
	else:
		upgrades.has_spell_element &= ~UpgradeSettings.HAS_ICE


func _on_electric_toggled(button_pressed: bool) -> void:
	UIAudioPlayer.check(button_pressed)
	if button_pressed:
		upgrades.has_spell_element |= UpgradeSettings.HAS_ELECTRIC
	else:
		upgrades.has_spell_element &= ~UpgradeSettings.HAS_ELECTRIC


func _on_chain_at_start_toggled(button_pressed: bool) -> void:
	UIAudioPlayer.check(button_pressed)
	if button_pressed:
		upgrades.has_chain_method |= UpgradeSettings.HAS_CHAIN_ON_START
	else:
		upgrades.has_chain_method &= ~UpgradeSettings.HAS_CHAIN_ON_START


func _on_chain_at_end_toggled(button_pressed: bool) -> void:
	UIAudioPlayer.check(button_pressed)
	if button_pressed:
		upgrades.has_chain_method |= UpgradeSettings.HAS_CHAIN_ON_END
	else:
		upgrades.has_chain_method &= ~UpgradeSettings.HAS_CHAIN_ON_END


func _on_chain_on_hit_toggled(button_pressed: bool) -> void:
	UIAudioPlayer.check(button_pressed)
	if button_pressed:
		upgrades.has_chain_method |= UpgradeSettings.HAS_CHAIN_ON_HIT
	else:
		upgrades.has_chain_method &= ~UpgradeSettings.HAS_CHAIN_ON_HIT


func _on_starting_upgrades_toggled(button_pressed: bool) -> void:
	UIAudioPlayer.check(button_pressed)
	starting_upgrades_panel.visible = button_pressed
	var pos_delta := starting_upgrades_panel.size.x * (-0.5 if button_pressed else 0.5)
	save_name.position.x += pos_delta
	random_name.position.x += pos_delta
	use_seed.position.x += pos_delta
	use_save_file.position.x += pos_delta
	use_normal.position.x += pos_delta
	use_hardcore.position.x += pos_delta
	seed_edit.position.x += pos_delta
	($Create as Button).position.x += pos_delta
	($Cancel as Button).position.x += pos_delta
	permadeath.position.x += pos_delta
	respawn.position.x += pos_delta
	sandbox.position.x += pos_delta
	respawn_options.position.x += pos_delta
	game_options.position.x += pos_delta
	game_mode_description_panel.position.x += pos_delta
	background.position.x += pos_delta
	worlds_list.position.x += pos_delta


func _on_S_value_changed(value: float) -> void:
	upgrades.level_running_speed = ceili(value)
	UIAudioPlayer.switch()
	S_value.text = "%.2f" % upgrades.max_running_speed()


func _on_use_seed_toggled(toggled_on: bool) -> void:
	UIAudioPlayer.check(toggled_on)
	if toggled_on:
		seed_edit.placeholder_text = "Seed"
		seed_edit.visible = true
		use_save_file.set_pressed_no_signal(false)
		use_normal.set_pressed_no_signal(false)
		use_hardcore.set_pressed_no_signal(false)
		worlds_list.visible = false
		permadeath.visible = true
		respawn.visible = true
		#sandbox.visible = true
		respawn_options.visible = true
		game_options.visible = true
		starting_upgrades.visible = true
		game_mode_description_panel.visible = false
		#generation_version_label.visible = true


func _on_use_save_file_toggled(toggled_on: bool) -> void:
	UIAudioPlayer.check(toggled_on)
	if toggled_on:
		seed_edit.placeholder_text = "Save File Name"
		use_seed.set_pressed_no_signal(false)
		use_normal.set_pressed_no_signal(false)
		use_hardcore.set_pressed_no_signal(false)
		worlds_list.visible = true
		seed_edit.visible = false
		permadeath.visible = false
		respawn.visible = false
		#sandbox.visible = false
		respawn_options.visible = false
		game_options.visible = false
		starting_upgrades.visible = false
		if starting_upgrades.button_pressed:
			starting_upgrades.button_pressed = false
		game_mode_description_panel.visible = false
		#generation_version_label.visible = false

func _on_use_normal_toggled(toggled_on: bool) -> void:
	UIAudioPlayer.check(toggled_on)
	if toggled_on:
		use_seed.set_pressed_no_signal(false)
		use_save_file.set_pressed_no_signal(false)
		use_hardcore.set_pressed_no_signal(false)
		seed_edit.visible = false
		permadeath.visible = false
		respawn.visible = false
		#sandbox.visible = false
		respawn_options.visible = false
		game_options.visible = false
		starting_upgrades.visible = false
		if starting_upgrades.button_pressed:
			starting_upgrades.button_pressed = false
		worlds_list.visible = false
		game_mode_description_panel.visible = true
		game_mode_description.text = "When you die you will respawn with all your spells and upgrades. However, you will lose all your artifacts."
		#generation_version_label.visible = false

func _on_use_hardcore_toggled(toggled_on: bool) -> void:
	UIAudioPlayer.check(toggled_on)
	if toggled_on:
		use_seed.set_pressed_no_signal(false)
		use_normal.set_pressed_no_signal(false)
		use_save_file.set_pressed_no_signal(false)
		seed_edit.visible = false
		permadeath.visible = false
		respawn.visible = false
		#sandbox.visible = false
		respawn_options.visible = false
		game_options.visible = false
		starting_upgrades.visible = false
		if starting_upgrades.button_pressed:
			starting_upgrades.button_pressed = false
		worlds_list.visible = false
		game_mode_description_panel.visible = true
		game_mode_description.text = "When you die the game is over"
		#generation_version_label.visible = false


func _on_save_name_focus_entered() -> void:
	UIAudioPlayer.focus()


func _on_seed_focus_entered() -> void:
	UIAudioPlayer.focus()


func _on_random_name_pressed() -> void:
	UIAudioPlayer.click()
	save_name.text = name_generator.english_names.generate(8, 1, 12, false)
