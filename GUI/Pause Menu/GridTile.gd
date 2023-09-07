class_name GridTile
extends Control

@export var color: Color = Color(0, 0.0, 0.0, 0.5)
var artifact: Artifact
var highlighted: Dictionary # int -> bool
var warning: Dictionary # int -> Color

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func warn(index: int, level: int, clr: Color, interval: float, count: int):
	for n in count * 2:
		await get_tree().create_timer(interval).timeout
		if warning.has(index):
			if warning[index].has(level):
				warning[index].erase(level)
			else:
				warning[index][level] = clr
		else:
			warning[index] = {level: clr}
		queue_redraw()
		
	
func draw_option(offset: Vector2, option: Artifact.Option, colors: Dictionary):
	const FONT_SIZE := 11
	var f := SystemFont.new()
	var center := size / 2
	var mask = sign(offset) * 0.5
	var inv_mask = Vector2.ZERO
	if mask.x != 0:
		inv_mask.y = 1
	else:
		inv_mask.x = 1
		
	var label_color_top = colors[0]
	var label_color_bottom = colors[0]
	var pattern_color = colors[2]
	
	var amount: String
	if option.effect != Artifact.Effect.NONE:
		amount = option.amount_description()
	elif option.event != Artifact.Event.NONE:
		amount = option.duration_description()
		
	var w := f.get_string_size(amount, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var dir: String
	if option.player_deals_damage() == 1:
		dir = option.element_description() + "=> "
	else:
		dir = "<= " + option.element_description()
	var v := f.get_string_size(dir, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var u := Vector2(max(w.x, v.x) + 4, (w.y + v.y) + 4)
	draw_string(f, center - Vector2(w.x / 2, -w.y / 2) + offset - mask * u, amount, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, label_color_top)
	draw_string(f, center - Vector2(v.x / 2, w.y / 2) + offset - mask * u, dir, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, label_color_bottom)
	
	if option.pattern == Artifact.Pattern.TRIANGLE:
		var a: Vector2 = center + offset + (-size / 2.5) * inv_mask
		var b: Vector2 = center + size / 4 * mask
		var c: Vector2 = center + offset + (size / 2.5) * inv_mask
		draw_line(a, b, pattern_color, 1, true)
		draw_line(b, c, pattern_color, 1, true)
	elif option.pattern == Artifact.Pattern.SQUARE:
		var a: Vector2 = center + offset + (-size / 4) * inv_mask
		var b: Vector2 = center + offset + (-size / 4) * inv_mask + -size / 1.5 * mask
		var c: Vector2 = center + offset + (size / 4) * inv_mask + -size / 1.5 * mask
		var d: Vector2 = center + offset + (size / 4) * inv_mask
		draw_line(a, b, pattern_color, 1, true)
		draw_line(b, c, pattern_color, 1, true)
		draw_line(c, d, pattern_color, 1, true)
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
		draw_arc(a, size.x * 0.33, s, e, 32, pattern_color, 1, true)

func get_label_color(index: int) -> Dictionary:
	var BASE = {0: Color.WHITE, 1: Color.WHITE, 2: Color.WHITE}
	var high_color := Color.WHITE
	match index:
		0: high_color = artifact.top.color()
		1: high_color = artifact.right.color()
		2: high_color = artifact.bottom.color()
		3: high_color = artifact.left.color()
	var HIGH = {0: high_color, 1: high_color, 2: high_color}
	
	var result : Dictionary = HIGH if highlighted.get(index, false) else BASE
	
	if warning.has(index):
		result.merge(warning[index], true)
		
	return result

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), color)
	if artifact == null:
		return
	
	draw_option(Vector2(0, -size.y / 2), artifact.top, get_label_color(0))
	draw_option(Vector2(0, size.y / 2), artifact.bottom, get_label_color(2))
	draw_option(Vector2(-size.x / 2, 0), artifact.left, get_label_color(3))
	draw_option(Vector2(size.x / 2, 0), artifact.right, get_label_color(1))
