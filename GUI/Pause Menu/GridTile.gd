class_name GridTile
extends Control

enum Direction { TOP=0, RIGHT, BOTTOM, LEFT }
enum Level { TOP=0, BOTTOM, PATTERN }

@export var mouse_filter_override: Control.MouseFilter = Control.MOUSE_FILTER_PASS

@export var color: Color = Color(0.15, 0.15, 0.15, 1.0)
var artifact: Artifact
var highlighted: Dictionary # [int]Artifact.Option
var warning: Dictionary # [int][int]Color
var normal_style: StyleBox
var disabled_style: StyleBox
var resolved_theme: Theme
var is_temporary: bool = false
var is_hidden: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mouse_filter = mouse_filter_override
	if theme == null:
		resolved_theme = load(ProjectSettings.get_setting("gui/theme/custom") as String) as Theme
		normal_style = resolved_theme.get_stylebox("normal", "Button")
		disabled_style = resolved_theme.get_stylebox("hover", "Button")
	else:
		resolved_theme = theme
		normal_style = theme.get_stylebox("normal", "Button")
		disabled_style = resolved_theme.get_stylebox("hover", "Button")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func warn(index: Direction, level: Level, clr: Color, interval: float, count: int) -> void:
	for n in count * 2:
		if not is_inside_tree():
			return
		await get_tree().create_timer(interval).timeout
		if warning.has(index):
			if (warning[index] as Dictionary).has(level):
				(warning[index] as Dictionary).erase(level)
			else:
				warning[index][level] = clr
		else:
			warning[index] = {level: clr}
		queue_redraw()
		
	
func draw_option(offset: Vector2, option: Artifact.Option, colors: Dictionary, connection: Artifact.Option) -> void:
	var font_size := 11
	var f := resolved_theme.default_font
	var center := size / 2
	var mask := offset.sign() * 0.5
	var inv_mask := Vector2.ZERO
	if mask.x != 0:
		inv_mask.y = 1
	else:
		inv_mask.x = 1
		
	var label_color_top := colors[0] as Color
	var label_color_bottom := colors[0] as Color
	var pattern_color := colors[2] as Color
	
	var amount: String
	if option.effect != Artifact.Effect.NONE:
		amount = option.amount_description()
	elif option.event != Artifact.Event.NONE:
		if connection != null and (connection.element == Artifact.Element.HEALTH or connection.element == Artifact.Element.MANA):
			amount = ""
		else:
			amount = option.duration_description()
		
	font_size = ceili(font_size * maxf(size.x / 176.0, 0.181818))
	var w := f.get_string_size(amount, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)

	var v := Vector2(32, 16) * (size / 176.0)
	var u := Vector2(maxf(w.x, v.x) + 12, (w.y + v.y) + 12)
	
	var dir_pos: Vector2 = center - Vector2(v.x / 2, w.y / 2) + offset - mask * u
	draw_string(f, dir_pos + Vector2(v.x / 2.0 - w.x / 2, v.y / 2.0 + w.y / 2.0 + f.get_descent(font_size)), amount, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, label_color_top)
	var dir_tex := option.direction_texture()
	if dir_tex == null:
		draw_texture_rect(option.element_texture(), Rect2(dir_pos + Vector2(v.x/4, -v.y/2), Vector2(v.x/2, v.y)), false, label_color_bottom)
	elif option.is_effect():
		draw_texture_rect(option.element_texture(), Rect2(dir_pos + Vector2(0, -v.y/2), Vector2(v.x/2, v.y)), false, label_color_bottom)
		draw_texture_rect(dir_tex, Rect2(dir_pos + Vector2(v.x/2, -v.y/2), Vector2(v.x/2, v.y)), false, label_color_bottom)
	else:
		draw_texture_rect(dir_tex, Rect2(dir_pos + Vector2(0, -v.y/2), Vector2(v.x/2, v.y)), false, label_color_bottom)
		draw_texture_rect(option.element_texture(), Rect2(dir_pos + Vector2(v.x/2, -v.y/2), Vector2(v.x/2, v.y)), false, label_color_bottom)
		
	if connection != null and option.event != Artifact.Event.NONE:
		var ind_size := size * 0.03
		var ind_center := center + offset - ind_size * mask * 2
		draw_colored_polygon(PackedVector2Array([ind_center + inv_mask * ind_size, ind_center + mask * ind_size * 2, ind_center + inv_mask * -ind_size]), pattern_color)
		
	var line_width := minf(size.x / 176.0, 1.0)
	if option.pattern == Artifact.Pattern.TRIANGLE:
		var a: Vector2 = center + offset + (-size / 2.5) * inv_mask
		var b: Vector2 = center + size / 4 * mask
		var c: Vector2 = center + offset + (size / 2.5) * inv_mask
		draw_line(a, b, pattern_color, line_width, true)
		draw_line(b, c, pattern_color, line_width, true)
	elif option.pattern == Artifact.Pattern.SQUARE:
		var a: Vector2 = center + offset + (-size / 4) * inv_mask
		var b: Vector2 = center + offset + (-size / 4) * inv_mask + -size / 1.5 * mask
		var c: Vector2 = center + offset + (size / 4) * inv_mask + -size / 1.5 * mask
		var d: Vector2 = center + offset + (size / 4) * inv_mask
		draw_line(a, b, pattern_color, line_width, true)
		draw_line(b, c, pattern_color, line_width, true)
		draw_line(c, d, pattern_color, line_width, true)
	elif option.pattern == Artifact.Pattern.CIRCLE:
		var a: Vector2 = center + offset
		var s := 0.0
		var e := 0.0
		if mask.x < 0:
			s = PI * 1.5
			e = PI * 2.5
		elif mask.x > 0:
			s = PI * 0.5
			e = PI * 1.5
		if mask.y < 0:
			s = 0
			e = PI * 1.0
		elif mask.y > 0:
			s = PI * 2.0
			e = PI * 1.0
		draw_arc(a, size.x * 0.33, s, e, 32, pattern_color, line_width, true)

func get_label_color(index: int) -> Dictionary:
	var BASE := {0: Color.WHITE, 1: Color.WHITE, 2: Color.WHITE}
	var high_color := Color.WHITE
	match index:
		0: high_color = artifact.top.color()
		1: high_color = artifact.right.color()
		2: high_color = artifact.bottom.color()
		3: high_color = artifact.left.color()
	var HIGH := {0: high_color, 1: high_color, 2: high_color}
	
	var result : Dictionary = HIGH if highlighted.get(index, null) != null else BASE
	
	if warning.has(index):
		#result.merge(warning[index], true)
		if (warning[index] as Dictionary).has(0):
			if warning[index][0] == result[0]:
				result[0] = Color(0, 0, 0, 0)
			else:
				result[0] = warning[index][0]
		if (warning[index] as Dictionary).has(1):
			if warning[index][1] == result[1]:
				result[1] = Color(0, 0, 0, 0)
			else:
				result[1] = warning[index][1]
		if (warning[index] as Dictionary).has(2):
			if warning[index][2] == result[2]:
				result[2] = Color(0, 0, 0, 0)
			else:
				result[2] = warning[index][2]
		
	return result

func _draw() -> void:
	if artifact == null or is_hidden:
		return
	
	if is_temporary:
		draw_style_box(disabled_style, Rect2(Vector2.ZERO, size))		
	else:
		draw_style_box(normal_style, Rect2(Vector2.ZERO, size))
	
	draw_option(Vector2(0, -size.y / 2), artifact.top, get_label_color(0), highlighted.get(0, null) as Artifact.Option)
	draw_option(Vector2(0, size.y / 2), artifact.bottom, get_label_color(2), highlighted.get(2, null) as Artifact.Option)
	draw_option(Vector2(-size.x / 2, 0), artifact.left, get_label_color(3), highlighted.get(3, null) as Artifact.Option)
	draw_option(Vector2(size.x / 2, 0), artifact.right, get_label_color(1), highlighted.get(1, null) as Artifact.Option)
	
	tooltip_text = artifact.top.description()

func _input(event: InputEvent) -> void:
	if artifact == null:
		return
		
	if event is InputEventMouseMotion:
		var ev := event as InputEventMouseMotion
		var pos := ev.global_position - global_position
		if not (pos.x < 0 or pos.y < 0 or pos.x > size.x or pos.y > size.y):
			pos = (size - pos) - size / 2.0
			if (pos / (size * 0.5)).length() < 0.4:
				tooltip_text = ""
			else: 
				var angle := pos.angle()
				var maa := fposmod(angle + PI * 2 - PI / 2 + PI / 8, PI * 2.0)
				var index := floori(maa / (PI * 2.0) * 8)
				if index == 0: tooltip_text = artifact.top.description()
				elif index == 2: tooltip_text = artifact.right.description()
				elif index == 4: tooltip_text = artifact.bottom.description()
				elif index == 6: tooltip_text = artifact.left.description()
				else: tooltip_text = ""
