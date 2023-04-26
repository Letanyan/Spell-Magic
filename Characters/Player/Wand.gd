class_name Wand

enum Kind { NONE, FIRE, PICK, FIRE_PICKED, MOD  }

class Option extends Object:
	var kind: Kind
	var spell: String
	
	func _init(kind: Kind = Kind.NONE, spell: String = ""):
		self.kind = kind
		self.spell = spell
		
	func save_dict():
		return {"kind": kind, "spell": spell}
		
	func load_dict(dict: Dictionary):
		kind = dict["kind"]
		spell = dict["spell"]

const basic_keys = [
	"LB",
	"LT",
	"RT",
	"RB",
	"N",
	"E",
	"S",
	"W",
	"UP",
	"DOWN",
	"LEFT",
	"RIGHT",
	"L3",
	"R3",
]

var name: String
var mods: Array
var keys: Dictionary
var picked: Spell

var current_actions: Dictionary

func _init():
	name = ""
	mods = []
	keys = {}
	picked = null
	current_actions = {}

func build_keys():
	for b in basic_keys:
		if not keys.has(b):
			keys[[b]] = Option.new()
	for m in mods:
		for key in keys:
			if key.find(m) == -1:
				var nKey = key.duplicate()
				nKey.insert(0, m)
				if not keys.has(nKey):
					keys[nKey] = Option.new()

func remove_mod(mod: String):
	var i = mods.find(mod)
	if i != -1:
		var m = mods[i]
		mods.remove_at(i)
		var to_remove = []
		for key in keys:
			if key.size() > 1 and key.find(m) != -1:
				to_remove.append(key)
		for k in to_remove:
			keys.erase(k)
	
func add_mod(mod: String):
	mods.append(mod)
	build_keys()
	
func find_spell(key: Array, book: MagicBook) -> Spell:
	var opt: Option = keys[key]
	if opt.kind == Kind.FIRE_PICKED:
		return picked
	elif opt.kind == Kind.MOD or opt.kind == Kind.NONE:
		return null
	for s in book.spells:
		if s.name == opt.spell:
			if opt.kind == Kind.FIRE:
				return s
			elif opt.kind == Kind.PICK:
				picked = s
				return
	return null

func action_down(action: String, book: MagicBook) -> Spell:
	current_actions[action] = 0
	for key in keys:
		if key.size() != current_actions.size():
			continue
		var found = true
		for k in current_actions:
			if key.find(k) == -1:
				found = false
				break
		if found:
			var opt: Option = keys[key]
			if opt.kind == Kind.FIRE or opt.kind == Kind.FIRE_PICKED or opt.kind == Kind.PICK:
				return find_spell(key, book)
	return null
	
func action_up(action: String):
	current_actions.erase(action)

func save_dict():
	var result = {
		"name": name,
		"keys": {},
		"picked": picked.save_dict() if picked != null else {},
		"mods": mods,
	}
	for key in keys:
		result["keys"][key] = keys[key].save_dict()
	return result
		
func load_dict(dict: Dictionary):
	name = dict["name"]
	mods = dict["mods"]
	picked = Spell.new()
#	picked.load_dict(dict["picked"])
	for k in dict["keys"]:
		var opt = Option.new()
		opt.load_dict(dict["keys"][k])
		keys[k] = opt

