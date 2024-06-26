class_name WorldSettings

var world_name: String
var player_position: Vector3
var keys: int
var last_save_time: float
var sed: int
var enemies_killed := {} # [World.Enemy]int
var is_paused: bool
var day_of_the_year: int
var time_of_day: float
var is_test_arena: bool = false

var hud_settings: HUDSettings
var camera_settings: CameraSettings
var upgrade_settings: UpgradeSettings
var game_mode_settings: GameModeSettings
var graphics_settings: GraphicsSettings
var audio_settings: AudioSettings

var viewport: Viewport

func _init(vp: Viewport = null) -> void:
	if vp == null:
		return
	viewport = vp
	hud_settings = HUDSettings.new()
	camera_settings = CameraSettings.new()
	upgrade_settings = UpgradeSettings.new()
	upgrade_settings.reset_all_stats_to_max_values()
	game_mode_settings = GameModeSettings.new()
	graphics_settings = GraphicsSettings.new(viewport)
	audio_settings = AudioSettings.new()

func save_dict() -> Dictionary:
	return {
		"name": world_name, "player": {"position": player_position, "keys": keys}, "seed": sed,
		"enemies_killed": enemies_killed, "day_of_the_year": day_of_the_year,
		"time_of_day": time_of_day, "is_test_arena": is_test_arena, "last_save_time": last_save_time,
		
		"upgrade_settings": upgrade_settings.save_dict(),
		"hud_settings": hud_settings.save_dict(),
		"camera_settings": camera_settings.save_dict(),
		"game_mode_settings": game_mode_settings.save_dict(),
		"graphics_settings": graphics_settings.save_dict(),
		"audio_settings": audio_settings.save_dict()
	}

func save() -> void:
	var dir := DirAccess.open("user://")
	if not dir.dir_exists("worlds"):
		dir.make_dir("worlds")
	if not dir.dir_exists("worlds/%s" % (world_name)):
		dir.make_dir("worlds/%s" % (world_name))
	var file := FileAccess.open("user://worlds/%s/settings.json" % (world_name), FileAccess.WRITE)
	file.store_var(save_dict())

func load_dict(data: Dictionary) -> void:
	world_name = data.get("name", "empty")
	player_position = (data.get("player", {}) as Dictionary).get("position", Vector3.ZERO)
	keys = (data.get("player", {}) as Dictionary).get("keys", 0)
	last_save_time = data.get("last_save_time", 0.0)
	sed = data.get("seed", 0)
	enemies_killed = data.get("enemies_killed", {})
	is_paused = false
	day_of_the_year = data.get("day_of_the_year", 1)
	time_of_day = data.get("time_of_day", 12.0)
	is_test_arena = data.get("is_test_arena", false)
	
	upgrade_settings = UpgradeSettings.new()
	upgrade_settings.load_dict(data.get("upgrade_settings", {}) as Dictionary)
	
	hud_settings = HUDSettings.new()
	hud_settings.load_dict(data.get("hud_settings", {}) as Dictionary)
	
	camera_settings = CameraSettings.new()
	camera_settings.load_dict(data.get("camera_settings", {}) as Dictionary)
	
	game_mode_settings = GameModeSettings.new()
	game_mode_settings.load_dict(data.get("game_mode_settings", {}) as Dictionary)
	
	graphics_settings = GraphicsSettings.new(viewport)
	graphics_settings.load_dict(data.get("graphics_settings", {}) as Dictionary)
	
	audio_settings = AudioSettings.new()
	audio_settings.load_dict(data.get("audio_settings", {}) as Dictionary)

func read(filename: String) -> void:
	var file := FileAccess.open("user://worlds/%s/settings.json" % (filename), FileAccess.READ)
	if file:
		var data := file.get_var() as Dictionary
		load_dict(data)
	else:
		load_dict({})

func enemies_killed_table() -> String:
	var result := "[table=2]\n"
	result += "[cell border=white][b]Enemy[/b][/cell][cell border=white][b]Total Killed[/b][/cell]"
	for kind: String in World.Enemy.keys():
		var number := enemies_killed.get(kind, 0) as int
		if kind == "NONE":
			continue
		result += "[cell border=white][b]%s[/b][/cell][cell border=white]%d[/cell]\n" % [kind, number]
	result += "[/table]"
	return result
