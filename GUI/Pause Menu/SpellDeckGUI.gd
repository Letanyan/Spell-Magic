class_name SpellDeckGUI
extends Control

@onready var h_flow: HFlowContainer = $ScrollContainer/HFlow

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
	for child in h_flow.get_children():
		h_flow.remove_child(child)
		child.queue_free()
	spell_index.clear()
		
	for spell in book.spells:
		var card := SPELL_CARD_GUI.instantiate() as SpellCardGUI
		h_flow.add_child(card)
		card.title.text = spell.name
		card.preview.texture = spell.create_thumbnail(false, thumbnail_cache)
