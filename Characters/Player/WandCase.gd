class_name WandCase

var wands: Array[Wand]
var selected_wand: int

func save(world_name: String) -> void:
	var file := FileAccess.open("user://worlds/%s/wand_case.json" % (world_name), FileAccess.WRITE)
	var data := []
	for w: Wand in wands:
		data.append(w.save_dict())
	file.store_var({"wands": data, "selected": selected_wand})
	
func read(world_name: String) -> void:
	var file := FileAccess.open("user://worlds/%s/wand_case.json" % (world_name), FileAccess.READ)
	if not file:
		wands = [Wand.basic()]
		selected_wand = 0
		return 
	var data := file.get_var() as Dictionary
	if data == null:
		wands = [Wand.basic()]
		selected_wand = 0
		return
	for d: Dictionary in data["wands"]:
		var w := Wand.new()
		w.load_dict(d)
		wands.append(w)
	selected_wand = data["selected"]
	
func _init() -> void:
	wands = []
	
func reset_by_deleting_all_wands() -> void:
	wands = [Wand.basic()]
	
func add(wand: Spell) -> void:
	wands.append(wand)
	
func remove(i: int) -> void:
	wands.remove_at(i)
