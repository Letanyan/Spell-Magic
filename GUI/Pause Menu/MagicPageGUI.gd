class_name MagicPage
extends Control

@onready var main_container: Panel = $container

@onready var name_edit: LineEdit = $container/name_edit
@onready var preview_image: Button = $container/preview_image
var preview_selector_thumbnail_buttons: Array[Button] = []
var preview_selector_position_buttons: Array[Button] = []
var current_preview_index: int = 0
@onready var preview_selector: Panel = $container/preview_selector
@onready var next_thumbnail: Button = $container/preview_selector/next_thumbnail
@onready var prev_thumbnail: Button = $container/preview_selector/prev_thumbnail
@onready var delete_thumbnail: Button = $container/preview_selector/delete_preview
@onready var flip_h_thumbnail: Button = $container/preview_selector/flip_h
@onready var flip_v_thumbnail: Button = $container/preview_selector/flip_v
@onready var rotate_cw_thumbnail: Button = $container/preview_selector/rotate_cw
@onready var rotate_ccw_thumbnail: Button = $container/preview_selector/rotate_ccw
@onready var scale_up_thumbnail: Button = $container/preview_selector/scale_up
@onready var scale_down_thumbnail: Button = $container/preview_selector/scale_down

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
@onready var load_from_clipboard: Button = $container/LoadFromClipboard
@onready var save_to_uni_book: Button = $container/SaveToUniBook

var errors_list := {}

var book: MagicBook
var is_universal: bool = false:
	set(value):
		if value:
			save_to_uni_book.tooltip_text = "Copy Spell to Clipboard"
			save_to_uni_book.icon = preload("res://GUI/Images/cloud-download.svg")
		else:
			save_to_uni_book.tooltip_text = "Save Spell to Universal Magic Book"
			save_to_uni_book.icon = preload("res://GUI/Images/cloud-upload.svg")
		is_universal = value
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
	preview_selector_thumbnail_buttons = [
		$container/preview_selector/line1, $container/preview_selector/line2, $container/preview_selector/line3,
		$container/preview_selector/line4, $container/preview_selector/line5, $container/preview_selector/line6,
		$container/preview_selector/bomb1, $container/preview_selector/bomb2, $container/preview_selector/bomb3,
		$container/preview_selector/bomb4, $container/preview_selector/bomb5, $container/preview_selector/bomb6,
		$container/preview_selector/circle1, $container/preview_selector/circle2, $container/preview_selector/circle3,
		$container/preview_selector/circle4, $container/preview_selector/circle5, $container/preview_selector/circle6,
		$container/preview_selector/outward1, $container/preview_selector/outward2, $container/preview_selector/outward3,
		$container/preview_selector/outward4, $container/preview_selector/outward5, $container/preview_selector/outward6,
		$container/preview_selector/inward1, $container/preview_selector/inward2, $container/preview_selector/inward3,
		$container/preview_selector/inward4, $container/preview_selector/inward5, $container/preview_selector/inward6,
	]
	preview_selector_position_buttons = [
		$container/preview_selector/pos_NW4, $container/preview_selector/pos_NE4, $container/preview_selector/pos_SW4,
		$container/preview_selector/pos_SE4, 
		$container/preview_selector/pos_NW, $container/preview_selector/pos_N, $container/preview_selector/pos_NE,
		$container/preview_selector/pos_W, $container/preview_selector/pos_E,
		$container/preview_selector/pos_SW, $container/preview_selector/pos_S, $container/preview_selector/pos_SE
	]
	
	var i := 0
	for btn in preview_selector_thumbnail_buttons:
		var img := Spell.preview_images[i]
		var tex := TintedTexture.new()
		tex.texture = load("res://GUI/Images/Spell Preview/[small] %s.svg" % img)
		tex.stretch_mode = TextureRect.StretchMode.STRETCH_TILE
		btn.icon = tex
		i += 1
	
func refresh_preview_thumbnails(spell: Spell) -> void:
	var tint_color := Spell.color_from_element(spell.element)
	preview_image.icon = spell.create_thumbnail(true, {})
	for btn in preview_selector_thumbnail_buttons:
		btn.set_pressed_no_signal(false)
		(btn.icon as TintedTexture).tint = tint_color
		(btn.icon as TintedTexture).flip_horizontal = spell.preview_is_horizontal_flip(current_preview_index)
		(btn.icon as TintedTexture).flip_vertical = spell.preview_is_vertical_flip(current_preview_index)
		(btn.icon as TintedTexture).rotation = spell.preview_rotation(current_preview_index)
		(btn.icon as TintedTexture).scale = spell.preview_scale(current_preview_index)
		(btn.icon as TintedTexture).offset = spell.preview_offset(current_preview_index)
		btn.queue_redraw()
	preview_selector_thumbnail_buttons[spell.preview_image[current_preview_index]].set_pressed_no_signal(true)
	
	for btn in preview_selector_position_buttons:
		btn.set_pressed_no_signal(false)
	if spell.preview_offset_tag(current_preview_index) > 0:
		preview_selector_position_buttons[spell.preview_offset_tag(current_preview_index) - 1].set_pressed_no_signal(true)
		
	preview_image.set_pressed_no_signal(false)
	flip_h_thumbnail.set_pressed_no_signal(spell.preview_is_horizontal_flip(current_preview_index))
	flip_v_thumbnail.set_pressed_no_signal(spell.preview_is_vertical_flip(current_preview_index))
	preview_image.queue_redraw()
	
	prev_thumbnail.disabled = current_preview_index == 0
	delete_thumbnail.disabled = spell.preview_image.size() <= 1
	if current_preview_index < spell.preview_image.size() - 1:
		next_thumbnail.text = ">"
	elif spell.preview_image.size() < 4 and (current_preview_index == spell.preview_image.size() - 1):
		next_thumbnail.text = "+"
	else:
		next_thumbnail.text = ">"
		next_thumbnail.disabled = true
	

func display_spell(magic_book: MagicBook, spell: Spell, index: int) -> void:
	UIAudioPlayer.silence = true
	
	book = magic_book
	current_index = index
	
	for i in range(Spell.Element.size()):
		element_combo.set_item_disabled(i, not book.settings.upgrade_settings.check_if_has_spell_element(Spell.Element.values()[i] as Spell.Element))
	for i in range(Spell.ChainCastKind.size()):
		chain_combo.set_item_disabled(i, not book.settings.upgrade_settings.check_if_has_chain_method(Spell.ChainCastKind.values()[i] as Spell.ChainCastKind))
	
	name_edit.text = spell.name
	
	current_preview_index = 0
	refresh_preview_thumbnails(spell)
	preview_selector.hide()
	
	x_edit.text = spell.x
	y_edit.text = spell.y
	z_edit.text = spell.z
	r_edit.text = spell.r
		
	power_edit.text = "%d" % spell.power
	duration_edit.text = Globals.format_number_nearest_place(spell.duration)
	delay_edit.text = spell.delay
	count_edit.text = "%d" % spell.count
	mana_edit.text = Globals.format_number_nearest_place(spell.mana_cost)
	cr_edit.text = Globals.format_number_nearest_place(spell.crit_rate)
	cd_edit.text = Globals.format_number_nearest_place(spell.crit_dmg)
	update_cooldown()
	
	element_combo.selected = spell.element
	chain_edit.text = spell.chain_configuration_call_text()
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
	
	UIAudioPlayer.silence = false
		
func update_cooldown() -> void:
	if current_index < 0:
		return
	book.spells[current_index].calculate_cooldown()
		
	var raw_radius := book.spells[current_index].radius_cache
	if raw_radius > book.settings.upgrade_settings.max_r() + book.settings.upgrade_settings.buff_r:
		errors_list["r"] = "Value of " + Globals.format_number_nearest_place(raw_radius) + " exceeds maximum of " + Globals.format_number_nearest_place(book.settings.upgrade_settings.max_r() + book.settings.upgrade_settings.buff_r)
	else:
		errors_list.erase("r")
	
	cooldown_label.text = "[left][font_size=16][img=l,24x24]res://GUI/Images/watch.svg[/img] Cooldown: " + Globals.format_number_nearest_place(book.spells[current_index].cooldown) + "s[/font_size][/left]"
	element_application.text = book.spells[current_index].elemental_application_description()
	if book.spells[current_index].chain_cast_kind != Spell.ChainCastKind.NONE and book.spells[current_index].chain != null:
		mana_cost.text = "Total (Inc. chain): " + Globals.format_number_nearest_place(book.spells[current_index].actual_mana_cost())
	else:
		mana_cost.text = ""
	
func _on_preview_image_pressed() -> void:
	UIAudioPlayer.click()
	preview_selector.visible = not preview_selector.visible
	if preview_selector.visible:
		prev_thumbnail.grab_focus()
	
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
		UIAudioPlayer.failed_click()
		return
	UIAudioPlayer.switch()
	book.spells[current_index].element = index as Spell.Element
	update_cooldown()
	update_spells_that_chain_to_current_spell()
	refresh_preview_thumbnails(book.spells[current_index])

func _on_chain_combo_selected(index: int) -> void:
	if current_index < 0:
		UIAudioPlayer.failed_click()
		return
	preview_selector.visible = false
	UIAudioPlayer.switch()
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
	book.spells[current_index].r = new_text
	var e := Expr.new(new_text)
	book.spells[current_index].r_expr = e
	if e.error.length() > 0:
		errors_list["r"] = e.error
	else:
		var raw := book.spells[current_index].radius_cache
		if raw > book.settings.upgrade_settings.max_r() + book.settings.upgrade_settings.buff_r:
			errors_list["r"] = "Value of " + Globals.format_number_nearest_place(raw) + " exceeds maximum of " + Globals.format_number_nearest_place(book.settings.upgrade_settings.max_r() + book.settings.upgrade_settings.buff_r)
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
	var option := Wand.Option.new()
	option.parse_spells(n, book)
	
	if n == "":
		spell.chain = null
		errors_list.erase("chain")
	elif option.spell_names.size() != 1:
		spell.chain = null
		errors_list["chain"] = "Only one spell is allowed to be chained"
	elif option.get_spell() == null:
		spell.chain = null
		errors_list["chain"] = "'%s' does not exists" % option.get_spell_name()
	elif option.get_spell().name == spell.name:
		errors_list["chain"] = "'%s' can not chain to itself" % spell.name
	else:
		var new_spell := option.get_spell()
		var problem_chain := book.find_recursive_spell_chain(spell, new_spell.name)
		if not problem_chain.is_empty():
			var message := "'%s' can not exist in a recursive spell chain " % new_spell
			for s in problem_chain:
				message += s + "->"
			errors_list["chain"] = message.trim_suffix("->")
		else:
			spell.chain = new_spell
			if not option.parameters.is_empty():
				spell.chain.configure_using_parameter_collection(option.parameters[0], spell.global_constant_variables())
				spell.configuration_parameters_for_chain = option.parameters[0]
			errors_list.erase("chain")
				
	old_chain_text = n
	update_cooldown()
	update_spells_that_chain_to_current_spell()

func _on_is_rel_toggled(button_pressed: bool) -> void:
	if current_index < 0:
		UIAudioPlayer.failed_click()
		return
	UIAudioPlayer.check(button_pressed)
	book.spells[current_index].follow = button_pressed
	update_spells_that_chain_to_current_spell()

func _on_is_bomb_toggled(button_pressed: bool) -> void:
	if current_index < 0:
		UIAudioPlayer.failed_click()
		return
	UIAudioPlayer.check(button_pressed)
	book.spells[current_index].is_bomb = button_pressed
	update_spells_that_chain_to_current_spell()
	
func _on_player_is_origin_toggled(button_pressed: bool) -> void:
	if current_index < 0:
		UIAudioPlayer.failed_click()
		return
	UIAudioPlayer.check(button_pressed)
	book.spells[current_index].player_is_origin = button_pressed
	update_spells_that_chain_to_current_spell()
	
func _on_is_sphere_toggled(toggled_on: bool) -> void:
	if current_index < 0:
		UIAudioPlayer.failed_click()
		return
	UIAudioPlayer.check(toggled_on)
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
	var spell := book.spells[current_index]
	var updated_spells := book.rebuild_spell_chain(spell)
	if not errors_list.is_empty():
		var last_error : String = errors_list.values()[errors_list.size() - 1]
		var last_key : String = errors_list.keys()[errors_list.size() - 1]
		error_label.text = "%s: %s" % [last_key, last_error]
	else:
		error_label.text = ""
		book.spell_was_updated.emit(spell)
	for s in updated_spells:
		book.spell_was_updated.emit(s)
	
func _on_view_chain_button_pressed() -> void:
	var n := chain_edit.text
	var option := Wand.Option.new()
	option.parse_spells(n, book)
	preview_selector.visible = false
	if n == "" or option.next_spell() == null:
		UIAudioPlayer.failed_click()
		return
	else:
		UIAudioPlayer.click()
		request_to_view_spell.emit(option.next_spell().name)
		
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
	selected_variables["r"] = []
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
	for find in regex.search_all(r_edit.text):
		(selected_variables["r"] as Array).append(Vector2i(find.get_start(), find.get_end() - find.get_start()))
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
		if not (selected_variables["x"] as Array).is_empty():
			x_edit.text = Globals.replace_ranges_in_string(x_edit.text, selected_variables["x"] as Array, new_word)
			_on_x_text_changed(x_edit.text)
		if not (selected_variables["y"] as Array).is_empty():
			y_edit.text = Globals.replace_ranges_in_string(y_edit.text, selected_variables["y"] as Array, new_word)
			_on_y_text_changed(y_edit.text)
		if not (selected_variables["z"] as Array).is_empty():
			z_edit.text = Globals.replace_ranges_in_string(z_edit.text, selected_variables["z"] as Array, new_word)
			_on_z_text_changed(z_edit.text)
		if not (selected_variables["D"] as Array).is_empty():
			delay_edit.text = Globals.replace_ranges_in_string(delay_edit.text, selected_variables["D"] as Array, new_word)
			_on_D_text_changed(delay_edit.text)
		if not (selected_variables["r"] as Array).is_empty():
			r_edit.text = Globals.replace_ranges_in_string(r_edit.text, selected_variables["r"] as Array, new_word)
			_on_r_text_changed(r_edit.text)
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
	
	if not errors_list.is_empty():
		for k: String in Spell.fixed_var_list:
			errors_list.erase("warning: subexpression '" + k + "'")
	
	for k: String in book.spells[current_index].expressions:
		var expr: Expr = book.spells[current_index].expressions[k]
		if expr.contains_variable(k):
			expr.error = "Recursive variable definition"
		if Spell.fixed_var_list.has(k):
			errors_list["warning: subexpression '" + k + "'"] = "Redefinition of '" + k + "' will have no effect."
		if expr.error.length() > 0:
			errors_list["expression " + k] = expr.error
		else:
			errors_list.erase("expression " + k)
	
	update_cooldown()
	update_spells_that_chain_to_current_spell()

func check_all_errors() -> void:
	if current_index < 0:
		return
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
	e = Expr.new(r_edit.text)
	if e.error.length() > 0:
		errors_list["r"] = e.error
		
	var raw: float = book.spells[current_index].radius_cache
	if raw > book.settings.upgrade_settings.max_r() + book.settings.upgrade_settings.buff_r:
		errors_list["r"] = "Value of %.1f exceeds maximum of %.1f" % [raw, book.settings.upgrade_settings.max_r() + book.settings.upgrade_settings.buff_r]
		
	var text := power_edit.text
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
		var option := Wand.Option.new()
		option.parse_spells(text, book)
		if option.spells.size() != 1:
			errors_list["chain"] = "Only one spell is allowed to be chained"
		else:
			var next_spell := option.next_spell()
			if next_spell == null:
				errors_list["chain"] = "'%s' does not exists" % option.next_spell()
			else:
				var disallow := book.can_use_spell(next_spell)
				if (chain_combo.selected as Spell.ChainCastKind) != Spell.ChainCastKind.NONE and disallow != MagicBook.DisallowSpellReason.NONE:
					errors_list["chain"] = "'%s''s chained spell has a problem" % [next_spell.name]
			
	for k: String in book.spells[current_index].expressions:
		var expr: Expr = book.spells[current_index].expressions[k]
		if expr.contains_variable(k):
			expr.error = "Recursive variable definition"
		if Spell.fixed_var_list.has(k):
			errors_list["warning: subexpression '" + k + "'"] = "Redefinition of '" + k + "' will have no effect."
		if expr.error.length() > 0:
			errors_list["expression " + k] = expr.error
		else:
			errors_list.erase("expression " + k)
			
	if not errors_list.is_empty():
		var last_error : String = errors_list.values()[errors_list.size() - 1]
		var last_key : String = errors_list.keys()[errors_list.size() - 1]
		error_label.text = "%s: %s" % [last_key, last_error]
	else:
		error_label.text = ""
	

func _on_delete_pressed() -> void:
	if current_index < 0:
		UIAudioPlayer.failed_click()
		return
		
	preview_selector.visible = false
	UIAudioPlayer.click()
	var s := book.spells[current_index]
	var popup := PopupDialog.display("Are you sure you want to delete the spell '" + s.name + "'")
	popup.confirmed.connect(func() -> void:
		if current_index < 0:
			return
		UIAudioPlayer.delete()
		book.spells.remove_at(current_index)
		delete_spell.emit(current_index)
	)
	popup.cancelled.connect(func() -> void: UIAudioPlayer.click())
	popup.show_in_root(self)
	

func _on_duplicate_pressed() -> void:
	if current_index < 0:
		UIAudioPlayer.failed_click()
		return
	UIAudioPlayer.click()
	preview_selector.visible = false
	duplicate_spell.emit(current_index)
	
func _on_save_to_uni_book_pressed() -> void:
	if current_index < 0:
		UIAudioPlayer.failed_click()
		return
	var spell := book.spells[current_index]
	UIAudioPlayer.click()
	if is_universal:
		var encoded := Marshalls.utf8_to_base64(str(spell.save_dict()))
		DisplayServer.clipboard_set(encoded)
	else:
		GlobalData.user_magic_book.add(spell)
		
func _on_load_from_clipboard_pressed() -> void:
	if current_index < 0 and DisplayServer.clipboard_has():
		UIAudioPlayer.failed_click()
		return
		
	var spell := book.spells[current_index]
	var popup := PopupDialog.display("Are you sure you want to overwrite the spell '" + spell.name + "' with copied spell")
	popup.confirmed.connect(func() -> void:
		var spell_text := DisplayServer.clipboard_get()
		if not Globals.is_base64(spell_text):
			UIAudioPlayer.failed_click()
			var popup_err := PopupDialog.display("Can not load spell. Invalid spell data.", "Okay", "")
			popup_err.cancelled.connect(func() -> void: UIAudioPlayer.click())
			popup_err.show_in_root(self)
			return
		var dict := Marshalls.base64_to_utf8(spell_text)
		var json := JSON.new()
		var err := json.parse(dict)
		
		if err != OK or not json.data is Dictionary:
			UIAudioPlayer.failed_click()
			var popup_err := PopupDialog.display("Can not load spell. Invalid spell data.", "Okay", "")
			popup_err.cancelled.connect(func() -> void: UIAudioPlayer.click())
			popup_err.show_in_root(self)
			return
		
		var contains_all_fields := true
		var fields := ["x", "y", "z", "r", "power", "duration", "count", "delay", "chain", "is_bomb",
			"is_rel", "el", "chain_cast_kind", "name", "id", "mana", "player_is_origin", "expression_strings", "is_active", 
			"elemental_application", "crit_rate", "crit_dmg", "spherical_coords", "preview_image", "preview_flags",
			"configuration_parameters_for_chain", "seen_by_player"]
		for field in fields:
			if not (json.data as Dictionary).has(field):
				contains_all_fields = false
				break
		if not contains_all_fields:
			UIAudioPlayer.failed_click()
			var popup_err := PopupDialog.display("Can not load spell. Invalid spell data.", "Okay", "")
			popup_err.cancelled.connect(func() -> void: UIAudioPlayer.click())
			popup_err.show_in_root(self)
			return
			
		UIAudioPlayer.click()
		var old_name := spell.name
		var old_id := spell.id
		spell.load_dict(json.data as Dictionary)
		spell.name = old_name
		spell.id = old_id
		var active_count := 0
		for s in book.spells:
			if s.is_active:
				active_count += 1
		spell.is_active = active_count < book.settings.upgrade_settings.max_spells_in_book()
		display_spell(book, book.spells[current_index], current_index)
	)
	popup.cancelled.connect(func() -> void: UIAudioPlayer.click())
	popup.show_in_root(self)

func hide_preview_selector() -> void:
	preview_selector.hide()
	preview_image.set_pressed_no_signal(false)
			
		
func _on_delete_thumnail_component_pressed() -> void:
	if current_index < 0:
		UIAudioPlayer.failed_click()
		return
	UIAudioPlayer.delete()
	var spell := book.spells[current_index]
	if spell.preview_image.size() > 1:
		spell.preview_image.remove_at(current_preview_index)
		spell.preview_flags.remove_at(current_preview_index)
		if current_preview_index > 0:
			current_preview_index -= 1
		refresh_preview_thumbnails(book.spells[current_index])
		prev_thumbnail.disabled = current_preview_index == 0
		delete_thumbnail.disabled = spell.preview_image.size() <= 1


func _on_next_thumbnail_pressed() -> void:
	if current_index < 0:
		UIAudioPlayer.failed_click()
		return
	UIAudioPlayer.switch()
	var spell := book.spells[current_index]
	if current_preview_index < spell.preview_image.size() - 1:	
		current_preview_index += 1
		prev_thumbnail.disabled = false
		refresh_preview_thumbnails(book.spells[current_index])
	elif spell.preview_image.size() < 4 and (current_preview_index == spell.preview_image.size() - 1):
		current_preview_index += 1
		prev_thumbnail.disabled = false
		delete_thumbnail.disabled = false
		book.spells[current_index].preview_image.append(0)
		book.spells[current_index].preview_flags.append(0)
		refresh_preview_thumbnails(book.spells[current_index])


func _on_prev_thumbnail_pressed() -> void:
	if current_index < 0:
		UIAudioPlayer.failed_click()
		return
	UIAudioPlayer.switch()
	if current_preview_index > 0:	
		current_preview_index -= 1
		refresh_preview_thumbnails(book.spells[current_index])
	if current_preview_index == 0:
		prev_thumbnail.disabled = true


func _on_flip_h_pressed() -> void:
	if current_index < 0:
		UIAudioPlayer.failed_click()
		return
	UIAudioPlayer.click()
	var s := book.spells[current_index]
	var result := not s.preview_is_horizontal_flip(current_preview_index)
	book.spells[current_index].set_preview_is_horizontal_flip(current_preview_index, result)
	for ibtn: Button in preview_selector_thumbnail_buttons:
		(ibtn.icon as TintedTexture).flip_horizontal = result
		ibtn.queue_redraw()
	flip_h_thumbnail.set_pressed_no_signal(result)
	preview_image.icon = book.spells[current_index].create_thumbnail(true, {})
	preview_image.queue_redraw()


func _on_flip_v_pressed() -> void:
	if current_index < 0:
		UIAudioPlayer.failed_click()
		return
	UIAudioPlayer.click()
	var s := book.spells[current_index]
	var result := not s.preview_is_vertical_flip(current_preview_index)
	book.spells[current_index].set_preview_is_vertical_flip(current_preview_index, result)
	for ibtn: Button in preview_selector_thumbnail_buttons:
		(ibtn.icon as TintedTexture).flip_vertical = result
		ibtn.queue_redraw()
	flip_v_thumbnail.set_pressed_no_signal(result)
	preview_image.icon = book.spells[current_index].create_thumbnail(true, {})
	preview_image.queue_redraw()


func _on_rotate_cw_pressed() -> void:
	if current_index < 0:
		UIAudioPlayer.failed_click()
		return
	UIAudioPlayer.click()
	var s := book.spells[current_index]
	var result := s.preview_rotation_tag(current_preview_index) + 1
	if result > 0b111: result = 0
	book.spells[current_index].set_preview_rotation_tag(current_preview_index, result)
	for ibtn: Button in preview_selector_thumbnail_buttons:
		(ibtn.icon as TintedTexture).rotation = book.spells[current_index].preview_rotation(current_preview_index)
		ibtn.queue_redraw()
	preview_image.icon = book.spells[current_index].create_thumbnail(true, {})
	preview_image.queue_redraw()


func _on_rotate_ccw_pressed() -> void:
	if current_index < 0:
		UIAudioPlayer.failed_click()
		return
	UIAudioPlayer.click()
	var s := book.spells[current_index]
	var result := s.preview_rotation_tag(current_preview_index) - 1
	if result < 0: result = 0b111
	book.spells[current_index].set_preview_rotation_tag(current_preview_index, result)
	for ibtn: Button in preview_selector_thumbnail_buttons:
		(ibtn.icon as TintedTexture).rotation = book.spells[current_index].preview_rotation(current_preview_index)
		ibtn.queue_redraw()
	preview_image.icon = book.spells[current_index].create_thumbnail(true, {})
	preview_image.queue_redraw()


func _on_scale_down_pressed() -> void:
	if current_index < 0:
		UIAudioPlayer.failed_click()
		return
	UIAudioPlayer.click()
	var s := book.spells[current_index]
	var result := s.preview_scale_tag(current_preview_index) - 1
	if result < 0: result = 0b111
	book.spells[current_index].set_preview_scale_tag(current_preview_index, result)
	for ibtn: Button in preview_selector_thumbnail_buttons:
		(ibtn.icon as TintedTexture).scale = book.spells[current_index].preview_scale(current_preview_index)
		ibtn.queue_redraw()
	preview_image.icon = book.spells[current_index].create_thumbnail(true, {})
	preview_image.queue_redraw()


func _on_scale_up_pressed() -> void:
	if current_index < 0:
		UIAudioPlayer.failed_click()
		return
	UIAudioPlayer.click()
	var s := book.spells[current_index]
	var result := s.preview_scale_tag(current_preview_index) + 1
	if result > 0b111: result = 0
	book.spells[current_index].set_preview_scale_tag(current_preview_index, result)
	for ibtn: Button in preview_selector_thumbnail_buttons:
		(ibtn.icon as TintedTexture).scale = book.spells[current_index].preview_scale(current_preview_index)
		ibtn.queue_redraw()
	preview_image.icon = book.spells[current_index].create_thumbnail(true, {})
	preview_image.queue_redraw()


func _on_pos_pressed(pidx: int) -> void:
	if current_index < 0:
		UIAudioPlayer.failed_click()
		return
		
	UIAudioPlayer.click()
	var is_pressed := not preview_selector_position_buttons[pidx].button_pressed
	if is_pressed:
		book.spells[current_index].set_preview_offset_tag(current_preview_index, 0)
	else:
		book.spells[current_index].set_preview_offset_tag(current_preview_index, pidx + 1)
		
	for ibtn: Button in preview_selector_thumbnail_buttons:
		(ibtn.icon as TintedTexture).offset = book.spells[current_index].preview_offset(current_preview_index)
		ibtn.queue_redraw()
		
	for ibtn in preview_selector_position_buttons: 
		ibtn.set_pressed_no_signal(false)
	preview_selector_position_buttons[pidx].set_pressed_no_signal(not is_pressed)
	preview_image.icon = book.spells[current_index].create_thumbnail(true, {})
	preview_image.queue_redraw()

func _on_thumbnail_image_pressed(btn: NodePath, img: String, i: int) -> void:
	if current_index < 0:
		UIAudioPlayer.failed_click()
		return
	UIAudioPlayer.click()
	book.spells[current_index].preview_image[current_preview_index] = i
	for ibtn: Button in preview_selector_thumbnail_buttons:
		ibtn.set_pressed_no_signal(false)
	(get_node(btn) as Button).set_pressed_no_signal(true)
	preview_image.icon = book.spells[current_index].create_thumbnail(true, {})
	preview_image.button_pressed = false


func _on_control_focus_entered() -> void:
	UIAudioPlayer.focus()
	preview_selector.visible = false
