extends Control

@onready var list_view: ListView = $ListView
var did_setup: bool = false

func _ready() -> void:
	var make := func() -> Control:
		#var result := (load("res://GUI/Pause Menu/WandCaseShelfItem.tscn") as PackedScene).instantiate() as WandCaseShelfItem
		var result := (load("res://GUI/ListView/ListViewDemoItem.tscn") as PackedScene).instantiate() as ListViewDemoItem
		print(result.position, " ", result.size)
		return result
		
	var update := func(item: ListViewDemoItem, index: int) -> void:
		#item.key.text = "Hello "+ str(index)
		item.label.text = "Hello " + str(index)
	list_view.setup(15, 48, make, update)

func _process(delta: float) -> void:
	pass
		
