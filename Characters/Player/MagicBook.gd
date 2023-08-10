class_name MagicBook

var spells: Array[Spell]
var last_use: Dictionary
var ignore_cooldown: bool

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
	settings = null
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
	
func can_use_spell(spell: Spell) -> bool:
	var used = last_use.get(spell.name, 0)
	return Time.get_unix_time_from_system() - used > spell.cooldown or ignore_cooldown

func rebuild_spell_chains():
	for s in spells:
		if s.chain != null:
			for t in spells:
				if s.chain.name == t.name:
					s.chain = t
					break
			
