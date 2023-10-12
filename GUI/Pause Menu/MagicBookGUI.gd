class_name MagicBookGUI
extends Control

@onready var sort_button: MenuButton = $SortButton
const TOTAL_SORT_ITEMS = 7
var sort_popup: PopupMenu = null
var sort_selected: int = 0
var sort_order: int = 0
@onready var filter_button: MenuButton = $FilterButton
const TOTAL_FILTER_ITEMS = 12
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

@onready var search_line_edit: LineEdit = $SearchLineEdit

var current_index := -1

@onready var page: MagicPage = $MagicPage

# Called when the node enters the scene tree for the first time.
func _ready():
	sort_popup = sort_button.get_popup()
	sort_popup.connect("id_pressed", sort_popup_selected)
	filter_popup = filter_button.get_popup()
	filter_popup.connect("id_pressed", filter_popup_selected)
	
	page.visible = false
	page.spell_name_changed.connect(func(n: String): reload_list())
	page.request_to_view_spell.connect(view_new_spell)
	page.delete_spell.connect(delete_spell_at_index)
	page.duplicate_spell.connect(duplicate_spell_at_index)
	page.return_focus.connect(func(): spell_index.grab_focus())
	
	
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
	
	page.display_spell(book, spell, current_index)
	
	page.visible = true
	
	filter_popup.set_item_disabled(TOTAL_FILTER_ITEMS - 1, false)
	filter_popup.set_item_text(TOTAL_FILTER_ITEMS - 1, "Chains '" + spell.name + "'")
	
	
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
		var search_text: String = search_line_edit.text
		var q0 := filter_options.is_empty() and search_text.is_empty()
		var has_element: bool = false
		if filter_options.get(0, false):
			has_element = true
			q0 = q0 or spell.element == Spell.Element.VOID
		if filter_options.get(1, false):
			has_element = true
			q0 = q0 or spell.element == Spell.Element.FIRE
		if filter_options.get(2, false):
			has_element = true
			q0 = q0 or spell.element == Spell.Element.WATER
		if filter_options.get(3, false):
			has_element = true
			q0 = q0 or spell.element == Spell.Element.AIR
		if filter_options.get(4, false):
			has_element = true
			q0 = q0 or spell.element == Spell.Element.ROCK
		if filter_options.get(5, false):
			has_element = true
			q0 = q0 or spell.element == Spell.Element.ICE
		if filter_options.get(6, false):
			has_element = true
			q0 = q0 or spell.element == Spell.Element.ELECTRIC
		var q1 := q0 or not has_element
		if filter_options.get(7, false):
			q1 = q1 and spell.player_is_origin
		if filter_options.get(8, false):
			q1 = q1 and spell.is_bomb
		if filter_options.get(9, false):
			q1 = q1 and spell.follow
		if filter_options.get(10, false):
			q1 = q1 and spell.is_active
		if filter_options.get(11, false):
			q1 = q1 and (spell.chain != null and spell.chain.name == filter_chain)
		if not search_text.is_empty():
			var s0 = spell.name.contains(search_text)
			if not s0 and spell.chain != null:
				s0 = spell.chain.name.contains(search_text)
			if not s0:
				for e in spell.expression_strings:
					if e.contains(search_text):
						s0 = true
						break
			q1 = q1 and s0
		if q1:
			spells_index_map[k] = spell.id
			k += 1
		
	create_button.disabled = k < book.spells.size()
	
func reload_list():
	spell_index.clear()
#	for s in book.spells:
#		spell_index.add_item(s.name)
	for k in spells_index_map:
		var s = book.spells[spells_index_map[k]]
		spell_index.add_item(s.name, load("res://GUI/Images/check-full.svg") if s.is_active else load("res://GUI/Images/check-empty.svg"))
	
		
func delete_spell_at_index(index: int):
	current_index = -1
	page.visible = false
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
		page.name_edit.grab_focus()
		page.name_edit.select_all()
		
func _on_create_pressed():
	var spell := Spell.new()
	var active_count := 0
	for s in book.spells:
		if s.is_active:
			active_count += 1
	spell.is_active = active_count < book.settings.upgrade_settings.max_spells_in_book
	spell.name = "New Spell"
	add_spell(spell)

func duplicate_spell_at_index(index: int):
	var spell: Spell = book.spells[index].duplicate()
	spell.name += " (Copy)"
	add_spell(spell)

func view_new_spell(spell_name: String):
	var i := 0
	for s in book.spells:
		if s.name == spell_name:
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
	

func _on_search_line_edit_text_changed(new_text: String) -> void:
	update_spells_list()
	reload_list()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not has_focus():
		return
		
	var direction := VelocityMovement.get_input_strength("pan_left", "pan_right", "pan_forward", "pan_back")
	
	if filter_button.has_focus():
		if direction.x > 0:
			sort_button.grab_focus()
		if direction.y < 0:
			spell_index.grab_focus()
	elif sort_button.has_focus():
		if direction.x < 0:
			filter_button.grab_focus()
		if direction.x > 0:
			search_line_edit.grab_focus()
		if direction.y < 0:
			spell_index.grab_focus()
	elif search_line_edit.has_focus():
		if direction.x < 0:
			filter_button.grab_focus()
		if direction.x > 0:
			page.grab_focus()
		if direction.y < 0:
			spell_index.grab_focus()
	elif spell_index.has_focus():
		if direction.x > 0:
			page.grab_focus()
		if direction.y < 0:
			filter_button.grab_focus()
		if direction.y > 0:
			create_button.grab_focus()


func _on_spell_index_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == 1 and at_position.x < 32:
		current_index = spells_index_map[index]
		if current_index < 0:
			return
		
		var spell: Spell = book.spells[current_index]
		if spell.is_active:
			spell.is_active = false
			update_spells_list()
			reload_list()
		else:
			var active_count := 0
			for s in book.spells:
				if s.is_active:
					active_count += 1
			if active_count < book.settings.upgrade_settings.max_spells_in_book:
				spell.is_active = true
				update_spells_list()
				reload_list()
