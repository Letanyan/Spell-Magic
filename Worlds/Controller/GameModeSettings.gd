class_name GameModeSettings

enum GameMode { PERMADEATH, RESPAWN, SANDBOX }

const RESPAWN_WITH_SPELLS_AND_WANDS: int = 1 << 0
const RESPAWN_WITH_UPGRADES: int = 1 << 1
const RESPAWN_WITH_ARTIFACTS: int = 1 << 2

var mode: GameMode 
var flags: int = 0

func _init(game_mode: GameMode = GameMode.RESPAWN, flagset: int = RESPAWN_WITH_UPGRADES) -> void:
	mode = game_mode
	flags = flagset
	
static func respawn_with_upgrades_only() -> GameModeSettings:
	return GameModeSettings.new(GameMode.RESPAWN, RESPAWN_WITH_UPGRADES)
	
static func permadeath() -> GameModeSettings:
	return GameModeSettings.new(GameMode.PERMADEATH, 0)
	
func save_dict() -> Dictionary:
	return {
		"mode": mode, "flags": flags
	}

func load_dict(dict: Dictionary) -> void:
	mode = dict.get("mode", GameMode.RESPAWN)
	flags = dict.get("flags", RESPAWN_WITH_UPGRADES)
