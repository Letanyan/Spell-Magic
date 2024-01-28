class_name WorldSettings

var world_name: String
var player_position: Vector3
var sed: int
var enemies_killed := {} # {World.Enemy: int}
var is_paused: bool
var day_of_the_year: int
var time_of_day: float

var hud_settings: HUDSettings
var camera_settings: CameraSettings
var upgrade_settings: UpgradeSettings
var game_mode_settings: GameModeSettings

func _init() -> void:
	hud_settings = HUDSettings.new()
	camera_settings = CameraSettings.new()
	upgrade_settings = UpgradeSettings.new()
	game_mode_settings = GameModeSettings.new()

func save_dict() -> Dictionary:
	return {
		"name": world_name, "player": {"position": player_position}, "seed": sed,
		"enemies_killed": enemies_killed, "day_of_the_year": day_of_the_year,
		"time_of_day": time_of_day,
		
		"upgrade_settings": upgrade_settings.save_dict(),
		"hud_settings": hud_settings.save_dict(),
		"camera_settings": camera_settings.save_dict(),
		"game_mode_settings": game_mode_settings.save_dict(),
	}

func save():
	var dir := DirAccess.open("user://")
	if not dir.dir_exists("worlds"):
		dir.make_dir("worlds")
	if not dir.dir_exists("worlds/%s" % (world_name)):
		dir.make_dir("worlds/%s" % (world_name))
	var file = FileAccess.open("user://worlds/%s/settings.json" % (world_name), FileAccess.WRITE)
	file.store_var(save_dict())

func load_dict(data: Dictionary):
	world_name = data.get("name", "empty")
	player_position = data.get("player", {}).get("position", Vector3.ZERO)
	sed = data.get("seed", 0)
	enemies_killed = data.get("enemies_killed", {})
	is_paused = false
	day_of_the_year = data.get("day_of_the_year", 1)
	time_of_day = data.get("time_of_day", 12.0)
	
	upgrade_settings = UpgradeSettings.new()
	upgrade_settings.load_dict(data.get("upgrade_settings", {}))
	
	hud_settings = HUDSettings.new()
	hud_settings.load_dict(data.get("hud_settings", {}))
	
	camera_settings = CameraSettings.new()
	camera_settings.load_dict(data.get("camera_settings", {}))
	
	game_mode_settings = GameModeSettings.new()
	game_mode_settings.load_dict(data.get("game_mode_settings", {}))

func read(filename: String):
	var file = FileAccess.open("user://worlds/%s/settings.json" % (filename), FileAccess.READ)
	var data = file.get_var()
	load_dict(data)
