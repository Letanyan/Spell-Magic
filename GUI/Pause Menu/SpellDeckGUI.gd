class_name SpellDeckGUI
extends Control

@onready var h_flow: HFlowContainer = $ScrollContainer/HFlow
@onready var key_bind_panel: Panel = $KeyBindPanel
@onready var key_bind_input: LineEdit = $KeyBindPanel/Dialog/Input

var book: MagicBook:
	set(value):
		book = value
		duplicate_book()
		reload_cards()
		
var thumbnail_cache: Dictionary = {}
var spell_index: Dictionary = {}

func update_spell_chains(base: Spell) -> void:
	var updated := book.rebuild_spell_chain(base)
	for spell in updated:
		book.spell_was_updated.emit(spell)

func add_spell(spell: Spell) -> void:
	spell.id = book.spells.size()
	book.add(spell)
	var chain_spell := spell.chain
	while chain_spell != null:
		chain_spell.id = book.spells.size()
		book.add(chain_spell)
		chain_spell = chain_spell.chain
	update_spell_chains(spell)
	reload_cards()
	
func duplicate_book() -> void:
	for i in book.spells.size():
		var s := book.spells[i].duplicate({}, true)
		book.spells[i] = s
		book.spell_index[s.name] = s
		s.id = i

const SPELL_CARD_GUI = preload("res://GUI/Pause Menu/SpellCardGUI.tscn")
func reload_cards() -> void:
	for child: SpellCardGUI in h_flow.get_children():
		child.is_active_toggled.disconnect(change_spell_is_active)
		h_flow.remove_child(child)
		child.queue_free()
	spell_index.clear()
		
	for spell in book.spells:
		var card := SPELL_CARD_GUI.instantiate() as SpellCardGUI
		h_flow.add_child(card)
		card.title.text = spell.name
		card.preview.texture = spell.create_thumbnail(Spell.ThumbnailSize.XLARGE, thumbnail_cache)
		card.tooltip_text = spell.description
		card.is_active.disabled = book.can_use_spell(spell, true) != MagicBook.DisallowSpellReason.NONE
		card.is_active.set_pressed_no_signal(spell.is_active)
		card.spell = spell
		card.is_active_toggled.connect(change_spell_is_active)
			
func update_cards() -> void:
	for card: SpellCardGUI in h_flow.get_children():
		var spell := book.spells[card.spell.id]
		card.title.text = spell.name
		card.preview.texture = spell.create_thumbnail(Spell.ThumbnailSize.XLARGE, thumbnail_cache)
		card.tooltip_text = spell.description
		card.is_active.disabled = book.can_use_spell(spell, true) != MagicBook.DisallowSpellReason.NONE
		card.is_active.set_pressed_no_signal(spell.is_active)
	
func change_spell_is_active(toggled_on: bool, current_index: int) -> void:
	if current_index < 0:
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
			update_cards()
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
			update_cards()
