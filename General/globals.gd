class_name Globals
extends Node

static func sea_level() -> float:
	return 400.0
	
static func behaviour_tick() -> float:
	return 0.166667
	
static func knowledge_tick() -> float:
	return 1.0
	
static func format_number_nearest_place(x: float, max_places: int = 2) -> String:
	if float(floori(x)) == x:
		return "%.0f" % x
	else:
		var i := 0
		while snappedf(x, 0.1 ** i) != x and i < max_places:
			i += 1
		return ("%%.%df" % i) % x

static func invf(v: float) -> float:
	if is_zero_approx(v):
		return 1.0 / 0.0000000001
	else:
		return 1.0 / v
		
static func rand_v3_abs(x: float, y: float, z: float) -> Vector3:
	return Vector3(x * randf(), y * randf(), z * randf())
	
static func rand_point_in_circle(r: float, h: float) -> Vector3:
	var p : Vector3 = Vector3(randf() * 2.0 - 1.0, 0, randf() * 2.0 - 1.0).normalized() * r + Vector3(0, h, 0)
	return p 

static func form_arc_in_circle(s: Vector3, e: Vector3, h: float) -> PathStyle.Segment:
	var a := s.x
	var b := s.z
	var c := e.x
	var d := e.z
	
	var p := Vector3(0.5*(c+a) + sqrt(3.0)/2.0 * (d-b), h, 0.5*(d+b) - sqrt(3.0)/2.0 * (c-a))
	var q := Vector3(0.5*(c+a) - sqrt(3.0)/2.0 * (d-b), h, 0.5*(d+b) + sqrt(3.0)/2.0 * (c-a))
	var m: Vector3
	if randf() < 0.5:
		m = p
	else:
		m = q
		
	return PathStyle.Segment.quad(s, e, m)

static func midpoint_tangent1(s: Vector3, e: Vector3) -> Vector3:
	var a := s.x
	var b := s.z
	var c := e.x
	var d := e.z
	
	return Vector3(0.5*(c+a) + sqrt(3.0)/2.0 * (d-b), (s.y + e.y) / 2.0, 0.5*(d+b) - sqrt(3.0)/2.0 * (c-a))

static func midpoint_tangent2(s: Vector3, e: Vector3) -> Vector3:
	var a := s.x
	var b := s.z
	var c := e.x
	var d := e.z
	return Vector3(0.5*(c+a) - sqrt(3.0)/2.0 * (d-b), (s.y + e.y) / 2.0, 0.5*(d+b) + sqrt(3.0)/2.0 * (c-a))
	
static func replace_ranges_in_string(source: String, ranges: Array, what: String) -> String:
	var result := ""
	var source_offset := 0
	var largest_ending_index := 0
	var shift_amount := 0
	var i := 0
	for found: Vector2i in ranges:
		if found.x != source_offset:
			var to_append := source.substr(source_offset, found.x - source_offset)
			result += to_append
			source_offset += to_append.length()
		result += what
		source_offset += found.y
		if found.y > largest_ending_index:
			largest_ending_index = found.y
		ranges[i] = Vector2i(found.x + shift_amount, what.length())
		shift_amount += what.length() - found.y
		i += 1
			
	if largest_ending_index < source.length():
		result += source.substr(source_offset, source.length() - source_offset)
	return result

class Ref extends RefCounted:
	var data: Variant
	
	func _init(value: Variant) -> void:
		data = value

static func particle_system_lifetime(p: GPUParticles3D) -> float:
	return p.lifetime * (1.0 + 1.0 - p.explosiveness) + 0.1

var game_settings: GameSettings = null
var controller: Controller = null
var magic_book: MagicBook = null
var nav: GDNavigator = null

func _ready() -> void:
	nav = GDNavigator.new()
	
	game_settings = GameSettings.new()
	game_settings.read()
	
	controller = Controller.new()
	
	magic_book = MagicBook.new()
	var upgrade_settings := UpgradeSettings.new()
	upgrade_settings.reset_all_stats_to_max_values()
	magic_book.settings = WorldSettings.new(get_viewport())
	magic_book.settings.upgrade_settings = upgrade_settings
	
	magic_book.read_absolute_path("res://magic_book.json")
	magic_book.rebuild_spell_chains()
