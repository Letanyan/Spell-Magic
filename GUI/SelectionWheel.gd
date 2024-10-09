@tool
class_name SelectionWheel
extends Container

@export var line_width: float = 1.0
@export var line_color: Color = Color(1, 1, 1, 0.1)
@export var background_color: Color = Color(0.1, 0.1, 0.1, 0.9)
@export var inner_circle_fraction: float = 0.75
@export var segments: Array[String] = []
var resolved_theme: Theme
var panel_style: StyleBox
var hover_style: StyleBox
var highlight_style: StyleBox

var last_selected_segment_index: int = -1
var selected_segment_index: int = -1

var mouse_down: Variant = null

signal on_segment_hover(index: int)
signal on_segment_unhover(index: int)
signal on_segment_selected(index: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if theme == null:
		resolved_theme = load(ProjectSettings.get_setting("gui/theme/custom") as String) as Theme
		panel_style = resolved_theme.get_stylebox("panel", "Panel")
		hover_style = resolved_theme.get_stylebox("pressed", "Button")
		highlight_style = resolved_theme.get_stylebox("focus", "CheckButton")
	else:
		resolved_theme = theme
		panel_style = theme.get_stylebox("panel", "Panel")
		hover_style = theme.get_stylebox("pressed", "Button")
		highlight_style = theme.get_stylebox("focus", "CheckButton")
	visibility_changed.connect(visiblity_did_change)
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		pass
		# TODO: update positions and size?
		#for coord: Vector2 in child_grid:
			#var node := child_grid[coord] as Control
			#node.position = coord * cell_size + offset + current_offset + Vector2(line_width, line_width)
			#node.size = cell_size - Vector2(line_width * 2, line_width * 2)


func _draw() -> void:
	var radius := minf(size.x, size.y) / 2.0
	var inner_radius := radius * inner_circle_fraction
	var text_radius := radius * (inner_circle_fraction + (1.0 - inner_circle_fraction) * 0.5) 
	var font := resolved_theme.default_font
	var font_size := 16
	
	#draw_circle(size / 2.0, radius, background_color, true, -1.0, true)
	#draw_circle(size / 2.0, radius + line_width, line_color, false, line_width, true)
	#draw_circle(size / 2.0, inner_radius, line_color, false, line_width, true)
	#draw_circle(size / 2.0, text_radius * 1.025, line_color, false, line_width, true)
	#draw_circle(size / 2.0, text_radius * 0.975, line_color, false, line_width, true)
	draw_circle(size / 2.0, text_radius * 1.0, line_color, false, line_width, true)
	draw_circle(size / 2.0, text_radius + line_width * 1.5, line_color, false, line_width * 0.25, true)
	draw_circle(size / 2.0, text_radius - line_width * 1.5, line_color, false, line_width * 0.25, true)
	
	if mouse_down != null:
		draw_circle(mouse_down as Vector2, 16, Color.RED)
	
	var angle_delta := (2.0 * PI) / float(segments.size())
	var current_angle := PI * 3.0 / 2.0 - angle_delta * 0.5
	var center := size / 2.0
	const w_off = Vector2(16, 8)
	const w_off_off = Vector2(w_off.x * -0.5, w_off.y * 0.25)
	var max_w := Vector2.ZERO
	for title in segments:
		#draw_line(center + Vector2(inner_radius, 0).rotated(current_angle), center + Vector2(radius, 0).rotated(current_angle), line_color, line_width, true)
		var w := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size) + w_off
		if w.x > max_w.x:
			max_w.x = w.x
		if w.y > max_w.y:
			max_w.y = w.y
		current_angle += angle_delta
	
	var i := 0
	current_angle = PI * 3.0 / 2.0 - angle_delta * 0.5
	for title in segments:
		var w := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size) + w_off
		var text_center := center + Vector2(inner_radius + (radius - inner_radius) * 0.5, 0).rotated(current_angle + angle_delta * 0.5)
		if i == selected_segment_index:
			draw_style_box(hover_style, Rect2(text_center - max_w * 0.5 + w_off_off, max_w))
		else:
			draw_style_box(panel_style, Rect2(text_center - max_w * 0.5 + w_off_off, max_w))
		draw_string(font, text_center - Vector2(w.x * 0.5, w.y * -0.25), title, HORIZONTAL_ALIGNMENT_FILL, -1, font_size)
		i += 1
		current_angle += angle_delta
		
		
func _gui_input(_event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	
	if _event is InputEventMouseMotion:
		var event := _event as InputEventMouseMotion
		if mouse_down == null:
			mouse_down = event.position
		else:
			var md := mouse_down as Vector2
			var index := -1
			if md.distance_to(event.position) > 16.0:
				var angle_delta := (2.0 * PI) / float(segments.size())
				# Why is this the offset? I don't know! Why do we swap both x and y for `angle`? I don't know!
				var angle_offset := PI * 0.5 + angle_delta * 0.166667 
				var angle := (Vector2(size.x - md.x, size.y - md.y) - Vector2(size.x - event.position.x, size.y - event.position.y)).angle() + angle_offset
				angle = fposmod(angle, PI * 2.0)
				index = floori(angle / (PI * 2.0) * segments.size())
			if index != selected_segment_index:
				if selected_segment_index != -1:
					on_segment_unhover.emit(selected_segment_index)
				on_segment_hover.emit(index)
				selected_segment_index = index
				queue_redraw()

func visiblity_did_change() -> void:
	if not visible:
		mouse_down = null
		if selected_segment_index != -1:
			on_segment_selected.emit(selected_segment_index)
		last_selected_segment_index = selected_segment_index
		selected_segment_index = -1
