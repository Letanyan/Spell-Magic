@tool
class_name InfinityGrid
extends Container

@export var cell_size: Vector2 = Vector2(32, 32)
@export var cell_scale: float = 1.0 
@export var offset: Vector2 = Vector2.ZERO
@export var line_width: float = 1.0
@export var line_color: Color = Color(1, 1, 1, 0.1)
@export var background_color: Color = Color(0.1, 0.1, 0.1, 0.9)
var panel_style: StyleBox
var hover_style: StyleBox
var highlight_style: StyleBox

var selected_cell_coord: Variant = null
var highlighted_cells := PackedVector2Array([])

var mouse_down: Variant = null
var current_offset := Vector2.ZERO

var child_grid := {} # [Vector2]Control

signal on_cell_selected(coord: Vector2, old_coord: Vector2)
signal on_cell_unselected(coord: Vector2)
signal on_cell_clicked(coord: Vector2, mouse_button_index: int)
signal on_cell_double_clicked(coord: Vector2, mouse_button_index: int)
signal on_cell_moused_over(coord: Vector2)

var double_click_timer: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if theme == null:
		var temp_theme: Theme = load(ProjectSettings.get_setting("gui/theme/custom") as String) as Theme
		panel_style = temp_theme.get_stylebox("panel", "Panel")
		hover_style = temp_theme.get_stylebox("focus", "Button")
		highlight_style = temp_theme.get_stylebox("focus", "CheckButton")
	else:
		panel_style = theme.get_stylebox("panel", "Panel")
		hover_style = theme.get_stylebox("focus", "Button")
		highlight_style = theme.get_stylebox("focus", "CheckButton")

func add_grid_tile(n: Control, coord: Vector2, overwrite: bool = false) -> void:
	if overwrite or not child_grid.has(coord):
		add_child(n)
		child_grid[coord] = n
	
func remove_grid_tile(n: Control) -> void:
	for coord: Vector2 in child_grid:
		if child_grid[coord] == n:
			child_grid.erase(coord)
			remove_child(n)
			break
			
func remove_tile_at_coord(coord: Vector2) -> void:
	if child_grid.has(coord):
		remove_child(child_grid[coord] as Control)
		child_grid.erase(coord)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		for coord: Vector2 in child_grid:
			var node := child_grid[coord] as Control
			var csize := cell_size * cell_scale
			node.position = coord * csize + offset + current_offset + Vector2(line_width, line_width)
			node.size = csize - Vector2(line_width * 2, line_width * 2)

func _draw() -> void:
	draw_style_box(panel_style, Rect2(Vector2.ZERO, size))
	#var font := load("res://GUI/ThemeUI/ChakraPetch-Regular.ttf") as Font
	
	var csize := cell_size * cell_scale
	var off_x := fmod(offset.x + current_offset.x, csize.x)
	var off_y := fmod(offset.y + current_offset.y, csize.y)
	#var off_i := (offset + current_offset)
	for x in range(0, size.x + csize.x, csize.x):
		if x + off_x <= 0 or x + off_x > size.x:
			continue
		draw_line(Vector2(x + off_x, 0), Vector2(x + off_x, size.y), line_color, line_width, true)
		#draw_string(font, Vector2(x + off_x, 10), str(floori((off_i.x - x) / csize.x)))
	for y in range(0, size.y + csize.y, csize.y):
		if y + off_y <= 0 or y + off_y > size.y:
			continue
		draw_line(Vector2(0, y + off_y), Vector2(size.x, y + off_y), line_color, line_width, true)
		#draw_string(font, Vector2(10, y + off_y), str(floori((off_i.y - y) / csize.y)))
		
	draw_line(Vector2(0, 0), Vector2(0, size.y), line_color, line_width, true)
	draw_line(Vector2(0, 0), Vector2(size.x, 0), line_color, line_width, true)
	draw_line(Vector2(size.x, size.y), Vector2(0, size.y), line_color, line_width, true)
	draw_line(Vector2(size.x, size.y), Vector2(size.x, 0), line_color, line_width, true)
	
	if selected_cell_coord != null:
		draw_style_box(hover_style, Rect2(selected_cell_coord as Vector2 * csize + offset + current_offset, csize))
		#draw_rect(Rect2(selected_cell_coord * csize + offset + current_offset, csize), Color(line_color.r, line_color.g, line_color.b, 1), false, line_width)
		
	for highlighted_cell in highlighted_cells:
		draw_style_box(highlight_style, Rect2(highlighted_cell * csize + offset + current_offset, csize))

func _gui_input(_event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	
	var csize := cell_size * cell_scale
	if _event is InputEventMouseButton:
		var event := _event as InputEventMouseButton
		var m_pos: Vector2 = event.global_position - global_position
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			offset = Vector2.ZERO
			queue_redraw()
			queue_sort()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var new_scale := minf(cell_scale * 1.1, 2.0)
			if not is_equal_approx(new_scale, cell_scale):
				var vsize := (size / csize).floor() * cell_size * (new_scale - cell_scale)
				var rm_pos := (m_pos / size) * vsize
				offset = (offset / cell_scale) * new_scale - rm_pos
				cell_scale = new_scale
				queue_redraw()
				queue_sort()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var new_scale := maxf(cell_scale * 0.9, 0.2)
			if not is_equal_approx(new_scale, cell_scale):
				var vsize := (size / csize).floor() * cell_size * (new_scale - cell_scale)
				var rm_pos := (m_pos / size) * vsize
				offset = (offset / cell_scale) * new_scale - rm_pos
				cell_scale = new_scale
				queue_redraw()
				queue_sort()
		elif mouse_down == null and event.pressed:
			if not (m_pos.x < 0 or m_pos.y < 0 or m_pos.x > size.x or m_pos.y > size.y):
				mouse_down = event.position
				current_offset = Vector2.ZERO
		else:
			offset += current_offset
			if mouse_down != null and current_offset.length() < 2.0:
				if not (m_pos.x < 0 or m_pos.y < 0 or m_pos.x > size.x or m_pos.y > size.y):
					m_pos -= offset
					m_pos /= csize
					m_pos = floor(m_pos)
					on_cell_clicked.emit(m_pos, event.button_index)
					if double_click_timer.get(event.button_index, false):
						on_cell_double_clicked.emit(m_pos, event.button_index)
					else:
						get_tree().create_timer(0.3).timeout.connect(func() -> void: double_click_timer[event.button_index] = false)
						double_click_timer[event.button_index] = true
					if event.button_index == MOUSE_BUTTON_LEFT:
						if m_pos == selected_cell_coord:
							selected_cell_coord = null
							on_cell_unselected.emit(m_pos)
						else:
							var old_pos: Vector2
							if selected_cell_coord != null:
								old_pos = selected_cell_coord as Vector2
							selected_cell_coord = m_pos
							on_cell_selected.emit(m_pos, old_pos)
					queue_redraw()
					queue_sort()
			current_offset = Vector2.ZERO
			mouse_down = null
	elif _event is InputEventMouseMotion:
		var event := _event as InputEventMouseMotion
		if mouse_down != null:
			current_offset = event.position - mouse_down
			queue_redraw()
			queue_sort()
		else:
			var m_pos: Vector2 = event.global_position - global_position
			if not (m_pos.x < 0 or m_pos.y < 0 or m_pos.x > size.x or m_pos.y > size.y):
				m_pos -= offset
				m_pos /= csize
				m_pos = floor(m_pos)
				on_cell_moused_over.emit(m_pos)
	elif _event is InputEventKey or _event is InputEventJoypadButton:
		if selected_cell_coord != null and has_focus():
			var old_pos := selected_cell_coord as Vector2
			if _event.is_action_pressed("ui_down"):
				selected_cell_coord += Vector2(0, 1)
				offset -= Vector2(0, 1) * csize
				on_cell_selected.emit(selected_cell_coord, old_pos)
				accept_event()
			if _event.is_action_pressed("ui_up"):
				selected_cell_coord += Vector2(0, -1)
				offset -= Vector2(0, -1) * csize
				on_cell_selected.emit(selected_cell_coord, old_pos)
				accept_event()
			if _event.is_action_pressed("ui_left"):
				selected_cell_coord += Vector2(-1, 0)
				offset -= Vector2(-1, 0) * csize
				on_cell_selected.emit(selected_cell_coord, old_pos)
				accept_event()
			if _event.is_action_pressed("ui_right"):
				selected_cell_coord += Vector2(1, 0)
				offset -= Vector2(1, 0) * csize
				on_cell_selected.emit(selected_cell_coord, old_pos)
				accept_event()
			queue_redraw()
			queue_sort()
	elif _event is InputEventJoypadMotion:
		var movement := VelocityMovement.get_input_strength("pan_left", "pan_right", "pan_forward", "pan_back") * 12
		current_offset += movement
		queue_redraw()
		queue_sort()

func center_grid_on_cell(coord: Vector2) -> void:
	var csize := cell_size * cell_scale
	offset.x = -coord.x * csize.x - csize.x / 2 + size.x / 2
	offset.y = -coord.y * csize.y - csize.y / 2 + size.y / 2
