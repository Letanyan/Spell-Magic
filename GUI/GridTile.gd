class_name GridTile
extends Control

@export var color: Color
var artifact: Artifact
var highlighted: Dictionary # int -> bool
var warning: Dictionary # int -> Color

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func warn(index: int, clr: Color, interval: float, count: int):
	for n in count * 2:
		await get_tree().create_timer(interval).timeout
		if warning.has(index):
			warning.erase(index)
		else:
			warning[index] = clr
		queue_redraw()
		
	
func draw_option(offset: Vector2, option: Artifact.Option, label_color: Color):
	const FONT_SIZE := 11
	var font_color := label_color
	var f := SystemFont.new()
	var center := size / 2
	var mask = sign(offset) * 0.5
	
	if option.effect != Artifact.Effect.NONE:
		var amount := option.amount_description() + " " + option.pattern_description()
		var w := f.get_string_size(amount, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
		var dir: String
		if option.player_deals_damage() == 1:
			dir = option.element_description() + "=> "
		else:
			dir = "<= " + option.element_description()
		var v := f.get_string_size(dir, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
		var u := Vector2(max(w.x, v.x) + 4, (w.y + v.y) + 4)
		draw_string(f, center - Vector2(w.x / 2, -w.y / 2) + offset - mask * u, amount, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, font_color)
		draw_string(f, center - Vector2(v.x / 2, w.y / 2) + offset - mask * u, dir, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, font_color)
	elif option.event != Artifact.Event.NONE:
		var amount := option.duration_description() + " " + option.pattern_description()
		var w := f.get_string_size(amount, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
		var dir: String
		if option.player_deals_damage() == 1:
			dir = option.element_description() + "=> "
		else:
			dir = "<= " + option.element_description()
		var v := f.get_string_size(dir, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
		var u := Vector2(max(w.x, v.x) + 4, (w.y + v.y) + 4)
		draw_string(f, center - Vector2(w.x / 2, -w.y / 2) + offset - mask * u, amount, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, font_color)
		draw_string(f, center - Vector2(v.x / 2, w.y / 2) + offset - mask * u, dir, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, font_color)

func get_label_color(index: int) -> Color:
	if warning.has(index):
		return warning[index]
	if highlighted.get(index, false):
		return Color.DEEP_PINK
	return Color.WHITE	

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), color)
	if artifact == null:
		return
	
	draw_option(Vector2(0, -size.y / 2), artifact.top, get_label_color(0))
	draw_option(Vector2(0, size.y / 2), artifact.bottom, get_label_color(2))
	draw_option(Vector2(-size.x / 2, 0), artifact.left, get_label_color(3))
	draw_option(Vector2(size.x / 2, 0), artifact.right, get_label_color(1))
