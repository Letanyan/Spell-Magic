extends Control

@onready var wand_index: ItemList = $WandIndex
var case: WandCase:
	set(value):
		case = value
		reload_list()

@onready var container: HFlowContainer = $panel/scroll/container
@onready var name_edit: LineEdit = $name

var current_index = -1

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
		var item = load("res://GUI/WandCaseShelfItem.tscn").instantiate()
		item.store_key = w
		item.store_action = wand.keys[w].kind
		item.store_spell = wand.keys[w].spell
		container.add_child(item)


func _on_save_pressed():
	if current_index < 0:
		return
	var wand: Wand = case.wands[current_index]
	
	wand.name = name_edit.text
	wand.keys.clear()
	for child in container.get_children():
		var c: WandCaseShelfItem = child
		var opt = Wand.Option.new()
		opt.spell = c.spell.text
		opt.kind = c.store_action as Wand.Kind
		if opt.kind == Wand.Kind.MOD:
			wand.mods.append(c.store_key)
		wand.keys[c.store_key] = opt
		
	reload_list()

func reload_list():
	wand_index.clear()
	for w in case.wands:
		wand_index.add_item(w.name)
	
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
