extends MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready():
	var shader = ShaderMaterial.new()
	shader.set_script("res://Worlds/Plane/plane.gdshader")
	var noiseTex = NoiseTexture2D.new()
	noiseTex.noise = FastNoiseLite.new()
	shader.set_shader_parameter("noise", noiseTex)
	mesh.surface_set_material(0, shader)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
