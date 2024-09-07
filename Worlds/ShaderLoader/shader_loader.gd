extends Node3D

@onready var mesh: MeshInstance3D = $mesh

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var mat: ShaderMaterial = (mesh.mesh as QuadMesh).material as ShaderMaterial
	const WAIT_TIME = 0.05
	
	mat.shader = load("res://Projectiles/electric.gdshader")
	await get_tree().create_timer(WAIT_TIME).timeout
	
	mat.shader = load("res://Projectiles/electirc_current.gdshader")
	await get_tree().create_timer(WAIT_TIME).timeout
	
	mat.shader = load("res://Projectiles/air_trail.gdshader")
	await get_tree().create_timer(WAIT_TIME).timeout
	
	mat.shader = load("res://General/standard.gdshader")
	await get_tree().create_timer(WAIT_TIME).timeout
	
	mat.shader = load("res://Characters/Enemy/Health Bar/health_bar.gdshader")
	await get_tree().create_timer(WAIT_TIME).timeout
	
	mat.shader = load("res://Characters/Enemy/Health Bar/status_effects.gdshader")
	await get_tree().create_timer(WAIT_TIME).timeout
	
	mat.shader = load("res://Characters/Enemy/Fish/fish.tscn::ShaderMaterial_ljn5y")
	await get_tree().create_timer(WAIT_TIME).timeout
	
	SceneHandler.load_new_scene("res://Worlds/TestArena/TestArena.tscn", "blink_to", func(content: Node3D) -> void: print("loading test arena"))
	#SceneHandler.load_new_scene("res://Worlds/MainMenu/MainMenuWorld.tscn", "blink_to", func(content: Node3D) -> void: print("loading main menu world"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
