@tool
class_name InfinityGrid
extends Container

@export var cell_size: Vector2 = Vector2(32, 32)
@export var offset: Vector2 = Vector2.ZERO
@export var line_width: float = 1.0
@export var line_color: Color = Color(1, 1, 1, 0.1)
@export var background_color: Color = Color(0.1, 0.1, 0.1, 0.9)
var panel_style: StyleBox
var hover_style: StyleBox

var selected_cell_coord: Variant = null

var mouse_down: Variant = null
var current_offset := Vector2.ZERO

var child_grid := {} # [Vector2]Control

signal on_cell_selected(coord: Vector2)
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
	else:
		panel_style = theme.get_stylebox("panel", "Panel")
		hover_style = theme.get_stylebox("focus", "Button")

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
			node.position = coord * cell_size + offset + current_offset + Vector2(line_width, line_width)
			node.size = cell_size - Vector2(line_width * 2, line_width * 2)

func _draw() -> void:
	draw_style_box(panel_style, Rect2(Vector2.ZERO, size))
	
	var off_x := fmod(offset.x + current_offset.x, cell_size.x)
	var off_y := fmod(offset.y + current_offset.y, cell_size.y)
	for x in range(0, size.x + cell_size.x, cell_size.x):
		if x + off_x <= 0 or x + off_x > size.x:
			continue
		draw_line(Vector2(x + off_x, 0), Vector2(x + off_x, size.y), line_color, line_width, true)
	for y in range(0, size.y + cell_size.y, cell_size.y):
		if y + off_y <= 0 or y + off_y > size.y:
			continue
		draw_line(Vector2(0, y + off_y), Vector2(size.x, y + off_y), line_color, line_width, true)
		
	draw_line(Vector2(0, 0), Vector2(0, size.y), line_color, line_width, true)
	draw_line(Vector2(0, 0), Vector2(size.x, 0), line_color, line_width, true)
	draw_line(Vector2(size.x, size.y), Vector2(0, size.y), line_color, line_width, true)
	draw_line(Vector2(size.x, size.y), Vector2(size.x, 0), line_color, line_width, true)
	
	if selected_cell_coord != null:
		draw_style_box(hover_style, Rect2(selected_cell_coord as Vector2 * cell_size + offset + current_offset, cell_size))
		#draw_rect(Rect2(selected_cell_coord * cell_size + offset + current_offset, cell_size), Color(line_color.r, line_color.g, line_color.b, 1), false, line_width)

func _gui_input(_event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
		
	if _event is InputEventMouseButton:
		var event := _event as InputEventMouseButton
		if mouse_down == null and event.pressed:
			var m_pos: Vector2 = event.global_position - global_position
			if not (m_pos.x < 0 or m_pos.y < 0 or m_pos.x > size.x or m_pos.y > size.y):
				mouse_down = event.position
				current_offset = Vector2.ZERO
		else:
			offset += current_offset
			if mouse_down != null and current_offset.length() < 2.0:
				var m_pos: Vector2 = event.global_position - global_position
				if not (m_pos.x < 0 or m_pos.y < 0 or m_pos.x > size.x or m_pos.y > size.y):
					m_pos -= offset
					m_pos /= cell_size
					m_pos = floor(m_pos)
					on_cell_clicked.emit(m_pos, event.button_index)
					if double_click_timer.get(event.button_index, false):
						on_cell_double_clicked.emit(m_pos, event.button_index)
					else:
						get_tree().create_timer(0.3).timeout.connect(func() -> void: double_click_timer[event.button_index] = false)
						double_click_timer[event.button_index] = true
					if event.button_index == 1:
						if m_pos == selected_cell_coord:
							selected_cell_coord = null
							on_cell_unselected.emit(m_pos)
						else:
							selected_cell_coord = m_pos
							on_cell_selected.emit(m_pos)
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
				m_pos /= cell_size
				m_pos = floor(m_pos)
				on_cell_moused_over.emit(m_pos)
	elif _event is InputEventKey or _event is InputEventJoypadButton:
		if selected_cell_coord != null and has_focus():
			if _event.is_action_pressed("DOWN"):
				selected_cell_coord += Vector2(0, 1)
				on_cell_selected.emit(selected_cell_coord)
				offset -= Vector2(0, 1) * cell_size
				accept_event()
			if _event.is_action_pressed("UP"):
				selected_cell_coord += Vector2(0, -1)
				on_cell_selected.emit(selected_cell_coord)
				offset -= Vector2(0, -1) * cell_size
				accept_event()
			if _event.is_action_pressed("LEFT"):
				selected_cell_coord += Vector2(-1, 0)
				on_cell_selected.emit(selected_cell_coord)
				offset -= Vector2(-1, 0) * cell_size
				accept_event()
			if _event.is_action_pressed("RIGHT"):
				selected_cell_coord += Vector2(1, 0)
				on_cell_selected.emit(selected_cell_coord)
				offset -= Vector2(1, 0) * cell_size
				accept_event()
			queue_redraw()
			queue_sort()
	elif _event is InputEventJoypadMotion:
		var e := _event as InputEventJoypadMotion
		var movement := VelocityMovement.get_input_strength("pan_left", "pan_right", "pan_forward", "pan_back") * 12
		current_offset += movement
		queue_redraw()
		queue_sort()

