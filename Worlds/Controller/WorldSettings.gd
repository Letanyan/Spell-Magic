class_name WorldSettings

var world_name: String
var player_position: Vector3
var sed: int

const HAS_FIRE := 1 << 0
const HAS_WATER := 1 << 1
const HAS_ROCK := 1 << 2
const HAS_AIR := 1 << 3
const HAS_ICE := 1 << 4
const HAS_ELECTRIC := 1 << 5
const HAS_VOID := 1 << 6
var has_spell_element := 0

const HAS_CHAIN_ON_START := 1 << 0
const HAS_CHAIN_ON_END := 1 << 1
const HAS_CHAIN_ON_HIT := 1 << 2
var has_chain_method := 0

var max_r := 0.1
var max_T := 1.0
var max_N := 1
var max_D := 0.0
var max_P := 1

var max_mana := 100.0
var max_health := 100.0

var max_spells_in_book := 4 

func check_if_has_spell_element(el: Spell.Element) -> bool:
	return has_spell_element & (1 << el) == 1

func check_if_has_chain_method(el: Spell.ChainCastKind) -> bool:
	return has_spell_element & (1 << el) == 1

func save():
	var dir := DirAccess.open("user://")
	if not dir.dir_exists("worlds"):
		dir.make_dir("worlds")
	if not dir.dir_exists("worlds/%s" % (world_name)):
		dir.make_dir("worlds/%s" % (world_name))
	var file = FileAccess.open("user://worlds/%s/settings.json" % (world_name), FileAccess.WRITE)
	file.store_var({
		"name": world_name, "player": {"position": player_position}, "seed": sed,
		"has_spell_element": has_spell_element, "has_chain_method": has_chain_method,
		"max_r": max_r, "max_T": max_T, "max_N": max_N, "max_D": max_D, "max_P": max_P,
		"max_mana": max_mana, "max_health": max_health, "max_spells_in_book": max_spells_in_book
	})

func read(filename: String):
	var file = FileAccess.open("user://worlds/%s/settings.json" % (filename), FileAccess.READ)
	var data = file.get_var()
	world_name = data["name"]
	player_position = data["player"]["position"]
	sed = data["seed"]
	
	has_spell_element = data.get("has_spell_element", 0)
	has_chain_method = data.get("has_chain_method", 0)
	max_r = data.get("max_r", 1)
	max_T = data.get("max_T", 1.0)
	max_N = data.get("max_N", 1)
	max_D = data.get("max_D", 0.0)
	max_P = data.get("max_P", 1.0)
	max_mana = data.get("max_mana", 100.0)
	max_health = data.get("max_health", 100.0)
	max_spells_in_book = data.get("max_spells_in_book", 4)
