class_name WandCaseShelfItem
extends Control

@onready var key: RichTextLabel = $key
@onready var cast_combo: OptionButton = $cast_combo
@onready var spell: LineEdit = $spell

var store_key: Array[String] = []
var store_action: Wand.Kind = Wand.Kind.NONE
var store_spell: Array[String] = []

var spell_changed: Callable
var action_changed: Callable
var autocomplete: Callable

var old_text: String = ""

signal move_down_request
signal move_up_request
signal return_focus

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
		
func setup() -> void:
	key.text = "[center]" + GlobalData.controller.key_images(store_key) + "[/center]"
	spell.text = ", ".join(store_spell)
	_on_spell_text_changed(", ".join(store_spell))
	cast_combo.selected = store_action
	spell.editable = store_action != Wand.Kind.NONE and store_action != Wand.Kind.MOD and store_action != Wand.Kind.FIRE_PICKED and store_action != Wand.Kind.RAPID_SELECT
	if store_key.size() > 1:
		cast_combo.set_item_disabled(8, true)
	else:
		cast_combo.set_item_disabled(8, false)

func _on_cast_combo_selected(id: int) -> void:
	if id > -1:
		action_changed.call(get_node(".") as WandCaseShelfItem, store_action as Wand.Kind, id as Wand.Kind)
		spell_changed.call(get_node(".") as WandCaseShelfItem, spell.text, true)
		spell.editable = id != Wand.Kind.NONE and id != Wand.Kind.MOD and id != Wand.Kind.FIRE_PICKED and id != Wand.Kind.RAPID_SELECT and id != Wand.Kind.FIRE_PICKED_HOLD

func _on_spell_text_changed(new_text: String) -> void:
	var updated_text: String = autocomplete.call(old_text, spell, true)
	spell_changed.call(get_node(".") as WandCaseShelfItem, updated_text, false)
	old_text = updated_text
	
func update_state(ignore_signals: bool) -> void:
	spell_changed.call(get_node(".") as WandCaseShelfItem, spell.text, ignore_signals)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not has_focus():
		return
		
	var direction := VelocityMovement.get_input_strength("pan_left", "pan_right", "pan_forward", "pan_back")
	
	if cast_combo.has_focus():
		if direction.x < 0:
			return_focus.emit()
		if direction.x > 0:
			spell.grab_focus()
	elif spell.has_focus():
		if direction.x < 0:
			cast_combo.grab_focus()
			
	if direction.y > 0:
		move_down_request.emit()
	if direction.y < 0:
		move_up_request.emit()
