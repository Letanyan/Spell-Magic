class_name WorldSettings

var world_name: String
var player_position: Vector3
var player_keys: int
var player_health: float
var player_mana: float
var last_save_time: float
var sed: int
var enemies_killed := {} ## [World.Enemy]int
var marked_entities := {} ## [Vector2i][]String
var is_paused: bool
var day_of_the_year: int
var time_of_day: float
var is_test_arena: bool = false
var is_level_editor: bool = false
var is_editing_level: bool = false
var is_shared_online: int = -1
var is_my_level: bool = false
var online_vote: int = 0
var world_generation_version: int = -1
var sea_level: float = 0.0
var world_radius: float = 10000.0
var world_level: int = 1
var difficulty_level: int = 2

var hud_settings: HUDSettings
var camera_settings: CameraSettings
var upgrade_settings: UpgradeSettings
var game_mode_settings: GameModeSettings
var graphics_settings: GraphicsSettings
var audio_settings: AudioSettings
var customisation_settings: CustomisationSettings

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
	customisation_settings = CustomisationSettings.new()

var temp_pos := Vector3.ZERO
func save_dict() -> Dictionary:
	return {
		"name": world_name, "player": {
			"position": player_position, "keys": player_keys,
			"health": player_health, "mana": player_mana,
		}, 
		"seed": sed,
		"enemies_killed": enemies_killed, "marked_entities": marked_entities, "day_of_the_year": day_of_the_year,
		"time_of_day": time_of_day, "is_test_arena": is_test_arena, "last_save_time": last_save_time,
		"world_generation_version": world_generation_version, "sea_level": sea_level, "world_radius": world_radius,
		"difficulty_level": difficulty_level, "is_level_editor": is_level_editor, "is_shared_online": is_shared_online,
		"online_vote": online_vote, "is_my_level": is_my_level,
		
		"upgrade_settings": upgrade_settings.save_dict(),
		"hud_settings": hud_settings.save_dict(),
		"camera_settings": camera_settings.save_dict(),
		"game_mode_settings": game_mode_settings.save_dict(),
		"graphics_settings": graphics_settings.save_dict(),
		"audio_settings": audio_settings.save_dict(),
		"customisation_settings": customisation_settings.save_dict(),
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
	var player := data.get("player", {}) as Dictionary
	player_position = player.get("position", Vector3.ZERO)
	#player_position = Vector3(randf() * 5000, 0, randf() * 5000)
	player_keys = player.get("keys", 0)
	player_health = player.get("health", 1000.0)
	player_mana = player.get("mana", 1000.0)
	last_save_time = data.get("last_save_time", 0.0)
	sed = data.get("seed", 0)
	enemies_killed = data.get("enemies_killed", {})
	marked_entities = data.get("marked_entities", {})
	is_paused = false
	day_of_the_year = data.get("day_of_the_year", 1)
	time_of_day = data.get("time_of_day", 12.0)
	is_test_arena = data.get("is_test_arena", false)
	is_level_editor = data.get("is_level_editor", false)
	is_shared_online = data.get("is_shared_online", -1)
	world_generation_version = data.get("world_generation_version", -1) 
	sea_level = data.get("sea_level", 0.0)
	world_radius = data.get("world_radius", 10000.0)
	difficulty_level = data.get("difficulty_level", 2)
	
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
	
	customisation_settings = CustomisationSettings.new()
	customisation_settings.load_dict(data.get("customisation_settings", {}) as Dictionary)

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
	for kind: World.Enemy in World.Enemy.values():
		var number := enemies_killed.get(kind, 0) as int
		if kind == World.Enemy.NONE:
			continue
		var desc := Globals.format_enemy_kind(kind)
		result += "[cell border=white][b]%s[/b][/cell][cell border=white]%d[/cell]\n" % [desc, number]
	result += "[/table]"
	return result

func max_keys() -> int:
	match world_generation_version:
		1: return 9
		
		# These should match the latest version
		-1: return 9
		_: return 9 
