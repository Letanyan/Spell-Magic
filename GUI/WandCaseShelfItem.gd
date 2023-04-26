class_name WandCaseShelfItem
extends Control

@onready var key: Label = $key
@onready var action: PopupMenu = $MenuBar/Action
@onready var spell: LineEdit = $spell

var store_key: Array = []
var store_action: Wand.Kind = Wand.Kind.NONE
var store_spell: String = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	var text = store_key[0]
	for i in range(1, store_key.size()):
		text += " + " + store_key[i]
	key.text = text
	spell.text = store_spell
	_on_action_id_pressed(store_action)
	if store_key.size() > 1:
		action.remove_item(4)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# FIXME: Update gui when MOD is selected
func _on_action_id_pressed(id):
	if id > -1:
		action.name = action.get_item_text(id)
		store_action = id
#		action.title = action.get_item_text(id)
