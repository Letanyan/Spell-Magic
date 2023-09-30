class_name MagicBook

var spells: Array[Spell]
var last_use: Dictionary
var ignore_cooldown: bool
enum DisallowSpellReason { NONE, COOLDOWN, MANA, COUNT, POWER, DURATION }

var settings: WorldSettings # set by the world

func save(world_name: String):
	var file = FileAccess.open("user://worlds/%s/magic_book.json" % (world_name), FileAccess.WRITE)
	var data = []
	for s in spells:
		data.append(s.save_dict())
	file.store_var(data)
	
func read(world_name: String):
	var file = FileAccess.open("user://worlds/%s/magic_book.json" % (world_name), FileAccess.READ)
	last_use = {}
	ignore_cooldown = false
	if not file:
		spells = []
		return 
	var data = file.get_var()
	if data == null:
		spells = []
		return
	for d in data:
		var s = Spell.new()
		s.load_dict(d)
		s.limit_r = settings.max_r
		s.limit_v = settings.max_v
		spells.append(s)
	
func _init():
	spells = []
	last_use = {}
	ignore_cooldown = false
	settings = null
	
func add(spell: Spell):
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
	var elapsed = Time.get_unix_time_from_system() - last_use.get(spell.name, 0)
	if elapsed < spell.cooldown and not ignore_cooldown:
		return DisallowSpellReason.COOLDOWN
		
	if spell.count > settings.max_N + settings.buff_N:
		return DisallowSpellReason.COUNT
	elif spell.count > settings.LIMIT_N:
		return DisallowSpellReason.COUNT
		
	if spell.duration > settings.max_T + settings.buff_T:
		return DisallowSpellReason.DURATION
	elif spell.duration > settings.LIMIT_T:
		return DisallowSpellReason.DURATION
		
	if spell.power > settings.max_P + settings.buff_P:
		return DisallowSpellReason.POWER
	elif spell.power > settings.LIMIT_P:
		return DisallowSpellReason.POWER
		
	if spell.actual_mana_cost() > settings.max_mana + settings.buff_mana:
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
