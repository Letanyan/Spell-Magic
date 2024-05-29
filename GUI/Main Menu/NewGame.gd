class_name NewGameScreen
extends Control

@onready var save_name: TextEdit = $SaveName
@onready var use_seed: Button = $UseSeed
@onready var use_save_file: Button = $UseSaveFile
@onready var seed_edit: TextEdit = $Seed

@onready var permadeath: Button = $Permadeath
@onready var respawn: Button = $Respawn
@onready var sandbox: Button = $Sandbox

@onready var respawn_options: Panel = $RespawnOptions

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

@onready var save_name_missing: Label = $SaveNameMissing




var game_mode: GameModeSettings.GameMode = GameModeSettings.GameMode.RESPAWN
var respawn_flags: int = GameModeSettings.RESPAWN_WITH_UPGRADES

var upgrades: UpgradeSettings

var main_menu_world: MainMenuWorld = null

var world_names: PackedStringArray = PackedStringArray([])
var world_name_exists := false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	upgrades = UpgradeSettings.new()
	health_slider.value = upgrades.max_health
	attack_slider.value = upgrades.max_attack
	defence_slider.value = upgrades.max_defence
	mana_slider.value = upgrades.max_mana
	velocity_slider.value = upgrades.max_v
	spell_count_slider.value = upgrades.max_spells_in_book
	T_slider.value = upgrades.max_T
	r_slider.value = upgrades.max_r
	P_slider.value = upgrades.max_P
	N_slider.value = upgrades.max_N
	S_slider.value = upgrades.max_running_speed
	auto_mana_slider.value = upgrades.max_mana_regen
	
	health_slider.min_value = upgrades.max_health
	attack_slider.min_value = upgrades.max_attack
	defence_slider.min_value = upgrades.max_defence
	mana_slider.min_value = upgrades.max_mana
	velocity_slider.min_value = upgrades.max_v
	spell_count_slider.min_value = upgrades.max_spells_in_book
	T_slider.min_value = upgrades.max_T
	r_slider.min_value = upgrades.max_r
	P_slider.min_value = upgrades.max_P
	N_slider.min_value = upgrades.max_N
	S_slider.min_value = upgrades.max_running_speed
	auto_mana_slider.min_value = upgrades.max_mana_regen 
	
	health_slider.max_value = upgrades.LIMIT_HEALTH
	attack_slider.max_value = upgrades.LIMIT_ATTACK
	defence_slider.max_value = upgrades.LIMIT_DEFENCE
	mana_slider.max_value = upgrades.LIMIT_MANA
	velocity_slider.max_value = upgrades.LIMIT_v
	spell_count_slider.max_value = upgrades.LIMIT_SPELLS_IN_BOOK
	T_slider.max_value = upgrades.LIMIT_T
	r_slider.max_value = upgrades.LIMIT_r
	P_slider.max_value = upgrades.LIMIT_P
	N_slider.max_value = upgrades.LIMIT_N
	S_slider.max_value = upgrades.LIMIT_RUNNING_SPEED
	auto_mana_slider.max_value = upgrades.LIMIT_MANA_REGEN
	
	spell_elements_fire.button_pressed = upgrades.check_if_has_spell_element(Spell.Element.FIRE)
	spell_elements_water.button_pressed = upgrades.check_if_has_spell_element(Spell.Element.WATER)
	spell_elements_rock.button_pressed = upgrades.check_if_has_spell_element(Spell.Element.ROCK)
	spell_elements_air.button_pressed = upgrades.check_if_has_spell_element(Spell.Element.AIR)
	spell_elements_ice.button_pressed = upgrades.check_if_has_spell_element(Spell.Element.AIR)
	spell_elements_electric.button_pressed = upgrades.check_if_has_spell_element(Spell.Element.ELECTRIC)
	
	chain_methods_chain_at_start.button_pressed = upgrades.check_if_has_chain_method(Spell.ChainCastKind.START)
	chain_methods_chain_at_end.button_pressed = upgrades.check_if_has_chain_method(Spell.ChainCastKind.END)
	chain_methods_chain_on_hit.button_pressed = upgrades.check_if_has_chain_method(Spell.ChainCastKind.HIT)
	
	var dir := DirAccess.open("user://")
	if not dir.dir_exists("worlds"):
		dir.make_dir("worlds")
	dir.change_dir("worlds")
	world_names = dir.get_directories()


func _on_cancel_pressed() -> void:
	main_menu_world.show_menu_screen(MainMenuWorld.MenuScreenKind.MAIN)
	#get_tree().change_scene_to_file("res://GUI/Main Menu/MainMenu.tscn")

func _on_create_pressed() -> void:
	if use_seed.button_pressed:
		var settings := WorldSettings.new(get_viewport())
		settings.load_dict(GlobalData.game_settings.default_world_settings.save_dict())
		settings.world_name = save_name.text
		if seed_edit.text.is_valid_int():
			settings.sed = seed_edit.text.to_int()
		else:
			settings.sed = hash(seed_edit.text)
		
		settings.game_mode_settings.mode = game_mode
		match game_mode:
			GameModeSettings.GameMode.RESPAWN:
				settings.game_mode_settings.flags = respawn_flags
		settings.upgrade_settings.load_dict(upgrades.save_dict())
		settings.save()

		SceneHandler.load_new_scene("res://Worlds/Demo/demo.tscn", "fade_to_black", func(content: DemoWorld) -> void: content.setup(settings))
	elif use_save_file.button_pressed:
		if not world_name_exists:
			return
		var settings := WorldSettings.new(get_viewport())
		settings.read(seed_edit.text)
		settings.world_name = save_name.text
		settings.save()

		SceneHandler.load_new_scene("res://Worlds/Demo/demo.tscn", "fade_to_black", func(content: DemoWorld) -> void: content.setup(settings))

	#var demo = load("res://Worlds/Demo/demo.tscn").instantiate()
	#demo.setup(settings)
	#
	#var current = get_tree().current_scene
	#get_tree().root.add_child(demo)
	#current.call_deferred("free")
	#get_tree().current_scene = demo


func _on_permadeath_toggled(button_pressed: bool) -> void:
	respawn.set_pressed_no_signal(not button_pressed)
	sandbox.set_pressed_no_signal(not button_pressed)
	game_mode = GameModeSettings.GameMode.PERMADEATH
	respawn_options.visible = false


func _on_respawn_toggled(button_pressed: bool) -> void:
	permadeath.set_pressed_no_signal(not button_pressed)
	sandbox.set_pressed_no_signal(not button_pressed)
	game_mode = GameModeSettings.GameMode.RESPAWN
	respawn_options.visible = true


func _on_sandbox_toggled(button_pressed: bool) -> void:
	respawn.set_pressed_no_signal(not button_pressed)
	permadeath.set_pressed_no_signal(not button_pressed)
	game_mode = GameModeSettings.GameMode.SANDBOX
	respawn_options.visible = false


func _on_upgrades_toggled(button_pressed: bool) -> void:
	if button_pressed:
		respawn_flags |= GameModeSettings.RESPAWN_WITH_UPGRADES
	else:
		respawn_flags &= ~(1 << GameModeSettings.RESPAWN_WITH_UPGRADES)


func _on_artifacts_toggled(button_pressed: bool) -> void:
	if button_pressed:
		respawn_flags |= GameModeSettings.RESPAWN_WITH_ARTIFACTS
	else:
		respawn_flags &= ~(1 << GameModeSettings.RESPAWN_WITH_ARTIFACTS)


func _on_spells_toggled(button_pressed: bool) -> void:
	if button_pressed:
		respawn_flags |= GameModeSettings.RESPAWN_WITH_SPELLS_AND_WANDS
	else:
		respawn_flags &= ~(1 << GameModeSettings.RESPAWN_WITH_SPELLS_AND_WANDS)


func _on_health_value_changed(value: float) -> void:
	health_value.text = str(int(value))
	upgrades.max_health = int(value)
	
func _on_defence_value_changed(value: float) -> void:
	defence_value.text = str(int(value))
	upgrades.max_attack = int(value)


func _on_attack_value_changed(value: float) -> void:
	attack_value.text = str(int(value))
	upgrades.max_defence = int(value)


func _on_mana_value_changed(value: float) -> void:
	mana_value.text = str(int(value))
	upgrades.max_mana = int(value)


func _on_velocity_value_changed(value: float) -> void:
	velocity_value.text = "%.1f" % value
	upgrades.max_v = value


func _on_spell_count_value_changed(value: float) -> void:
	spell_count_value.text = str(int(value))
	upgrades.max_spells_in_book = int(value)

func _on_auto_mana_slider_value_changed(value: float) -> void:
	auto_mana_value.text = "%.1f" % value
	upgrades.max_mana_regen = value


func _on_T_value_changed(value: float) -> void:
	T_value.text = str(int(value))
	upgrades.max_T = int(value)


func _on_r_value_changed(value: float) -> void:
	r_value.text = "%.1f" % value
	upgrades.max_r = value


func _on_P_value_changed(value: float) -> void:
	P_value.text = str(int(value))
	upgrades.max_P = int(value)


func _on_N_value_changed(value: float) -> void:
	N_value.text = str(int(value))
	upgrades.max_N = int(value)


func _on_fire_toggled(button_pressed: bool) -> void:
	if button_pressed:
		upgrades.has_spell_element |= UpgradeSettings.HAS_FIRE
	else:
		upgrades.has_spell_element &= ~(1 << UpgradeSettings.HAS_FIRE)


func _on_water_toggled(button_pressed: bool) -> void:
	if button_pressed:
		upgrades.has_spell_element |= UpgradeSettings.HAS_WATER
	else:
		upgrades.has_spell_element &= ~(1 << UpgradeSettings.HAS_WATER)


func _on_rock_toggled(button_pressed: bool) -> void:
	if button_pressed:
		upgrades.has_spell_element |= UpgradeSettings.HAS_ROCK
	else:
		upgrades.has_spell_element &= ~(1 << UpgradeSettings.HAS_ROCK)


func _on_air_toggled(button_pressed: bool) -> void:
	if button_pressed:
		upgrades.has_spell_element |= UpgradeSettings.HAS_AIR
	else:
		upgrades.has_spell_element &= ~(1 << UpgradeSettings.HAS_AIR)


func _on_ice_toggled(button_pressed: bool) -> void:
	if button_pressed:
		upgrades.has_spell_element |= UpgradeSettings.HAS_ICE
	else:
		upgrades.has_spell_element &= ~(1 << UpgradeSettings.HAS_ICE)


func _on_electric_toggled(button_pressed: bool) -> void:
	if button_pressed:
		upgrades.has_spell_element |= UpgradeSettings.HAS_ELECTRIC
	else:
		upgrades.has_spell_element &= ~(1 << UpgradeSettings.HAS_ELECTRIC)


func _on_chain_at_start_toggled(button_pressed: bool) -> void:
	if button_pressed:
		upgrades.has_chain_method |= UpgradeSettings.HAS_CHAIN_ON_START
	else:
		upgrades.has_chain_method &= ~(1 << UpgradeSettings.HAS_CHAIN_ON_START)


func _on_chain_at_end_toggled(button_pressed: bool) -> void:
	if button_pressed:
		upgrades.has_chain_method |= UpgradeSettings.HAS_CHAIN_ON_END
	else:
		upgrades.has_chain_method &= ~(1 << UpgradeSettings.HAS_CHAIN_ON_END)


func _on_chain_on_hit_toggled(button_pressed: bool) -> void:
	if button_pressed:
		upgrades.has_chain_method |= UpgradeSettings.HAS_CHAIN_ON_HIT
	else:
		upgrades.has_chain_method &= ~(1 << UpgradeSettings.HAS_CHAIN_ON_HIT)


func _on_starting_upgrades_toggled(button_pressed: bool) -> void:
	starting_upgrades_panel.visible = button_pressed


func _on_S_value_changed(value: float) -> void:
	S_value.text = "%.2f" % value
	upgrades.max_running_speed = value


func _on_seed_text_changed() -> void:
	if use_save_file.button_pressed:
		save_name_missing.visible = false
		for world_name in world_names:
			if world_name == seed_edit.text:
				world_name_exists = true
				return
		world_name_exists = false
		save_name_missing.visible = true


func _on_use_seed_toggled(toggled_on: bool) -> void:
	seed_edit.placeholder_text = "Seed"
	use_save_file.set_pressed_no_signal(not toggled_on)
	permadeath.visible = toggled_on
	respawn.visible = toggled_on
	sandbox.visible = toggled_on
	respawn_options.visible = toggled_on
	starting_upgrades.visible = toggled_on


func _on_use_save_file_toggled(toggled_on: bool) -> void:
	seed_edit.placeholder_text = "Save File Name"
	use_seed.set_pressed_no_signal(not toggled_on)
	permadeath.visible = not toggled_on
	respawn.visible = not toggled_on
	sandbox.visible = not toggled_on
	respawn_options.visible = not toggled_on
	starting_upgrades.visible = not toggled_on
	if toggled_on:
		starting_upgrades.set_pressed_no_signal(false)
		starting_upgrades_panel.visible = false
