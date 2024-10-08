class_name GameSettings

enum ReadyState { NOT, IN, IS }
enum NotesUnlockSettings { IN_GAME, SHOW_ALL, HIDE_ALL }

var last_world: String
var default_world_settings: WorldSettings
var user_functions: Dictionary
var user_functions_text: String
var unlocked_notes: Dictionary
var notes_unlock_settings: NotesUnlockSettings

func save() -> void:
	var file := FileAccess.open("user://settings.json", FileAccess.WRITE)
	
	file.store_var({
		"last_world": last_world, "user_functions_text": user_functions_text,
		"default_world_settings": default_world_settings.save_dict(),
		"unlocked_notes": unlocked_notes, "notes_unlock_settings": notes_unlock_settings,
	})

func read() -> void:
	var file := FileAccess.open("user://settings.json", FileAccess.READ)
	var data: Dictionary
	if file != null:
		data = file.get_var()
	else:
		data = {}
	last_world = data.get("last_world", "")
	
	default_world_settings = WorldSettings.new(null)
	default_world_settings.load_dict(data.get("default_world_settings", {}) as Dictionary)
	
	unlocked_notes = data.get("unlocked_notes", {}) as Dictionary
	notes_unlock_settings = data.get("notes_unlock_settings", NotesUnlockSettings.IN_GAME) as NotesUnlockSettings
	
	build_user_functions(data.get("user_functions_text", "") as String)
	
func build_user_functions(text: String) -> void:
	user_functions_text = text
	var lines := text.split("\n")
	user_functions.clear()
	for line in lines:
		build_user_function(line)
	
func build_user_function(text: String) -> void:
	if not text.contains("="):
		return
		
	var parts := text.split("=", false, 2)
	if parts.size() != 2:
		return
		
	var decl := parts[0]
	var defn := parts[1]
	
	var args := decl.split(" ", false)
	var spell_name := ""
	var spell_args := PackedStringArray([])
	if args.size() >= 1:
		spell_name = args[0]
		for i in range(1, args.size()):
			spell_args.append(args[i])
			
	GlobalData.game_settings.set_user_function(spell_name, spell_args, defn)
	
func set_user_function(fn: String, args: PackedStringArray, expr: String) -> void:
	var gdexpr := Expr.new(expr)
	args.reverse()
	user_functions[fn] = {"args": args, "expr": gdexpr.back, "defn": expr}

func remove_user_function(fn: String) -> void:
	user_functions.erase(fn)

static func get_world_names() -> Array:
	var dir := DirAccess.open("user://")
	if not dir.dir_exists("worlds"):
		dir.make_dir("worlds")
	dir.change_dir("worlds")
	var worlds := dir.get_directories()
	var times: Array[Array] = []
	for world in worlds:
		var settings := WorldSettings.new(null)
		settings.read(world)
		if not settings.is_test_arena:
			times.append([world, settings.last_save_time])
		
	times.sort_custom(func(a: Array[Variant], b: Array[Variant]) -> bool: return a[1] > b[1])
	return times

static var notes := {
	"func rot_x, rot_y, rot_z": "[t]rot_*[/t] can be used to rotate a point around a vector. The parameters of the functions are as follows, [t]rot_*(a, vx, vy, vz, px, py, pz)[/t], where [t]a[/t] defines the angle around the vector [t](vx, vy, vz)[/t] which the point [t](px, py, pz)[/t] is rotated.",
	"func lerp": "[t]lerp[/t] which is short for interpolate moves between 2 values. [t]lerp(t, A, B)[/t] is defined as [t]A+t*(B-A)[/t].",
	"func segment2, segment3, segment4, segment5": "",
	"func unit_x, unit_y, unit_z": "",
	"func dot2, dot3": "",
	"func cross_x, cross_y, cross_z": "",
	"func proj_x, proj_y, proj_z": "",
	"func quad": "",
	"func cubic": "",
	"func clamp": "",
	"func if": "",
	"func cube": "",
	"func cbrt": "",
	"func sqr": "",
	"func sqrt": "",
	"func abs": "",
	"func logN": "",
	"func log10": "",
	"func pow": "",
	"func min": "",
	"func max": "",
	"func not": "",
	"func eq": "",
	"func neq": "",
	"func lt": "",
	"func lte": "",
	"func gt": "",
	"func gte": "",
	"func ceil": "",
	"func round": "",
	"func floor": "",
	"func div": "",
	"func mod": "",
	"func inv": "",
	"func sin": "",
	"func cos": "",
	"func tan": "",
	"func asin": "",
	"func acos": "",
	"func atan": "",
	"func sinh": "",
	"func cosh": "",
	"func tanh": "",
	"func atan2": "",
	
	"artifact pattern": "",
	"artifact event": "",
	"artifact effect": "",
	"artifact element": "",
	"artifact connections": "",
	
	"spell x, y, z": "",
	"spell D": "",
	"spell T": "",
	
	"variable u, v, w": "",
	"variable U, V, W": "",
	"variable ru, rv, rw": "",
	"variable rU, rV, rW": "",
}
