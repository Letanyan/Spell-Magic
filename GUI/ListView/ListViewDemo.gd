extends Control

@onready var list_view: ListView = $ListView
var did_setup: bool = false
var red_channel := 0.0

func _ready() -> void:
	var make := func() -> Control:
		#var result := (load("res://GUI/Pause Menu/WandCaseShelfItem.tscn") as PackedScene).instantiate() as WandCaseShelfItem
		var result := (load("res://GUI/ListView/ListViewDemoItem.tscn") as PackedScene).instantiate() as ListViewDemoItem
		return result
		
	
	var update := func(item: ListViewDemoItem, index: int) -> void:
		#item.key.text = "Hello "+ str(index)
		if item.color_rect.color.r == 0.0:
			red_channel += 1.0 / 1000.0
			item.color_rect.color.r = red_channel
		item.label.text = "Hello " + str(index)
	list_view.setup(1000, 48, make, update)
	
func _process(delta: float) -> void:
	$Label.text = str(Engine.get_frames_per_second())
		
