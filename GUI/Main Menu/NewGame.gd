class_name NewGameScreen
extends Control

@onready var permadeath: Button = $Permadeath
@onready var respawn: Button = $Respawn
@onready var sandbox: Button = $Sandbox

@onready var respawn_options: Panel = $RespawnOptions

var game_mode: GameModeSettings.GameMode = GameModeSettings.GameMode.RESPAWN
var respawn_flags: int = GameModeSettings.RESPAWN_WITH_UPGRADES

var upgrades: UpgradeSettings

var main_menu_world: MainMenuWorld = null

var world_names := []
var world_name_exists := false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	upgrades = UpgradeSettings.new()
	$StartingUpgradesPanel/Health/Slider.value = upgrades.max_health
	$StartingUpgradesPanel/Attack/Slider.value = upgrades.max_attack
	$StartingUpgradesPanel/Defence/Slider.value = upgrades.max_defence
	$StartingUpgradesPanel/Mana/Slider.value = upgrades.max_mana
	$StartingUpgradesPanel/Velocity/Slider.value = upgrades.max_v
	$StartingUpgradesPanel/SpellCount/Slider.value = upgrades.max_spells_in_book
	$StartingUpgradesPanel/T/Slider.value = upgrades.max_T
	$StartingUpgradesPanel/r/Slider.value = upgrades.max_r
	$StartingUpgradesPanel/P/Slider.value = upgrades.max_P
	$StartingUpgradesPanel/N/Slider.value = upgrades.max_N
	
	$StartingUpgradesPanel/Health/Slider.min_value = upgrades.max_health
	$StartingUpgradesPanel/Attack/Slider.min_value = upgrades.max_attack
	$StartingUpgradesPanel/Defence/Slider.min_value = upgrades.max_defence
	$StartingUpgradesPanel/Mana/Slider.min_value = upgrades.max_mana
	$StartingUpgradesPanel/Velocity/Slider.min_value = upgrades.max_v
	$StartingUpgradesPanel/SpellCount/Slider.min_value = upgrades.max_spells_in_book
	$StartingUpgradesPanel/T/Slider.min_value = upgrades.max_T
	$StartingUpgradesPanel/r/Slider.min_value = upgrades.max_r
	$StartingUpgradesPanel/P/Slider.min_value = upgrades.max_P
	$StartingUpgradesPanel/N/Slider.min_value = upgrades.max_N
	
	$StartingUpgradesPanel/Health/Slider.max_value = upgrades.LIMIT_HEALTH
	$StartingUpgradesPanel/Attack/Slider.max_value = upgrades.LIMIT_ATTACK
	$StartingUpgradesPanel/Defence/Slider.max_value = upgrades.LIMIT_DEFENCE
	$StartingUpgradesPanel/Mana/Slider.max_value = upgrades.LIMIT_MANA
	$StartingUpgradesPanel/Velocity/Slider.max_value = upgrades.LIMIT_v
	$StartingUpgradesPanel/SpellCount/Slider.max_value = upgrades.LIMIT_SPELLS_IN_BOOK
	$StartingUpgradesPanel/T/Slider.max_value = upgrades.LIMIT_T
	$StartingUpgradesPanel/r/Slider.max_value = upgrades.LIMIT_r
	$StartingUpgradesPanel/P/Slider.max_value = upgrades.LIMIT_P
	$StartingUpgradesPanel/N/Slider.max_value = upgrades.LIMIT_N
	
	$StartingUpgradesPanel/SpellElements/Fire.button_pressed = upgrades.check_if_has_spell_element(Spell.Element.FIRE)
	$StartingUpgradesPanel/SpellElements/Water.button_pressed = upgrades.check_if_has_spell_element(Spell.Element.WATER)
	$StartingUpgradesPanel/SpellElements/Rock.button_pressed = upgrades.check_if_has_spell_element(Spell.Element.ROCK)
	$StartingUpgradesPanel/SpellElements/Air.button_pressed = upgrades.check_if_has_spell_element(Spell.Element.AIR)
	$StartingUpgradesPanel/SpellElements/Ice.button_pressed = upgrades.check_if_has_spell_element(Spell.Element.AIR)
	$StartingUpgradesPanel/SpellElements/Electric.button_pressed = upgrades.check_if_has_spell_element(Spell.Element.ELECTRIC)
	
	$StartingUpgradesPanel/ChainMethods/ChainAtStart.button_pressed = upgrades.check_if_has_chain_method(Spell.ChainCastKind.START)
	$StartingUpgradesPanel/ChainMethods/ChainAtEnd.button_pressed = upgrades.check_if_has_chain_method(Spell.ChainCastKind.END)
	$StartingUpgradesPanel/ChainMethods/ChainOnHit.button_pressed = upgrades.check_if_has_chain_method(Spell.ChainCastKind.HIT)
	
	var dir := DirAccess.open("user://")
	if not dir.dir_exists("worlds"):
		dir.make_dir("worlds")
	dir.change_dir("worlds")
	world_names = dir.get_directories()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_cancel_pressed() -> void:
	main_menu_world.show_menu_screen(MainMenuWorld.MenuScreenKind.MAIN)
	#get_tree().change_scene_to_file("res://GUI/Main Menu/MainMenu.tscn")


func _on_create_pressed() -> void:
	if $UseSeed.button_pressed:
		var settings := WorldSettings.new(get_viewport())
		settings.load_dict(GlobalData.game_settings.default_world_settings.save_dict())
		settings.world_name = $SaveName.text
		settings.sed = hash($Seed.text)
		
		settings.game_mode_settings.mode = game_mode
		match game_mode:
			GameModeSettings.GameMode.RESPAWN:
				settings.game_mode_settings.flags = respawn_flags
		settings.upgrade_settings.load_dict(upgrades.save_dict())
		settings.save()

		SceneHandler.load_new_scene("res://Worlds/Demo/demo.tscn", "fade_to_black", func(content): content.setup(settings))
	elif $UseSaveFile.button_pressed:
		if not world_name_exists:
			return
		var settings := WorldSettings.new(get_viewport())
		settings.read($Seed.text)
		settings.world_name = $SaveName.text
		settings.save()

		SceneHandler.load_new_scene("res://Worlds/Demo/demo.tscn", "fade_to_black", func(content): content.setup(settings))

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
	$StartingUpgradesPanel/Health/Value.text = str(int(value))
	upgrades.max_health = int(value)
	
func _on_defence_value_changed(value: float) -> void:
	$StartingUpgradesPanel/Defence/Value.text = str(int(value))
	upgrades.max_attack = int(value)


func _on_attack_value_changed(value: float) -> void:
	$StartingUpgradesPanel/Attack/Value.text = str(int(value))
	upgrades.max_defence = int(value)


func _on_mana_value_changed(value: float) -> void:
	$StartingUpgradesPanel/Mana/Value.text = str(int(value))
	upgrades.max_mana = int(value)


func _on_velocity_value_changed(value: float) -> void:
	$StartingUpgradesPanel/Velocity/Value.text = "%.1f" % value
	upgrades.max_v = value


func _on_spell_count_value_changed(value: float) -> void:
	$StartingUpgradesPanel/SpellCount/Value.text = str(int(value))
	upgrades.max_spells_in_book = int(value)


func _on_T_value_changed(value: float) -> void:
	$StartingUpgradesPanel/T/Value.text = str(int(value))
	upgrades.max_T = int(value)


func _on_r_value_changed(value: float) -> void:
	$StartingUpgradesPanel/r/Value.text = "%.2f" % value
	upgrades.max_r = value


func _on_P_value_changed(value: float) -> void:
	$StartingUpgradesPanel/P/Value.text = str(int(value))
	upgrades.max_P = int(value)


func _on_N_value_changed(value: float) -> void:
	$StartingUpgradesPanel/N/Value.text = str(int(value))
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
	$StartingUpgradesPanel.visible = button_pressed


func _on_S_value_changed(value: float) -> void:
	$StartingUpgradesPanel/S/Value.text = "%.2f" % value
	upgrades.max_running_speed = value


func _on_seed_text_changed() -> void:
	if $UseSaveFile.button_pressed:
		$SaveNameMissing.visible = false
		for world_name in world_names:
			if world_name == $Seed.text:
				world_name_exists = true
				return
		world_name_exists = false
		$SaveNameMissing.visible = true


func _on_use_seed_toggled(toggled_on: bool) -> void:
	$Seed.placeholder_text = "Seed"
	$UseSaveFile.set_pressed_no_signal(not toggled_on)
	permadeath.visible = toggled_on
	respawn.visible = toggled_on
	sandbox.visible = toggled_on
	$RespawnOptions.visible = toggled_on
	$StartingUpgrades.visible = toggled_on


func _on_use_save_file_toggled(toggled_on: bool) -> void:
	$Seed.placeholder_text = "Save Name"
	$UseSeed.set_pressed_no_signal(not toggled_on)
	permadeath.visible = not toggled_on
	respawn.visible = not toggled_on
	sandbox.visible = not toggled_on
	$RespawnOptions.visible = not toggled_on
	$StartingUpgrades.visible = not toggled_on
	if toggled_on:
		$StartingUpgrades.set_pressed_no_signal(false)
		$StartingUpgradesPanel.visible = false
