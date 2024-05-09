extends Control

@onready var list_view: ListView = $ListView
var did_setup: bool = false

func _ready() -> void:
	var make := func() -> Control:
		return load("res://GUI/ListView/ListViewDemoItem.tscn").instantiate() as ListViewDemoItem
	var update := func(item: ListViewDemoItem, index: int) -> void:
		item.label.text = "Click me " + str(index) + " time(s)"
	list_view.setup(15, 64, make, update)

func _process(delta: float) -> void:
	pass
		
