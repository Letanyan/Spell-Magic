class_name Wand

enum Kind { NONE, FIRE, FIRE_HOLD, RAPID_FIRE, PICK, FIRE_PICKED, FIRE_PICKED_HOLD, RAPID_SELECT, MOD  }

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
		if spell.size() <= 0:
			return ""
		spell_index += 1
		if spell_index >= spell.size():
			spell_index = 0
		return spell[spell_index]
		
	func display_rotated_spells_list() -> String:
		if spell.size() == 0:
			return ""
		var result := ""
		var i := spell_index + 1
		if i >= spell.size():
			i = 0
		while true:
			result += spell[i] + ", "
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

const pc_keys = {
	"LT": "shift",
	"LB": "ctrl",
	"RT": "left mouse",
	"RB": "right mouse",
	"S": "space",
	"W": "R",
	"E": "E",
	"N": "Q",
	"UP": "up",
	"DOWN": "down",
	"LEFT": "left",
	"RIGHT": "right",
	"L3": "Z",
	"R3": "alt",
	"move_forward": "W",
	"move_left": "A",
	"move_back": "S",
	"move_right": "D",
}

const pc_images = {
	"LT": "[img=%d]res://addons/controller_icons/assets/key/shift.png[/img]",
	"LB": "[img=%d]res://addons/controller_icons/assets/key/ctrl.png[/img]",
	"RT": "[img=%d]res://addons/controller_icons/assets/mouse/left.png[/img]",
	"RB": "[img=%d]res://addons/controller_icons/assets/mouse/right.png[/img]",
	"S": "[img=%d]res://addons/controller_icons/assets/key/space.png[/img]",
	"W": "[img=%d]res://addons/controller_icons/assets/key/r.png[/img]",
	"E": "[img=%d]res://addons/controller_icons/assets/key/e.png[/img]",
	"N": "[img=%d]res://addons/controller_icons/assets/key/q.png[/img]",
	"UP": "[img=%d]res://addons/controller_icons/assets/key/arrow_up.png[/img]",
	"DOWN": "[img=%d]res://addons/controller_icons/assets/key/arrow_down.png[/img]",
	"LEFT": "[img=%d]res://addons/controller_icons/assets/key/arrow_left.png[/img]",
	"RIGHT": "[img=%d]res://addons/controller_icons/assets/key/arrow_right.png[/img]",
	"L3": "[img=%d]res://addons/controller_icons/assets/key/z.png[/img]",
	"R3": "[img=%d]res://addons/controller_icons/assets/key/alt.png[/img]",
	"move_forward": "[img=%d]res://addons/controller_icons/assets/key/w.png[/img]",
	"move_left": "[img=%d]res://addons/controller_icons/assets/key/a.png[/img]",
	"move_back": "[img=%d]res://addons/controller_icons/assets/key/s.png[/img]",
	"move_right": "[img=%d]res://addons/controller_icons/assets/key/d.png[/img]",
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

var current_actions: Dictionary

signal spell_disallowed(spell: Spell, reason: MagicBook.DisallowSpellReason)
signal spell_updated
signal action_updated
signal picked_spell_changed
signal key_down
signal key_up

func _init():
	name = ""
	mods = {}
	keys = {}
	picked = ""
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

func get_bound_keys() -> Dictionary:
	var result := {}
	for key in keys:
		var is_valid := true
		var mod_count := 0
		for ca in current_actions:
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
		is_rapid_fire.data = true if opt.kind == Kind.RAPID_FIRE or opt.kind == Kind.RAPID_SELECT else false
		if opt.kind == Kind.FIRE_HOLD or opt.kind == Kind.FIRE_PICKED_HOLD:
			keys[best_candidate].start_hold = Time.get_unix_time_from_system()
		elif opt.kind == Kind.FIRE or opt.kind == Kind.FIRE_PICKED or opt.kind == Kind.PICK or opt.kind == Kind.RAPID_FIRE or opt.kind == Kind.RAPID_SELECT:
			var s = find_spell(best_candidate, book)
			if s == null:
				key_down.emit()
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
			
	if not best_candidate.is_empty():
		var opt: Option = keys[best_candidate]
		if opt.kind == Kind.FIRE_HOLD or opt.kind == Kind.FIRE_PICKED_HOLD:
			var s = find_spell(best_candidate, book)
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
	
static func key_images(key: Array, size: int = 32) -> String:
	var text = (pc_images[key[0]] % size)
	for i in range(1, key.size()):
		text += " + " + (pc_images[key[i]] % size)
	return text
