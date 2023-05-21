class_name WandCaseShelfItem
extends Control

@onready var key: Label = $key
@onready var action: PopupMenu = $MenuBar/Action
@onready var spell: LineEdit = $spell

var store_key: Array = []
var store_action: Wand.Kind = Wand.Kind.NONE
var store_spell: String = ""

var spell_changed: Callable
var action_changed: Callable

# Called when the node enters the scene tree for the first time.
func _ready():
	key.text = Wand.key_description(store_key)
	spell.text = store_spell
	action.name = action.get_item_text(store_action)
	if store_key.size() > 1:
		action.remove_item(5)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_action_id_pressed(id):
	if id > -1:
		action.name = action.get_item_text(id)
		action_changed.call(store_action as Wand.Kind, id as Wand.Kind)

func _on_spell_text_changed(new_text):
	spell_changed.call(new_text)
