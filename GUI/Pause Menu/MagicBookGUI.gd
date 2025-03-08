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
		page.book = value
		duplicate_book()
		reload_list()
		create_button.disabled = book.settings.game_mode_settings.has_flag(GameModeSettings.DISALLOW_SPELL_EDITING)
var is_universal: bool = false
		

var spells_index_map := {}

@onready var create_button: Button = $Create

@onready var search_line_edit: LineEdit = $SearchLineEdit

var current_index := -1

@onready var page: MagicPage = $MagicPage

var check_full := load("res://GUI/Images/check-full.svg") as Texture2D
var check_empty := load("res://GUI/Images/check-empty.svg") as Texture2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sort_popup = sort_button.get_popup()
	sort_popup.connect("id_pressed", sort_popup_selected)
	filter_popup = filter_button.get_popup()
	filter_popup.connect("id_pressed", filter_popup_selected)
	
	page.visible = false
	page.spell_name_changed.connect(func(n: String) -> void: reload_list())
	page.spell_description_changed.connect(func(n: String) -> void:
		if current_index < 0 or spell_index.get_selected_items().is_empty():
			return
		spell_index.set_item_tooltip(spell_index.get_selected_items()[0], n)
	)
	page.request_to_view_spell.connect(view_new_spell)
	page.delete_spell.connect(delete_spell_at_index)
	page.duplicate_spell.connect(duplicate_spell_at_index)
	page.return_focus.connect(func() -> void: spell_index.grab_focus())
	
	SignalBus.spell_from_global_book_exported.connect(func(spell: Spell) -> void:
		if not is_universal:
			add_spell(spell)	
	)
	
	
func duplicate_book() -> void:
	for i in book.spells.size():
		var s := book.spells[i].duplicate({}, true)
		book.spells[i] = s
		book.spell_index[s.name] = s
		s.id = i

func _on_spell_index_item_selected(index: int) -> void:
	current_index = spells_index_map[index]
	UIAudioPlayer.click()
	var spell: Spell = book.spells[current_index]
	spell.seen_by_player = true
	if is_universal:
		spell_index.set_item_icon(index, null)
	else:
		spell_index.set_item_icon(index, check_full if spell.is_active else check_empty)
		spell_index.set_item_icon_modulate(index, Color.WHITE)
	
	page.display_spell(book, spell, current_index)
	
	page.visible = true
	
	filter_popup.set_item_disabled(TOTAL_FILTER_ITEMS - 1, false)
	if not filter_options.get(11, false):
		filter_popup.set_item_text(TOTAL_FILTER_ITEMS - 1, "Chains '" + spell.name + "'")
	
	
func update_spells_list() -> void:
	var spells_list := book.spells.duplicate(false)
	
	var is_ascending := sort_order == 0
	if sort_selected == 0:
		spells_list.sort_custom(func(a: Spell, b: Spell) -> bool: return a.name < b.name if is_ascending else a.name > b.name)
	elif sort_selected == 1:
		spells_list.sort_custom(func(a: Spell, b: Spell) -> bool: return a.duration < b.duration if is_ascending else a.duration > b.duration)
	elif sort_selected == 2:
		spells_list.sort_custom(func(a: Spell, b: Spell) -> bool: return a.count < b.count if is_ascending else a.count > b.count)
	elif sort_selected == 3:
		spells_list.sort_custom(func(a: Spell, b: Spell) -> bool: return a.power < b.power if is_ascending else a.power > b.power)
	elif sort_selected == 4:
		spells_list.sort_custom(func(a: Spell, b: Spell) -> bool: return a.mana_cost < b.mana_cost if is_ascending else a.mana_cost > b.mana_cost)
	elif sort_selected == 5:
		spells_list.sort_custom(func(a: Spell, b: Spell) -> bool: return a.cooldown < b.cooldown if is_ascending else a.cooldown > b.cooldown)
		
	spells_index_map = {}
	var k := 0
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
			q0 = q0 or spell.element == Spell.Element.ROCK
		if filter_options.get(3, false):
			has_element = true
			q0 = q0 or spell.element == Spell.Element.ELECTRIC
		if filter_options.get(4, false):
			has_element = true
			q0 = q0 or spell.element == Spell.Element.WATER
		if filter_options.get(5, false):
			has_element = true
			q0 = q0 or spell.element == Spell.Element.AIR
		if filter_options.get(6, false):
			has_element = true
			q0 = q0 or spell.element == Spell.Element.ICE
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
			var s0 := spell.name.contains(search_text)
			if not s0 and spell.chain != null:
				s0 = spell.chain.name.contains(search_text)
			if not s0:
				for e: String in spell.expression_strings:
					if e.contains(search_text):
						s0 = true
						break
			q1 = q1 and s0
		if q1:
			spells_index_map[k] = spell.id
			k += 1
		
	create_button.disabled = k < book.spells.size()
	
func reload_list() -> void:
	var spell_name := ""
	if current_index > -1:
		spell_name = book.spells[current_index].name
		
	spell_index.clear()
	update_spells_list()
	var j := 0
	for k: int in spells_index_map:
		var s := book.spells[spells_index_map[k]]
		if not is_universal:
			spell_index.add_item(s.name, check_full if s.is_active else check_empty)
			if s.seen_by_player:
				spell_index.set_item_icon_modulate(spell_index.item_count - 1, Color.WHITE)
			else:
				spell_index.set_item_icon_modulate(spell_index.item_count - 1, Color(1.0, 0.752941, 0.0))
		else:
			spell_index.add_item(s.name, null)
		spell_index.set_item_tooltip(j, s.description)
		j += 1
		
	if not spell_name.is_empty():
		for i in spell_index.item_count:
			if spell_index.get_item_text(i) == spell_name:
				spell_index.select(i)
				break
	
func update_book_without_selection() -> void:
	current_index = -1
	page.visible = false
	update_book()
	
func update_book() -> void:
	reload_list()
		
func delete_spell_at_index(index: int) -> void:
	for i in book.spells.size():
		book.spells[i].id = i
	update_book_without_selection()

func add_spell(spell: Spell, select_on_create: bool = true) -> void:
	spell.id = book.spells.size()
	book.add(spell)
	var chain_spell := spell.chain
	while chain_spell != null:
		chain_spell.id = book.spells.size()
		book.add(chain_spell)
		chain_spell = chain_spell.chain
	reload_list()
	var k_index := -1
	for k: int in spells_index_map:
		if spells_index_map[k] == spell.id:
			k_index = k
			break
	if select_on_create and k_index != -1:
		_on_spell_index_item_selected(k_index)
		spell_index.select(k_index, true)
		page.name_edit.grab_focus()
		page.name_edit.select_all()
		
func _on_create_pressed() -> void:
	UIAudioPlayer.click()
	var load_from_clipboard := false
	var json := JSON.new()
	while DisplayServer.clipboard_has(): # run once. We do this because the logic is easier when we can use `break` 
		load_from_clipboard = true
		var spell_text := DisplayServer.clipboard_get()
		if not Globals.is_base64(spell_text):
			load_from_clipboard = false
			break
		var dict := Marshalls.base64_to_utf8(spell_text)
		var err := json.parse(dict)
		if err != OK or not json.data is Dictionary:
			load_from_clipboard = false
			break
		for field in Spell.all_spell_fields:
			if not (json.data as Dictionary).has(field):
				load_from_clipboard = false
				break
		break
		
	if load_from_clipboard:
		var popup := PopupDialog.display("Do you want to load spell from Clipboard?", "No", "Yes")
		popup.confirmed.connect(func() -> void:
			UIAudioPlayer.click()
			var spell := Spell.new()
			spell.load_dict(json.data as Dictionary)
			var active_count := 0
			for s in book.spells:
				if s.is_active:
					active_count += 1
			add_spell(spell)
			spell.is_active = active_count < book.settings.upgrade_settings.max_spells_in_book()
		)
		popup.cancelled.connect(func() -> void: 
			UIAudioPlayer.click()
			var spell := Spell.new()
			spell.name = "New Spell"
			add_spell(spell)
			if is_universal:
				spell.is_active = true
		)
		popup.show_in_root(self)
	else:
		var spell := Spell.new()
		spell.name = "New Spell"
		add_spell(spell)
		if is_universal:
			spell.is_active = true
		

func duplicate_spell_at_index(index: int) -> void:
	var spell: Spell = book.spells[index].duplicate()
	spell.name += "-copy"
	add_spell(spell)

func view_new_spell(spell_name: String) -> void:
	var spell := book.find_spell(spell_name)
	if spell == null:
		return
	var k_index := -1
	for k: int in spells_index_map:
		if spells_index_map[k] == spell.id:
			k_index = k
			break
	if k_index != -1:
		_on_spell_index_item_selected(k_index)
		spell_index.select(k_index, true)
		

func sort_popup_selected(id: int) -> void:
	var is_order := id > TOTAL_SORT_ITEMS - 1
	UIAudioPlayer.switch()
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
		
	reload_list()
	
func _on_sort_button_pressed() -> void:
	UIAudioPlayer.click()
	
func filter_popup_selected(id: int) -> void:
	var is_selected := filter_options.has(id)
	if is_selected:
		UIAudioPlayer.check(false)
		filter_options.erase(id)
	else:
		UIAudioPlayer.check(true)
		filter_options[id] = true
	filter_popup.set_item_checked(id, not is_selected)
	if id == TOTAL_FILTER_ITEMS - 1 and current_index != -1:
		if filter_options.has(id):
			filter_chain = book.spells[current_index].name
		else:
			filter_popup.set_item_text(id, "Chains '" + book.spells[current_index].name + "'")
		
	reload_list()
	
func _on_filter_button_pressed() -> void:
	UIAudioPlayer.click()

func _on_search_line_edit_text_changed(new_text: String) -> void:
	reload_list()
	
func _on_spell_index_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == 1 and at_position.x < 32:
		current_index = spells_index_map[index]
		if current_index < 0:
			return
		if is_universal:
			return
		
		var spell: Spell = book.spells[current_index]
		if spell.is_active:
			var can_use := book.can_use_spell(spell)
			if can_use == MagicBook.DisallowSpellReason.COOLDOWN:
				var popup := PopupDialog.display("Spell currently on cooldown. Wait until the spell is of cooldown to deactive.", "Okay", "")
				popup.cancelled.connect(func() -> void: UIAudioPlayer.click())
				popup.confirmed.connect(func() -> void: UIAudioPlayer.click())
				UIAudioPlayer.failed_click()
				get_tree().root.add_child(popup)
			else:
				UIAudioPlayer.check(false)
				spell.is_active = false
				reload_list()
		else:
			var active_count := 0
			for s in book.spells:
				if s.is_active:
					active_count += 1
					
			if active_count >= book.settings.upgrade_settings.max_spells_in_book():
				var can_upgrade := book.settings.upgrade_settings.max_spells_in_book() < UpgradeSettings.LIMIT_SPELLS_IN_BOOK
				var options := ""
				if can_upgrade:
					options = "Upgrade 'Max Active Spells' or deactive another spell first."
				else:
					options = "Deactive another spell first."
				var popup := PopupDialog.display("Total active spells limit reached." + options, "Okay", "")
				popup.cancelled.connect(func() -> void: UIAudioPlayer.click())
				popup.confirmed.connect(func() -> void: UIAudioPlayer.click())
				UIAudioPlayer.failed_click()
				popup.show_in_root(self)
			else:
				UIAudioPlayer.check(true)
				spell.is_active = true
				reload_list()


func _on_search_line_edit_focus_entered() -> void:
	UIAudioPlayer.focus()
