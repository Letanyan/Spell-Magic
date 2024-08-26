class_name AnimationControl extends Node

@export var pivot_point := Vector2(0.5, 0.5)

@export var hover_size := Vector2(0, 0)
@export var hover_offset := Vector2(0, 0)
@export var hover_rotation := Vector2(0, 0)
@export var hover_scale := Vector2(0, 0)

@export var hover_duration := 0.2
@export var hover_transition_type := Tween.TransitionType.TRANS_QUAD

var target: Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	target = get_parent()
	target.mouse_entered.connect(on_hover)
	target.mouse_exited.connect(off_hover)
	call_deferred("setup")

func setup() -> void:
	target.pivot_offset = target.size * pivot_point

func on_hover() -> void:
	add_tween("size", target.size + hover_size, hover_duration)
	
func off_hover() -> void:
	add_tween("size", target.size - hover_size, hover_duration)

func add_tween(property: String, value: Variant, seconds: float) -> void:
	var tween := get_tree().create_tween()
	tween.tween_property(target, property, value, seconds).set_trans(hover_transition_type)
