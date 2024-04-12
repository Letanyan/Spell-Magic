class_name MagicPage
extends Control

@onready var name_edit: LineEdit = $container/name_edit

@onready var x_edit: LineEdit = $container/x_edit
@onready var y_edit: LineEdit = $container/y_edit
@onready var z_edit: LineEdit = $container/z_edit
@onready var r_edit: LineEdit = $container/r_edit

@onready var power_edit: LineEdit = $container/power_edit
@onready var duration_edit: LineEdit = $container/duration_edit
@onready var delay_edit: LineEdit = $container/delay_edit
@onready var count_edit: LineEdit = $container/count_edit

@onready var element_combo: OptionButton = $container/element_combo
@onready var chain_edit: LineEdit = $container/chain_edit
@onready var chain_combo: OptionButton = $container/chain_combo
@onready var is_rel: CheckButton = $container/is_rel
@onready var is_bomb: CheckButton = $container/is_bomb
@onready var player_is_origin: CheckButton = $container/player_is_origin
@onready var expressions: TextEdit = $container/expressions

@onready var mana_edit: LineEdit = $container/mana_edit
@onready var cooldown_label: Label = $container/cooldown
@onready var mana_cost: Label = $container/mana_cost

@onready var error_label: Label = $container/error_label

@onready var duplicate_button: Button = $container/Duplicate
@onready var delete_button: Button = $container/Delete


var errors_list := {}

var book: MagicBook
var current_index := -1
var old_chain_text: String = ""

signal spell_name_changed(new_text: String)
signal request_to_view_spell(spell_name: String)
signal delete_spell(index: int)
signal duplicate_spell(index: int)
signal return_focus

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func display_spell(magic_book: MagicBook, spell: Spell, index: int):
	book = magic_book
	current_index = index
	
	for i in range(Spell.Element.size()):
		element_combo.set_item_disabled(i, not book.settings.upgrade_settings.check_if_has_spell_element(Spell.Element.values()[i]))
	for i in range(Spell.ChainCastKind.size()):
		chain_combo.set_item_disabled(i, not book.settings.upgrade_settings.check_if_has_chain_method(Spell.ChainCastKind.values()[i]))
	
	name_edit.text = spell.name
	
	x_edit.text = spell.x
	y_edit.text = spell.y
	z_edit.text = spell.z
	r_edit.text = "%.2f" % spell.radius
	
	power_edit.text = "%d" % spell.power
	duration_edit.text = "%.2f" % spell.duration
	delay_edit.text = spell.delay
	count_edit.text = "%d" % spell.count
	mana_edit.text = "%.2f" % spell.mana_cost
	update_cooldown()
	
	element_combo.selected = spell.element
	chain_edit.text = spell.chain.name if spell.chain else ""
	old_chain_text = chain_edit.text
	chain_combo.selected = spell.chain_cast_kind
	is_rel.button_pressed = spell.follow
	is_bomb.button_pressed = spell.is_bomb
	player_is_origin.button_pressed = spell.player_is_origin
	
	expressions.text = ""
	for n in spell.expression_strings:
		expressions.text += "%s = %s\n" % [n, spell.expression_strings[n]]
		
	if index < 0:
		name_edit.editable = false
		x_edit.editable = false
		y_edit.editable = false
		z_edit.editable = false
		r_edit.editable = false
		power_edit.editable = false
		duration_edit.editable = false
		delay_edit.editable = false
		count_edit.editable = false
		mana_edit.editable = false
		element_combo.disabled = true
		chain_edit.editable = false
		chain_combo.disabled = true
		is_rel.disabled = true
		is_bomb.disabled = true
		player_is_origin.disabled = true
		expressions.editable = false
		$container/Delete.disabled = true
		$container/view_chain_button.disabled = true
		$container/Duplicate.disabled = true
		
	check_all_errors()
		
func update_cooldown():
	if current_index < 0:
		return
	book.spells[current_index].calculate_cooldown()
	cooldown_label.text = "Cooldown: " + ("%.2f" % book.spells[current_index].cooldown) + "s"
	if book.spells[current_index].chain != null:
		mana_cost.text = "Total (Inc. chain): " + ("%.2f" % book.spells[current_index].actual_mana_cost())
	else:
		mana_cost.text = ""
	
func _on_name_edit_text_changed(new_text):
	if current_index < 0:
		return
	book.spells[current_index].name = new_text
	spell_name_changed.emit(new_text)
	
func _on_element_combo_selected(index):
	if current_index < 0:
		return
	book.spells[current_index].element = index as Spell.Element
	update_cooldown()
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
		errors_list["x"] = e.error
	else:
		errors_list.erase("x")
	update_spells_that_chain_to_current_spell()

func _on_y_text_changed(new_text):
	if current_index < 0:
		return
	book.spells[current_index].y = new_text
	var e := Expr.new(new_text)
	book.spells[current_index].y_expr = e
	if e.error.length() > 0:
		errors_list["y"] = e.error
	else:
		errors_list.erase("y")
	update_spells_that_chain_to_current_spell()

func _on_z_text_changed(new_text):
	if current_index < 0:
		return
	book.spells[current_index].z = new_text
	var e := Expr.new(new_text)
	book.spells[current_index].z_expr = e
	if e.error.length() > 0:
		errors_list["z"] = e.error
	else:
		errors_list.erase("z")
	update_spells_that_chain_to_current_spell()

func _on_r_text_changed(new_text: String):
	if current_index < 0:
		return
	if not new_text.is_valid_float():
		errors_list["r"] = "'%s' is not a valid number" % new_text
	else:
		errors_list.erase("r")
	var raw: float = new_text.to_float()
	book.spells[current_index].radius = raw
	if raw > book.settings.upgrade_settings.max_r + book.settings.upgrade_settings.buff_r:
		errors_list["r"] = "Value of %d exceeds maximum of %d" % [raw, book.settings.upgrade_settings.max_r + book.settings.upgrade_settings.buff_r]
	else:
		errors_list.erase("r")
	update_cooldown()
	update_spells_that_chain_to_current_spell()

func _on_N_text_changed(new_text: String):
	if current_index < 0:
		return
	if not new_text.is_valid_int():
		errors_list["N"] = "'%s' is not a valid number" % new_text
	else:
		errors_list.erase("N")
	var raw: int = new_text.to_int()
	book.spells[current_index].count = raw
	if raw > book.settings.upgrade_settings.max_N + book.settings.upgrade_settings.buff_N:
		errors_list["N"] = "Value of %d exceeds maximum of %d" % [raw, book.settings.upgrade_settings.max_N + book.settings.upgrade_settings.buff_N]
	else:
		errors_list.erase("N")
	update_cooldown()
	update_spells_that_chain_to_current_spell()

func _on_P_text_changed(new_text: String):
	if current_index < 0:
		return
	if not new_text.is_valid_float():
		errors_list["P"] = "'%s' is not a valid number" % new_text
	else:
		errors_list.erase("P")
	var raw: float = new_text.to_float()
	book.spells[current_index].power = raw
	if raw > book.settings.upgrade_settings.max_P + book.settings.upgrade_settings.buff_P:
		errors_list["P"] = "Value of %d exceeds maximum of %d" % [raw, book.settings.upgrade_settings.max_P + book.settings.upgrade_settings.buff_P]
	else:
		errors_list.erase("P")
	update_cooldown()
	update_spells_that_chain_to_current_spell()

func _on_T_text_changed(new_text: String):
	if current_index < 0:
		return
	if not new_text.is_valid_float():
		errors_list["T"] = "'%s' is not a valid number" % new_text
	else:
		errors_list.erase("T")
	var raw: float = new_text.to_float()
	book.spells[current_index].duration = raw
	if raw > book.settings.upgrade_settings.max_T + book.settings.upgrade_settings.buff_T:
		errors_list["T"] = "Value of %.2fs exceeds maximum of %.2fs" % [raw, book.settings.upgrade_settings.max_T + book.settings.upgrade_settings.buff_T]
	else:
		errors_list.erase("T")
	update_cooldown()
	update_spells_that_chain_to_current_spell()

func _on_D_text_changed(new_text: String):
	if current_index < 0:
		return
	book.spells[current_index].delay = new_text
	var e := Expr.new(new_text)
	book.spells[current_index].d_expr = e
	if e.error.length() > 0:
		errors_list["D"] = e.error
	else:
		errors_list.erase("D")
	update_spells_that_chain_to_current_spell()

func _on_chain_text_changed(new_text: String):
	if current_index < 0:
		return
	var spell: Spell = book.spells[current_index]
	
	var n: String = book.autocomplete(old_chain_text, chain_edit, false)
	
	if n == "":
		spell.chain = null
	elif n != spell.name:
		spell.chain = null
		for s in book.spells:
			if s.name == n:
				spell.chain = s
		if spell.chain == null:
			errors_list["chain"] = "'%s' does not exists" % n
		else:
			errors_list.erase("chain")
				
	old_chain_text = n
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
	
func _on_player_is_origin_toggled(button_pressed):
	if current_index < 0:
		return
	book.spells[current_index].player_is_origin = button_pressed
	update_spells_that_chain_to_current_spell()
	
func _on_M_text_changed(new_text):
	if current_index < 0:
		return
	if not new_text.is_valid_float():
		errors_list["M"] = "'%s' is not a valid number" % new_text
	else:
		errors_list.erase("M")
	var raw: float = new_text.to_float()
	book.spells[current_index].mana_cost = raw
	if raw > book.settings.upgrade_settings.max_mana + book.settings.upgrade_settings.buff_mana:
		errors_list["M"] = "Value of %ds exceeds maximum of %ds" % [raw, book.settings.upgrade_settings.max_mana + book.settings.upgrade_settings.buff_mana]
	else:
		errors_list.erase("M")
	update_cooldown()
	update_spells_that_chain_to_current_spell()
	
func update_spells_that_chain_to_current_spell():
	if current_index < 0:
		return
	if not errors_list.is_empty():
		var last_error : String = errors_list.values()[errors_list.size() - 1]
		var last_key : String = errors_list.keys()[errors_list.size() - 1]
		error_label.text = "%s: %s" % [last_key, last_error]
	else:
		error_label.text = ""
	book.rebuild_spell_chains()
	
func _on_view_chain_button_pressed():
	var n := chain_edit.text
	if n == "":
		return
	else:
		request_to_view_spell.emit(n)
		
func _on_constants_text_changed() -> void:
	if current_index < 0:
		return
	
	var result := {}
	var text: String = expressions.text
	var definitions = text.split("\n", false)
	for def in definitions:
		var atoms = def.split("=", false)
		if atoms.size() == 2:
			result[atoms[0].strip_edges()] = atoms[1].strip_edges()
	
	book.spells[current_index].expression_strings = result
	book.spells[current_index].build_expressions()
	
	for k in book.spells[current_index].expressions:
		var e: Expr = book.spells[current_index].expressions[k]
		if e.error.length() > 0:
			errors_list["constant " + k] = e.error
		else:
			errors_list.erase("constant " + k)
	
	update_cooldown()
	update_spells_that_chain_to_current_spell()

func check_all_errors():
	errors_list.clear()
	
	var e := Expr.new(x_edit.text)
	if e.error.length() > 0:
		errors_list["x"] = e.error
	e = Expr.new(y_edit.text)
	if e.error.length() > 0:
		errors_list["y"] = e.error
	e = Expr.new(z_edit.text)
	if e.error.length() > 0:
		errors_list["z"] = e.error
	e = Expr.new(delay_edit.text)
	if e.error.length() > 0:
		errors_list["D"] = e.error
		
	var text := r_edit.text
	if not text.is_valid_float():
		errors_list["r"] = "'%s' is not a valid number" % text
	var raw: float = text.to_float()
	if raw > book.settings.upgrade_settings.max_r + book.settings.upgrade_settings.buff_r:
		errors_list["r"] = "Value of %d exceeds maximum of %d" % [raw, book.settings.upgrade_settings.max_r + book.settings.upgrade_settings.buff_r]
		
	text = power_edit.text
	if not text.is_valid_float():
		errors_list["P"] = "'%s' is not a valid number" % text
	raw = text.to_float()
	if raw > book.settings.upgrade_settings.max_P + book.settings.upgrade_settings.buff_P:
		errors_list["P"] = "Value of %d exceeds maximum of %d" % [raw, book.settings.upgrade_settings.max_P + book.settings.upgrade_settings.buff_P]
		
	text = duration_edit.text
	if not text.is_valid_float():
		errors_list["T"] = "'%s' is not a valid number" % text
	raw = text.to_float()
	if raw > book.settings.upgrade_settings.max_T + book.settings.upgrade_settings.buff_T:
		errors_list["T"] = "Value of %.2f exceeds maximum of %.2f" % [raw, book.settings.upgrade_settings.max_T + book.settings.upgrade_settings.buff_T]
		
	text = count_edit.text
	if not text.is_valid_float():
		errors_list["N"] = "'%s' is not a valid number" % text
	raw = text.to_float()
	if raw > book.settings.upgrade_settings.max_N + book.settings.upgrade_settings.buff_N:
		errors_list["N"] = "Value of %d exceeds maximum of %d" % [raw, book.settings.upgrade_settings.max_N + book.settings.upgrade_settings.buff_N]
		
	text = mana_edit.text
	if not text.is_valid_float():
		errors_list["M"] = "'%s' is not a valid number" % text
	raw = text.to_float()
	if raw > book.settings.upgrade_settings.max_mana + book.settings.upgrade_settings.buff_mana:
		errors_list["M"] = "Value of %.2f exceeds maximum of %.2f" % [raw, book.settings.upgrade_settings.max_mana + book.settings.upgrade_settings.buff_mana]
		
	text = chain_edit.text
	if not text.is_empty():
		var found := false
		for s in book.spells:
			if s.name == text:
				found = true
				break
		if not found:
			errors_list["chain"] = "'%s' does not exists" % text
			
	for k in book.spells[current_index].expressions:
		var expr: Expr = book.spells[current_index].expressions[k]
		if expr.error.length() > 0:
			errors_list["constant " + k] = expr.error
		else:
			errors_list.erase("constant " + k)
			
	if not errors_list.is_empty():
		var last_error : String = errors_list.values()[errors_list.size() - 1]
		var last_key : String = errors_list.keys()[errors_list.size() - 1]
		error_label.text = "%s: %s" % [last_key, last_error]
	else:
		error_label.text = ""
	

func _on_delete_pressed() -> void:
	if current_index < 0:
		return
		
	var s := book.spells[current_index]
	var popup := PopupDialog.display("Are you sure you want to delete the spell '" + s.name + "'")
	popup.confirmed.connect(func():
		if current_index < 0:
			return
		book.spells.remove_at(current_index)
		delete_spell.emit(current_index)
	)
	get_tree().root.add_child(popup)
	

func _on_duplicate_pressed() -> void:
	if current_index < 0:
		return
	duplicate_spell.emit(current_index)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
		
	var direction := VelocityMovement.get_input_strength("pan_left", "pan_right", "pan_forward", "pan_back")
	
	if name_edit.has_focus():
		if direction.x > 0:
			element_combo.grab_focus()
		if direction.y > 0:
			x_edit.grab_focus()
	elif element_combo.has_focus():
		if direction.x < 0:
			name_edit.grab_focus()
		if direction.y > 0:
			power_edit.grab_focus()
	elif x_edit.has_focus():
		if direction.x < 0:
			return_focus.emit()
		if direction.x > 0:
			duration_edit.grab_focus()
		if direction.y < 0:
			name_edit.grab_focus()
		if direction.y > 0:
			y_edit.grab_focus()
	elif y_edit.has_focus():
		if direction.x < 0:
			return_focus.emit()
		if direction.x > 0:
			delay_edit.grab_focus()
		if direction.y < 0:
			x_edit.grab_focus()
		if direction.y > 0:
			z_edit.grab_focus()
	elif z_edit.has_focus():
		if direction.x < 0:
			return_focus.emit()
		if direction.x > 0:
			count_edit.grab_focus()
		if direction.y < 0:
			y_edit.grab_focus()
		if direction.y > 0:
			r_edit.grab_focus()
	elif r_edit.has_focus():
		if direction.x < 0:
			return_focus.emit()
		if direction.x > 0:
			power_edit.grab_focus()
		if direction.y < 0:
			z_edit.grab_focus()
		if direction.y > 0:
			chain_edit.grab_focus()
	elif duration_edit.has_focus():
		if direction.x < 0:
			x_edit.emit()
		if direction.y < 0:
			name_edit.grab_focus()
		if direction.y > 0:
			delay_edit.grab_focus()
	elif delay_edit.has_focus():
		if direction.x < 0:
			y_edit.emit()
		if direction.y < 0:
			duration_edit.grab_focus()
		if direction.y > 0:
			count_edit.grab_focus()
	elif count_edit.has_focus():
		if direction.x < 0:
			z_edit.emit()
		if direction.y < 0:
			delay_edit.grab_focus()
		if direction.y > 0:
			power_edit.grab_focus()
	elif power_edit.has_focus():
		if direction.x < 0:
			r_edit.emit()
		if direction.y < 0:
			count_edit.grab_focus()
		if direction.y > 0:
			chain_combo.grab_focus()
	elif chain_edit.has_focus():
		if direction.x < 0:
			return_focus.emit()
		if direction.x > 0:
			expressions.grab_focus()
		if direction.y < 0:
			r_edit.grab_focus()
		if direction.y > 0:
			player_is_origin.grab_focus()
	elif chain_combo.has_focus():
		if direction.x < 0:
			chain_edit.emit()
		if direction.y < 0:
			power_edit.grab_focus()
		if direction.y > 0:
			expressions.grab_focus()
	elif player_is_origin.has_focus():
		if direction.x < 0:
			return_focus.emit()
		if direction.x > 0:
			expressions.grab_focus()
		if direction.y < 0:
			chain_edit.grab_focus()
		if direction.y > 0:
			is_bomb.grab_focus()
	elif is_bomb.has_focus():
		if direction.x < 0:
			return_focus.emit()
		if direction.x > 0:
			expressions.grab_focus()
		if direction.y < 0:
			player_is_origin.grab_focus()
		if direction.y > 0:
			is_rel.grab_focus()
	elif is_rel.has_focus():
		if direction.x < 0:
			return_focus.emit()
		if direction.x > 0:
			expressions.grab_focus()
		if direction.y < 0:
			is_bomb.grab_focus()
		if direction.y > 0:
			mana_edit.grab_focus()
	elif mana_edit.has_focus():
		if direction.x < 0:
			return_focus.emit()
		if direction.x > 0:
			expressions.grab_focus()
		if direction.y < 0:
			is_rel.grab_focus()
		if direction.y > 0:
			duplicate_button.grab_focus()
	elif expressions.has_focus():
		if direction.x < 0:
			player_is_origin.emit()
		if direction.y < 0:
			power_edit.grab_focus()
		if direction.y > 0:
			duplicate_button.grab_focus()
	elif duplicate_button.has_focus():
		if direction.x < 0:
			return_focus.emit()
		if direction.x > 0:
			delete_button.grab_focus()
		if direction.y < 0:
			mana_edit.grab_focus()
	elif delete_button.has_focus():
		if direction.x < 0:
			duplicate_button.emit()
		if direction.y < 0:
			expressions.grab_focus()

