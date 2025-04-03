class_name Menu
extends Control

enum Kind { ANY, WANDS, UPGRADES, ARTIFACTS, SPELLS, NOTES, SETTINGS }

@onready var background: Panel = $Background
@onready var game_menu: GameMenu = $GameMenu

@onready var magic_book: MagicBookGUI = $Background/MagicBook
@onready var wand_case: WandCaseGUI = $Background/WandCase
@onready var artifacts: ArtifactsGUI = $Background/Artifacts
@onready var upgrades: UpgradesGUI = $Background/Upgrades
@onready var notes: NotesUI = $Background/Notes
@onready var settings: SettingsGUI = $Background/Settings
@onready var spell_deck: SpellDeckGUI = $Background/SpellDeckGUI
var current_index := Kind.WANDS

@onready var spells_button: Button = $Background/Tabbar/HBox/Spells
@onready var wands_button: Button = $Background/Tabbar/HBox/Wands
@onready var artifacts_button: Button = $Background/Tabbar/HBox/Artifacts
@onready var quit_button: Button = $Background/Tabbar/Quit
@onready var upgrades_button: Button = $Background/Tabbar/HBox/Upgrades
@onready var settings_button: Button = $Background/Tabbar/Settings
@onready var notes_button: Button = $Background/Tabbar/HBox/Notes

@onready var message_panel: Panel = $Background/MessagePanel
@onready var message_label: Label = $Background/MessagePanel/MessageLabel

var is_quick_menu: bool = false
var is_showing: bool = false
var player: Player
var world_settings: WorldSettings
var player_in_combat: bool = false
var showing_customisation: bool = false

signal close_menu
signal tab_opened(index: int)

func setup(book: MagicBook, case: WandCase, artifaces: Artifacts, _world_settings: WorldSettings, _player: Player) -> void:
	magic_book.book = book
	spell_deck.book = book
	wand_case.book = book
	wand_case.case = case
	artifacts.artifacts = artifaces
	upgrades.settings = _world_settings
	settings.world_settings = _world_settings
	settings.player = _player
	player = _player
	world_settings = _world_settings
	
	if world_settings.game_mode_settings.has_flag(GameModeSettings.SHOP_FOR_UPGRADES):
		upgrades_button.text = "Upgrades"
	else:
		upgrades_button.text = "Stats"
		upgrades.make_display_only(true)
		
	
	settings.exit_game.connect(func() -> void: get_tree().quit())
	settings.save_game.connect(func() -> void: save_changes())
	settings.main_menu.connect(func() -> void: SceneHandler.load_new_scene("res://Worlds/MainMenu/MainMenuWorld.tscn", "fade_to_black"))
	
	game_menu.continue_game.connect(func() -> void: close_menu.emit())
	game_menu.exit_game.connect(func() -> void: get_tree().quit())
	game_menu.save_game.connect(func() -> void: save_changes())
	game_menu.main_menu.connect(func() -> void: SceneHandler.load_new_scene("res://Worlds/MainMenu/MainMenuWorld.tscn", "fade_to_black"))
	game_menu.settings.connect(func() -> void:
		is_quick_menu = false
		update_index(Kind.SETTINGS)
	)
	
	settings.tab_changed.connect(update_camera_and_menu)

func _ready() -> void:
	SignalBus.pick_up_world_item_artifact.connect(func(a: Artifact, m: String) -> void: artifacts.update_list_and_grid())
	SignalBus.pick_up_world_item_spell.connect(func(s: Spell, m: String) -> void: 
		magic_book.add_spell(s, false)
		spell_deck.add_spell(s)
		var w := wand_case.case.wands[wand_case.case.selected_wand]
		for i: String in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]:
			var opt := w.keys[PackedStringArray([i])] as Wand.Option
			if not opt.spells.is_empty():
				continue
			opt.kind = Wand.Kind.PICK
			opt.parse_spells(s.name, magic_book.book)
			break
	)
	SignalBus.pick_up_world_item_coin.connect(func(c: int, m: String) -> void: upgrades.update_state(UpgradeSettings.PurchaseError.NONE))

func update_index(index: Kind) -> void:
	UIAudioPlayer.switch()
	save_changes()
	var is_opening := current_index == index
	current_index = index
	magic_book.visible = false
	spell_deck.visible = false
	wand_case.visible = false
	artifacts.visible = false
	upgrades.visible = false
	notes.visible = false
	settings.visible = false
	message_panel.visible = false
	if is_quick_menu:
		game_menu.visible = true
		background.visible = false
	else:
		game_menu.visible = false
		background.visible = true
	spells_button.set_pressed_no_signal(false)
	wands_button.set_pressed_no_signal(false)
	artifacts_button.set_pressed_no_signal(false)
	upgrades_button.set_pressed_no_signal(false)
	notes_button.set_pressed_no_signal(false)
	settings_button.set_pressed_no_signal(false)
	if GlobalData.is_demo and (current_index == Kind.ARTIFACTS or (current_index == Kind.UPGRADES and settings.world_settings.game_mode_settings.has_flag(GameModeSettings.SHOP_FOR_UPGRADES))):
		match current_index:
			Kind.ARTIFACTS: artifacts_button.grab_focus(); artifacts_button.set_pressed_no_signal(true); message_label.text = "Not Available in Demo\nArtifacts Disabled"
			Kind.UPGRADES: upgrades_button.grab_focus(); upgrades_button.set_pressed_no_signal(true); message_label.text = "Not Available in Demo\nUpgrades Disabled"
		message_panel.visible = true
	elif player_in_combat and current_index <= Kind.SPELLS:
		match current_index:
			Kind.SPELLS:
				spells_button.grab_focus(); spells_button.set_pressed_no_signal(true);
				if settings.world_settings.game_mode_settings.has_flag(GameModeSettings.SPELL_DECK_BUILDING):
					message_label.text = "Currently in Combat\nSpell Deck Disabled"
				else:
					message_label.text = "Currently in Combat\nMagic Book Disabled"
			Kind.WANDS: wands_button.grab_focus(); wands_button.set_pressed_no_signal(true); message_label.text = "Currently in Combat\nWand Case Disabled"
			Kind.ARTIFACTS: artifacts_button.grab_focus(); artifacts_button.set_pressed_no_signal(true); message_label.text = "Currently in Combat\nArtifacts Disabled"
			Kind.UPGRADES: upgrades_button.grab_focus(); upgrades_button.set_pressed_no_signal(true); message_label.text = "Currently in Combat\nUpgrades Disabled"
		message_panel.visible = true
	else:
		match current_index:
			Kind.SPELLS:
				if settings.world_settings.game_mode_settings.has_flag(GameModeSettings.SPELL_DECK_BUILDING):
					spell_deck.visible = true; spells_button.grab_focus(); spells_button.set_pressed_no_signal(true); spell_deck.duplicate_book()
				else:
					magic_book.visible = true; spells_button.grab_focus(); spells_button.set_pressed_no_signal(true); magic_book.duplicate_book()
			Kind.WANDS: wand_case.visible = true; wands_button.grab_focus(); wands_button.set_pressed_no_signal(true); wand_case.reload_wand_shelf_items(); wand_case.update_wand_shelf_items(true)
			Kind.ARTIFACTS: artifacts.visible = true; artifacts_button.grab_focus(); artifacts_button.set_pressed_no_signal(true); artifacts.update_list_and_grid()
			Kind.UPGRADES: upgrades.visible = true; upgrades_button.grab_focus(); upgrades_button.set_pressed_no_signal(true); upgrades.update_state(UpgradeSettings.PurchaseError.NONE)
			Kind.NOTES: notes.visible = true; notes_button.grab_focus(); notes_button.set_pressed_no_signal(true); notes.update_notes() 
			Kind.SETTINGS: settings.visible = true; settings_button.grab_focus(); settings_button.set_pressed_no_signal(true); settings.update_controls()
	if not is_opening:
		update_camera_and_menu(settings.tab_container.get_current_tab_control().name)
	tab_opened.emit(current_index)
	
func update_camera_and_menu(settings_tab: String) -> void:
	if not is_quick_menu and current_index == Kind.SETTINGS and settings_tab == "Skin":
		showing_customisation = true
		player.animate_spring_arm(true, 0.2)
		background.set_anchors_preset(Control.PRESET_TOP_WIDE)
		background.size.y = 88
	elif showing_customisation:
		showing_customisation = false
		player.animate_spring_arm(false, 0.2)
		background.set_anchors_preset(Control.PRESET_FULL_RECT)
		background.size = size

func _on_spells_pressed() -> void:
	update_index(Kind.SPELLS)

func _on_wands_pressed() -> void:
	update_index(Kind.WANDS)

func _on_artifacts_pressed() -> void:
	update_index(Kind.ARTIFACTS)
	
func _on_upgrades_pressed() -> void:
	update_index(Kind.UPGRADES)
	
func _on_notes_pressed() -> void:
	update_index(Kind.NOTES)
	
func _on_settings_pressed() -> void:
	update_index(Kind.SETTINGS)

func open(kind: Kind) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	UIAudioPlayer.open()
	visible = true
	is_showing = true
	if kind == Kind.ANY:
		update_index(current_index)
	else:
		is_quick_menu = false
		update_index(kind)
	world_settings.save()

func close() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	UIAudioPlayer.close()
	is_showing = false
	visible = false
	save_changes()
	
func open_game_menu() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	UIAudioPlayer.open()
	visible = true
	is_showing = true
	is_quick_menu = true
	update_index(current_index)
	world_settings.save()
	
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
		
	GlobalData.controller.handle_input(event)
		
	if event is InputEventJoypadButton and not is_quick_menu:
		if event.is_action_pressed("RB"):
			update_index(next_index())
		elif event.is_action_pressed("LB"):
			update_index(prev_index())
			
		if event.is_action_pressed("Back"):
			if spells_button.has_focus() or wands_button.has_focus() or artifacts_button.has_focus() or quit_button.has_focus() or upgrades_button.has_focus() or notes_button.has_focus() or settings_button.has_focus():
				close_menu.emit()
	
func next_index() -> Kind:
	var index := current_index
	if settings.world_settings.game_mode_settings.has_flag(GameModeSettings.SHOP_FOR_UPGRADES):
		index = (current_index + 1) as Kind
	else:
		if current_index + 1 == Kind.UPGRADES:
			index = (current_index + 2) as Kind
		else:
			index = (current_index + 1) as Kind
		
	if index < 1:
		index = (Kind.size() - 1) as Kind
	elif index >= Kind.size():
		index = 1 as Kind
	return index
			
func prev_index() -> Kind:
	var index := current_index
	if settings.world_settings.game_mode_settings.has_flag(GameModeSettings.SHOP_FOR_UPGRADES):
		index = (current_index - 1) as Kind
	else:
		if current_index - 1 == Kind.UPGRADES:
			index = (current_index - 2) as Kind
		else:
			index = (current_index - 1) as Kind
			
	if index < 1:
		index = (Kind.size() - 1) as Kind
	elif index >= Kind.size():
		index = 1 as Kind
	return index


func save_changes() -> void:
	if magic_book.visible:
		if world_settings.is_test_arena:
			magic_book.book.save_absolute_path("res://magic_book.json")
		else:
			magic_book.book.save(world_settings.world_name)
	if spell_deck.visible:
		if not world_settings.is_test_arena:
			spell_deck.book.save(world_settings.world_name)
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
