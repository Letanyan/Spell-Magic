extends Node3D

@export var offset: float = 2.0

@onready var parent = get_parent_node_3d()
@onready var previous_positon = parent.global_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var velocity = parent.global_position - previous_positon
	global_position = parent.global_position + velocity * offset
	previous_positon = parent.global_position
