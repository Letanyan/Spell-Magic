class_name WandCaseShelfItem
extends Control

@onready var key: Label = $key
@onready var cast_combo: OptionButton = $cast_combo
@onready var spell: LineEdit = $spell

var store_key: Array = []
var store_action: Wand.Kind = Wand.Kind.NONE
var store_spell: Array = []

var spell_changed: Callable
var action_changed: Callable

# Called when the node enters the scene tree for the first time.
func _ready():
	key.text = Wand.key_description(store_key)
	spell.text = ", ".join(store_spell)
	cast_combo.selected = store_action
	spell.editable = store_action != Wand.Kind.NONE and store_action != Wand.Kind.MOD and store_action != Wand.Kind.FIRE_PICKED and store_action != Wand.Kind.RAPID_SELECT
	if store_key.size() > 1:
		cast_combo.set_item_disabled(5, true)
	else:
		cast_combo.set_item_disabled(5, false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_cast_combo_selected(id):
	if id > -1:
		action_changed.call(store_action as Wand.Kind, id as Wand.Kind)
		spell_changed.call(spell.text)
		spell.editable = id != Wand.Kind.NONE and id != Wand.Kind.MOD and id != Wand.Kind.FIRE_PICKED and id != Wand.Kind.RAPID_SELECT and id != Wand.Kind.FIRE_PICKED_HOLD

func _on_spell_text_changed(new_text):
	spell_changed.call(new_text)
