class_name GameSettings

enum ReadyState { NOT, IN, IS }

var last_world: String
var default_world_settings: WorldSettings
var user_functions: Dictionary
var user_functions_text: String

func save() -> void:
	var file := FileAccess.open("user://settings.json", FileAccess.WRITE)
	
	file.store_var({
		"last_world": last_world, "user_functions_text": user_functions_text,
		"default_world_settings": default_world_settings.save_dict()
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
