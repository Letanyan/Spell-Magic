extends Node3D

@onready var target: MeshInstance3D = $Target
@onready var agent: CharacterBody3D = $Agent
var positions: Array[Vector3] = []
@onready var collision: CollisionShape3D = $Agent/collision

var path_draw_tick := 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	path_draw_tick -= delta
	if path_draw_tick <= 0.0:
		for pos in positions:
			DebugDraw3D.draw_sphere(pos, Navigator.bounds(collision.shape) / 2.0, Color(1, 0, 0), 0.5)
		path_draw_tick = 0.5

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("DOWN"):
		positions = Navigator.find_target_path(agent, target.position, collision.shape, 0)
		print("hello")
