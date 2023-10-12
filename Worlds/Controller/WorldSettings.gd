class_name WorldSettings

var world_name: String
var player_position: Vector3
var sed: int
var enemies_killed := {} # {World.Enemy: int}

var hud_settings: HUDSettings
var camera_settings: CameraSettings
var upgrade_settings: UpgradeSettings
var game_mode_settings: GameModeSettings

func save():
	var dir := DirAccess.open("user://")
	if not dir.dir_exists("worlds"):
		dir.make_dir("worlds")
	if not dir.dir_exists("worlds/%s" % (world_name)):
		dir.make_dir("worlds/%s" % (world_name))
	var file = FileAccess.open("user://worlds/%s/settings.json" % (world_name), FileAccess.WRITE)
	file.store_var({
		"name": world_name, "player": {"position": player_position}, "seed": sed,
		"enemies_killed": enemies_killed,
		
		"upgrade_settings": upgrade_settings.save_dict(),
		"hud_settings": hud_settings.save_dict(),
		"camera_settings": camera_settings.save_dict(),
		"game_mode_settings": game_mode_settings.save_dict(),
	})

func read(filename: String):
	var file = FileAccess.open("user://worlds/%s/settings.json" % (filename), FileAccess.READ)
	var data = file.get_var()
	world_name = data["name"]
	player_position = data["player"]["position"]
	sed = data["seed"]
	enemies_killed = data.get("enemies_killed", {})
	
	upgrade_settings = UpgradeSettings.new()
	upgrade_settings.load_dict(data.get("upgrade_settings", {}))
	
	hud_settings = HUDSettings.new()
	hud_settings.load_dict(data.get("hud_settings", {}))
	
	camera_settings = CameraSettings.new()
	camera_settings.load_dict(data.get("camera_settings", {}))
	
	game_mode_settings = GameModeSettings.new()
	game_mode_settings.load_dict(data.get("game_mode_settings", {}))
