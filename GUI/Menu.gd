class_name Menu
extends Control

enum Kind { ANY, SPELLS, WANDS }

@onready var magic_book: Control = $MagicBook
@onready var wand_case: Control = $WandCase

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


func _on_spells_pressed():
	save_changes()
	magic_book.visible = true
	wand_case.visible = false


func _on_wands_pressed():
	save_changes()
	magic_book.visible = false
	wand_case.visible = true

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

func save_changes():
	if magic_book.visible:
		magic_book.book.save()
	if wand_case.visible:
		wand_case.case.save()
