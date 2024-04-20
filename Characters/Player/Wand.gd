class_name Wand

enum Kind { NONE, FIRE, FIRE_HOLD, RAPID_FIRE, PICK, FIRE_PICKED, FIRE_PICKED_HOLD, RAPID_SELECT, MOD  }

class Option:
	var kind: Kind
	var spell: Array
	var spell_index: int
	var start_hold: float
	
	func _init(_kind: Kind = Kind.NONE, _spell: Array = []) -> void:
		kind = _kind
		spell = _spell
		spell_index = spell.size() - 1
		start_hold = 0.0
		
	func save_dict() -> Dictionary:
		return {"kind": kind, "spell": spell}
		
	func load_dict(dict: Dictionary) -> void:
		kind = dict["kind"]
		var s: Variant = dict["spell"] 
		if s is String:
			spell = [s]
		else:
			spell = s as Array[String]
		spell_index = spell.size() - 1
		start_hold = 0.0
		
	func next_spell() -> String:
		if spell.size() <= 0:
			return ""
		spell_index += 1
		if spell_index >= spell.size():
			spell_index = 0
		return spell[spell_index]
		
	func display_rotated_spells_list(book: MagicBook = null) -> String:
		if spell.size() == 0:
			return ""
		var result := ""
		var i := spell_index + 1
		if i >= spell.size():
			i = 0
		while true:
			if book == null and not book.can_use_spell_with_name(spell[i] as String):
				result += spell[i] + ", "
			else:
				result += "[color=#F05]" + spell[i] + "[/color], "
				
			if i == spell_index:
				break
			i += 1
			if i >= spell.size():
				i = 0
		result = result.substr(0, result.length() - 2)
		return result

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

var name: String
var mods: Dictionary # [String]bool
var keys: Dictionary # [[]String]Option
var picked: String

var current_actions: Dictionary # [String]bool

signal spell_disallowed(spell: Spell, reason: MagicBook.DisallowSpellReason)
signal spell_updated
signal action_updated
signal picked_spell_changed
signal key_down
signal key_up

func _init() -> void:
	name = "Wand"
	mods = {}
	keys = {}
	picked = ""
	current_actions = {}
	build_keys()

func build_keys() -> void:
	for b: String in basic_keys:
		if not keys.has([b]):
			keys[[b]] = Option.new()
	for m: String in mods:
		for key: Array in keys:
			if key.find(m) == -1:
				var nKey := key.duplicate()
				nKey.insert(0, m)
				if not keys.has(nKey):
					keys[nKey] = Option.new()

func get_bound_keys() -> Dictionary:
	var result := {}
	for key: Array in keys:
		var is_valid := true
		var mod_count := 0
		for ca: String in current_actions:
			if not mods.has(ca):
				continue
			mod_count += 1
			if key.find(ca) == -1:
				is_valid = false
				break
		if is_valid and key.size() - mod_count == 1:
			result[key] = keys[key]
			
	return result

static func basic() -> Wand:
	var result := Wand.new()
	result.build_keys()
	return result
	

func remove_mod(mod: String) -> void:
	if mods.has(mod):
		mods.erase(mod)
		var to_remove := []
		for key: Array in keys:
			if key.size() > 1 and key.find(mod) != -1:
				to_remove.append(key)
		for k: Array in to_remove:
			keys.erase(k)
	
func add_mod(mod: String) -> void:
	mods[mod] = true
	build_keys()
	
func find_spell(key: Array, book: MagicBook) -> Spell:
	var opt: Option = keys[key]
	if opt.kind == Kind.FIRE_PICKED or opt.kind == Kind.RAPID_SELECT or opt.kind == Kind.FIRE_PICKED_HOLD:
		for s in book.spells:
			if s.name == picked:
				return s
		return null
	elif opt.kind == Kind.MOD or opt.kind == Kind.NONE:
		return null
	var opt_spell := opt.next_spell()
	for s in book.spells:
		if s.name == opt_spell:
			if opt.kind == Kind.FIRE or opt.kind == Kind.FIRE_HOLD or opt.kind == Kind.RAPID_FIRE:
				return s
			elif opt.kind == Kind.PICK:
				picked = s.name
				picked_spell_changed.emit()
				return null
	return null

func action_down(action: String, book: MagicBook, is_rapid_fire: Globals.Ref) -> Spell:
	if action != "":
		current_actions[action] = 0
	var best_candidate := []
	for key: Array in keys:
		if key.size() > current_actions.size():
			continue
		var found := true
		for k: String in key:
			if not current_actions.has(k):
				found = false
				break
		if found and key.size() > best_candidate.size():
			best_candidate = key
				
	if not best_candidate.is_empty():
		var opt: Option = keys[best_candidate]
		is_rapid_fire.data = true if opt.kind == Kind.RAPID_FIRE or opt.kind == Kind.RAPID_SELECT else false
		if opt.kind == Kind.FIRE_HOLD or opt.kind == Kind.FIRE_PICKED_HOLD:
			keys[best_candidate].start_hold = Time.get_unix_time_from_system()
		elif opt.kind == Kind.FIRE or opt.kind == Kind.FIRE_PICKED or opt.kind == Kind.PICK or opt.kind == Kind.RAPID_FIRE or opt.kind == Kind.RAPID_SELECT:
			var s := find_spell(best_candidate, book)
			if s == null:
				key_down.emit()
				return null
				
			if opt.kind == Kind.RAPID_FIRE or opt.kind == Kind.RAPID_SELECT:
				var start_time: float = keys[best_candidate].start_hold
				var now := Time.get_unix_time_from_system()
				if start_time == 0.0 or now - start_time >= s.cooldown:
					keys[best_candidate].start_hold = now
				else:
					return null
				
			var can_use: MagicBook.DisallowSpellReason = book.can_use_spell(s)
			match can_use:
				MagicBook.DisallowSpellReason.NONE:
					book.use_spell(s)
					key_down.emit()
					return s
				_:
					spell_disallowed.emit(s, can_use)
					key_down.emit()
					return null
	key_down.emit()
	return null
	
func action_up(action: String, book: MagicBook) -> Spell:
	var best_candidate := []
	for key: Array in keys:
		if key.size() > current_actions.size():
			continue
		var found := true
#		for k in current_actions:
#			if key.find(k) == -1:
#				found = false
#				break
		for k: String in key:
			if not current_actions.has(k):
				found = false
				break
		if found and key.size() > best_candidate.size():
			best_candidate = key
			
	if not best_candidate.is_empty():
		var opt: Option = keys[best_candidate]
		if opt.kind == Kind.FIRE_HOLD or opt.kind == Kind.FIRE_PICKED_HOLD:
			var s := find_spell(best_candidate, book)
			if s == null:
				key_up.emit()
				return null
				
			var can_use: MagicBook.DisallowSpellReason = book.can_use_spell(s)
			match can_use:
				MagicBook.DisallowSpellReason.NONE:
					book.use_spell(s)
					current_actions.erase(action)
					s.charge = Time.get_unix_time_from_system() - opt.start_hold
					key_up.emit()
					return s
				_:
					spell_disallowed.emit(s, can_use)
					current_actions.erase(action)
					key_up.emit()
					return null
				
	current_actions.erase(action)
	key_up.emit()
	return null

func save_dict() -> Dictionary:
	var result := {
		"name": name,
		"keys": {},
		"mods": mods,
	}
	for key: Array in keys:
		result["keys"][key] = (keys[key] as Option) .save_dict()
	return result
		
func load_dict(dict: Dictionary) -> void:
	name = dict["name"]
	mods = dict["mods"]
	picked = ""
	for k: Array in dict["keys"]:
		var opt := Option.new()
		opt.load_dict(dict["keys"][k] as Dictionary)
		keys[k] = opt
