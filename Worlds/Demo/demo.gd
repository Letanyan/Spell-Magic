extends Node

@onready var player: Player = $Player
@onready var enemy: Enemy = $enemy
@onready var ground = $Ground
# @onready var ground_mesh = $Ground/Mesh
# @onready var ground_collision = $Ground/Collision

@onready var chunker = Terrain.new(noise_elevation, noise_dryness, noise_temperature, 128, 512)

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	update_terrain()
	
#	buildTerrain()
#	enemy.set_movement_target(player.position + Vector3(1, 1, 1))

func update_terrain():
	var chunks = chunker.find_chunks_to_load_from_position(player.position.x, player.position.z)
	for chunk in chunks:
		ground.add_child(chunk)
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _physics_process(delta):
	pass
#	update_terrain()

var spell_index = 7

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	if event.is_action_pressed("one"):
		spell_index = 0
	if event.is_action_pressed("two"):
		spell_index = 1
	if event.is_action_pressed("three"):
		spell_index = 2
	if event.is_action_pressed("four"):
		spell_index = 3
	if event.is_action_pressed("five"):
		spell_index = 4
	if event.is_action_pressed("six"):
		spell_index = 5
	if event.is_action_pressed("seven"):
		spell_index = 6
	if event.is_action_pressed("eight"):
		spell_index = 7
	if event.is_action_pressed("nine"):
		spell_index = 8
	if event.is_action_pressed("zero"):
		spell_index = 9
		
	if event.is_action_pressed("fire"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		var spell_vars = player.spell_variables(true)
		var circle = Spell.new(true, "sin(t * 2) * 5", "-0.2", "cos(t * 2) * 5", "1", 0.5, 50000, Spell.Element.AIR, spell_vars)
		var blast = Spell.new(false, "t * u * 10", "t * v * 10", "t * w * 10", "t * 2", 0, 5000, Spell.Element.FIRE, spell_vars)
		var drop = Spell.new(false, "u * 5", "t * -9.8 * 3 + 15", "w * 5", "1 + r0 * 5", 0.5, 50000, Spell.Element.ROCK, spell_vars)
		var push = Spell.new(false, "u * 30 * t + u * 2", "t * 20 * v", "w * 30 * t + w * 2", "1 + r0 * 0", 0.2, 50000, Spell.Element.ROCK, spell_vars)
		var aqua = Spell.new(false, "t * u * 10", "t * v * 10 + 2", "t * w * 10", "t", 0, 5000, Spell.Element.WATER, spell_vars)
		var back = Spell.new(false, "u * -20 * t + u * 5", "-0.75", "w * -20 * t + w * 5", "1 + r0 * 0", 0.3, 50000, Spell.Element.ROCK, spell_vars)
		var fan = Spell.new(false, "u * 2 + u * 2 * (t / 5)", "-0.75 + v * (t / 5)", "w * 2 + w * 2 * (t / 5)", "2", 0.8, 50000, Spell.Element.AIR, spell_vars)
		var hover = Spell.new(false, "-3 * u + u * t * 6", "-6 + t * 12", "-3 * w + w * t * 6", "2", 0.8, 500, Spell.Element.AIR, spell_vars)
		
		var spells = [
			drop, # 1
			push, # 2
			back, # 3
			fan,  # 4
			circle, # 5
			blast, # 6
			aqua, # 7
			hover, #8
		]
		
		add_child(player.cast_spell(spells[spell_index]))
		
	if event.is_action_pressed("shift"):
#		player.set_movement_target(Vector3(randf() * 10, randf() * 10, randf() * 10))
		var spell_vars = player.spell_variables(true)
		var hover = Spell.new(true, "-0.5", "t * 30 - 20", "0.5", "2", 1, 500, Spell.Element.AIR, spell_vars)
		add_child(player.cast_spell(hover))
		
@export var noise_elevation: Noise
@export var noise_temperature: Noise
@export var noise_dryness: Noise

func noise_texture(noise: Noise, w: int, h: int) -> NoiseTexture2D:
	var result = NoiseTexture2D.new()
	result.noise = noise
	result.width = w
	result.height = h
	result.seamless = true
	return result

func noise(x: float, y: float) -> float:
	return noise_elevation.get_noise_2d(x, y) * 50.0
#	var a = noise_struct.get_noise_2d(x, y) * 50.0
#	var b = noise_erosion.get_noise_2d(x, y) ** 2 * 50.0
#	var c = noise_peaks.get_noise_2d(x, y) / 2 + 0.5
#	return lerp(a, b, c)

@onready var heightShader = preload("res://Worlds/Demo/height.gdshader")
@onready var biome_mat = preload("res://Worlds/Plane/biome.tres")
func buildTerrain():
	var mesh = ArrayMesh.new()
	var plane = PlaneMesh.new()
	var collision_points = PackedVector3Array()
	const H = 1000.0
	const S = 50.0
	plane.size = Vector2(H, H)
	plane.subdivide_depth = H / S
	plane.subdivide_width = H / S
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane.get_mesh_arrays())
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)
	
	for i in range(mdt.get_vertex_count()):
		mdt.set_vertex_normal(i, Vector3.ZERO)
	
	var red = Color(1, 0, 0)
	var blue = Color(0, 0, 1)
	
	for i in range(mdt.get_face_count()):
		var a = mdt.get_face_vertex(i, 0)
		var b = mdt.get_face_vertex(i, 1)
		var c = mdt.get_face_vertex(i, 2)
		var A = mdt.get_vertex(a)
		var B = mdt.get_vertex(b)
		var C = mdt.get_vertex(c)
		var Ah = noise(A.x, A.z)
		var Bh = noise(B.x, B.z)
		var Ch = noise(C.x, C.z)
		A.y = Ah
		B.y = Bh
		C.y = Ch
		var face_norm = (C - A).cross(B - A).normalized()
		
		var Av = mdt.get_vertex_normal(a)
		var Bv = mdt.get_vertex_normal(b)
		var Cv = mdt.get_vertex_normal(c)
		
		mdt.set_vertex_normal(a, Av + face_norm)
		mdt.set_vertex_normal(b, Bv + face_norm)
		mdt.set_vertex_normal(c, Cv + face_norm)
		
		mdt.set_vertex(a, A)
		mdt.set_vertex(b, B)
		mdt.set_vertex(c, C)
		
		mdt.set_vertex_uv(a, Vector2.ZERO)
		mdt.set_vertex_uv(b, Vector2.ZERO)
		mdt.set_vertex_uv(c, Vector2.ZERO)
			
	for i in range(mdt.get_vertex_count()):
		var norm = mdt.get_vertex_normal(i).normalized()
		collision_points.append(mdt.get_vertex(i))
		mdt.set_vertex_normal(i, norm)
			
	mesh.clear_surfaces()
	mdt.commit_to_surface(mesh)
	var mi = MeshInstance3D.new()
	#var mat = StandardMaterial3D.new()
	#mat.albedo_color = Color(1, 0, 0)
	biome_mat.set_shader_parameter("texture_width", H)
	biome_mat.set_shader_parameter("texture_depth", H)
	biome_mat.set_shader_parameter("elevation", noise_texture(noise_elevation, H, H))
	biome_mat.set_shader_parameter("temperature", noise_texture(noise_temperature, H, H))
	biome_mat.set_shader_parameter("dryness", noise_texture(noise_dryness, H, H))
	mesh.surface_set_material(0, biome_mat)
	mi.mesh = mesh
	mi.create_trimesh_collision()
	
	var nav_mesh = NavigationMesh.new()
	nav_mesh.create_from_mesh(mesh)
	var nav = NavigationRegion3D.new()
	nav.navigation_mesh = nav_mesh
	nav.add_child(mi)
	nav.bake_navigation_mesh(true)
	
	ground.add_child(nav)
	
	"""
	var shape = ConvexPolygonShape3D.new()
	shape.points = collision_points
	var collision = CollisionShape3D.new()
	collision.shape = shape
	ground.add_child(collision)
	"""
