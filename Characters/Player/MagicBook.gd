class_name MagicBook

var spells: Array[Spell]
var spell_index: Dictionary
var cooldown: Dictionary ## [String]float
var ignore_cooldown: bool
enum DisallowSpellReason { NONE, COOLDOWN, MANA, COUNT, POWER, DURATION, RADIUS, ACTIVE, VELOCITY, CHAINED_SPELL, CRIT_RATE, CRIT_DMG, ELEMENT }

var settings: WorldSettings # set by the world

signal spell_was_updated(spell: Spell)

func save(world_name: String) -> void:
	save_absolute_path("user://worlds/%s/magic_book.json" % (world_name))
	
func save_absolute_path(file_path: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	var data := []
	for s in spells:
		data.append(s.save_dict())
	file.store_var(data)
	file.close()
	
func export_absolute_path(file_path: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	var data := ""
	for s in spells:
		data += s.make_gdscript_init(s.name, true)
	file.store_string(data)
	file.close()
	
func read(world_name: String, create_default_spell: bool = true) -> bool:
	return read_absolute_path("user://worlds/%s/magic_book.json" % (world_name), create_default_spell)
		
func read_absolute_path(file_path: String, create_default_spell: bool = true) -> bool:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		if create_default_spell:
			var starters := settings.upgrade_settings.default_starter_spell()
			for key: String in starters:
				add(starters[key] as Spell)
		return false
	var data := file.get_var() as Array
	if data == null:
		if create_default_spell:
			var starters := settings.upgrade_settings.default_starter_spell()
			for key: String in starters:
				add(starters[key] as Spell)
		return false
	var active_count := 0
	spells = []
	cooldown = {}
	spell_index = {}
	for d: Dictionary in data:
		var s := Spell.new()
		s.load_dict(d)
		s.limit_r = settings.upgrade_settings.max_r()
		s.limit_v = settings.upgrade_settings.max_v()
		s.is_active = s.is_active and active_count < settings.upgrade_settings.max_spells_in_book()
		if s.is_active:
			active_count += 1
		spells.append(s)
		spell_index[s.name] = s
	return true
	
func _init() -> void:
	spells = []
	cooldown = {}
	spell_index = {}
	ignore_cooldown = false
	settings = null
	
func reset_by_deleting_all_spells() -> void:
	spells = []
	spell_index.clear()
	cooldown = {}
	
func add(spell: Spell) -> void:
	var active_count := 0
	for s in spells:
		if s.is_active:
			active_count += 1
	spell.is_active = active_count < settings.upgrade_settings.max_spells_in_book() and can_use_spell(spell, true) == DisallowSpellReason.NONE
	spells.append(spell)
	spell_index[spell.name] = spell
	
func remove(i: int) -> void:
	var s := spells[i]
	spells.remove_at(i)
	spell_index.erase(s.name)

func use_spell(spell: Spell) -> void:
	if cooldown.has(spell.name):
		var v := cooldown[spell.name] as float
		cooldown[spell.name] = maxf(v, spell.cooldown)
	else:
		cooldown[spell.name] = spell.cooldown
	var ns := spell.chain
	var ck := spell.chain_cast_kind
	while ns != null and ck != Spell.ChainCastKind.NONE:
		if cooldown.has(ns.name):
			var v := cooldown[ns.name] as float
			cooldown[ns.name] = maxf(v, ns.cooldown)
		else:
			cooldown[ns.name] = ns.cooldown
		ck = ns.chain_cast_kind
		ns = ns.chain
	
func can_use_spell(spell: Spell, ignore_perpetual: bool = false) -> DisallowSpellReason:
	if not spell.is_active and not ignore_perpetual:
		return DisallowSpellReason.ACTIVE
	
	if cooldown.has(spell.name) and not ignore_cooldown and not ignore_perpetual:
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
		
	if spell.crit_rate > settings.upgrade_settings.max_crit_rate():
		return DisallowSpellReason.CRIT_RATE
	elif spell.crit_rate > settings.upgrade_settings.LIMIT_CRIT_RATE:
		return DisallowSpellReason.CRIT_RATE
		
	if spell.crit_dmg > settings.upgrade_settings.max_crit_dmg():
		return DisallowSpellReason.CRIT_DMG
	elif spell.crit_dmg > settings.upgrade_settings.LIMIT_CRIT_DMG:
		return DisallowSpellReason.CRIT_DMG
		
	var radius := spell.radius_cache
	if radius > settings.upgrade_settings.max_r() + settings.upgrade_settings.buff_r:
		return DisallowSpellReason.RADIUS
	elif radius > settings.upgrade_settings.LIMIT_r:
		return DisallowSpellReason.RADIUS
		
	if not settings.upgrade_settings.check_if_has_spell_element(spell.element):
		return DisallowSpellReason.ELEMENT
		
	if spell.actual_mana_cost() > settings.upgrade_settings.max_mana() + settings.upgrade_settings.buff_mana:
		return DisallowSpellReason.MANA
		
	if spell.can_cast_chain():
		var chain_issue := can_use_spell(spell.chain)
		if chain_issue != DisallowSpellReason.NONE:
			return DisallowSpellReason.CHAINED_SPELL
		
	return DisallowSpellReason.NONE
	
func can_use_spell_with_name(n: String) -> DisallowSpellReason:
	var s := find_spell(n)
	if s != null:
		return can_use_spell(s)
	return DisallowSpellReason.ACTIVE

func rebuild_spell_chain(spell: Spell) -> Array[Spell]:
	var updated_spells: Array[Spell] = []
	for s in spells:
		if s.chain != null and s.chain.name == spell.name:
			updated_spells.append(s)
			if s.configuration_parameters_for_chain.is_empty():
				s.chain = spell
			else:
				s.chain = spell.duplicate()
				s.chain.configure_using_parameter_collection(s.configuration_parameters_for_chain, s.global_constant_variables())
	return updated_spells

func rebuild_spell_chains() -> void:
	for s in spells:
		if s.chain != null:
			for t in spells:
				if s.chain.name == t.name:
					if s.configuration_parameters_for_chain.is_empty():
						s.chain = t
					else:
						s.chain = t.duplicate()
						s.chain.configure_using_parameter_collection(s.configuration_parameters_for_chain, s.global_constant_variables())
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
 		
func update_spell_cooldowns(delta: float) -> void:
	var to_remove_from_map: Array[String] = []
	for s: String in cooldown:
		cooldown[s] = (cooldown[s] as float) - delta
		if cooldown[s] < 0.0:
			to_remove_from_map.append(s)
			
	for s in to_remove_from_map:
		cooldown.erase(s)
			
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
		if text[sidx] in "\n\t,":
			break
		sidx -= 1
	sidx += 1
	
	if not text.is_empty():
		while sidx < text.length() and text[sidx] == " ":
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
		for p: String in ["element", "CD", "CR", "name"]:
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
	var complete_has_spaces := complete.contains(" ")
		
	var fidx := edit.caret_column
	if fidx == text.length():
		fidx -= 1
	while fidx < text.length():
		if text[fidx] in "\n\t,()" or (not complete_has_spaces and text[fidx] == " "):
			break
		fidx += 1

	if fidx < edit.caret_column:
		pass
	edit.delete_text(edit.caret_column, fidx)
	edit.insert_text_at_caret(suffix)
	edit.select(eidx, eidx + suffix.length())
	
	return edit.text
	
	
	
	
