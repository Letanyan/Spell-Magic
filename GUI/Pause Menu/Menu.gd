class_name Menu
extends Control

enum Kind { ANY, SPELLS, WANDS, ARTIFACTS, UPGRADES, SETTINGS }

@onready var magic_book: MagicBookGUI = $MagicBook
@onready var wand_case: WandCaseGUI = $WandCase
@onready var artifacts: ArtifactsGUI = $Artifacts
@onready var upgrades: UpgradesGUI = $Upgrades
@onready var settings: SettingsGUI = $Settings
var current_index := 0

@onready var spells_button: Button = $Tabbar/Spells
@onready var wands_button: Button = $Tabbar/Wands
@onready var artifacts_button: Button = $Tabbar/Artifacts
@onready var quit_button: Button = $Tabbar/Quit
@onready var upgrades_button: Button = $Tabbar/Upgrades
@onready var settings_button: Button = $Tabbar/Settings

@onready var message_panel: Panel = $MessagePanel
@onready var message_label: Label = $MessagePanel/MessageLabel

var is_showing: bool = false
var player: Player
var world_settings: WorldSettings
var player_in_combat: bool = false

signal close_menu

func setup(book: MagicBook, case: WandCase, artifaces: Artifacts, _world_settings: WorldSettings, _player: Player) -> void:
	magic_book.book = book
	wand_case.book = book
	wand_case.case = case
	artifacts.artifacts = artifaces
	upgrades.settings = _world_settings
	settings.world_settings = _world_settings
	settings.player = _player
	player = _player
	world_settings = _world_settings
	
	settings.exit_game.connect(func() -> void: get_tree().quit())
	settings.save_game.connect(func() -> void: save_changes())
	settings.main_menu.connect(func() -> void: SceneHandler.load_new_scene("res://Worlds/MainMenu/MainMenuWorld.tscn", "fade_to_black"))

func _ready() -> void:
	SignalBus.pick_up_world_item_artifact.connect(func(a: Artifact, m: String) -> void: artifacts.update_list_and_grid())
	SignalBus.pick_up_world_item_spell.connect(func(s: Spell, m: String) -> void: magic_book.add_spell(s))
	SignalBus.pick_up_world_item_coin.connect(func(c: int, m: String) -> void: upgrades.update_state(UpgradeSettings.PurchaseError.NONE))

func update_index(index: int) -> void:
	UIAudioPlayer.switch()
	save_changes()
	const MAX_INDEX = 4 # used for wrap around
	if index < 0:
		current_index = MAX_INDEX
	elif index > MAX_INDEX:
		current_index = 0
	else:
		current_index = index
	magic_book.visible = false
	wand_case.visible = false
	artifacts.visible = false
	upgrades.visible = false
	settings.visible = false
	message_panel.visible = false
	spells_button.set_pressed_no_signal(false)
	wands_button.set_pressed_no_signal(false)
	artifacts_button.set_pressed_no_signal(false)
	upgrades_button.set_pressed_no_signal(false)
	settings_button.set_pressed_no_signal(false)
	if GlobalData.is_demo and (current_index == 2 or current_index == 3):
		match current_index:
			2: message_label.text = "Not Available in Demo\nArtifacts Disabled"; artifacts_button.set_pressed_no_signal(true)
			3: message_label.text = "Not Available in Demo\nUpgrades Disabled"; upgrades_button.set_pressed_no_signal(true)
		message_panel.visible = true
	elif player_in_combat and current_index < 4:
		match current_index:
			0: message_label.text = "Currently in Combat\nMagic Book Disabled"; spells_button.set_pressed_no_signal(true)
			1: message_label.text = "Currently in Combat\nWand Case Disabled"; wands_button.set_pressed_no_signal(true)
			2: message_label.text = "Currently in Combat\nArtifacts Disabled"; artifacts_button.set_pressed_no_signal(true)
			3: message_label.text = "Currently in Combat\nUpgrades Disabled"; upgrades_button.set_pressed_no_signal(true)
		message_panel.visible = true
	else:
		match current_index:
			0: magic_book.visible = true; spells_button.grab_focus(); spells_button.set_pressed_no_signal(true); magic_book.duplicate_book()
			1: wand_case.visible = true; wands_button.grab_focus(); wands_button.set_pressed_no_signal(true); wand_case.reload_wand_shelf_items(); wand_case.update_wand_shelf_items(true)
			2: artifacts.visible = true; artifacts_button.grab_focus(); artifacts_button.set_pressed_no_signal(true); artifacts.update_list_and_grid()
			3: upgrades.visible = true; upgrades_button.grab_focus(); upgrades_button.set_pressed_no_signal(true); upgrades.update_state(UpgradeSettings.PurchaseError.NONE)
			4: settings.visible = true; settings_button.grab_focus(); settings_button.set_pressed_no_signal(true); settings.update_controls()
		if current_index == 4 and settings.tab_container.get_current_tab_control().name == "Customisation":
			player.animate_spring_arm_length(3, 0.2)
		else:
			player.animate_spring_arm_length(0, 0.2)
			
		

func _on_spells_pressed() -> void:
	update_index(0)

func _on_wands_pressed() -> void:
	update_index(1)

func _on_artifacts_pressed() -> void:
	update_index(2)
	
func _on_upgrades_pressed() -> void:
	update_index(3)
	
func _on_settings_pressed() -> void:
	update_index(4)

func open(kind: Kind) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	UIAudioPlayer.open()
	visible = true
	is_showing = true
	match kind:
		Kind.SPELLS:
			_on_spells_pressed()
		Kind.WANDS:
			_on_wands_pressed()
		Kind.ARTIFACTS:
			_on_artifacts_pressed()
		Kind.UPGRADES:
			_on_upgrades_pressed()
		Kind.SETTINGS:
			_on_settings_pressed()
		Kind.ANY:
			update_index(current_index)
	world_settings.save()

func close() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	UIAudioPlayer.close()
	is_showing = false
	visible = false
	save_changes()
	
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
		
	GlobalData.controller.handle_input(event)
		
	if event is InputEventJoypadButton:
		if event.is_action_pressed("RB"):
			update_index(current_index + 1)
		elif event.is_action_pressed("LB"):
			update_index(current_index - 1)
			
		if event.is_action_pressed("Back"):
			if spells_button.has_focus() or wands_button.has_focus() or artifacts_button.has_focus() or quit_button.has_focus() or upgrades_button.has_focus() or settings_button.has_focus():
				close_menu.emit()
	

func save_changes() -> void:
	if magic_book.visible:
		if world_settings.is_test_arena:
			magic_book.book.save_absolute_path("res://magic_book.json")
		else:
			magic_book.book.save(world_settings.world_name)
	if wand_case.visible:
		wand_case.case.save(world_settings.world_name)
	if artifacts.visible:
		artifacts.artifacts.save(world_settings.world_name)
	if upgrades.visible:
		upgrades.settings.save()
	if settings.visible:
		settings.world_settings.save()
		if settings.is_magic_book_selected:
			settings.save_user_magic_book()
	world_settings.save()


func _on_quit_pressed() -> void:
	UIAudioPlayer.click()
	close_menu.emit()
