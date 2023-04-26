class_name WandCase

var wands: Array

func save():
	var file = FileAccess.open("user://wand_case.json", FileAccess.WRITE)
	var data = []
	for w in wands:
		data.append(w.save_dict())
	file.store_var(data)
	
func load():
	var file = FileAccess.open("user://wand_case.json", FileAccess.READ)
	if not file:
		wands = []
		return 
	var data = file.get_var()
	if data == null:
		wands = []
		return
	for d in data:
		var w = Wand.new()
		w.load_dict(d)
		wands.append(w)
	
func _init():
	wands = []
	
func add(wand: Spell):
	wands.append(wand)
	
func remove(i: int):
	wands.remove_at(i)
