class_name Globals
extends Node
	
static func behaviour_tick() -> float:
	return 0.01666666666667
	
static func knowledge_tick() -> float:
	return 1.0
	
static func move_tick() -> float:
	return 0.0166667
	
static func enemy_update_radius() -> float:
	return 150.0
	
static func format_number_nearest_place(x: float, max_places: int = 2, show_sign: bool = false) -> String:
	var s := "+" if show_sign else ""
	if float(floori(x)) == x:
		return ("%%%s.0f" % s) % x
	else:
		var i := 0
		while snappedf(x, 0.1 ** i) != x and i < max_places:
			i += 1
		return ("%%.%s%df" % [s, i]) % x

static func invf(v: float) -> float:
	if is_zero_approx(v):
		return 1.0 / 0.0000000001
	else:
		return 1.0 / v
	
static func fract(x: float) -> float:
	if x > 0:
		return x - int(x)
	else:
		return x - (int(x) + 1)
	
static func project_point_onto_sphere(point: Vector3, radius: float, center: Vector3 = Vector3.ZERO) -> Vector3:
	var P := point - center
	var Q := radius / P.length() * P
	return Q + center
	
static func look_at(p: Node3D, dir: Vector3) -> void:
	if dir != Vector3.ZERO:
		var origin := p.position
		var target := p.position + dir * 100000
		if Vector3.UP.cross((target - origin).normalized()).is_zero_approx():
			p.look_at_from_position(origin, p.position + Vector3.UP, Vector3.BACK)
		else:
			p.look_at_from_position(origin, target)
			
static func look_at_point(p: Node3D, target: Vector3) -> void:
	var origin := p.global_position
	if origin != target:
		if Vector3.UP.cross((target - origin).normalized()).is_zero_approx():
			p.look_at_from_position(origin, p.position + Vector3.UP, Vector3.BACK)
		else:
			p.look_at_from_position(origin, target)
			
static func looking_at(p: Node3D, target: Vector3) -> Transform3D:
	var origin := p.position
	var result := T.I
	if Vector3.UP.cross((target - origin).normalized()).is_zero_approx():
		result = p.global_transform.looking_at(origin + Vector3.UP, Vector3.BACK)
	else:
		result = p.global_transform.looking_at(target)
	return result

static func form_arc_in_circle(s: Vector3, e: Vector3, h: float, rng: RandomNumberGenerator = null) -> Segment:
	var a := s.x
	var b := s.z
	var c := e.x
	var d := e.z
	
	var p := Vector3(0.5*(c+a) + sqrt(3.0)/2.0 * (d-b), h, 0.5*(d+b) - sqrt(3.0)/2.0 * (c-a))
	var q := Vector3(0.5*(c+a) - sqrt(3.0)/2.0 * (d-b), h, 0.5*(d+b) + sqrt(3.0)/2.0 * (c-a))
	var m: Vector3
	if rng == null:
		m = p if randf() < 0.5 else q
	else:
		m = p if rng.randf() < 0.5 else q
		
	return Segment.quad(s, e, m)

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
	
static func encode_v3(v: Vector3) -> String:
	return "%.v" % v
	
static var regex := RegEx.create_from_string("^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)?$")
static func is_base64(s: String) -> bool:
	return regex.search(s) != null
	
static func dampen(source: float, target: float, rate: float, delta: float) -> float:
	return lerpf(source, target, 1 - pow(rate, delta))
	
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

func get_date_time_string(timestamp: int) -> String:
	var dict := Time.get_datetime_dict_from_unix_time(timestamp)
	var month := ""
	match dict.month:
		1: month = "January"
		2: month = "February"
		3: month = "March"
		4: month = "April"
		5: month = "May"
		6: month = "June"
		7: month = "July"
		8: month = "August"
		9: month = "September"
		10: month = "October"
		11: month = "November"
		12: month = "December"
	return "%d %s %d (%02d:%02d)" % [dict.day, month, dict.year, dict.hour, dict.minute]

static func save_credits() -> void:
	if not FileAccess.file_exists("user://credits/license/godotengine.txt"):
		var dir := DirAccess.open("user://")
		if not dir.dir_exists("credits"):
			dir.make_dir("credits/")
			dir.make_dir("credits/license")
		var file := FileAccess.open("user://credits/license/godotengine.txt", FileAccess.WRITE)
		file.store_string(Engine.get_license_text())
		file.close()
		var license_info := Engine.get_license_info()
		for license_name: String in license_info:
			file = FileAccess.open("user://credits/license/%s.txt" % license_name, FileAccess.WRITE)
			file.store_string(license_info[license_name] as String)
			file.close()
			
		file = FileAccess.open("user://credits/copyright.txt", FileAccess.WRITE)
		var copyright_info := Engine.get_copyright_info()
		for info in copyright_info:
			file.store_string((info["name"] as String) + "\n")
			var parts := info["parts"] as Array
			for part: Dictionary in parts:
				file.store_string("Files: ")
				for f: String in part["files"]:
					file.store_string(f + "\n")
				file.store_string("Copyright: ")
				for f: String in part["copyright"]:
					file.store_string(f + "\n")
				file.store_string("License: " + (part["license"] as String) + "\n\n")
			file.store_string("\n")
		file.flush()
		file.close()
			

class Ref extends RefCounted:
	var storage: Variant = null
	var data: Variant
	
	func _init(value: Variant) -> void:
		data = value
		storage = value
		
enum Layer {
	WORLD    = 1 << 0, 
	PLAYER   = 1 << 1,
	ENEMY    = 1 << 2,
	FIRE     = 1 << 3,
	ROCK     = 1 << 4,
	WATER    = 1 << 5,
	AIR      = 1 << 6,
	ICE      = 1 << 7,
	ELECTRIC = 1 << 8,
	OBJECT   = 1 << 9,
	ITEM     = 1 << 10,
}

static func particle_system_lifetime(p: GPUParticles3D) -> float:
	return p.lifetime * (1.0 + 1.0 - p.explosiveness) + 0.1

var game_settings: GameSettings = null
var controller: Controller = null
var magic_book: MagicBook = null
var user_magic_book: MagicBook = null
var nav: GDNavigator = null
var is_debug: bool = true

const encoded_dryness_noise = "DwAJAAAAAAAAQBMAAACAPxMAbxKDOggAAAAAAD8AAAAAAA=="
const encoded_temperature_noise = "DQAGAAAAAAAAQBMAAACAPxMAbxKDOggAAAAAAD8AAAAAAA=="

# Near spread
#const encoded_x_noise = "DQABAAAAAAAAQBMAzczMPRMACtcjPAgAAAAAAD8AAAAAAA=="
#const encoded_y_noise = "EgACAAAAAAAAABAACtejPA0AAwAAAAAAAEATAM3MzD0TAArXIzwIAAAAAIA+AAAAAAAAAADIwgAAAAA/AAAAAAA="

# Mid spread
const encoded_x_noise = "DQAEAAAAAABAQBMAmpmZPRMAbxIDOwgAAAAAAD8AAACAPw=="
const encoded_y_noise = "EAAAAEA/DwACAAAAAACAPxMAmpmZPRMAbxIDOwgAAAAAAD8AAAAAAAAAACBB"

# Far spread
#const encoded_x_noise = "DQADAAAAAAAAQBMAzczMPRMAbxKDOggAAAAAAAAAAAAAAA=="
#const encoded_y_noise = "EgACAAAAAAAAABAACtcjPA0ABAAAAOxRyEATAM3MzD0TAG8SgzoIAAAAAIA+AAAAAAAAAADIwgAAAAA/AAAAAAA="

func _ready() -> void:
	is_debug = false # OS.is_debug_build()
	
	nav = GDNavigator.new()
	
	game_settings = GameSettings.new()
	game_settings.read()
	
	controller = Controller.new()
	
	var upgrade_settings := UpgradeSettings.new()
	upgrade_settings.reset_all_stats_to_max_values()
	
	magic_book = MagicBook.new()
	magic_book.settings = WorldSettings.new(get_viewport())
	magic_book.settings.upgrade_settings = upgrade_settings
	magic_book.read_absolute_path("res://magic_book.json")
	magic_book.rebuild_spell_chains()
	
	user_magic_book = MagicBook.new()
	user_magic_book.settings = WorldSettings.new(get_viewport())
	user_magic_book.settings.upgrade_settings = upgrade_settings
	user_magic_book.read_absolute_path("user://universal_magic_book.json")
	user_magic_book.rebuild_spell_chains()
	
	#if user_magic_book.spells.is_empty():
		#for spell in magic_book.spells:
			#user_magic_book.add(spell)
