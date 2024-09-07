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

var _visible_items: Dictionary = {} # [int]bool

func _ready() -> void:
	get_tree().get_root().size_changed.connect(generate_items)

func _process(delta: float) -> void:
	pass

func setup(total: int, height: float, template: Callable, update: Callable) -> void:
	total_items = total
	height_for_items = height
	make_template = template
	update_item = update
	y_offset = 0
	scroll_bar.value = 0
	items_offset = 0
	generate_items()

func generate_items() -> void:
	if height_for_items <= 0:
		return
	
	items_shown = mini(ceili(size.y / height_for_items), total_items) + 1
	if total_items + 1 == items_shown and size.y >= (items_shown - 1) * height_for_items:
		scroll_bar.value = 0
		scroll_bar.visible = false
		y_offset = 0
		items_offset = 0
	else:
		scroll_bar.visible = true
	
	if items_shown < items.size():
		for i in items.size() - items_shown:
			var item := items.pop_back() as Control
			if item != null:
				holder.remove_child(item)
	if items_shown > items.size():
		for i in items_shown - items.size():
			var item := make_template.call() as Control
			items.append(item)
			holder.add_child(item)
			
	update_y_offset()
	
func update_items() -> void:
	var min_index := 0
	var min_value := 999_999_999.0
	for i in items.size():
		if items[i].position.y < min_value:
			min_value = items[i].position.y
			min_index = i
	
	var new_visible_items := {}
	for i in items.size():
		var j := items_offset + posmod(i - min_index, items.size())
		if j >= 0 and j < total_items:
			if not _visible_items.has(j):
				update_item.call(items[i], j)
			new_visible_items[j] = true
			
	_visible_items = new_visible_items
	
func update_y_offset() -> void:
	var view_count := (total_items - items_shown + 1)
	var x := (1.0 - scroll_bar.value)
	var parent_height_correction := size.y - (items_shown - 1) * height_for_items
	var old_offset := items_offset
	items_offset = roundi(scroll_bar.value * view_count - 0.5)
	if scroll_bar.value == 1.0:
		items_offset -= 1
		
	var i := 0
	for item in items:
		var virtual_y := i * height_for_items + x * view_count * height_for_items
		item.position.y = fmod(virtual_y, items_shown * height_for_items) - height_for_items + (1 - x) * parent_height_correction
		i += 1
	
	if items_offset != old_offset:
		update_items()

func _on_scroll_bar_scrolling() -> void:
	update_y_offset()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if scroll_bar.visible and event.is_pressed():
			if (event as InputEventMouseButton).button_index == MOUSE_BUTTON_WHEEL_UP:
				scroll_bar.value -= 32.0 / ((total_items - items_shown + 1) * height_for_items + size.y - (items_shown - 1) * height_for_items)
				update_y_offset()
			if (event as InputEventMouseButton).button_index == MOUSE_BUTTON_WHEEL_DOWN:
				scroll_bar.value += 32.0 / ((total_items - items_shown + 1) * height_for_items + size.y - (items_shown - 1) * height_for_items)
				update_y_offset()
