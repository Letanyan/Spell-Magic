class_name Wand

enum Kind { NONE, FIRE, FIRE_HOLD, RAPID_FIRE, PICK, FIRE_PICKED, FIRE_PICKED_HOLD, FIRE_PICKED_RAPID, MOD  }

class Option:
	var kind: Kind
	var spell_names: Array[String]
	var spells: Array[Spell]
	var parameters: Array[Dictionary] ## [][String]String
	var spell_index: int
	var start_hold: float
	
	func _init() -> void:
		kind = Kind.NONE
		spell_names = []
		spells = []
		parameters = []
		for s in spells:
			parameters.append({})
		spell_index = spells.size() - 1
		start_hold = 0.0
		
	func set_spells_with_names(book: MagicBook) -> void:
		spells.clear()
		for i in spell_names.size():
			var s := book.find_spell(spell_names[i])
			if s == null:
				spells.append(null)
			else:
				if not parameters[i].is_empty():
					s = s.duplicate()
					s.configure_using_parameter_collection(parameters[i], {})
				spells.append(s)
		
	func save_dict() -> Dictionary:
		return {"kind": kind, "spell": spell_names, "parameters": parameters}
		
	func load_dict(dict: Dictionary, book: MagicBook) -> void:
		kind = dict["kind"]
		var s: Variant = dict["spell"] 
		spell_names = []
		if s is String:
			spell_names = [s]
		else:
			spell_names.assign(s as Array[String])
		parameters.assign(dict.get("parameters", []) as Array[Dictionary])
		while parameters.size() < spells.size():
			parameters.append({})
		set_spells_with_names(book)
		spell_index = spell_names.size() - 1
		start_hold = 0.0
		
	func next_spell() -> Spell:
		if spells.size() <= 0:
			return null
		spell_index += 1
		if spell_index >= spells.size():
			spell_index = 0
		return spells[spell_index]
		
	func get_spell() -> Spell:
		if not (spell_index >= 0 and spell_index < spells.size()):
			return null
		return spells[spell_index]
		
	func get_spell_name() -> String:
		if not (spell_index >= 0 and spell_index < spells.size()):
			return ""
		return spell_names[spell_index]
		
	func display_rotated_spells_list(color_spell: Callable) -> String:
		if spells.size() == 0:
			return ""
		var result := ""
		var saved_index := spell_index
		
		spell_index += 1
		if spell_index >= spells.size():
			spell_index = 0
		while true:
			result += color_spell.call(self) + ", "	
			if spell_index == saved_index:
				break
			spell_index += 1
			if spell_index >= spells.size():
				spell_index = 0
		result = result.substr(0, result.length() - 2)
		return result
		
	func spell_was_updated(spell: Spell) -> void:
		for i in spells.size():
			var s := spells[i]
			if s == null: continue
			if s.name != spell.name: continue
			spells[i] = spell.duplicate()
			if not parameters.is_empty():
				spells[i].configure_using_parameter_collection(parameters[i], {})
			
	func parse_spells(text: String, book: MagicBook) -> void:
		const SPELL_NAME = 0
		const PARAM_NAME = 1
		const PARAM_VALUE = 2
		
		var state := SPELL_NAME
		var buffer := ""
		var param_name := ""
		
		spells.clear()
		spell_names.clear()
		parameters.clear()
		
		var param_paren_count := 0
		for s in text:
			match state:
				SPELL_NAME:
					if "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890 -_".contains(s):
						buffer += s
					elif s == "(":
						state = PARAM_NAME
						buffer = buffer.lstrip("\t\n\r ").rstrip("\t\n\r ")
						if not buffer.is_empty():
							spell_names.append(buffer)
							parameters.append({})
							buffer = ""
					elif s == ",":
						buffer = buffer.lstrip("\t\n\r ").rstrip("\t\n\r ")
						if not buffer.is_empty():
							spell_names.append(buffer)
							parameters.append({})
							buffer = ""
				PARAM_NAME:
					if "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890_".contains(s):
						buffer += s
					elif s == "=":
						state = PARAM_VALUE
						param_name = buffer.lstrip("\t\n\r ").rstrip("\t\n\r ")
						buffer = ""
					elif s == ",":
						state = PARAM_NAME
						buffer = ""
					elif s == ")":
						state = SPELL_NAME
						buffer = ""
				PARAM_VALUE:
					if "1234567890.-qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM_ (+-*/^".contains(s) or (param_paren_count > 0 and (s == "," or s == ")")):
						buffer += s
						if s == "(":
							param_paren_count += 1
						elif s == ")":
							param_paren_count -= 1
					elif s == ",":
						state = PARAM_NAME
						buffer = buffer.lstrip("\t\n\r ").rstrip("\t\n\r ")
						parameters[parameters.size() - 1][param_name] = buffer
						buffer = ""
						param_paren_count = 0
					elif s == ")":
						state = SPELL_NAME
						buffer = buffer.lstrip("\t\n\r ").rstrip("\t\n\r ")
						parameters[parameters.size() - 1][param_name] = buffer
						buffer = ""
						param_paren_count = 0
		
		match state:
			SPELL_NAME:
				buffer = buffer.lstrip("\t\n ").rstrip("\t\n ")
				if not buffer.is_empty():
					spell_names.append(buffer)
					parameters.append({})
			PARAM_VALUE:
				buffer = buffer.lstrip("\t\n ").rstrip("\t\n ")
				parameters[parameters.size() - 1][param_name] = buffer
		
		if not spell_names.is_empty() and (spell_names.back() as String).is_empty():
			spell_names.pop_back()
			parameters.pop_back()
		set_spells_with_names(book)
		spell_index = spell_names.size() - 1

const basic_keys: Array[String] = [
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
var mods: Dictionary ## [String]bool
var keys: Dictionary ## [PackedStringArray]Option
var picked_key: PackedStringArray
var picked_index: int

var current_actions: Dictionary ## [String]bool
var selection_wheel: SelectionWheel

signal spell_disallowed(spell: Spell, reason: MagicBook.DisallowSpellReason)
signal spell_updated
signal action_updated
signal picked_spell_changed
signal key_down
signal key_up
signal will_show_selection_wheel

func _init() -> void:
	name = "Default"
	mods = {}
	keys = {}
	picked_key = PackedStringArray([])
	picked_index = -1
	current_actions = {}
	build_keys()

func build_keys() -> void:
	var dict_contains_dict := func(hay: Dictionary, needle: Dictionary) -> bool:
		for key: Dictionary in hay:
			if key == needle:
				return true
		return false
	
	var new_keys := {}
	for b: String in basic_keys:
		var packed := PackedStringArray([b])
		if not new_keys.has(packed):
			new_keys[packed] = Option.new()
	var found: Dictionary = {}
	for m: String in mods:
		for key: PackedStringArray in new_keys:
			if key.find(m) == -1:
				var nKey := key.duplicate()
				nKey.insert(0, m)
				var dict := {m: true}
				for k: String in key:
					dict[k] = true
				if not dict_contains_dict.call(found, dict):
					found[dict] = true
					new_keys[nKey] = Option.new()
					
	for key: PackedStringArray in new_keys:
		if keys.has(key):
			new_keys[key] = keys[key]
		
	keys = new_keys

func get_bound_keys() -> Dictionary:
	var result := {}
	for key: PackedStringArray in keys:
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
		build_keys()
	
func add_mod(mod: String) -> void:
	mods[mod] = true
	build_keys()
	
func picked_name() -> String:
	if picked_key.is_empty() or picked_index < 0 or not keys.has(picked_key) or picked_index >= (keys[picked_key].spells as Array).size():
		return ""
	return keys[picked_key].spells[picked_index]
	
func spell_was_updated(spell: Spell) -> void:
	for key: PackedStringArray in keys:
		(keys[key] as Option).spell_was_updated(spell)
	
func get_spell(opt: Option, book: MagicBook) -> Spell:
	if opt.kind == Kind.FIRE_PICKED or opt.kind == Kind.FIRE_PICKED_RAPID or opt.kind == Kind.FIRE_PICKED_HOLD:
		if picked_key.is_empty() or picked_index < 0 or not keys.has(picked_key) or picked_index >= (keys[picked_key].spells as Array).size():
			return null
		var picked_option := keys[picked_key] as Option
		var picked := picked_option.spells[picked_index].name
		var picked_parameters := picked_option.parameters[picked_index]
		for s in book.spells:
			if s.name == picked:
				if picked_parameters.is_empty():
					return s
				else:
					var ns := s.duplicate()
					ns.configure_using_parameter_collection(picked_parameters, {})
					return ns
		return null
	elif opt.kind == Kind.MOD or opt.kind == Kind.NONE:
		return null
	elif opt.kind == Kind.FIRE or opt.kind == Kind.FIRE_HOLD or opt.kind == Kind.RAPID_FIRE or opt.kind == Kind.PICK:
		return opt.get_spell()
	return null
	
func find_spell(key: PackedStringArray, book: MagicBook) -> Spell:
	var opt: Option = keys[key]
	if opt.kind == Kind.FIRE_PICKED or opt.kind == Kind.FIRE_PICKED_RAPID or opt.kind == Kind.FIRE_PICKED_HOLD:
		if picked_key.is_empty() or picked_index < 0 or not keys.has(picked_key) or picked_index >= (keys[picked_key].spells as Array).size():
			return null
		var picked_option := keys[picked_key] as Option
		var picked := picked_option.spells[picked_index].name
		var picked_parameters := picked_option.parameters[picked_index]
		for s in book.spells:
			if s.name == picked:
				if picked_parameters.is_empty():
					return s
				else:
					var ns := s.duplicate()
					ns.configure_using_parameter_collection(picked_parameters, {})
					return ns
		return null
	elif opt.kind == Kind.MOD or opt.kind == Kind.NONE:
		return null
	var opt_spell := opt.next_spell()
	if opt.kind == Kind.FIRE or opt.kind == Kind.FIRE_HOLD or opt.kind == Kind.RAPID_FIRE:
		return opt_spell
	elif opt.kind == Kind.PICK:
		picked_key = key
		picked_index = opt.spell_index
		picked_spell_changed.emit()
		return null
	return null

func action_down(action: String, book: MagicBook, is_rapid_fire: Globals.Ref) -> Spell:
	if action != "":
		current_actions[action] = 0
	var best_candidate := PackedStringArray([])
	for key: PackedStringArray in keys:
		if key.size() > current_actions.size():
			continue
		var found := true
		for k in key:
			if not current_actions.has(k):
				found = false
				break
		if found and key.size() > best_candidate.size():
			best_candidate = key
				
	if not best_candidate.is_empty():
		var opt: Option = keys[best_candidate]
		is_rapid_fire.data = true if opt.kind == Kind.RAPID_FIRE or opt.kind == Kind.FIRE_PICKED_RAPID else false
		if opt.kind == Kind.FIRE_HOLD or opt.kind == Kind.FIRE_PICKED_HOLD or opt.kind == Kind.PICK:
			opt.start_hold = Time.get_unix_time_from_system()
			if opt.kind == Kind.PICK and selection_wheel != null:
				var spell_names: Array[String] = []
				for spell in opt.spells:
					spell_names.append(spell.name)
				selection_wheel.segments = spell_names
				will_show_selection_wheel.emit()
				selection_wheel.get_tree().create_timer(0.123).timeout.connect(func() -> void:
					var charge := Time.get_unix_time_from_system() - opt.start_hold
					if charge > 0.075 and not selection_wheel.segments.is_empty():
						Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
						selection_wheel.show()
				)
		elif opt.kind == Kind.FIRE or opt.kind == Kind.FIRE_PICKED or opt.kind == Kind.RAPID_FIRE or opt.kind == Kind.FIRE_PICKED_RAPID:
			var s := find_spell(best_candidate, book)
			if s == null:
				key_down.emit()
				return null
				
			if opt.kind == Kind.RAPID_FIRE or opt.kind == Kind.FIRE_PICKED_RAPID:
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
	var best_candidate := PackedStringArray([])
	for key: PackedStringArray in keys:
		if key.size() > current_actions.size():
			continue
		var found := true
#		for k in current_actions:
#			if key.find(k) == -1:
#				found = false
#				break
		for k in key:
			if not current_actions.has(k):
				found = false
				break
		if found and key.size() > best_candidate.size() and key.find(action) != -1:
			best_candidate = key
			
	current_actions.erase(action)
			
	if not best_candidate.is_empty():
		var opt: Option = keys[best_candidate]
		if opt.kind == Kind.PICK:
			var charge := Time.get_unix_time_from_system() - opt.start_hold
			opt.start_hold = Time.get_unix_time_from_system() + 500
			selection_wheel.hide()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			if charge < 0.123:
				find_spell(best_candidate, book)
				key_up.emit()
				return null
			elif selection_wheel != null:
				var index := selection_wheel.last_selected_segment_index
				if index != -1:
					opt.spell_index = index - 1 if index != 0 else opt.spells.size() - 1
					find_spell(best_candidate, book)
					key_up.emit()
					return null
		elif opt.kind == Kind.FIRE_HOLD or opt.kind == Kind.FIRE_PICKED_HOLD:
			var s := find_spell(best_candidate, book)
			if s == null:
				key_up.emit()
				return null
				
			var can_use: MagicBook.DisallowSpellReason = book.can_use_spell(s)
			match can_use:
				MagicBook.DisallowSpellReason.NONE:
					book.use_spell(s)
					s.charge = Time.get_unix_time_from_system() - opt.start_hold
					key_up.emit()
					return s
				_:
					spell_disallowed.emit(s, can_use)
					key_up.emit()
					return null
				
	key_up.emit()
	return null
	

func save_dict() -> Dictionary:
	var result := {
		"name": name, "keys": {}, "mods": mods,
	}
	for key: PackedStringArray in keys:
		result["keys"][key] = (keys[key] as Option).save_dict()
	return result
		
func load_dict(dict: Dictionary, book: MagicBook) -> void:
	name = dict["name"]
	mods = dict["mods"]
	for k: Variant in dict["keys"]:
		var opt := Option.new()
		opt.load_dict(dict["keys"][k] as Dictionary, book)
		if k is Array:
			keys[PackedStringArray(k as Array)] = opt
		else:
			keys[k] = opt
