class_name MagicBook

var spells: Array
var last_use: Dictionary
var ignore_cooldown: bool

func save():
	var file = FileAccess.open("user://magic_book.json", FileAccess.WRITE)
	var data = []
	for s in spells:
		data.append(s.save_dict())
	file.store_var(data)
	
func load():
	var file = FileAccess.open("user://magic_book.json", FileAccess.READ)
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
		spells.append(s)
	
func _init():
	spells = []
	last_use = {}
	ignore_cooldown = false
	
func add(spell: Spell):
	spells.append(spell)
	
func remove(i: int):
	spells.remove_at(i)

func use_spell(spell: Spell):
	last_use[spell.name] = Time.get_unix_time_from_system()
	
func can_use_spell(spell: Spell) -> bool:
	var used = last_use.get(spell.name, 0)
	return Time.get_unix_time_from_system() - used > spell.cooldown or ignore_cooldown
