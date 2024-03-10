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
	
static func midpoint_tangent1(s: Vector3, e: Vector3) -> Vector3:
	var a := s.x
	var b := s.z
	var c := e.x
	var d := e.z
	
	return Vector3(0.5*(c+a) + sqrt(3.0)/2.0 * (d-b), 0, 0.5*(d+b) - sqrt(3.0)/2.0 * (c-a))

static func midpoint_tangent2(s: Vector3, e: Vector3) -> Vector3:
	var a := s.x
	var b := s.z
	var c := e.x
	var d := e.z
	return Vector3(0.5*(c+a) - sqrt(3.0)/2.0 * (d-b), 0, 0.5*(d+b) + sqrt(3.0)/2.0 * (c-a))

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
	game_settings.read(get_viewport())
	
	controller = Controller.new()
	
	magic_book = MagicBook.new()
	var upgrade_settings = UpgradeSettings.new()
	upgrade_settings.reset_all_stats_to_max_values()
	magic_book.settings = WorldSettings.new(get_viewport())
	magic_book.settings.upgrade_settings = upgrade_settings
	
	magic_book.read_absolute_path("res://magic_book.json")
	magic_book.rebuild_spell_chains()
