extends Node

@onready var player: Player = $Player
@onready var ground = $Ground
# @onready var ground_mesh = $Ground/Mesh
# @onready var ground_collision = $Ground/Collision

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	buildTerrain()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

var spell_index = 0

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
		
	if event.is_action_pressed("fire"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		var circle = Spell.new("tx + sin(t * 2) * 5", "ty + t * v", "tz + cos(t * 2) * 5", "1", 1, 5000, Spell.Element.FIRE, player.spell_variables(true))
		var blast = Spell.new("x + t * u * 10", "y + t * v * 10", "z + t * w * 10", "t * 2", 0, 5000, Spell.Element.FIRE, player.spell_variables(true))
		var drop = Spell.new("x + u * 5", "y + t * -9.8 * 3 + 15", "z + w * 5", "1 + r0 * 5", 0, 50000, Spell.Element.ROCK, player.spell_variables(true))
		var push = Spell.new("x + u * 300 * t + u * 2", "y + t * 200 * v", "z + w * 300 * t + w * 2", "1 + r0 * 0", 0, 50000, Spell.Element.ROCK, player.spell_variables(true))
		var aqua = Spell.new("x + t * u * 10", "y + t * v * 10 + 2", "z + t * w * 10", "t", 0, 5000, Spell.Element.WATER, player.spell_variables(true))
		var back = Spell.new("x + u * -20 * t + u * 5", "y - 0.75", "z + w * -20 * t + w * 5", "1 + r0 * 0", 0, 50000, Spell.Element.ROCK, player.spell_variables(true))
		
		var spells = [
			drop,
			push,
			back,
			circle,
			blast,
			aqua,
		]
		
		add_child(player.cast_spell(spells[spell_index]))
#		player.impulse = Vector3(1, 1, 1) * 50
		
#		var n = Expr.new("5 * cx + sin(3 / 5) + (cos(1 / 2) * tan(3 / 4))")
#		print(n.compute({"cx": 3.0}))
	
#		if $UserInterface/Retry.visible:
#			get_tree().reload_current_scene()
#		else:
#			$Player.fire(self)
		
@export var noise_struct: Noise
@export var noise_erosion: Noise
@export var noise_peaks: Noise

func noise(x: float, y: float) -> float:
	var a = noise_struct.get_noise_2d(x, y) * 50.0
	var b = noise_erosion.get_noise_2d(x, y) ** 2 * 50.0
	var c = noise_peaks.get_noise_2d(x, y) / 2 + 0.5
	return lerp(a, b, c)

@onready var heightShader = preload("res://Worlds/Demo/height.gdshader")
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
	var mat = ShaderMaterial.new()
	mat.shader = heightShader
	#var mat = StandardMaterial3D.new()
	#mat.albedo_color = Color(1, 0, 0)
	mesh.surface_set_material(0, mat)
	mi.mesh = mesh
	mi.create_trimesh_collision()
	ground.add_child(mi)
	
	"""
	var shape = ConvexPolygonShape3D.new()
	shape.points = collision_points
	var collision = CollisionShape3D.new()
	collision.shape = shape
	ground.add_child(collision)
	"""
