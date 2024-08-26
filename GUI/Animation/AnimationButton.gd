class_name AnimationButton
extends Button

@export var pivot_point := Vector2(0.5, 0.5)
@export var hover_scale := Vector2(1, 1)
@export var duration := 0.2
@export var transition_type := Tween.TransitionType.TRANS_QUAD

var hover_tween: Tween
@export var hover_rotation := 90.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mouse_entered.connect(on_hover)
	mouse_exited.connect(off_hover)
	call_deferred("setup")
	
func setup() -> void:
	pivot_offset = size * pivot_point

func on_hover() -> void:
	add_tween("scale", hover_scale, duration)
	add_tween("self_modulate", Color(1, 0, 0, 1), duration)
	add_tween("rotation", hover_rotation, -1)
	
func off_hover() -> void:
	add_tween("scale", Vector2(1, 1), duration)
	add_tween("self_modulate", Color(1, 1, 1, 1), duration)

func add_tween(property: String, value: Variant, seconds: float) -> void:
	var tween := get_tree().create_tween()
	tween.tween_property(self, property, value, seconds).set_trans(transition_type)
