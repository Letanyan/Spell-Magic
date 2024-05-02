class_name WandCaseGUI
extends Control

@onready var wand_index: ItemList = $WandIndex
var case: WandCase:
	set(value):
		case = value
		current_index = value.selected_wand
		reload_list()

@onready var container: VBoxContainer = $panel/scroll/container
@onready var name_edit: LineEdit = $name

@onready var create_button: Button = $create
@onready var delete_button: Button = $delete
@onready var use_button: Button = $use

var current_index := -1
var use_current_wand: Callable
var book: MagicBook
var spell_errors := {}

signal new_wand_selected
	
func update_wand_shelf_items(ignore_signals: bool) -> void:
	for c in container.get_children():
		if c is WandCaseShelfItem:
			(c as WandCaseShelfItem).update_state(ignore_signals)
	if ignore_signals and current_index > -1:
		(case.wands[current_index] as Wand).spell_updated.emit()
	
func reload_wand_shelf_items(index: int = current_index) -> void:
	if index < 0:
		return
	var wand: Wand = case.wands[index]
	current_index = index
	
	name_edit.text = wand.name
	
	for c in container.get_children():
		container.remove_child(c)
		
	var prev_item: WandCaseShelfItem = null
	for w: PackedStringArray in wand.keys:
		var item := (load("res://GUI/Pause Menu/WandCaseShelfItem.tscn") as PackedScene).instantiate() as WandCaseShelfItem
		item.store_key.assign(w)
		item.store_action = wand.keys[w].kind
		item.store_spell.assign(wand.keys[w].spell as Array[String])
		
		item.return_focus.connect(func() -> void: wand_index.grab_focus())
		if prev_item != null:
			item.move_up_request.connect(func() -> void: prev_item.grab_focus())
		if prev_item != null:
			prev_item.move_down_request.connect(func() -> void: item.grab_focus())
		prev_item = item
		
		item.spell_changed = func(text: String, ignore_signals: bool) -> void:
			var all_spells := text.split(",", false)
			var missing_errors := []
			var not_active_errors := []
			for i in range(all_spells.size()):
				var n := all_spells[i].lstrip(" \t\n\r").rstrip(" \t\n\r")
				var s := book.copy_spell(n)
				if s == null:
					missing_errors.append("'[b]" + n + "[/b]'")
				elif not s.is_active:
					not_active_errors.append("'[b]" + s.name + "[/b]'")
				all_spells[i] = n

			if missing_errors.is_empty() and not_active_errors.is_empty():
				item.key.text = "[center]" + GlobalData.controller.key_images(item.store_key) + "[/center]"
			else:
				var errors := ""
				if not missing_errors.is_empty():
					errors = ", ".join(missing_errors) + " missing"
				if not not_active_errors.is_empty():
					errors += ("" if missing_errors.is_empty() else ".") + ", ".join(not_active_errors) + " not active"
				item.key.text = "[center][color=#f33]" + errors + "[/color][/center]"
			(wand.keys[w].spell as Array[String]).assign(all_spells)
			wand.keys[w].spell_index = all_spells.size() - 1
			if not ignore_signals:
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
	
func _on_wand_index_item_selected(index: int) -> void:
	reload_wand_shelf_items(index)

func reload_list() -> void:
	wand_index.clear()
	var i := 0
	for w: Wand in case.wands:
		if i == case.selected_wand:
			wand_index.add_item(w.name, preload("res://GUI/Images/radio-full.svg"))
		else:
			wand_index.add_item(w.name, preload("res://GUI/Images/radio-empty.svg"))
		i += 1
	if current_index > -1:
		reload_wand_shelf_items(current_index)
	
func _on_delete_pressed() -> void:
	if current_index < 0:
		return
		
	var filename := case.wands[current_index].name as String
	var popup := PopupDialog.display("Are you sure you want to delete the wand '" + filename + "'")
	popup.confirmed.connect(func() -> void:
		if current_index < 0:
			return
		case.wands.remove_at(current_index)
		if case.wands.size() == 0:
			current_index = -1
		elif current_index >= case.wands.size():
			current_index = case.wands.size() - 1
		reload_list()
	)
	get_tree().root.add_child(popup)
	

func _on_create_pressed() -> void:
	var wand := Wand.new()
	var wand_count := 1
	var is_numbered_wand := RegEx.new()
	is_numbered_wand.compile("[Ww][Aa][Nn][Dd]\\s\\d+")
	for w: Wand in case.wands:
		var mat := is_numbered_wand.search(w.name) 
		if mat and mat.get_start(0) == 0:
			wand_count += 1
	wand.name = "Wand " + str(wand_count)
	case.wands.append(wand)
	reload_list()
	reload_wand_shelf_items(case.wands.size() - 1)


func _on_name_text_changed(new_text: String) -> void:
	if current_index < 0:
		return
	case.wands[current_index].name = new_text
	wand_index.set_item_text(current_index, new_text)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not has_focus():
		return
		
	var direction := VelocityMovement.get_input_strength("pan_left", "pan_right", "pan_forward", "pan_back")
	
	if wand_index.has_focus():
		if direction.x > 0:
			container.grab_focus()
		if direction.y > 0:
			create_button.grab_focus()
	elif create_button.has_focus():
		if direction.x > 0:
			name_edit.grab_focus()
		if direction.y < 0:
			wand_index.grab_focus()
	elif container.has_focus():
		if direction.x < 0:
			wand_index.grab_focus()
		if direction.y > 0:
			name_edit.grab_focus()
	elif name_edit.has_focus():
		if direction.x < 0:
			create_button.grab_focus()
		if direction.x > 0:
			delete_button.grab_focus()
		if direction.y < 0:
			container.grab_focus()
	elif delete_button.has_focus():
		if direction.x < 0:
			name_edit.grab_focus()
		if direction.x > 0:
			use_button.grab_focus()
		if direction.y < 0:
			container.grab_focus()
	elif use_button.has_focus():
		if direction.x < 0:
			delete_button.grab_focus()
		if direction.y < 0:
			container.grab_focus()


func _on_wand_index_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == 1 and at_position.x < 32:
		current_index = index
		if current_index < 0:
			return
		case.selected_wand = current_index
		use_current_wand.call(current_index)
		new_wand_selected.emit(case.wands[current_index])
		reload_list()
