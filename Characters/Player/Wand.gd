class_name Wand

enum Kind { NONE, FIRE, PICK, FIRE_PICKED, FIRE_HOLD, MOD  }

class Option:
	var kind: Kind
	var spell: Array
	var spell_index: int
	var start_hold: float
	
	func _init(_kind: Kind = Kind.NONE, _spell: Array = []):
		kind = _kind
		spell = _spell
		spell_index = spell.size() - 1
		start_hold = 0.0
		
	func save_dict():
		return {"kind": kind, "spell": spell}
		
	func load_dict(dict: Dictionary):
		kind = dict["kind"]
		var s = dict["spell"] 
		if s is String:
			spell = [s]
		else:
			spell = s as Array[String]
		spell_index = spell.size() - 1
		start_hold = 0.0
		
	func next_spell() -> String:
		spell_index += 1
		if spell_index >= spell.size():
			spell_index = 0
		return spell[spell_index]

const basic_keys = [
	"LT",
	"LB",
	"RT",
	"RB",
	"S",
	"W",
	"E",
	"N",
	"UP",
	"DOWN",
	"LEFT",
	"RIGHT",
	"L3",
	"R3",
	"move_left",
	"move_right",
	"move_forward",
	"move_back"
]

const pc_keys = {
	"LT": "Shift",
	"LB": "Ctrl",
	"RT": "Left Mouse",
	"RB": "Right Mouse",
	"S": "Space",
	"W": "R",
	"E": "E",
	"N": "Q",
	"UP": "Up",
	"DOWN": "Down",
	"LEFT": "Left",
	"RIGHT": "Right",
	"L3": "Z",
	"R3": "Alt",
	"move_forward": "W",
	"move_left": "A",
	"move_back": "S",
	"move_right": "D",
}

const ps_keys = {
	"LT": "L2",
	"LB": "L1",
	"RT": "R2",
	"RB": "R1",
	"S": "Cross",
	"W": "Square",
	"E": "Circle",
	"N": "Triangle",
	"UP": "Up",
	"DOWN": "Down",
	"LEFT": "Left",
	"RIGHT": "Right",
	"L3": "L3",
	"R3": "R3",
	"move_forward": "Move Forward",
	"move_left": "Move Left",
	"move_back": "Move Back",
	"move_right": "Move Right",
}

var name: String
var mods: Dictionary
var keys: Dictionary
var picked: String
var ignore_cooldown: bool

var current_actions: Dictionary

signal spell_on_cooldown

func _init():
	name = ""
	mods = {}
	keys = {}
	picked = ""
	ignore_cooldown = false
	current_actions = {}
	build_keys()

func build_keys():
	for b in basic_keys:
		if not keys.has([b]):
			keys[[b]] = Option.new()
	for m in mods:
		for key in keys:
			if key.find(m) == -1:
				var nKey = key.duplicate()
				nKey.insert(0, m)
				if not keys.has(nKey):
					keys[nKey] = Option.new()

static func basic() -> Wand:
	var result := Wand.new()
	result.build_keys()
	return result
	

func remove_mod(mod: String):
	if mods.has(mod):
		mods.erase(mod)
		var to_remove := []
		for key in keys:
			if key.size() > 1 and key.find(mod) != -1:
				to_remove.append(key)
		for k in to_remove:
			keys.erase(k)
	
func add_mod(mod: String):
	mods[mod] = true
	build_keys()
	
func find_spell(key: Array, book: MagicBook) -> Spell:
	var opt: Option = keys[key]
	if opt.kind == Kind.FIRE_PICKED:
		for s in book.spells:
			if s.name == picked:
				return s
		return null
	elif opt.kind == Kind.MOD or opt.kind == Kind.NONE:
		return null
	var opt_spell := opt.next_spell()
	for s in book.spells:
		if s.name == opt_spell:
			if opt.kind == Kind.FIRE or opt.kind == Kind.FIRE_HOLD:
				return s
			elif opt.kind == Kind.PICK:
				picked = s.name
				return null
	return null

func action_down(action: String, book: MagicBook) -> Spell:
	current_actions[action] = 0
	var best_candidate := []
	for key in keys:
		if key.size() > current_actions.size():
			continue
		var found = true
		for k in key:
			if not current_actions.has(k):
				found = false
				break
		if found and key.size() > best_candidate.size():
			best_candidate = key
				
	if not best_candidate.is_empty():
		var opt: Option = keys[best_candidate]
		if opt.kind == Kind.FIRE_HOLD:
			keys[best_candidate].start_hold = Time.get_unix_time_from_system()
		elif opt.kind == Kind.FIRE or opt.kind == Kind.FIRE_PICKED or opt.kind == Kind.PICK:
			var s = find_spell(best_candidate, book)
			if s == null:
				return null
			if book.can_use_spell(s):
				book.use_spell(s)
				return s
			else:
				spell_on_cooldown.emit(s)
				return null
	return null
	
func action_up(action: String, book: MagicBook):
	var best_candidate := []
	for key in keys:
		if key.size() > current_actions.size():
			continue
		var found = true
#		for k in current_actions:
#			if key.find(k) == -1:
#				found = false
#				break
		for k in key:
			if not current_actions.has(k):
				found = false
				break
		if found and key.size() > best_candidate.size():
			best_candidate = key
			
#	print(best_candidate)
	if not best_candidate.is_empty():
		var opt: Option = keys[best_candidate]
		if opt.kind == Kind.FIRE_HOLD:
			var s = find_spell(best_candidate, book)
			if book.can_use_spell(s):
				book.use_spell(s)
				current_actions.erase(action)
				s.charge = Time.get_unix_time_from_system() - opt.start_hold
				return s
			else:
				spell_on_cooldown.emit(s)
				current_actions.erase(action)
				return null
	current_actions.erase(action)
	return null

func save_dict():
	var result = {
		"name": name,
		"keys": {},
		"mods": mods,
	}
	for key in keys:
		result["keys"][key] = keys[key].save_dict()
	return result
		
func load_dict(dict: Dictionary):
	name = dict["name"]
	mods = dict["mods"]
	picked = ""
	for k in dict["keys"]:
		var opt = Option.new()
		opt.load_dict(dict["keys"][k])
		keys[k] = opt

static func key_description(key: Array) -> String:
	var text = pc_keys[key[0]]
	for i in range(1, key.size()):
		text += " + " + pc_keys[key[i]]
	return text
