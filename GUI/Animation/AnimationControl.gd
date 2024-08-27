class_name AnimationControl extends Node

@export var pivot_point := Vector2(0.5, 0.5)

@export var hover_size := Vector2(12, 12)
@export var hover_offset := Vector2(0, 0)
@export var hover_rotation := Vector2(0, 0)
@export var hover_scale := Vector2(0, 0)

@export var hover_duration := 0.2
@export var hover_transition_type := Tween.TransitionType.TRANS_QUAD

var target: Control
var style_box: StyleBoxGradientFill
var loop_tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	target = get_parent()
	target.mouse_entered.connect(on_hover)
	target.mouse_exited.connect(off_hover)
	style_box = target.get_theme_stylebox("pressed") as StyleBoxGradientFill
	call_deferred("setup")

func setup() -> void:
	target.pivot_offset = target.size * pivot_point

func on_hover() -> void:
	add_tween("size", target.size + hover_size, hover_duration)
	add_tween("position", target.position + -hover_size / 2, hover_duration)
	add_tween_callback(hover_duration, Color(0.5, 0, 0, 1), Color(0, 0.5, 0, 1))
	
func off_hover() -> void:
	if loop_tween != null:
		loop_tween.kill()
	add_tween("size", target.size - hover_size, hover_duration)
	add_tween("position", target.position + hover_size / 2, hover_duration)
	add_tween_callback(hover_duration, Color(0, 0.5, 0, 1), Color(0.5, 0, 0, 1))

func add_tween(property: String, value: Variant, seconds: float) -> void:
	var tween := get_tree().create_tween()
	tween.tween_property(target, property, value, seconds).set_trans(hover_transition_type)
	
func add_tween_loop(property: String, start: Variant, end: Variant, seconds: float) -> void:
	if loop_tween != null:
		loop_tween.kill()
	loop_tween = get_tree().create_tween()
	loop_tween.tween_property(target, property, start, seconds).set_trans(hover_transition_type)
	loop_tween.tween_property(target, property, end, seconds).set_trans(hover_transition_type)
	loop_tween.set_loops(0)

func add_tween_callback(seconds: float, start: Color, end: Color) -> void:
	var tween := get_tree().create_tween()
	tween.tween_method(func(color: Color) -> void:
		style_box.fill_gradient_start_color = color
	, start, end, seconds)
