extends RayCast3D

@export var step_target: Marker3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var hit_point = get_collision_point()
	if hit_point:
		step_target.global_position = hit_point
