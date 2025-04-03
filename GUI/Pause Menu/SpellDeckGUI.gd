class_name SpellDeckGUI
extends Control

@onready var h_flow: HFlowContainer = $ScrollContainer/HFlow

var book: MagicBook
var thumbnail_cache: Dictionary = {}

func add_spell(s: Spell) -> void:
	pass
	
func duplicate_book() -> void:
	pass

func update_cards() -> void:
	for child in h_flow.get_children():
		h_flow.remove_child(child)
		child.queue_free()
		
	for spell in book.spells:
		var card := SpellCardGUI.new()
		card.title.text = spell.name
		card.preview.texture = spell.create_thumbnail(false, thumbnail_cache)
		h_flow.add_child(card)
