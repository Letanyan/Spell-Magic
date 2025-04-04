class_name SpellCardGUI
extends Panel

@onready var title: Label = $Title
@onready var preview: TextureRect = $Preview
@onready var is_active: CheckBox = $IsActive
var spell: Spell = null

signal is_active_toggled(toggled_on: bool, spell_id: int)

func _on_is_active_toggled(toggled_on: bool) -> void:
	var sid := spell.id if spell != null else -1
	is_active_toggled.emit(toggled_on, sid)
