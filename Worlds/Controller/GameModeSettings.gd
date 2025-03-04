class_name GameModeSettings

enum GameMode { PERMADEATH, RESPAWN, SANDBOX }

const RESPAWN_WITH_SPELLS_AND_WANDS: int = 1 << 0
const RESPAWN_WITH_UPGRADES: int = 1 << 1
const RESPAWN_WITH_ARTIFACTS: int = 1 << 2
const DISALLOW_SPELL_EDITING: int = 1 << 3
const RESPAWN_WITH_COINS: int = 1 << 4
const SHOP_FOR_UPGRADES: int = 1 << 5

var mode: GameMode 
var flags: int = 0

func _init(game_mode: GameMode = GameMode.RESPAWN, flagset: int = RESPAWN_WITH_UPGRADES) -> void:
	mode = game_mode
	flags = flagset
	
static func respawn_with_upgrades_only() -> GameModeSettings:
	return GameModeSettings.new(GameMode.RESPAWN, RESPAWN_WITH_UPGRADES)
	
static func permadeath() -> GameModeSettings:
	return GameModeSettings.new(GameMode.PERMADEATH, 0)
	
static func normal_mode() -> GameModeSettings:
	return GameModeSettings.new(GameMode.RESPAWN, RESPAWN_WITH_UPGRADES | RESPAWN_WITH_SPELLS_AND_WANDS | RESPAWN_WITH_ARTIFACTS)
	
static func hardcore_mode() -> GameModeSettings:
	return GameModeSettings.new(GameMode.PERMADEATH, DISALLOW_SPELL_EDITING)
	
func has_flag(flag: int) -> bool:
	return flags & flag != 0
	
func game_mode_description() -> String:
	match mode:
		GameMode.PERMADEATH: return "Permadeath"
		GameMode.RESPAWN: return "Respawn"
		GameMode.SANDBOX: return "Sandbox"
	return ""
	
func flags_description() -> PackedStringArray:
	var result := PackedStringArray([])
	if flags & RESPAWN_WITH_ARTIFACTS != 0:
		result.append("Respawn with Artifacts")
	if flags & RESPAWN_WITH_SPELLS_AND_WANDS != 0:
		result.append("Respawn with Spells and Wands")
	if flags & RESPAWN_WITH_UPGRADES != 0:
		result.append("Respawn with Upgrades")
	if flags & DISALLOW_SPELL_EDITING != 0:
		result.append("Disallow Spell Editing")
	if flags & RESPAWN_WITH_COINS != 0:
		result.append("Respawn with Coins")
	if flags & SHOP_FOR_UPGRADES != 0:
		result.append("Shop for Upgrades")
	return result
	
func save_dict() -> Dictionary:
	return {
		"mode": mode, "flags": flags
	}

func load_dict(dict: Dictionary) -> void:
	mode = dict.get("mode", GameMode.RESPAWN)
	flags = dict.get("flags", RESPAWN_WITH_UPGRADES)
