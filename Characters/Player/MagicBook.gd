class_name MagicBook

var spells: Array[Spell]
var last_use: Dictionary # [String: Unix.Time]
var ignore_cooldown: bool
enum DisallowSpellReason { NONE, COOLDOWN, MANA, COUNT, POWER, DURATION, ACTIVE }

var settings: WorldSettings # set by the world

func save(world_name: String):
	save_absolute_path("user://worlds/%s/magic_book.json" % (world_name))
	
func save_absolute_path(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	var data = []
	for s in spells:
		data.append(s.save_dict())
	file.store_var(data)
	
func read(world_name: String):
	read_absolute_path("user://worlds/%s/magic_book.json" % (world_name))
		
func read_absolute_path(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	last_use = {}
	ignore_cooldown = false
	if not file:
		spells = []
		return 
	var data = file.get_var()
	if data == null:
		spells = []
		return
	var active_count := 0
	for d in data:
		var s = Spell.new()
		s.load_dict(d)
		s.limit_r = settings.upgrade_settings.max_r
		s.limit_v = settings.upgrade_settings.max_v
		if s.is_active:
			active_count += 1
		s.is_active = s.is_active and active_count < settings.upgrade_settings.max_spells_in_book
		spells.append(s)
	
func _init():
	spells = []
	last_use = {}
	ignore_cooldown = false
	settings = null
	
func reset_by_deleting_all_spells():
	spells = []
	last_use = {}
	
func add(spell: Spell):
	var active_count := 0
	for s in spells:
		if s.is_active:
			active_count += 1
	spell.is_active = active_count < settings.upgrade_settings.max_spells_in_book
	spells.append(spell)
	
func remove(i: int):
	spells.remove_at(i)

func use_spell(spell: Spell):
	var t = Time.get_unix_time_from_system()
	last_use[spell.name] = t
	var s = spell.chain
	while s != null:
		last_use[s.name] = t
		s = s.chain
	
func can_use_spell(spell: Spell) -> DisallowSpellReason:
	if not spell.is_active:
		return DisallowSpellReason.ACTIVE
	
	var elapsed = Time.get_unix_time_from_system() - last_use.get(spell.name, 0)
	if elapsed < spell.cooldown and not ignore_cooldown:
		return DisallowSpellReason.COOLDOWN
		
	if spell.count > settings.upgrade_settings.max_N + settings.upgrade_settings.buff_N:
		return DisallowSpellReason.COUNT
	elif spell.count > settings.upgrade_settings.LIMIT_N:
		return DisallowSpellReason.COUNT
		
	if spell.duration > settings.upgrade_settings.max_T + settings.upgrade_settings.buff_T:
		return DisallowSpellReason.DURATION
	elif spell.duration > settings.upgrade_settings.LIMIT_T:
		return DisallowSpellReason.DURATION
		
	if spell.power > settings.upgrade_settings.max_P + settings.upgrade_settings.buff_P:
		return DisallowSpellReason.POWER
	elif spell.power > settings.upgrade_settings.LIMIT_P:
		return DisallowSpellReason.POWER
		
	if spell.actual_mana_cost() > settings.upgrade_settings.max_mana + settings.upgrade_settings.buff_mana:
		return DisallowSpellReason.MANA
		
	return DisallowSpellReason.NONE

func rebuild_spell_chains():
	for s in spells:
		if s.chain != null:
			for t in spells:
				if s.chain.name == t.name:
					s.chain = t
					break
			
func update_spell_limits(v: float, r: float):
	for s in spells:
		s.limit_v = v
		s.limit_r = r
		
func update_spell_buff_limits(v: float, r: float):
	for s in spells:
		s.buff_v = v
		s.buff_r = r

func spell_exists(n: String) -> bool:
	for s in spells:
		if s.name == n:
			return true
	return false
	
func spell_with_name(n: String, constants: Dictionary = {}, duplicate: bool = false) -> Spell:
	for s in spells:
		if s.name == n:
			if not constants.is_empty() or duplicate:
				var result := s.duplicate()
				result.overwrite_expressions(constants)
				return result
			return s
	return null

func autocomplete(old_text: String, edit: LineEdit, suggest_only_active: bool) -> String:
	var text := edit.text
	if old_text.length() > text.length():
		return text
	var eidx := edit.caret_column
	var sidx := edit.caret_column
	if sidx == text.length():
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
	for s in spells:
		if (s.is_active or not suggest_only_active) and s.name.begins_with(prefix):
			complete = s.name
			break
			
	if complete.is_empty():
		return text
		
	var suffix := complete.substr(eidx - sidx, complete.length() - (eidx - sidx))
		
	edit.insert_text_at_caret(suffix)
	edit.select(eidx, eidx + suffix.length())
	
	return edit.text
	
	
	
	
