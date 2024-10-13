@tool
class_name SelectionWheel
extends Container

@export var line_width: float = 1.0
@export var line_color: Color = Color(1, 1, 1, 0.1)
@export var background_color: Color = Color(0.1, 0.1, 0.1, 0.9)
@export var inner_circle_fraction: float = 0.6
@export var segments: Array[String] = []
@export var image_segments := {} # [String]Texture2D
@export var radius_range := Vector2(256, 512)
@export var dead_zone := 16.0
@export var sensitivity := 32.0
var resolved_theme: Theme
var panel_style: StyleBox
var hover_style: StyleBox
var highlight_style: StyleBox

var last_selected_segment_index: int = -1
var selected_segment_index: int = -1

var mouse_down: Variant = null # Vector2?
var mouse_angle: Variant = null # float?

signal on_segment_hover(index: int)
signal on_segment_unhover(index: int)
signal on_segment_selected(index: int)

const base_texture = preload("res://GUI/ThemeUI/NeoBaseGradient.tres")
const high_texture = preload("res://GUI/ThemeUI/NeoColorSaturatedGradient.tres")
const norm_texture = preload("res://GUI/ThemeUI/NeoColorGradient.tres")

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
	mouse_down = size / 2

func draw_arc_tex(center: Vector2, inner_radius: float, radius: float, start_angle: float, angle_offset: float, arc_detail: int, tex: Texture2D) -> void:
	var bounding_box := Vector2(radius * 2, radius * 2)
	
	var vertices := PackedVector2Array([])
	var uvs := PackedVector2Array([])
	
	var ca := start_angle + PI / 512.0
	var ad := angle_offset - PI / 256.0
	var coord := Vector2(cos(ca) * inner_radius, sin(ca) * inner_radius)
	vertices.append(center + coord)
	uvs.append((coord + coord * 0.5) / bounding_box)
	coord = Vector2(cos(ca) * radius, sin(ca) * radius)
	vertices.append(center + coord)
	uvs.append((coord + coord * 0.5) / bounding_box)
	var angle_step := ad / float(arc_detail)
	for samples in arc_detail:
		coord = Vector2(cos(ca + angle_step * samples) * radius, sin(ca + angle_step * samples) * radius)
		vertices.append(center + coord)
		uvs.append((coord + coord * 0.5) / bounding_box)
		
	coord = Vector2(cos(ca + ad) * radius, sin(ca + ad) * radius)
	vertices.append(center + coord)
	uvs.append((coord + coord * 0.5) / bounding_box)
	coord = Vector2(cos(ca + ad) * inner_radius, sin(ca + ad) * inner_radius)
	vertices.append(center + coord)
	uvs.append((coord + coord * 0.5) / bounding_box)
	for samples in arc_detail:
		coord = Vector2(cos(ca + angle_step * (arc_detail - 1 - samples)) * inner_radius, sin(ca + angle_step * (arc_detail - 1 - samples)) * inner_radius)
		vertices.append(center + coord)
		uvs.append((coord + coord * 0.5) / bounding_box)
	
	if not Geometry2D.triangulate_polygon(vertices).is_empty():
		draw_polygon(vertices, PackedColorArray([]), uvs, tex)
	else:
		draw_arc(center, radius, ca, ca + ad, 8, Color.BLACK, radius - inner_radius, true)

func _draw() -> void:
	var radius := clampf(minf(size.x, size.y) / 2.0, radius_range.x, radius_range.y)
	var inner_radius := radius * inner_circle_fraction
	var text_radius := radius * (inner_circle_fraction + (1.0 - inner_circle_fraction) * 0.5) 
	var font := resolved_theme.default_font
	var font_size := 16
	
	#if mouse_down != null:
		#draw_circle(mouse_down as Vector2, dead_zone, Color.RED)
	
	var angle_delta := (2.0 * PI) / float(segments.size())
	var current_angle := PI * 3.0 / 2.0 - angle_delta * 0.5
	var center := size / 2.0
	const w_off = Vector2(16, 8)
	const w_off_off = Vector2(w_off.x * -0.5, w_off.y * 0.25)
	var max_w := Vector2.ZERO
	for title in segments:
		var display_title := title.substr(0, mini(title.length(), 10))
		draw_line(center + Vector2(text_radius - line_width * 3, 0).rotated(current_angle), center + Vector2(text_radius + line_width * 1.5, 0).rotated(current_angle), line_color, line_width, true)
		var w := font.get_string_size(display_title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size) + w_off
		if w.x > max_w.x:
			max_w.x = w.x
		if w.y > max_w.y:
			max_w.y = w.y
		current_angle += angle_delta
		
	if mouse_angle != null:
		var ma := (mouse_angle as float)
		draw_line(center + Vector2(text_radius - line_width * 3, 0).rotated(ma), center + Vector2(text_radius + line_width * 1.5, 0).rotated(ma), line_color, line_width, true)
	
	var i := 0
	current_angle = PI * 3.0 / 2.0 - angle_delta * 0.5
	@warning_ignore("integer_division")
	var arc_detail := 64 / maxi(segments.size(), 1)
	for title in segments:
		var display_title := title.substr(0, mini(title.length(), 10))
		var im_size := Vector2.ZERO
		var img: Texture2D = null
		if image_segments.has(title):
			img = image_segments[title] as Texture2D
			im_size = img.get_size()
			
		var w := font.get_string_size(display_title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size) + w_off
		var text_center := center + Vector2(inner_radius + (radius - inner_radius) * 0.5, 0).rotated(current_angle + angle_delta * 0.5)
		
		draw_arc_tex(center, inner_radius - 2, radius + 2, current_angle, angle_delta, arc_detail, high_texture)
		var tex: Texture2D
		if i == selected_segment_index:
			tex = high_texture
		else:
			tex = base_texture
		draw_arc_tex(center, inner_radius, radius, current_angle + PI / 512.0, angle_delta - PI / 256.0, arc_detail, tex)
			
			
		draw_string(font, text_center - Vector2(w.x * 0.5, w.y * -0.25) - Vector2(0, im_size.y * 0.5) - w_off_off, display_title, HORIZONTAL_ALIGNMENT_FILL, -1, font_size)
		if img != null:
			draw_texture_rect(img, Rect2(text_center - im_size / 2.0 + Vector2(0, max_w.y * 0.33), im_size), false)
		i += 1
		current_angle += angle_delta
		
		
func _gui_input(_event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	
	if _event is InputEventJoypadMotion:
		if mouse_down == null:
			mouse_down = Vector2.ZERO
		var event := _event as InputEventJoypadMotion
		
		if event.axis == JOY_AXIS_RIGHT_X:
			mouse_down.x = event.axis_value
		if event.axis == JOY_AXIS_RIGHT_Y:
			mouse_down.y = event.axis_value
		
		var md := mouse_down as Vector2
		var index := -1
		if md.length() > (dead_zone / radius_range.x):
			var angle_delta := (2.0 * PI) / float(segments.size())
			var ma := Vector2(size.x - md.x, size.y - md.y).angle()
			var maa := fposmod(ma + PI * 0.5 + angle_delta * 0.5, PI * 2.0)
			index = floori(maa / (PI * 2.0) * segments.size())
			mouse_angle = ma
		else:
			mouse_angle = null
		if index != selected_segment_index:
			if selected_segment_index != -1:
				on_segment_unhover.emit(selected_segment_index)
			on_segment_hover.emit(index)
			selected_segment_index = index
		queue_redraw()
			
	elif _event is InputEventMouseMotion:
		var event := _event as InputEventMouseMotion
		
		if mouse_down == null:
			#mouse_down = event.position
			mouse_down = global_position + size / 2.0
		else:
			var md := mouse_down as Vector2
			var index := -1
			if md.distance_to(event.position) > dead_zone:
				var angle_delta := (2.0 * PI) / float(segments.size())
				var ma := (Vector2(size.x - md.x, size.y - md.y) - Vector2(size.x - event.position.x, size.y - event.position.y)).angle()
				var maa := fposmod(ma + PI * 0.5 + angle_delta * 0.5, PI * 2.0)
				index = floori(maa / (PI * 2.0) * segments.size())
				mouse_angle = ma
			else:
				mouse_angle = null
			if index != selected_segment_index:
				if selected_segment_index != -1:
					on_segment_unhover.emit(selected_segment_index)
				on_segment_hover.emit(index)
				selected_segment_index = index
			queue_redraw()
			
		if Input.mouse_mode == Input.MouseMode.MOUSE_MODE_CONFINED_HIDDEN and mouse_down != null:
			var center := mouse_down as Vector2
			if center.distance_to(event.position) > sensitivity:
				var V := event.position - center
				Input.warp_mouse(center + V / V.length() * sensitivity)

func visiblity_did_change() -> void:
	if not visible:
		mouse_down = null
		if selected_segment_index != -1:
			on_segment_selected.emit(selected_segment_index)
		last_selected_segment_index = selected_segment_index
		selected_segment_index = -1
