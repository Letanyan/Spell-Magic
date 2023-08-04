class_name MagicBookGUI
extends Control

@onready var sort_button: MenuButton = $SortButton
const TOTAL_SORT_ITEMS = 7
var sort_popup: PopupMenu = null
var sort_selected: int = 0
var sort_order: int = 0
@onready var filter_button: MenuButton = $FilterButton
const TOTAL_FILTER_ITEMS = 10
var filter_popup: PopupMenu = null
var filter_options := {}
var filter_chain := ""

@onready var spell_index: ItemList = $SpellIndex
var book: MagicBook:
	set(value):
		book = value
		duplicate_book()
		update_spells_list()
		reload_list()

var spells_index_map := {}

@onready var create_button: Button = $Create
@onready var duplicate_button: Button = $Duplicate
		
@onready var name_edit: LineEdit = $container/name_edit

@onready var x_edit: LineEdit = $container/x/edit
@onready var y_edit: LineEdit = $container/y/edit
@onready var z_edit: LineEdit = $container/z/edit
@onready var r_edit: LineEdit = $container/r/edit

@onready var power_edit: LineEdit = $container/power/edit
@onready var duration_edit: LineEdit = $container/duration/edit
@onready var delay_edit: LineEdit = $container/delay/edit
@onready var count_edit: LineEdit = $container/count/edit

@onready var element_combo: OptionButton = $container/element_combo
@onready var chain_edit: LineEdit = $container/chain/edit
@onready var chain_combo: OptionButton = $container/chain_combo
@onready var is_rel: CheckButton = $container/is_rel
@onready var is_bomb: CheckButton = $container/is_bomb

@onready var mana_edit: LineEdit = $container/mana/edit
@onready var cooldown_label: Label = $container/cooldown

@onready var error_label: Label = $container/error_label

var current_index := -1

# Called when the node enters the scene tree for the first time.
func _ready():
	sort_popup = sort_button.get_popup()
	sort_popup.connect("id_pressed", sort_popup_selected)
	filter_popup = filter_button.get_popup()
	filter_popup.connect("id_pressed", filter_popup_selected)
	
	$container.visible = false
	
	
func duplicate_book():
	for i in book.spells.size():
		var s = book.spells[i].duplicate()
		book.spells[i] = s
		s.id = i

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_spell_index_item_selected(index):
	current_index = spells_index_map[index]
	var spell: Spell = book.spells[current_index]
	
	duplicate_button.disabled = index < 0
	
	name_edit.text = spell.name
	
	x_edit.text = spell.x
	y_edit.text = spell.y
	z_edit.text = spell.z
	r_edit.text = spell.r
	
	power_edit.text = "%.2f" % spell.power
	duration_edit.text = "%.2f" % spell.duration
	delay_edit.text = spell.delay
	count_edit.text = "%d" % spell.count
	mana_edit.text = "%.2f" % spell.mana_cost
	update_cooldown()
	
	element_combo.selected = spell.element
	chain_edit.text = spell.chain.name if spell.chain else ""
	chain_combo.selected = spell.chain_cast_kind
	is_rel.button_pressed = spell.follow
	is_bomb.button_pressed = spell.is_bomb
	$container.visible = true
	
	filter_popup.set_item_disabled(TOTAL_FILTER_ITEMS - 1, false)
	filter_popup.set_item_text(TOTAL_FILTER_ITEMS - 1, "Chains '" + spell.name + "'")


func _on_save_pressed():
	if current_index < 0:
		return
	var spell: Spell = book.spells[current_index]
	spell.name = name_edit.text
	spell.x = x_edit.text
	spell.y = y_edit.text
	spell.z = z_edit.text
	spell.r = r_edit.text
	
	spell.x_expr = Expr.new(spell.x)
	spell.y_expr = Expr.new(spell.y)
	spell.z_expr = Expr.new(spell.z)
	spell.r_expr = Expr.new(spell.r)
	
	spell.power = power_edit.text.to_float()
	spell.duration = duration_edit.text.to_float()
	spell.delay = delay_edit.text
	spell.count = count_edit.text.to_int()
	spell.element = element_combo.selected as Spell.Element
	
	spell.d_expr = Expr.new(spell.delay)
	
	var n := chain_edit.text
	if n == "":
		spell.chain = null
	elif n != spell.name:
		for s in book.spells:
			if s.name == n:
				spell.chain = s
				
	if spell.name != "":
		for s in book.spells:
			if s.chain != null and s.chain.name == spell.name and s.name != spell.name:
				s.chain = spell
	
	spell.follow = is_rel.button_pressed
	spell.is_bomb = is_bomb.button_pressed
	reload_list()
	
func update_spells_list():
	var spells_list := book.spells.duplicate(false)
	
	var is_ascending := sort_order == 0
	if sort_selected == 0:
		spells_list.sort_custom(func(a, b): return a.name < b.name if is_ascending else a.name > b.name)
	elif sort_selected == 1:
		spells_list.sort_custom(func(a, b): return a.duration < b.duration if is_ascending else a.duration > b.duration)
	elif sort_selected == 2:
		spells_list.sort_custom(func(a, b): return a.count < b.count if is_ascending else a.count > b.count)
	elif sort_selected == 3:
		spells_list.sort_custom(func(a, b): return a.power < b.power if is_ascending else a.power > b.power)
	elif sort_selected == 4:
		spells_list.sort_custom(func(a, b): return a.mana_cost < b.mana_cost if is_ascending else a.mana_cost > b.mana_cost)
	elif sort_selected == 5:
		spells_list.sort_custom(func(a, b): return a.cooldown < b.cooldown if is_ascending else a.cooldown > b.cooldown)
		
	spells_index_map = {}
	var k = 0
	for i in range(spells_list.size()):
		var spell: Spell = spells_list[i]
		var q0 := filter_options.is_empty()
		q0 = q0 or filter_options.get(0, false) and spell.element == Spell.Element.FIRE
		q0 = q0 or filter_options.get(1, false) and spell.element == Spell.Element.WATER
		q0 = q0 or filter_options.get(2, false) and spell.element == Spell.Element.AIR
		q0 = q0 or filter_options.get(3, false) and spell.element == Spell.Element.ROCK
		q0 = q0 or filter_options.get(4, false) and spell.element == Spell.Element.ICE
		q0 = q0 or filter_options.get(5, false) and spell.element == Spell.Element.ELECTRIC
		q0 = q0 or filter_options.get(6, false) and spell.element == Spell.Element.VOID
		q0 = q0 or filter_options.get(7, false) and spell.is_bomb
		q0 = q0 or filter_options.get(8, false) and spell.follow
		q0 = q0 or filter_options.get(9, false) and (spell.chain != null and spell.chain.name == filter_chain)
		if q0:
			spells_index_map[k] = spell.id
			k += 1
		
	create_button.disabled = k < book.spells.size()
	
func reload_list():
	spell_index.clear()
#	for s in book.spells:
#		spell_index.add_item(s.name)
	for k in spells_index_map:
		var s = book.spells[spells_index_map[k]]
		spell_index.add_item(s.name)
	
		
func _on_delete_pressed():
	if current_index < 0:
		return
	book.spells.remove_at(current_index)
	current_index = -1
	$container.visible = false
	update_spells_list()
	reload_list()

func add_spell(spell: Spell):
	spell.id = book.spells.size()
	book.spells.append(spell)
	update_spells_list()
	reload_list()
	var k_index := -1
	for k in spells_index_map:
		if spells_index_map[k] == spell.id:
			k_index = k
			break
	if k_index != -1:
		_on_spell_index_item_selected(k_index)
		spell_index.select(k_index, true)
		name_edit.grab_focus()
		name_edit.select_all()
		
func _on_create_pressed():
	var spell := Spell.new()
	spell.name = "New Spell"
	add_spell(spell)

func _on_duplicate_pressed():
	if current_index < 0:
		return
	var spell: Spell = book.spells[current_index].duplicate()
	spell.name += " (Copy)"
	add_spell(spell)

func _on_name_edit_text_changed(new_text):
	if current_index < 0:
		return
	book.spells[current_index].name = new_text
	reload_list()

func _on_element_combo_selected(index):
	if current_index < 0:
		return
	book.spells[current_index].element = index as Spell.Element
	update_spells_that_chain_to_current_spell()

func _on_chain_combo_selected(index):
	if current_index < 0:
		return
	book.spells[current_index].chain_cast_kind = index as Spell.ChainCastKind
	update_spells_that_chain_to_current_spell()

func _on_x_text_changed(new_text):
	if current_index < 0:
		return
	book.spells[current_index].x = new_text
	var e := Expr.new(new_text)
	book.spells[current_index].x_expr = e
	if e.error.length() > 0:
		error_label.text = "x: " + e.error
	else:
		error_label.text = ""
	update_spells_that_chain_to_current_spell()

func _on_y_text_changed(new_text):
	if current_index < 0:
		return
	book.spells[current_index].y = new_text
	var e := Expr.new(new_text)
	book.spells[current_index].y_expr = e
	if e.error.length() > 0:
		error_label.text = "y: " + e.error
	else:
		error_label.text = ""
	update_spells_that_chain_to_current_spell()

func _on_z_text_changed(new_text):
	if current_index < 0:
		return
	book.spells[current_index].z = new_text
	var e := Expr.new(new_text)
	book.spells[current_index].z_expr = e
	if e.error.length() > 0:
		error_label.text = "z: " + e.error
	else:
		error_label.text = ""
	update_spells_that_chain_to_current_spell()

func _on_r_text_changed(new_text):
	if current_index < 0:
		return
	book.spells[current_index].r = new_text
	var e := Expr.new(new_text)
	book.spells[current_index].r_expr = e
	if e.error.length() > 0:
		error_label.text = "r: " + e.error
	else:
		error_label.text = ""
	update_spells_that_chain_to_current_spell()

func _on_N_text_changed(new_text):
	if current_index < 0:
		return
	book.spells[current_index].count = clamp(new_text.to_int(), 1, 25)
	update_cooldown()
	update_spells_that_chain_to_current_spell()

func _on_P_text_changed(new_text):
	if current_index < 0:
		return
	book.spells[current_index].power = clamp(new_text.to_float(), 0.0, 100.0)
	update_cooldown()
	update_spells_that_chain_to_current_spell()

func _on_T_text_changed(new_text):
	if current_index < 0:
		return
	book.spells[current_index].duration = clamp(new_text.to_float(), 0.0166667, 25.0)
	update_cooldown()
	update_spells_that_chain_to_current_spell()

func _on_D_text_changed(new_text):
	if current_index < 0:
		return
	book.spells[current_index].delay = new_text
	var e := Expr.new(new_text)
	book.spells[current_index].d_expr = e
	if e.error.length() > 0:
		error_label.text = "D: " + e.error
	else:
		error_label.text = ""
	update_spells_that_chain_to_current_spell()

func _on_chain_text_changed(new_text):
	if current_index < 0:
		return
	var spell: Spell = book.spells[current_index]
	
	var n := chain_edit.text
	if n == "":
		spell.chain = null
	elif n != spell.name:
		for s in book.spells:
			if s.name == n:
				spell.chain = s
				
	update_cooldown()
	update_spells_that_chain_to_current_spell()

func _on_is_rel_toggled(button_pressed):
	if current_index < 0:
		return
	book.spells[current_index].follow = button_pressed
	update_spells_that_chain_to_current_spell()

func _on_is_bomb_toggled(button_pressed):
	if current_index < 0:
		return
	book.spells[current_index].is_bomb = button_pressed
	update_spells_that_chain_to_current_spell()
	
func _on_M_text_changed(new_text):
	if current_index < 0:
		return
	book.spells[current_index].mana_cost = clamp(new_text.to_float(), 0.0, 100.0)
	update_cooldown()
	update_spells_that_chain_to_current_spell()

func update_cooldown():
	if current_index < 0:
		return
	book.spells[current_index].calculate_cooldown()
	cooldown_label.text = "Cooldown: " + ("%.2f" % book.spells[current_index].cooldown) + "s"
	

func update_spells_that_chain_to_current_spell():
	if current_index < 0:
		return
	book.rebuild_spell_chains()

func _on_view_chain_button_pressed():
	var n := chain_edit.text
	if n == "":
		return
	else:
		var i := 0
		for s in book.spells:
			if s.name == n:
				_on_spell_index_item_selected(i)
				spell_index.select(i, true)
			i += 1

func sort_popup_selected(id: int):
	var is_order = id > TOTAL_SORT_ITEMS - 1
	if is_order:
		sort_order = id - TOTAL_SORT_ITEMS
		var other := (1 if sort_order == 0 else 0) + TOTAL_SORT_ITEMS
		sort_popup.set_item_checked(id, true)
		sort_popup.set_item_checked(other, false)
	else:
		for i in range(TOTAL_SORT_ITEMS):
			sort_popup.set_item_checked(i, false)
		sort_popup.set_item_checked(id, true)
		sort_selected = id
		
	update_spells_list()
	reload_list()
	
func filter_popup_selected(id: int):
	var is_selected := filter_options.has(id)
	if is_selected:
		filter_options.erase(id)
	else:
		filter_options[id] = true
	filter_popup.set_item_checked(id, not is_selected)
	if id == TOTAL_FILTER_ITEMS - 1 and current_index != -1:
		filter_chain = book.spells[current_index].name
		
	update_spells_list()
	reload_list()

