class_name WandCase

var wands: Array
var selected_wand: int

func save():
	var file = FileAccess.open("user://wand_case.json", FileAccess.WRITE)
	var data = []
	for w in wands:
		data.append(w.save_dict())
	file.store_var({"wands": data, "selected": selected_wand})
	
func load():
	var file = FileAccess.open("user://wand_case.json", FileAccess.READ)
	if not file:
		wands = [Wand.basic()]
		selected_wand = 0
		return 
	var data = file.get_var()
	if data == null:
		wands = [Wand.basic()]
		selected_wand = 0
		return
	for d in data["wands"]:
		var w = Wand.new()
		w.load_dict(d)
		wands.append(w)
	selected_wand = data["selected"]
	
func _init():
	wands = []
	
func add(wand: Spell):
	wands.append(wand)
	
func remove(i: int):
	wands.remove_at(i)
