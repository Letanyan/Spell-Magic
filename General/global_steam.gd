extends Node

var status: int = -1
var status_description: String = ""
var is_on_steam_deck: bool = false
var is_online: bool = false
var is_owned: bool = false
var steam_app_id: int = 480
var steam_id: int = 0
var steam_username: String = ""
var is_enabled: bool = false

enum Achievements {
	ACH_NONE,
	ACH_DESERT_KEY, ACH_FOREST_KEY, ACH_GRASSLAND_KEY, ACH_HFIL_KEY, ACH_JUNGLE_KEY,
	ACH_OTHERWORLD_KEY, ACH_SAVANNAH_KEY, ACH_TAIGA_KEY, ACH_TUNDRA_KEY, ACH_INCREASED_WORLD_LEVEL
}
var achievements := {}

func _ready() -> void:
	initialize_achievments()
	initialize_steam()

func _physics_process(delta: float) -> void:
	Steam.run_callbacks()
	
func initialize_achievments() -> void:
	for key: Achievements in Achievements.values():
		achievements[key] = false
	
func initialize_steam() -> void:
	Steam.user_stats_received.connect(_on_steam_stats_ready, ConnectFlags.CONNECT_ONE_SHOT)
	var initialize_response: Dictionary = Steam.steamInitEx(true)
	status = initialize_response["status"]
	status_description = initialize_response["verbal"]
	if status == 0:
		is_enabled = true
		is_on_steam_deck = Steam.isSteamRunningOnSteamDeck()
		is_online = Steam.loggedOn()
		is_owned = Steam.isSubscribed()
		steam_id = Steam.getSteamID()
		steam_username = Steam.getPersonaName()
		steam_app_id = Steam.current_app_id
		Steam.requestUserStats(steam_id)
	else:
		print("Steam not initialized: %s " % initialize_response)
		
func _on_steam_stats_ready(game: int, result: int, user: int) -> void:
	for key: Achievements in Achievements.values():
		get_achievement(key)
	
func get_achievement(key: Achievements) -> void:
	if not is_enabled or GlobalData.is_demo:
		return
	var this_achievement: Dictionary = Steam.getAchievement(Achievements.keys()[key] as String)
	if this_achievement['ret']:
		if this_achievement['achieved']:
			achievements[key] = true
		else:
			achievements[key] = false
			
func set_achievement(key: Achievements) -> void:
	if not is_enabled or GlobalData.is_demo:
		return
	if not achievements[key]:
		achievements[key] = true
		var skey := Achievements.keys()[key] as String
		Steam.setAchievement(skey)
		Steam.storeStats()
	
func unset_achievement(key: Achievements) -> void:
	if not is_enabled or GlobalData.is_demo:
		return
	if achievements[key]:
		achievements[key] = false
		var skey := Achievements.keys()[key] as String
		Steam.clearAchievement(skey)
		Steam.storeStats()

func achievement_pick_up_key(biome: World.Biome) -> Achievements:
	match biome:
		World.Biome.DESERT: return Achievements.ACH_DESERT_KEY
		World.Biome.FOREST: return Achievements.ACH_FOREST_KEY
		World.Biome.GRASSLAND: return Achievements.ACH_GRASSLAND_KEY
		World.Biome.HFIL: return Achievements.ACH_HFIL_KEY
		World.Biome.JUNGLE: return Achievements.ACH_JUNGLE_KEY
		World.Biome.OTHERWORLD: return Achievements.ACH_OTHERWORLD_KEY
		World.Biome.SAVANNAH: return Achievements.ACH_SAVANNAH_KEY
		World.Biome.TAIGA: return Achievements.ACH_TAIGA_KEY
		World.Biome.TUNDRA: return Achievements.ACH_TUNDRA_KEY
	return Achievements.ACH_NONE

func show_store() -> void:
	if not is_enabled:
		return 
	Steam.activateGameOverlayToStore(3427990)
