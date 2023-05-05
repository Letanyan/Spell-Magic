extends Control

@onready var spell_index: ItemList = $SpellIndex
var book: MagicBook:
	set(value):
		book = value
		reload_list()
		
		
@onready var name_edit: LineEdit = $container/name_edit

@onready var x_edit: LineEdit = $container/x/edit
@onready var y_edit: LineEdit = $container/y/edit
@onready var z_edit: LineEdit = $container/z/edit
@onready var r_edit: LineEdit = $container/r/edit

@onready var power_edit: LineEdit = $container/power/edit
@onready var duration_edit: LineEdit = $container/duration/edit
@onready var delay_edit: LineEdit = $container/delay/edit
@onready var count_edit: LineEdit = $container/count/edit

@onready var element_edit: LineEdit = $container/element/edit
@onready var chain_edit: LineEdit = $container/chain/edit
@onready var is_rel: CheckButton = $container/is_rel
@onready var is_bomb: CheckButton = $container/is_bomb

@onready var error_label: Label = $container/error_label

var current_index = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_spell_index_item_selected(index):
	var spell: Spell = book.spells[index]
	current_index = index
	
	name_edit.text = spell.name
	
	x_edit.text = spell.x
	y_edit.text = spell.y
	z_edit.text = spell.z
	r_edit.text = spell.r
	
	power_edit.text = "%f" % spell.power
	duration_edit.text = "%f" % spell.duration
	delay_edit.text = spell.delay
	count_edit.text = "%d" % spell.count
	
	element_edit.text = Spell.name_from_element(spell.element)
	chain_edit.text = spell.chain.name if spell.chain else ""
	is_rel.button_pressed = spell.is_relative_to_player_current_pos
	is_bomb.button_pressed = spell.is_bomb
	$container.visible = true


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
	spell.element = Spell.element_from_name(element_edit.text)
	
	spell.d_expr = Expr.new(spell.delay)
	
	var n = chain_edit.text
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
	
	spell.is_relative_to_player_current_pos = is_rel.button_pressed
	spell.is_bomb = is_bomb.button_pressed
	reload_list()
	
func reload_list():
	spell_index.clear()
	for s in book.spells:
		spell_index.add_item(s.name)
	
		
func _on_delete_pressed():
	if current_index < 0:
		return
	book.spells.remove_at(current_index)
	current_index = -1
	$container.visible = false
	reload_list()


func _on_create_pressed():
	var spell = Spell.new()
	spell.name = "New Spell"
	book.spells.append(spell)
	reload_list()
	_on_spell_index_item_selected(book.spells.size() - 1)
	name_edit.grab_focus()
	name_edit.select_all()


func _on_name_edit_text_changed(new_text):
	if current_index < 0:
		return
	book.spells[current_index].name = new_text
	reload_list()

func _on_element_text_changed(new_text):
	if current_index < 0:
		return
	book.spells[current_index].element = Spell.element_from_name(new_text)

func _on_x_text_changed(new_text):
	if current_index < 0:
		return
	book.spells[current_index].x = new_text
	var e = Expr.new(new_text)
	book.spells[current_index].x_expr = e
	print(e.error)
	if e.error.length() > 0:
		error_label.text = "x: " + e.error


func _on_y_text_changed(new_text):
	if current_index < 0:
		return
	book.spells[current_index].y = new_text
	var e = Expr.new(new_text)
	book.spells[current_index].y_expr = e
	if e.error.length() > 0:
		error_label.text = "y: " + e.error

func _on_z_text_changed(new_text):
	if current_index < 0:
		return
	book.spells[current_index].z = new_text
	var e = Expr.new(new_text)
	book.spells[current_index].z_expr = e
	if e.error.length() > 0:
		error_label.text = "z: " + e.error

func _on_r_text_changed(new_text):
	if current_index < 0:
		return
	book.spells[current_index].r = new_text
	var e = Expr.new(new_text)
	book.spells[current_index].r_expr = e
	if e.error.length() > 0:
		error_label.text = "r: " + e.error

func _on_N_text_changed(new_text):
	if current_index < 0:
		return
	book.spells[current_index].count = new_text.to_int()

func _on_P_text_changed(new_text):
	if current_index < 0:
		return
	book.spells[current_index].power = new_text.to_float()

func _on_T_text_changed(new_text):
	if current_index < 0:
		return
	book.spells[current_index].duration = new_text.to_float()

func _on_D_text_changed(new_text):
	if current_index < 0:
		return
	book.spells[current_index].delay = new_text
	var e = Expr.new(new_text)
	book.spells[current_index].d_expr = e
	if e.error.length() > 0:
		error_label.text = "D: " + e.error

func _on_chain_text_changed(new_text):
	if current_index < 0:
		return
	var spell = book.spells[current_index]
	
	var n = chain_edit.text
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

func _on_is_rel_toggled(button_pressed):
	if current_index < 0:
		return
	book.spells[current_index].is_relative_to_player_current_pos = button_pressed

func _on_is_bomb_toggled(button_pressed):
	if current_index < 0:
		return
	book.spells[current_index].is_bomb = button_pressed
