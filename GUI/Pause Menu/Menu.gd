class_name Menu
extends Control

enum Kind { ANY, SPELLS, WANDS, ARTIFACTS, UPGRADES, SETTINGS }

@onready var magic_book: MagicBookGUI = $MagicBook
@onready var wand_case: WandCaseGUI = $WandCase
@onready var artifacts: ArtifactsGUI = $Artifacts
@onready var upgrades: UpgradesGUI = $Upgrades
@onready var settings: SettingsGUI = $Settings
var current_index := 0

var is_showing: bool = false
var world_settings: WorldSettings

func setup(book: MagicBook, case: WandCase, artifaces: Artifacts, _world_settings: WorldSettings):
	magic_book.book = book
	wand_case.book = book
	wand_case.case = case
	artifacts.artifacts = artifaces
	upgrades.settings = _world_settings
	settings.world_settings = _world_settings
	world_settings = _world_settings

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func update_index(index):
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
		0: magic_book.visible = true
		1: wand_case.visible = true
		2: artifacts.visible = true
		3: upgrades.visible = true
		4: settings.visible = true

func _on_spells_pressed():
	update_index(0)

func _on_wands_pressed():
	wand_case.update_wand_shelf_items(true)
	update_index(1)

func _on_artifacts_pressed() -> void:
	update_index(2)
	
func _on_upgrades_pressed() -> void:
	update_index(3)
	
func _on_settings_pressed() -> void:
	update_index(4)

func open(kind: Kind):
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

func close():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	is_showing = false
	visible = false
	save_changes()
	
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	
	if event.is_action_pressed("RB"):
		update_index(current_index + 1)
	elif event.is_action_pressed("LB"):
		update_index(current_index - 1)

func save_changes():
	if magic_book.visible:
		if world_settings.world_name == "empty":
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
	get_tree().change_scene_to_file("res://GUI/Main Menu/MainMenu.tscn")

