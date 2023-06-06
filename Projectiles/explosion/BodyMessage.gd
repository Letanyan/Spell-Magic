extends Node3D


@onready var animator = $AnimationPlayer

var text: String:
	set(value):
		$label.text = value
	get:
		return $label.text

# Called when the node enters the scene tree for the first time.
func _ready():
	animator.play("rise")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _physics_process(delta):
	if not animator.is_playing():
		queue_free()

func get_rise_animation() -> Animation:
	return animator.get_animation("rise")

func set_rise_modulate(initial: Color, final: Color):
	var animation := get_rise_animation()
	var idx := animation.find_track("label:modulate", Animation.TYPE_VALUE)
	animation.track_insert_key(idx, 0.0, initial)
	animation.track_insert_key(idx, 1.0, final)
	
func set_rise_outline_modulate(initial: Color, final: Color):
	var animation := get_rise_animation()
	var idx := animation.find_track("label:outline_modulate", Animation.TYPE_VALUE)
	animation.track_insert_key(idx, 0.0, initial)
	animation.track_insert_key(idx, 1.0, final)
