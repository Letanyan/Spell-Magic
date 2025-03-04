extends Node3D

@onready var mesh: MeshInstance3D = $mesh

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Globals.save_credits()
	
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
	
	mat.shader = load("res://General/standard_solid.gdshader")
	await get_tree().create_timer(WAIT_TIME).timeout
	
	mat.shader = load("res://General/standard_solid_nature.gdshader")
	await get_tree().create_timer(WAIT_TIME).timeout
	
	mat.shader = load("res://Models/Nature/nature_mat.gdshader")
	await get_tree().create_timer(WAIT_TIME).timeout
	
	mat.shader = load("res://Characters/Enemy/Health Bar/health_bar.gdshader")
	await get_tree().create_timer(WAIT_TIME).timeout
	
	mat.shader = load("res://Characters/Enemy/Health Bar/status_effects.gdshader")
	await get_tree().create_timer(WAIT_TIME).timeout
	
	mat.shader = load("res://Worlds/SkyBox/water.gdshader")
	await get_tree().create_timer(WAIT_TIME).timeout
	
	mat.shader = load("res://Characters/Player/MainPlayer.gdshader")
	await get_tree().create_timer(WAIT_TIME).timeout
	
	mat.shader = load("res://Worlds/Generator/Terrain/biome_p.gdshader")
	await get_tree().create_timer(WAIT_TIME).timeout
	
	mat.shader = load("res://Worlds/MainMenu/env_fire.gdshader")
	await get_tree().create_timer(WAIT_TIME).timeout
	
	mat.shader = load("res://Worlds/SkyBox/sky.gdshader")
	await get_tree().create_timer(WAIT_TIME).timeout
	
	if GlobalData.is_debug:
		SceneHandler.load_new_scene("res://Worlds/TestArena/TestArena.tscn", "blink_to", func(content: Node3D) -> void: pass)
		#SceneHandler.load_new_scene("res://Worlds/MainMenu/MainMenuWorld.tscn", "blink_to", func(content: Node3D) -> void: pass, Quotes.random())
	else:
		SceneHandler.load_new_scene("res://Worlds/MainMenu/MainMenuWorld.tscn", "blink_to", func(content: Node3D) -> void: pass, Quotes.random())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
