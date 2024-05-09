class_name ListView
extends Control

@onready var scroll_bar: ScrollBar = $scroll_bar
@onready var holder: Control = $holder

var make_template: Callable # () -> Control
var update_item: Callable # (item: Control, index: int) -> void
var total_items: int
var height_for_items: float

var items: Array[Control]
var y_offset: float = 0.0
var items_offset: int = 0
var items_shown: int = 0

func _ready() -> void:
	get_tree().get_root().size_changed.connect(generate_items)

func _process(delta: float) -> void:
	pass

func setup(total: int, height: float, template: Callable, update: Callable) -> void:
	total_items = total
	height_for_items = height
	make_template = template
	update_item = update
	scroll_bar.page = height_for_items
	generate_items()

func generate_items() -> void:
	items_shown = mini(ceili(size.y / height_for_items) + 1, total_items)
	if total_items == items_shown:
		scroll_bar.max_value = 0
		scroll_bar.value = 0
		scroll_bar.visible = false
		y_offset = 0
		items_offset = 0
	else:
		scroll_bar.max_value = height_for_items * (total_items - items_shown + 3) - height_for_items / 3.0
		scroll_bar.visible = true
	
	if items_shown < items.size():
		items.sort_custom(func(a: Control, b: Control) -> bool: return a.position.y < b.position.y)
		for i in items.size() - items_shown:
			var item := items.pop_back() as Control
			if item != null:
				holder.remove_child(item)
	if items_shown > items.size():
		items.sort_custom(func(a: Control, b: Control) -> bool: return a.position.y < b.position.y)
		var j := items.size()
		var origin := items[0].position.y if j > 0 else 0.0
		for i in items_shown - items.size():
			var item := make_template.call() as Control
			items.append(item)
			item.position.y = (j + i) * height_for_items + origin
			holder.add_child(item)
	update_items()
	
func update_items() -> void:
	var i := items_offset
	for item in items:
		if i >= 0 and i < total_items:
			update_item.call(item, i)
		i += 1

func update_y_offset() -> void:
	if not scroll_bar.visible:
		return
		
	var new_y_offset := scroll_bar.value
	var change_in_y := y_offset - new_y_offset
	if y_offset - change_in_y < 0:
		change_in_y = -absf(y_offset)
	if y_offset - change_in_y > scroll_bar.max_value:
		change_in_y = absf(scroll_bar.max_value - y_offset)
		
	for item in items:
		item.position.y += change_in_y
	for item in items:
		if item.position.y > size.y:
			items_offset -= 1
			item.position.y -= items_shown * height_for_items
		if item.position.y < -height_for_items:
			items_offset += 1			
			item.position.y += items_shown * height_for_items
			
	items.sort_custom(func(a: Control, b: Control) -> bool: return a.position.y < b.position.y)
	y_offset -= change_in_y
	update_items()

func _on_scroll_bar_scrolling() -> void:
	update_y_offset()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if scroll_bar.visible and event.is_pressed():
			if (event as InputEventMouseButton).button_index == MOUSE_BUTTON_WHEEL_UP:
				scroll_bar.value -= 64
				update_y_offset()
			if (event as InputEventMouseButton).button_index == MOUSE_BUTTON_WHEEL_DOWN:
				scroll_bar.value += 64
				update_y_offset()
		
