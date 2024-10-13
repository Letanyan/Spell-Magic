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


var is_showing: bool = false
var world_settings: WorldSettings

signal close_menu

func setup(book: MagicBook, case: WandCase, artifaces: Artifacts, _world_settings: WorldSettings) -> void:
	magic_book.book = book
	wand_case.book = book
	wand_case.case = case
	artifacts.artifacts = artifaces
	upgrades.settings = _world_settings
	settings.world_settings = _world_settings
	world_settings = _world_settings
	
	settings.exit_game.connect(func() -> void: get_tree().quit())
	settings.save_game.connect(func() -> void: save_changes())
	settings.main_menu.connect(func() -> void: SceneHandler.load_new_scene("res://Worlds/MainMenu/MainMenuWorld.tscn", "fade_to_black"))

func _ready() -> void:
	SignalBus.pick_up_world_item_artifact.connect(func(a: Artifact, m: String) -> void: artifacts.update_list_and_grid())
	SignalBus.pick_up_world_item_spell.connect(func(s: Spell, m: String) -> void: magic_book.add_spell(s))
	SignalBus.pick_up_world_item_coin.connect(func(c: int, m: String) -> void: upgrades.update_state(UpgradeSettings.PurchaseError.NONE))

func update_index(index: int) -> void:
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
	match current_index:
		0: magic_book.visible = true; # spells_button.grab_focus()
		1: wand_case.visible = true; # wands_button.grab_focus()
		2: artifacts.visible = true; # artifacts_button.grab_focus()
		3: upgrades.visible = true; # upgrades_button.grab_focus()
		4: settings.visible = true; # settings_button.grab_focus()
	spells_button.set_pressed_no_signal(magic_book.visible)
	wands_button.set_pressed_no_signal(wand_case.visible)
	artifacts_button.set_pressed_no_signal(artifacts.visible)
	upgrades_button.set_pressed_no_signal(upgrades.visible)
	settings_button.set_pressed_no_signal(settings.visible)

func _on_spells_pressed() -> void:
	update_index(0)

func _on_wands_pressed() -> void:
	wand_case.update_wand_shelf_items(true)
	update_index(1)

func _on_artifacts_pressed() -> void:
	update_index(2)
	
func _on_upgrades_pressed() -> void:
	update_index(3)
	
func _on_settings_pressed() -> void:
	update_index(4)

func open(kind: Kind) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true
	is_showing = true
	if magic_book.visible and kind == Kind.ANY:
		magic_book.duplicate_book()
	match kind:
		Kind.SPELLS:
			magic_book.duplicate_book()
			_on_spells_pressed()
		Kind.WANDS:
			wand_case.reload_wand_shelf_items()
			_on_wands_pressed()
		Kind.ARTIFACTS:
			artifacts.update_list_and_grid()
			_on_artifacts_pressed()
		Kind.UPGRADES:
			_on_upgrades_pressed()
		Kind.SETTINGS:
			settings.update_controls()
			_on_settings_pressed()
	world_settings.save()

func close() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	is_showing = false
	visible = false
	save_changes()
	
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
		
	if event is InputEventJoypadButton:
		if event.is_action_pressed("RT"):
			update_index(current_index + 1)
		elif event.is_action_pressed("LT"):
			update_index(current_index - 1)
			
		if event.is_action_pressed("Back"):
			if not (spells_button.has_focus() or wands_button.has_focus() or artifacts_button.has_focus() or quit_button.has_focus() or upgrades_button.has_focus() or settings_button.has_focus()):
				quit_button.grab_focus()
			else:
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
	world_settings.save()


func _on_quit_pressed() -> void:
	close_menu.emit()
