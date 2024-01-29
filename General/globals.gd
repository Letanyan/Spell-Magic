class_name Globals
extends Node

static func sea_level() -> float:
	return 400.0
	
static func behaviour_tick() -> float:
	return 0.5
	
static func knowledge_tick() -> float:
	return 1.0

static func invf(v: float) -> float:
	if is_zero_approx(v):
		return 1.0 / 0.0000000001
	else:
		return 1.0 / v
		
static func rand_v3_abs(x: float, y: float, z: float) -> Vector3:
	return Vector3(x * randf(), y * randf(), z * randf())

class Ref extends RefCounted:
	var data
	
	func _init(value) -> void:
		data = value

static func particle_system_lifetime(p: GPUParticles3D) -> float:
	return p.lifetime * (1.0 + 1.0 - p.explosiveness) + 0.1

var game_settings: GameSettings = null
var controller: Controller = null
var magic_book: MagicBook = null

func _ready() -> void:
	game_settings = GameSettings.new()
	game_settings.read()
	
	controller = Controller.new()
	
	magic_book = MagicBook.new()
	var upgrade_settings = UpgradeSettings.new()
	upgrade_settings.max_health = UpgradeSettings.LIMIT_HEALTH
	upgrade_settings.max_mana = UpgradeSettings.LIMIT_MANA
	upgrade_settings.max_D = UpgradeSettings.LIMIT_D
	upgrade_settings.max_N = UpgradeSettings.LIMIT_N
	upgrade_settings.max_P = UpgradeSettings.LIMIT_P
	upgrade_settings.max_r = UpgradeSettings.LIMIT_r
	upgrade_settings.max_spells_in_book = UpgradeSettings.LIMIT_SPELLS_IN_BOOK
	upgrade_settings.max_v = UpgradeSettings.LIMIT_v
	upgrade_settings.max_T = UpgradeSettings.LIMIT_T
	magic_book.settings = WorldSettings.new()
	magic_book.settings.upgrade_settings = upgrade_settings
	
	magic_book.read_absolute_path("res://magic_book.json")
	magic_book.rebuild_spell_chains()
	print(magic_book.spells)
