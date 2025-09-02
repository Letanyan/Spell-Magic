class_name WandCase

var play_mode_wands: Array[Wand]
var selected_play_wand: int
var build_mode_wands: Array[Wand]
var selected_build_wand: int
var is_build_mode: bool = false

var wands: Array[Wand]:
	set(value):
		if is_build_mode:
			build_mode_wands = value
		else:
			play_mode_wands = value
	get:
		return build_mode_wands if is_build_mode else play_mode_wands
		
var selected_wand: int:
	set(value):
		if is_build_mode:
			selected_build_wand = value
		else:
			selected_play_wand = value
	get:
		return selected_build_wand if is_build_mode else selected_play_wand

func save(world_name: String) -> void:
	var file := FileAccess.open("user://worlds/%s/wand_case.json" % (world_name), FileAccess.WRITE)
	var play_data := []
	for w: Wand in play_mode_wands:
		play_data.append(w.save_dict())
	var build_data := []
	for w: Wand in build_mode_wands:
		build_data.append(w.save_dict())
	file.store_var({"wands": play_data, "selected": selected_play_wand, "build_mode_wands": build_data, "selected_build_wand": selected_build_wand})
	file.close()
	
func read(world_name: String, book: MagicBook) -> bool:
	var file := FileAccess.open("user://worlds/%s/wand_case.json" % (world_name), FileAccess.READ)
	if not file:
		play_mode_wands = [Wand.basic()]
		build_mode_wands = [Wand.basic()]
		selected_play_wand = 0
		selected_build_wand = 0
		return false
	var data := file.get_var() as Dictionary
	if data == null:
		play_mode_wands = [Wand.basic()]
		build_mode_wands = [Wand.basic()]
		selected_play_wand = 0
		selected_build_wand = 0
		return false
	for d: Dictionary in data["wands"]:
		var w := Wand.new()
		w.load_dict(d, book)
		play_mode_wands.append(w)
	for d: Dictionary in data.get("build_mode_wands", []):
		var w := Wand.new()
		w.load_dict(d, book)
		build_mode_wands.append(w)
	selected_play_wand = data["selected"]
	selected_build_wand = data.get("selected_build_wand", 0)
	return true
	
func _init() -> void:
	play_mode_wands = []
	build_mode_wands = []
	
func reset_by_deleting_all_wands() -> void:
	play_mode_wands = [Wand.basic()]
	selected_play_wand = 0
	
func reset_by_setting_is_for_user(book: MagicBook) -> void:
	play_mode_wands.clear()
	selected_play_wand = 0
	for wand in build_mode_wands:
		if not wand.is_for_user:
			continue
		var w := Wand.new()
		w.load_dict(wand.save_dict(), book)
		play_mode_wands.append(w)
	if play_mode_wands.is_empty():
		play_mode_wands.append(Wand.basic())
	
func add(wand: Spell) -> void:
	if is_build_mode:
		build_mode_wands.append(wand)
	else:
		play_mode_wands.append(wand)
	
func remove(i: int) -> void:
	if is_build_mode:
		build_mode_wands.remove_at(i)
	else:
		play_mode_wands.remove_at(i)

func current_wand() -> Wand:
	return build_mode_wands[selected_build_wand] if is_build_mode else play_mode_wands[selected_play_wand]

func spell_was_updated(spell: Spell) -> void:
	for wand: Wand in build_mode_wands if is_build_mode else play_mode_wands:
		wand.spell_was_updated(spell)
