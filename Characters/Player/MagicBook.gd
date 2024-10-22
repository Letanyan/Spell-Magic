class_name MagicBook

var spells: Array[Spell]
var spell_index: Dictionary
var last_use: Dictionary # [String]Unix.Time
var ignore_cooldown: bool
enum DisallowSpellReason { NONE, COOLDOWN, MANA, COUNT, POWER, DURATION, RADIUS, ACTIVE, VELOCITY }

var settings: WorldSettings # set by the world

func save(world_name: String) -> void:
	save_absolute_path("user://worlds/%s/magic_book.json" % (world_name))
	
func save_absolute_path(file_path: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	var data := []
	for s in spells:
		data.append(s.save_dict())
	file.store_var(data)
	
func export_absolute_path(file_path: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	var data := ""
	for s in spells:
		data += s.make_gdscript_init(s.name, true)
	file.store_string(data)
	
func read(world_name: String) -> void:
	read_absolute_path("user://worlds/%s/magic_book.json" % (world_name))
		
func read_absolute_path(file_path: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.READ)
	last_use = {}
	ignore_cooldown = false
	spell_index = {}
	if not file:
		spells = []
		return 
	var data := file.get_var() as Array
	if data == null:
		spells = []
		return
	var active_count := 0
	for d: Dictionary in data:
		var s := Spell.new()
		s.load_dict(d)
		s.limit_r = settings.upgrade_settings.max_r()
		s.limit_v = settings.upgrade_settings.max_v()
		if s.is_active:
			active_count += 1
		s.is_active = s.is_active and active_count < settings.upgrade_settings.max_spells_in_book()
		spells.append(s)
		spell_index[s.name] = s
	
func _init() -> void:
	spells = []
	last_use = {}
	ignore_cooldown = false
	settings = null
	
func reset_by_deleting_all_spells() -> void:
	spells = []
	spell_index.clear()
	last_use = {}
	
func add(spell: Spell) -> void:
	var active_count := 0
	for s in spells:
		if s.is_active:
			active_count += 1
	spell.is_active = active_count <= settings.upgrade_settings.max_spells_in_book()
	spells.append(spell)
	spell_index[spell.name] = spell
	
func remove(i: int) -> void:
	var s := spells[i]
	spells.remove_at(i)
	spell_index.erase(s.name)

func use_spell(spell: Spell) -> void:
	var t := Time.get_unix_time_from_system()
	last_use[spell.name] = t
	var s := spell.chain
	while s != null:
		last_use[s.name] = t
		s = s.chain
	
func can_use_spell(spell: Spell) -> DisallowSpellReason:
	if not spell.is_active:
		return DisallowSpellReason.ACTIVE
	
	var elapsed := Time.get_unix_time_from_system() - last_use.get(spell.name, 0.0) as float
	if elapsed < spell.cooldown and not ignore_cooldown:
		return DisallowSpellReason.COOLDOWN
		
	if spell.count > settings.upgrade_settings.max_N() + settings.upgrade_settings.buff_N:
		return DisallowSpellReason.COUNT
	elif spell.count > settings.upgrade_settings.LIMIT_N:
		return DisallowSpellReason.COUNT
		
	if spell.duration > settings.upgrade_settings.max_T() + settings.upgrade_settings.buff_T:
		return DisallowSpellReason.DURATION
	elif spell.duration > settings.upgrade_settings.LIMIT_T:
		return DisallowSpellReason.DURATION
		
	if spell.power > settings.upgrade_settings.max_P() + settings.upgrade_settings.buff_P:
		return DisallowSpellReason.POWER
	elif spell.power > settings.upgrade_settings.LIMIT_P:
		return DisallowSpellReason.POWER
		
	if spell.radius > settings.upgrade_settings.max_r() + settings.upgrade_settings.buff_r:
		return DisallowSpellReason.RADIUS
	elif spell.radius > settings.upgrade_settings.LIMIT_r:
		return DisallowSpellReason.RADIUS
		
	if spell.actual_mana_cost() > settings.upgrade_settings.max_mana() + settings.upgrade_settings.buff_mana:
		return DisallowSpellReason.MANA
		
	return DisallowSpellReason.NONE
	
func can_use_spell_with_name(n: String) -> DisallowSpellReason:
	var s := find_spell(n)
	if s != null:
		return can_use_spell(s)
	return DisallowSpellReason.ACTIVE

func rebuild_spell_chains() -> void:
	for s in spells:
		if s.chain != null:
			for t in spells:
				if s.chain.name == t.name:
					s.chain = t
					break
		
func find_parent_chains(spell: Spell) -> PackedStringArray:
	var result := PackedStringArray([])
	for s in spells:
		if s.chain != null and s.chain.name == spell.name:
			result.append(s.name)
	return result
					
func find_recursive_spell_chain(parent: Spell, child: String) -> PackedStringArray:
	for s in spells:
		var chain := s.find_chain_list(true)
		if not chain.is_empty() and chain[chain.size() - 1] == parent.name and chain.has(child):
			return chain
		
	return PackedStringArray([])
 			
func update_spell_limits(v: float, r: float) -> void:
	for s in spells:
		s.limit_v = v
		s.limit_r = r
		
func update_spell_buff_limits(v: float, r: float) -> void:
	for s in spells:
		s.buff_v = v
		s.buff_r = r
		
func update_spell_attack_and_defence(atk: float, def: float) -> void:
	for s in spells:
		s.buff_attack = atk
		s.buff_defence = def

func spell_exists(n: String) -> bool:
	for s in spells:
		if s.name == n:
			return true
	return false
	
func find_spell(n: String) -> Spell:
	return spell_index.get(n, null) as Spell
	
func copy_spell(n: String) -> Spell:
	var s := spell_index.get(n, null) as Spell
	if s == null:
		return null
	var result := s.duplicate({}, false)
	return result
	
func copy_and_configure_spell(n: String, constants: Dictionary, element: Spell.Element, duration: float, power: float, radius: float, count: int, crit_rate: float, crit_dmg: float, mana: float) -> Spell:
	var s := spell_index.get(n, null) as Spell
	if s == null:
		return null
	var result := s.duplicate({}, false)
	result.configure(constants, element, duration, power, radius, count, crit_rate, crit_dmg, mana)
	return result

func autocomplete(old_text: String, edit: LineEdit, suggest_only_active: bool, ignore_recursive_chains: Spell = null) -> String:
	var text := edit.text
	if old_text.length() > text.length():
		return text
		
	var in_param_list := false
	var current_spell_name := ""
	if true:
		var i := 0
		var paren_count := 0
		while i < edit.caret_column:
			if paren_count == 0: 
				if "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890 -_".contains(text[i]):
					current_spell_name += text[i]
				elif text[i] != "(":
					current_spell_name = ""
			if text[i] == "(":
				paren_count += 1
			elif text[i] == ")":
				paren_count -= 1
			i += 1
		current_spell_name = current_spell_name.lstrip("\n\t\r ").rstrip("\n\t\r ")
		in_param_list = paren_count != 0
		
	var eidx := edit.caret_column
	var sidx := edit.caret_column
	if sidx == text.length():
		sidx -= 1
	if sidx >= 0 and text[sidx] in " \n\t,":
		sidx -= 1
	while sidx >= 0:
		if text[sidx] in " \n\t,":
			break
		sidx -= 1
	sidx += 1
	
	if sidx == eidx:
		return text
		
	var prefix := text.substr(sidx, eidx - sidx)
	
	var complete := ""
	if in_param_list:
		var s := find_spell(current_spell_name)
		if s == null:
			return text
		for p: String in s.expression_strings:
			if p.begins_with(prefix):
				complete = p
				break
		for p: String in ["element", "CD", "CR"]:
			if p.begins_with(prefix):
				complete = p
				break
	else:
		for s in spells:
			if (s.is_active or not suggest_only_active) and s.name.begins_with(prefix):
				if ignore_recursive_chains == null or find_recursive_spell_chain(ignore_recursive_chains, s.name).is_empty():
					complete = s.name
					break
			
	if complete.is_empty():
		return text
		
	var suffix := complete.substr(eidx - sidx, complete.length() - (eidx - sidx))
		
	var fidx := edit.caret_column
	if fidx == text.length():
		fidx -= 1
	while fidx < text.length():
		if text[fidx] in " \n\t,()":
			break
		fidx += 1
	
	edit.delete_text(edit.caret_column, fidx)
	edit.insert_text_at_caret(suffix)
	edit.select(eidx, eidx + suffix.length())
	
	return edit.text
	
	
	
	
