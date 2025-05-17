class_name WandCaseShelfItem
extends Control

@onready var key: RichTextLabel = $key
@onready var cast_combo: OptionButton = $cast_combo
@onready var spell: LineEdit = $spell

var store_key: Array[String] = []
var store_action: Wand.Kind = Wand.Kind.NONE
var store_spell: Array[String] = []
var store_params: Array[Dictionary] = []

var spell_changed: Callable
var action_changed: Callable
var autocomplete: Callable

var old_text: String = ""
var delete_key_pressed: bool = false

signal move_down_request
signal move_up_request
signal return_focus

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
		
func setup() -> void:
	key.text = "[center]" + GlobalData.controller.key_images(store_key) + "[/center]"
	#spell.text = ", ".join(store_spell)
	var actual_spell_text := build_spell_list()
	spell.text = actual_spell_text
	_on_spell_text_changed(actual_spell_text)
	cast_combo.selected = store_action
	spell.editable = store_action != Wand.Kind.NONE and store_action != Wand.Kind.MOD and store_action != Wand.Kind.FIRE_PICKED and store_action != Wand.Kind.FIRE_PICKED_RAPID
	if store_key.size() > 1:
		cast_combo.set_item_disabled(8, true)
	else:
		cast_combo.set_item_disabled(8, false)

func _on_cast_combo_selected(id: int) -> void:
	if id > -1:
		UIAudioPlayer.switch()
		action_changed.call(get_node(".") as WandCaseShelfItem, store_action as Wand.Kind, id as Wand.Kind)
		spell_changed.call(get_node(".") as WandCaseShelfItem, spell.text, true)
		spell.editable = id != Wand.Kind.NONE and id != Wand.Kind.MOD and id != Wand.Kind.FIRE_PICKED and id != Wand.Kind.FIRE_PICKED_RAPID and id != Wand.Kind.FIRE_PICKED_HOLD

func _on_spell_text_changed(new_text: String) -> void:
	var updated_text: String = autocomplete.call(old_text, spell, true) if not delete_key_pressed else new_text
	spell_changed.call(get_node(".") as WandCaseShelfItem, updated_text, false)
	old_text = updated_text
	delete_key_pressed = false
	
func update_state(ignore_signals: bool) -> void:
	spell_changed.call(get_node(".") as WandCaseShelfItem, spell.text, ignore_signals)

func build_spell_list() -> String:
	var result := ""
	for i in store_spell.size():
		result += store_spell[i]
		if not store_params[i].is_empty():
			result += "("
			var j := 0
			for k: String in store_params[i]:
				result += k + " = " + store_params[i][k]
				if j < store_params[i].size() - 1:
					result += ", "
				j += 1
			result += ")"
		if i < store_spell.size() - 1:
			result += ", "
	return result


func _on_spell_focus_entered() -> void:
	UIAudioPlayer.focus()


func _on_cast_combo_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ev := event as InputEventKey
		if ev.is_action_released("ui_up"):
			move_up_request.emit()
		elif ev.is_action_released("ui_down"):
			move_down_request.emit()


func _on_spell_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ev := event as InputEventKey
		if ev.is_action_pressed("ui_text_backspace") or ev.is_action_pressed("ui_text_delete"):
			delete_key_pressed = true

func make_level_editor_shelf(is_level_editor: bool) -> void:
	if is_level_editor:
		cast_combo.add_item("Remove Projectile", 9)
		cast_combo.add_item("Place Spell Scroll", 10)
