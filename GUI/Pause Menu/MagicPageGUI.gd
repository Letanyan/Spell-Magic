class_name MagicPage
extends Control

@onready var main_container: Panel = $container

@onready var name_edit: LineEdit = $container/name_edit
@onready var preview_image: Button = $container/preview_image
var preview_selector: Panel
var preview_selector_buttons: Array[Button] = []
var preview_images: Array[Texture2D] = []
#var next_thumbnail: Button
#var prev_thumbnail: Button
var flip_h_thumbnail: Button
var flip_v_thumbnail: Button
var rotate_cw_thumbnail: Button
var rotate_ccw_thumbnail: Button
#var next_position_thumbnail: Button
#var prev_position_thumbnail: Button

@onready var x_edit: LineEdit = $container/x_edit
@onready var y_edit: LineEdit = $container/y_edit
@onready var z_edit: LineEdit = $container/z_edit
@onready var r_edit: LineEdit = $container/r_edit
@onready var x_label: RichTextLabel = $container/x
@onready var y_label: RichTextLabel = $container/y
@onready var z_label: RichTextLabel = $container/z

@onready var power_edit: LineEdit = $container/power_edit
@onready var duration_edit: LineEdit = $container/duration_edit
@onready var delay_edit: LineEdit = $container/delay_edit
@onready var count_edit: LineEdit = $container/count_edit
@onready var cr_edit: LineEdit = $container/CR_edit
@onready var cd_edit: LineEdit = $container/CD_edit

@onready var element_combo: OptionButton = $container/element_combo
@onready var chain_edit: LineEdit = $container/chain_edit
@onready var chain_combo: OptionButton = $container/chain_combo
@onready var is_rel: CheckButton = $container/is_rel
@onready var is_bomb: CheckButton = $container/is_bomb
@onready var is_sphere: CheckButton = $container/is_sphere
@onready var player_is_origin: CheckButton = $container/player_is_origin
@onready var expressions: TextEdit = $container/expressions

@onready var mana_edit: LineEdit = $container/mana_edit
@onready var cooldown_label: RichTextLabel = $container/cooldown
@onready var mana_cost: Label = $container/mana_cost
@onready var element_application: RichTextLabel = $container/element_application

@onready var view_chain_button: Button = $container/view_chain_button 

@onready var error_label: Label = $container/error_label

@onready var duplicate_button: Button = $container/Duplicate
@onready var delete_button: Button = $container/Delete

var errors_list := {}

var book: MagicBook
var current_index := -1
var old_chain_text: String = ""
var selected_variables: Dictionary = {}
var constants_text_changed: bool = false # Used to avoid triggering expressions caret changed when text is changed
var selected_variables_origin_line := -1
var last_selected_variable := ""

signal spell_name_changed(new_text: String)
signal request_to_view_spell(spell_name: String)
signal delete_spell(index: int)
signal duplicate_spell(index: int)
signal return_focus

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if preview_selector == null:
		make_preview_selector()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func display_spell(magic_book: MagicBook, spell: Spell, index: int) -> void:
	book = magic_book
	current_index = index
	
	for i in range(Spell.Element.size()):
		element_combo.set_item_disabled(i, not book.settings.upgrade_settings.check_if_has_spell_element(Spell.Element.values()[i] as Spell.Element))
	for i in range(Spell.ChainCastKind.size()):
		chain_combo.set_item_disabled(i, not book.settings.upgrade_settings.check_if_has_chain_method(Spell.ChainCastKind.values()[i] as Spell.ChainCastKind))
	
	name_edit.text = spell.name
	var tint_color := Spell.color_from_element(spell.element)
	(preview_image.icon as TintedTexture).texture = preview_images[spell.preview_image]
	(preview_image.icon as TintedTexture).tint = tint_color
	(preview_image.icon as TintedTexture).flip_horizontal = spell.preview_is_horizontal_flip()
	(preview_image.icon as TintedTexture).flip_vertical = spell.preview_is_vertical_flip()
	(preview_image.icon as TintedTexture).rotation = spell.preview_rotation()
	for btn: Button in preview_selector_buttons:
		btn.set_pressed_no_signal(false)
		(btn.icon as TintedTexture).tint = tint_color
		(btn.icon as TintedTexture).flip_horizontal = spell.preview_is_horizontal_flip()
		(btn.icon as TintedTexture).flip_vertical = spell.preview_is_vertical_flip()
		(btn.icon as TintedTexture).rotation = spell.preview_rotation()
	preview_selector_buttons[spell.preview_image].set_pressed_no_signal(true)
	preview_image.set_pressed_no_signal(false)
	flip_h_thumbnail.set_pressed_no_signal(spell.preview_is_horizontal_flip())
	flip_v_thumbnail.set_pressed_no_signal(spell.preview_is_vertical_flip())
	preview_selector.hide()
	preview_image.queue_redraw()
	
	x_edit.text = spell.x
	y_edit.text = spell.y
	z_edit.text = spell.z
	r_edit.text = Globals.format_number_nearest_place(spell.radius)
		
	power_edit.text = "%d" % spell.power
	duration_edit.text = Globals.format_number_nearest_place(spell.duration)
	delay_edit.text = spell.delay
	count_edit.text = "%d" % spell.count
	mana_edit.text = Globals.format_number_nearest_place(spell.mana_cost)
	cr_edit.text = Globals.format_number_nearest_place(spell.crit_rate)
	cd_edit.text = Globals.format_number_nearest_place(spell.crit_dmg)
	update_cooldown()
	
	element_combo.selected = spell.element
	chain_edit.text = spell.chain.name if spell.chain else ""
	chain_edit.editable = book.settings.upgrade_settings.has_chain_method != 0
	old_chain_text = chain_edit.text
	chain_combo.selected = spell.chain_cast_kind
	is_rel.button_pressed = spell.follow
	is_bomb.button_pressed = spell.is_bomb
	is_sphere.button_pressed = spell.spherical_coords
	player_is_origin.button_pressed = spell.player_is_origin
	
	expressions.text = ""
	for n: String in spell.expression_strings:
		expressions.text += "%s = %s\n" % [n, spell.expression_strings[n]]
		
	var is_editable := index >= 0 and not book.settings.game_mode_settings.has_flag(GameModeSettings.DISALLOW_SPELL_EDITING)
	preview_image.disabled = not is_editable
	name_edit.editable = is_editable
	x_edit.editable = is_editable
	y_edit.editable = is_editable
	z_edit.editable = is_editable
	r_edit.editable = is_editable
	power_edit.editable = is_editable
	duration_edit.editable = is_editable
	delay_edit.editable = is_editable
	count_edit.editable = is_editable
	mana_edit.editable = is_editable
	element_combo.disabled = not is_editable
	chain_edit.editable = is_editable
	chain_combo.disabled = not is_editable
	is_rel.disabled = not is_editable
	is_bomb.disabled = not is_editable
	is_sphere.disabled = not is_editable
	player_is_origin.disabled = not is_editable
	expressions.editable = is_editable
	delete_button.disabled = not is_editable
	view_chain_button.disabled = not is_editable
	duplicate_button.disabled = not is_editable
	cr_edit.editable = is_editable
	cd_edit.editable = is_editable
		
	check_all_errors()
		
func update_cooldown() -> void:
	if current_index < 0:
		return
	book.spells[current_index].calculate_cooldown()
	
	cooldown_label.text = "[left][font_size=16][img=l,24x24]res://GUI/Images/watch.svg[/img] Cooldown: " + Globals.format_number_nearest_place(book.spells[current_index].cooldown) + "s[/font_size][/left]"
	element_application.text = book.spells[current_index].elemental_application_description()
	if book.spells[current_index].chain != null:
		mana_cost.text = "Total (Inc. chain): " + Globals.format_number_nearest_place(book.spells[current_index].actual_mana_cost())
	else:
		mana_cost.text = ""
	
func _on_preview_image_pressed() -> void:
	preview_selector.visible = preview_image.button_pressed
	
func _on_name_edit_text_changed(new_text: String) -> void:
	if current_index < 0:
		return
	var old_key := book.spells[current_index].name
	var old_value := book.spell_index[old_key] as Spell
	book.spell_index.erase(old_key)
	book.spell_index[new_text] = old_value
	book.spells[current_index].name = new_text
	for s in book.spells:
		if s.name == old_key:
			book.spell_index[s.name] = s
			break
	spell_name_changed.emit(new_text)
	
func _on_element_combo_selected(index: int) -> void:
	if current_index < 0:
		return
	book.spells[current_index].element = index as Spell.Element
	update_cooldown()
	update_spells_that_chain_to_current_spell()

func _on_chain_combo_selected(index: int) -> void:
	if current_index < 0:
		return
	book.spells[current_index].chain_cast_kind = index as Spell.ChainCastKind
	update_cooldown()
	update_spells_that_chain_to_current_spell()

func _on_x_text_changed(new_text: String) -> void:
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

func _on_y_text_changed(new_text: String) -> void:
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

func _on_z_text_changed(new_text: String) -> void:
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

func _on_r_text_changed(new_text: String) -> void:
	if current_index < 0:
		return
	if not new_text.is_valid_float():
		errors_list["r"] = "'%s' is not a valid number" % new_text
	else:
		errors_list.erase("r")
	var raw: float = new_text.to_float()
	book.spells[current_index].radius = raw
	if raw > book.settings.upgrade_settings.max_r() + book.settings.upgrade_settings.buff_r:
		errors_list["r"] = "Value of %.1f exceeds maximum of %.1f" % [raw, book.settings.upgrade_settings.max_r() + book.settings.upgrade_settings.buff_r]
	else:
		errors_list.erase("r")
	update_cooldown()
	update_spells_that_chain_to_current_spell()

func _on_N_text_changed(new_text: String) -> void:
	if current_index < 0:
		return
	if not new_text.is_valid_int():
		errors_list["N"] = "'%s' is not a valid number" % new_text
	else:
		errors_list.erase("N")
	var raw: int = new_text.to_int()
	book.spells[current_index].count = raw
	if raw > book.settings.upgrade_settings.max_N() + book.settings.upgrade_settings.buff_N:
		errors_list["N"] = "Value of %d exceeds maximum of %d" % [raw, book.settings.upgrade_settings.max_N() + book.settings.upgrade_settings.buff_N]
	else:
		errors_list.erase("N")
	update_cooldown()
	update_spells_that_chain_to_current_spell()

func _on_P_text_changed(new_text: String) -> void:
	if current_index < 0:
		return
	if not new_text.is_valid_float():
		errors_list["P"] = "'%s' is not a valid number" % new_text
	else:
		errors_list.erase("P")
	var raw: float = new_text.to_float()
	book.spells[current_index].power = raw
	if raw > book.settings.upgrade_settings.max_P() + book.settings.upgrade_settings.buff_P:
		errors_list["P"] = "Value of %d exceeds maximum of %d" % [raw, book.settings.upgrade_settings.max_P() + book.settings.upgrade_settings.buff_P]
	else:
		errors_list.erase("P")
	update_cooldown()
	update_spells_that_chain_to_current_spell()

func _on_T_text_changed(new_text: String) -> void:
	if current_index < 0:
		return
	if not new_text.is_valid_float():
		errors_list["T"] = "'%s' is not a valid number" % new_text
	else:
		errors_list.erase("T")
	var raw: float = new_text.to_float()
	book.spells[current_index].duration = raw
	if raw > book.settings.upgrade_settings.max_T() + book.settings.upgrade_settings.buff_T:
		errors_list["T"] = "Value of " + Globals.format_number_nearest_place(raw) + "s exceeds maximum of " + Globals.format_number_nearest_place(book.settings.upgrade_settings.max_T() + book.settings.upgrade_settings.buff_T) + "s"
	else:
		errors_list.erase("T")
	update_cooldown()
	update_spells_that_chain_to_current_spell()

func _on_D_text_changed(new_text: String) -> void:
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
	
func _on_cr_text_changed(new_text: String) -> void:
	if current_index < 0:
		return
	if not new_text.is_valid_float():
		errors_list["CR"] = "'%s' is not a valid number" % new_text
	else:
		errors_list.erase("CR")
	var raw: float = new_text.to_float()
	book.spells[current_index].crit_rate = raw
	update_cooldown()
	update_spells_that_chain_to_current_spell()

func _on_cd_text_changed(new_text: String) -> void:
	if current_index < 0:
		return
	if not new_text.is_valid_float():
		errors_list["CD"] = "'%s' is not a valid number" % new_text
	else:
		errors_list.erase("CD")
	var raw: float = new_text.to_float()
	book.spells[current_index].crit_dmg = raw
	update_cooldown()
	update_spells_that_chain_to_current_spell()

func _on_chain_text_changed(new_text: String) -> void:
	if current_index < 0:
		return
	var spell: Spell = book.spells[current_index]
	
	var n: String = book.autocomplete(old_chain_text, chain_edit, false, spell)
	
	if n == "":
		spell.chain = null
		errors_list.erase("chain")
	elif n == spell.name:
		errors_list["chain"] = "'%s' can not chain to itself" % n
	else:
		var problem_chain := book.find_recursive_spell_chain(spell, n)
		if not problem_chain.is_empty():
			var message := "'%s' can not exist in a recursive spell chain " % n
			for s in problem_chain:
				message += s + "->"
			errors_list["chain"] = message.trim_suffix("->")
		else:
			spell.chain = null
			for s in book.spells:
				if s.name == n:
					spell.chain = s
					break
			if spell.chain == null:
				errors_list["chain"] = "'%s' does not exists" % n
			else:
				errors_list.erase("chain")
				
	old_chain_text = n
	update_cooldown()
	update_spells_that_chain_to_current_spell()

func _on_is_rel_toggled(button_pressed: bool) -> void:
	if current_index < 0:
		return
	book.spells[current_index].follow = button_pressed
	update_spells_that_chain_to_current_spell()

func _on_is_bomb_toggled(button_pressed: bool) -> void:
	if current_index < 0:
		return
	book.spells[current_index].is_bomb = button_pressed
	update_spells_that_chain_to_current_spell()
	
func _on_player_is_origin_toggled(button_pressed: bool) -> void:
	if current_index < 0:
		return
	book.spells[current_index].player_is_origin = button_pressed
	update_spells_that_chain_to_current_spell()
	
func _on_is_sphere_toggled(toggled_on: bool) -> void:
	if current_index < 0:
		return
	book.spells[current_index].spherical_coords = toggled_on
	update_spells_that_chain_to_current_spell()
	
func _on_M_text_changed(new_text: String) -> void:
	if current_index < 0:
		return
	if not new_text.is_valid_float():
		errors_list["M"] = "'%s' is not a valid number" % new_text
	else:
		errors_list.erase("M")
	var raw: float = new_text.to_float()
	book.spells[current_index].mana_cost = raw
	if raw > book.settings.upgrade_settings.max_mana() + book.settings.upgrade_settings.buff_mana:
		errors_list["M"] = "Value of " + Globals.format_number_nearest_place(raw) + "s exceeds maximum of " + Globals.format_number_nearest_place(book.settings.upgrade_settings.max_mana() + book.settings.upgrade_settings.buff_mana) + "s"
	else:
		errors_list.erase("M")
	update_cooldown()
	update_spells_that_chain_to_current_spell()
	
func update_spells_that_chain_to_current_spell() -> void:
	if current_index < 0:
		return
	if not errors_list.is_empty():
		var last_error : String = errors_list.values()[errors_list.size() - 1]
		var last_key : String = errors_list.keys()[errors_list.size() - 1]
		error_label.text = "%s: %s" % [last_key, last_error]
	else:
		error_label.text = ""
	book.rebuild_spell_chains()
	
func _on_view_chain_button_pressed() -> void:
	var n := chain_edit.text
	if n == "":
		return
	else:
		request_to_view_spell.emit(n)
		
func _on_expressions_focus_exited() -> void:
	selected_variables.clear()
	selected_variables_origin_line = -1
	constants_text_changed = false
	last_selected_variable = ""
		
func _on_expressions_caret_changed() -> void:
	if current_index < 0:
		return
		
	if constants_text_changed:
		constants_text_changed = false
		return
		
	selected_variables.clear()
	selected_variables_origin_line = expressions.get_caret_line()
	var atoms := expressions.get_line(selected_variables_origin_line).split("=", false)
	var selected := ""
	
	if atoms.size() == 2:
		# use this for auto select variable to update
		#selected = atoms[0].strip_edges()
		
		# use this for manual variable selection
		if atoms[0].strip_edges() == expressions.get_selected_text():
			selected = expressions.get_selected_text()
		
	if selected.is_empty() or last_selected_variable == selected:
		return
	
	var found := false
	for v: String in book.spells[current_index].expression_strings:
		if v == selected:
			found = true
		
	if not found:
		return
		
	selected_variables["x"] = []
	selected_variables["y"] = []
	selected_variables["z"] = []
	selected_variables["D"] = []
	var regex := RegEx.new()
	regex.compile("(?<=\\b)" + selected + "(?=\\b)")
	for find in regex.search_all(x_edit.text):
		(selected_variables["x"] as Array).append(Vector2i(find.get_start(), find.get_end() - find.get_start()))
	for find in regex.search_all(y_edit.text):
		(selected_variables["y"] as Array).append(Vector2i(find.get_start(), find.get_end() - find.get_start()))
	for find in regex.search_all(z_edit.text):
		(selected_variables["z"] as Array).append(Vector2i(find.get_start(), find.get_end() - find.get_start()))
	for find in regex.search_all(delay_edit.text):
		(selected_variables["D"] as Array).append(Vector2i(find.get_start(), find.get_end() - find.get_start()))
	for line_number in expressions.get_line_count():
		if line_number == selected_variables_origin_line:
			continue
		var line := expressions.get_line(line_number)
		selected_variables[str(line_number)] = []
		for find in regex.search_all(line):
			(selected_variables[str(line_number)] as Array).append(Vector2i(find.get_start(), find.get_end() - find.get_start()))
		
func _on_expressions_text_changed() -> void:
	if current_index < 0:
		return
	
	constants_text_changed = true
	var result := {}
	var text: String = expressions.text
	var definitions := text.split("\n", false)
	for def: String in definitions:
		var atoms := def.split("=", false)
		if atoms.size() == 2:
			var n := atoms[0].strip_edges()
			while n.begins_with("~"):
				n = n.substr(1)
			result[n] = atoms[1].strip_edges()
	
	if selected_variables_origin_line > -1 and selected_variables_origin_line < result.size() and not selected_variables.is_empty():
		var new_word := result.keys()[selected_variables_origin_line] as String
		x_edit.text = Globals.replace_ranges_in_string(x_edit.text, selected_variables["x"] as Array, new_word)
		y_edit.text = Globals.replace_ranges_in_string(y_edit.text, selected_variables["y"] as Array, new_word)
		z_edit.text = Globals.replace_ranges_in_string(z_edit.text, selected_variables["z"] as Array, new_word)
		delay_edit.text = Globals.replace_ranges_in_string(delay_edit.text, selected_variables["D"] as Array, new_word)
		for line_number in expressions.get_line_count():
			if line_number == selected_variables_origin_line:
				continue
			var line := expressions.get_line(line_number)
			var new_line := Globals.replace_ranges_in_string(line, selected_variables.get(str(line_number), []) as Array, new_word)
			if new_line != line:
				expressions.set_line(line_number, new_line)
				var atoms := new_line.split("=", false)
				if atoms.size() == 2:
					result[atoms[0].strip_edges()] = atoms[1].strip_edges()
		expressions.queue_redraw()
		
			
	book.spells[current_index].expression_strings = result
	book.spells[current_index].build_expressions()
	
	#for k: String in book.spells[current_index].expressions:
		#var e: Expr = book.spells[current_index].expressions[k]
		#if e.contains_variable(k):
			#e.error = "Recursive variable definition"
		#if e.error.length() > 0:
			#errors_list["constant " + k] = e.error
		#else:
			#errors_list.erase("constant " + k)
	
	update_cooldown()
	update_spells_that_chain_to_current_spell()

func check_all_errors() -> void:
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
	if raw > book.settings.upgrade_settings.max_r() + book.settings.upgrade_settings.buff_r:
		errors_list["r"] = "Value of %.1f exceeds maximum of %.1f" % [raw, book.settings.upgrade_settings.max_r() + book.settings.upgrade_settings.buff_r]
		
	text = power_edit.text
	if not text.is_valid_float():
		errors_list["P"] = "'%s' is not a valid number" % text
	raw = text.to_float()
	if raw > book.settings.upgrade_settings.max_P() + book.settings.upgrade_settings.buff_P:
		errors_list["P"] = "Value of %d exceeds maximum of %d" % [raw, book.settings.upgrade_settings.max_P() + book.settings.upgrade_settings.buff_P]
		
	text = duration_edit.text
	if not text.is_valid_float():
		errors_list["T"] = "'%s' is not a valid number" % text
	raw = text.to_float()
	if raw > book.settings.upgrade_settings.max_T() + book.settings.upgrade_settings.buff_T:
		errors_list["T"] = "Value of " + Globals.format_number_nearest_place(raw) + "s exceeds maximum of " + Globals.format_number_nearest_place(book.settings.upgrade_settings.max_T() + book.settings.upgrade_settings.buff_T) + "s"
		
	text = count_edit.text
	if not text.is_valid_float():
		errors_list["N"] = "'%s' is not a valid number" % text
	raw = text.to_float()
	if raw > book.settings.upgrade_settings.max_N() + book.settings.upgrade_settings.buff_N:
		errors_list["N"] = "Value of %d exceeds maximum of %d" % [raw, book.settings.upgrade_settings.max_N() + book.settings.upgrade_settings.buff_N]
		
	text = mana_edit.text
	if not text.is_valid_float():
		errors_list["M"] = "'%s' is not a valid number" % text
	raw = text.to_float()
	if raw > book.settings.upgrade_settings.max_mana() + book.settings.upgrade_settings.buff_mana:
		errors_list["M"] = "Value of " + Globals.format_number_nearest_place(raw) + "s exceeds maximum of " + Globals.format_number_nearest_place(book.settings.upgrade_settings.max_mana() + book.settings.upgrade_settings.buff_mana) + "s"
	
	text = cr_edit.text
	if not text.is_valid_float():
		errors_list["CR"] = "'%s' is not a valid number" % text
		
	text = cd_edit.text
	if not text.is_valid_float():
		errors_list["CD"] = "'%s' is not a valid number" % text
		
	text = chain_edit.text
	if not text.is_empty():
		var found := false
		for s in book.spells:
			if s.name == text:
				found = true
				break
		if not found:
			errors_list["chain"] = "'%s' does not exists" % text
			
	#for k: String in book.spells[current_index].expressions:
		#var expr: Expr = book.spells[current_index].expressions[k]
		#if expr.contains_variable(k):
			#expr.error = "Recursive variable definition"
		#if expr.error.length() > 0:
			#errors_list["constant " + k] = expr.error
		#else:
			#errors_list.erase("constant " + k)
			
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
	popup.confirmed.connect(func() -> void:
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

func hide_preview_selector() -> void:
	preview_selector.hide()
	preview_image.set_pressed_no_signal(false)

func make_preview_selector() -> void:
	const S = 32
	const ROWS = 7
	const COLS = 6
	
	preview_selector = Panel.new()
	preview_selector.size = Vector2(S * COLS + 8 * (COLS + 1), S * ROWS + 8 * (ROWS + 1))
	preview_selector.position = preview_image.position + Vector2(0, preview_image.size.y + 8)
	var preview_title := Label.new()
	preview_title.text = "Thumbnail"
	preview_title.label_settings = LabelSettings.new()
	preview_title.label_settings.font_size = 21
	preview_title.position = Vector2(0, 8)
	preview_title.size.x = preview_selector.size.x
	preview_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview_selector.add_child(preview_title)
	
	main_container.add_child(preview_selector)
	
	var c := 0
	var r := 1
	var i := 0
	for img in Spell.preview_images:
		var btn := Button.new()
		btn.size = Vector2(S, S)
		btn.position = Vector2(c * S + 8 * (c + 1), r * S + 8 * (r + 1))
		var tex := TintedTexture.new()
		var raw_tex := load("res://GUI/Images/Spell Preview/[small] %s.svg" % img) as CompressedTexture2D
		tex.texture = raw_tex
		preview_images.append(raw_tex)
		preview_selector_buttons.append(btn)
		btn.icon = tex
		btn.toggle_mode = true
		btn.pressed.connect(func() -> void:
			if current_index < 0:
				return
			book.spells[current_index].preview_image = i
			for ibtn: Button in preview_selector_buttons:
				ibtn.set_pressed_no_signal(false)
			btn.set_pressed_no_signal(true)
			btn.focus_exited.connect(hide_preview_selector)
			var s := book.spells[current_index]
			(preview_image.icon as TintedTexture).texture = raw_tex
			(preview_image.icon as TintedTexture).flip_horizontal = s.preview_is_horizontal_flip()
			(preview_image.icon as TintedTexture).flip_vertical = s.preview_is_vertical_flip()
			(preview_image.icon as TintedTexture).rotation = s.preview_rotation()
			preview_image.button_pressed = false
			preview_selector.hide()
		)
		preview_selector.add_child(btn)
		i += 1
		c += 1
		if c >= COLS:
			c = 0
			r += 1
			
	var sep := HSeparator.new()
	sep.size = Vector2(preview_selector.size.x, 8)
	sep.position = Vector2(0, S * ROWS)
	preview_selector.add_child(sep)
	
	flip_h_thumbnail = Button.new()
	flip_h_thumbnail.text = "H"
	flip_h_thumbnail.size = Vector2(S, S)
	flip_h_thumbnail.position = Vector2(S * 0 + 8 * 1, S * (ROWS - 1) + 8 * ROWS)
	flip_h_thumbnail.toggle_mode = true
	flip_h_thumbnail.pressed.connect(func() -> void:
		if current_index < 0:
			return
		var s := book.spells[current_index]
		var result := not s.preview_is_horizontal_flip()
		book.spells[current_index].set_preview_is_horizontal_flip(result)
		for ibtn: Button in preview_selector_buttons:
			(ibtn.icon as TintedTexture).flip_horizontal = result
			ibtn.queue_redraw()
		flip_h_thumbnail.set_pressed_no_signal(result)
		(preview_image.icon as TintedTexture).flip_horizontal = result
		preview_image.queue_redraw()
	)
	
	flip_v_thumbnail = Button.new()
	flip_v_thumbnail.text = "V"
	flip_v_thumbnail.size = Vector2(S, S)
	flip_v_thumbnail.position = Vector2(S * 1 + 8 * 2, S * (ROWS - 1) + 8 * ROWS)
	flip_v_thumbnail.toggle_mode = true
	flip_v_thumbnail.pressed.connect(func() -> void:
		if current_index < 0:
			return
		var s := book.spells[current_index]
		var result := not s.preview_is_vertical_flip()
		book.spells[current_index].set_preview_is_vertical_flip(result)
		for ibtn: Button in preview_selector_buttons:
			(ibtn.icon as TintedTexture).flip_vertical = result
			ibtn.queue_redraw()
		flip_v_thumbnail.set_pressed_no_signal(result)
		(preview_image.icon as TintedTexture).flip_vertical = result	
		preview_image.queue_redraw()
	)
	
	rotate_cw_thumbnail = Button.new()
	rotate_cw_thumbnail.text = "C"
	rotate_cw_thumbnail.size = Vector2(S, S)
	rotate_cw_thumbnail.position = Vector2(S * 2 + 8 * 3, S * (ROWS - 1) + 8 * ROWS)
	rotate_cw_thumbnail.pressed.connect(func() -> void:
		if current_index < 0:
			return
		var s := book.spells[current_index]
		var result := s.preview_rotation_tag() + 1
		if result > 0b111: result = 0
		book.spells[current_index].set_preview_is_rotation_tag(result)
		for ibtn: Button in preview_selector_buttons:
			(ibtn.icon as TintedTexture).rotation = book.spells[current_index].preview_rotation()
			ibtn.queue_redraw()
		(preview_image.icon as TintedTexture).rotation = book.spells[current_index].preview_rotation()	
		preview_image.queue_redraw()
	)
	
	rotate_ccw_thumbnail = Button.new()
	rotate_ccw_thumbnail.text = "CC"
	rotate_ccw_thumbnail.size = Vector2(S, S)
	rotate_ccw_thumbnail.position = Vector2(S * 3 + 8 * 4, S * (ROWS - 1) + 8 * ROWS)
	rotate_ccw_thumbnail.pressed.connect(func() -> void:
		if current_index < 0:
			return
		var s := book.spells[current_index]
		var result := s.preview_rotation_tag() - 1
		if result < 0: result = 0b111
		book.spells[current_index].set_preview_is_rotation_tag(result)
		for ibtn: Button in preview_selector_buttons:
			(ibtn.icon as TintedTexture).rotation = book.spells[current_index].preview_rotation()
			ibtn.queue_redraw()
		(preview_image.icon as TintedTexture).rotation = book.spells[current_index].preview_rotation()	
		preview_image.queue_redraw()
	)
	
	preview_selector.add_child(flip_h_thumbnail)
	preview_selector.add_child(flip_v_thumbnail)
	preview_selector.add_child(rotate_cw_thumbnail)
	preview_selector.add_child(rotate_ccw_thumbnail)
			
	preview_selector.hide()
