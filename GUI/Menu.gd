class_name Menu
extends Control

enum Kind { ANY, SPELLS, WANDS }

@onready var magic_book: Control = $MagicBook
@onready var wand_case: Control = $WandCase
var current_index = 0

var is_showing: bool = false

func setup(book: MagicBook, case: WandCase):
	magic_book.book = book
	wand_case.case = case

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func update_index(index):
	save_changes()
	if index < 0:
		current_index = 1
	elif index > 1:
		current_index = 0
	else:
		current_index = index
	magic_book.visible = false
	wand_case.visible = false
	match index:
		0: magic_book.visible = true
		1: wand_case.visible = true

func _on_spells_pressed():
	update_index(0)

func _on_wands_pressed():
	update_index(1)

func open(kind: Kind):
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true
	is_showing = true
	match kind:
		Kind.SPELLS:
			_on_spells_pressed()
		Kind.WANDS:
			_on_wands_pressed()

func close():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	is_showing = false
	visible = false
	save_changes()
	
func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("RB"):
		update_index(current_index + 1)
	elif event.is_action_pressed("LB"):
		update_index(current_index - 1)
	

func save_changes():
	if magic_book.visible:
		magic_book.book.save()
	if wand_case.visible:
		wand_case.case.save()
