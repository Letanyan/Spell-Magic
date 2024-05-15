extends Node3D

@onready var target: MeshInstance3D = $Target
@onready var agent: CharacterBody3D = $Agent
var positions: Array[Vector3] = []
@onready var collision: CollisionShape3D = $Agent/collision
@onready var camera_3d: Camera3D = $Camera3D

var path_draw_tick := 1.0
var camera_angle := 0.0
var angle_increase := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	path_draw_tick -= delta
	if path_draw_tick <= 0.0:
		for pos in positions:
			DebugDraw3D.draw_sphere(pos, Navigator.shape_max_bound(collision.shape) / 2.0, Color(1, 0, 0), 0.5)
		path_draw_tick = 0.5

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("E"):
		angle_increase = 0.0
		positions = Navigator.find_target_path(agent, target.position, collision.shape, 0)
	elif event.is_action("RIGHT"):
		angle_increase = clampf(angle_increase + 0.01, 0, 0.3)
		camera_angle += angle_increase
		camera_3d.position.x = cos(camera_angle) * 20
		camera_3d.position.z = sin(camera_angle) * 20
		camera_3d.look_at(Vector3.ZERO)
	elif event.is_action("LEFT"):
		angle_increase = clampf(angle_increase + 0.01, 0, 0.3)
		camera_angle -= angle_increase
		camera_3d.position.x = cos(camera_angle) * 20
		camera_3d.position.z = sin(camera_angle) * 20
		camera_3d.look_at(Vector3.ZERO)
	else:
		angle_increase = 0.0
	if event.is_action_released("RIGHT") or event.is_action_released("LEFT"):
		angle_increase = 0.0
		
