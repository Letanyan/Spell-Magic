class_name GridTile
extends Control

@export var color: Color
var artifact: Artifact
var highlighted: Dictionary # int -> bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func draw_option(offset: Vector2, option: Artifact.Option, highlight: bool):
	const FONT_SIZE := 11
	var font_color := Color.WHITE
	var f := SystemFont.new()
	var center := size / 2
	var mask = sign(offset) * 0.5
	
	if highlight:
		font_color = Color.DEEP_PINK
	
	if option.effect != Artifact.Effect.NONE:
		var amount := option.amount_description() + " " + option.element_description()
		var w := f.get_string_size(amount, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
		var dir := "=>" if option.player_deals_damage() == 1 else "<="
		var v := f.get_string_size(dir, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
		var u := Vector2(max(w.x, v.x) + 4, (w.y + v.y) + 4)
		draw_string(f, center - Vector2(w.x / 2, -w.y / 2) + offset - mask * u, amount, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, font_color)
		draw_string(f, center - Vector2(v.x / 2, w.y / 2) + offset - mask * u, dir, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, font_color)
	elif option.event != Artifact.Event.NONE:
		var amount := option.element_description()
		var w := f.get_string_size(amount, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
		var dir := "=>" if option.player_deals_damage() == 1 else "<="
		var v := f.get_string_size(dir, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
		var u := Vector2(max(w.x, v.x) + 4, (w.y + v.y) + 4)
		draw_string(f, center - Vector2(w.x / 2, -w.y / 2) + offset - mask * u, amount, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, font_color)
		draw_string(f, center - Vector2(v.x / 2, w.y / 2) + offset - mask * u, dir, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, font_color)
	

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), color)
	if artifact == null:
		return
		
#	var f := SystemFont.new()
#	var w := f.get_string_size(artifact.name)
#	draw_string(f, Vector2(size.x / 2 - w.x / 2, size.y / 2), artifact.name, HORIZONTAL_ALIGNMENT_CENTER, -1, 9)
	
	draw_option(Vector2(0, -size.y / 2), artifact.top, highlighted.get(0, false))
	draw_option(Vector2(0, size.y / 2), artifact.bottom, highlighted.get(2, false))
	draw_option(Vector2(-size.x / 2, 0), artifact.left, highlighted.get(3, false))
	draw_option(Vector2(size.x / 2, 0), artifact.right, highlighted.get(1, false))
	
#	const FONT_SIZE := 11
#	var top_str := artifact.top.description()
#	if not top_str.is_empty():
#		w = f.get_string_size(top_str, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
#		draw_string(f, Vector2(size.x / 2 - w.x / 2, w.y), top_str, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
#
#	var bottom_str := artifact.bottom.description()
#	if not bottom_str.is_empty():
#		w = f.get_string_size(bottom_str, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
#		draw_string(f, Vector2(size.x / 2 - w.x / 2, size.y - w.y), bottom_str, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
#
#	var left_str := artifact.left.description()
#	if not left_str.is_empty():
#		w = f.get_string_size(left_str, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
#		draw_string(f, Vector2(4, size.y / 2), left_str, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
#
#	var right_str := artifact.right.description()
#	if not right_str.is_empty():
#		w = f.get_string_size(right_str, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
#		draw_string(f, Vector2(size.x - w.x - 4, size.y / 2), right_str, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
