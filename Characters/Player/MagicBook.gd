class_name MagicBook

var spells: Array

func save():
	var file = FileAccess.open("user://magic_book.json", FileAccess.WRITE)
	var data = []
	for s in spells:
		data.append(s.save_dict())
	file.store_var(data)
	
func load():
	var file = FileAccess.open("user://magic_book.json", FileAccess.READ)
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
	
func add(spell: Spell):
	spells.append(spell)
	
func remove(i: int):
	spells.remove_at(i)
