extends Control

@onready var wand_index: ItemList = $WandIndex
var case: WandCase:
	set(value):
		case = value
		current_index = value.selected_wand
		reload_list()

@onready var container: VBoxContainer = $panel/scroll/container
@onready var name_edit: LineEdit = $name

var current_index = -1
var use_current_wand: Callable
var book: MagicBook
var spell_errors := {}

signal new_wand_selected

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _on_wand_index_item_selected(index):
	var wand: Wand = case.wands[index]
	current_index = index
	
	name_edit.text = wand.name
	
	for c in container.get_children():
		container.remove_child(c)
		
	for w in wand.keys:
		var item = load("res://GUI/Pause Menu/WandCaseShelfItem.tscn").instantiate()
		item.store_key = w
		item.store_action = wand.keys[w].kind
		item.store_spell = wand.keys[w].spell
		
		item.spell_changed = func(text: String):
			var all_spells := text.split(",", false)
			var errors := []
			for i in range(all_spells.size()):
				var n := all_spells[i].lstrip(" \t\n\r").rstrip(" \t\n\r")
				if not book.spell_exists(n):
					errors.append(n)
				all_spells[i] = n
				
			if errors.is_empty():
				item.key.label_settings.font_color = Color.WHITE
				item.key.text = Wand.key_description(item.store_key)
			else:
				item.key.label_settings.font_color = Color.CRIMSON
				item.key.text = "Missing: " + ", ".join(errors)
			wand.keys[w].spell = all_spells
			wand.keys[w].spell_index = all_spells.size() - 1
			wand.spell_updated.emit()
		
		item.action_changed = func(from: Wand.Kind, to: Wand.Kind) -> bool:
			item.store_action = to
			wand.keys[w].kind = to
			wand.action_updated.emit()
			if to == Wand.Kind.MOD:
				wand.add_mod(w[0])
				_on_wand_index_item_selected(current_index)
				return true
			elif from == Wand.Kind.MOD:
				wand.remove_mod(w[0])
				_on_wand_index_item_selected(current_index)
				return true
			return false
			
		item.autocomplete = book.autocomplete
			
		container.add_child(item)

func reload_list():
	wand_index.clear()
	for w in case.wands:
		wand_index.add_item(w.name)
	if current_index > -1:
		_on_wand_index_item_selected(current_index)
	
func _on_delete_pressed():
	if current_index < 0:
		return
	case.wands.remove_at(current_index)
	reload_list()

func _on_create_pressed():
	var wand = Wand.new()
	wand.name = "New Wand"
	case.wands.append(wand)
	reload_list()
	_on_wand_index_item_selected(case.wands.size() - 1)


func _on_name_text_changed(new_text):
	if current_index < 0:
		return
	case.wands[current_index].name = new_text
	wand_index.set_item_text(current_index, new_text)


func _on_use_pressed():
	if current_index < 0:
		return
	case.selected_wand = current_index
	use_current_wand.call(current_index)
	new_wand_selected.emit(case.wands[current_index])
