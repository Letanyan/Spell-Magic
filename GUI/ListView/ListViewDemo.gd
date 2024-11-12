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
	
	
	var indices := [0, 1, 2, 3, 4]
	var items := ["A", "B", "C", "D", "E"]
	var high := 5
	
	var find_index := func(idx: int) -> int:
		var tidx := idx
		while indices[idx] != tidx:
			idx = indices[idx]
		return idx
	
	var remove := func(idx: int, top: int) -> int:
		var fidx = find_index.call(idx)
		var temp = items[fidx]
		items[fidx] = items[top - 1]
		items[top - 1] = temp
		var tidx = indices[fidx]
		indices[fidx] = indices[top - 1]
		indices[top - 1] = tidx
		print("remove: ", idx, "     ^", top)
		print(indices)
		print(items)
		print("--------------")
		return top - 1
		
	var add := func(x: String, top: int) -> int:
		items[top] = x
		print("add: ", x, "       ^", top)
		print(indices)
		print(items)
		print("--------------")
		return top + 1
		
	high = remove.call(1, high)
	high = add.call("X", high)
	high = remove.call(0, high)
	high = remove.call(2, high)
	high = remove.call(3, high)
	high = add.call("Y", high)
	high = add.call("Z", high)
	high = add.call("W", high)
	high = remove.call(0, high)
	high = remove.call(1, high)
	high = remove.call(2, high)
	high = remove.call(3, high)
	high = remove.call(4, high)
	high = add.call("A", high)
	high = add.call("B", high)
	high = add.call("C", high)
	high = add.call("D", high)
	high = add.call("E", high)
	
	print("\n==================")
	var ordered := ""
	for i in 5:
		ordered += items[find_index.call(i)]
	print(ordered)
	
	

func _process(delta: float) -> void:
	$Label.text = str(Engine.get_frames_per_second())
		
