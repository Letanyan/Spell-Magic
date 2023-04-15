class_name SpellBody
extends Node3D

signal world_hit

var element: Spell.Element

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_area_3d_body_entered(body):
	match element:
		Spell.Element.FIRE:
			world_hit.emit(self, body)
		Spell.Element.ROCK:
			if body != get_node("body"):
				world_hit.emit(self, body)

func update_shape(r: float, ignore_time: bool):
	match element:
		Spell.Element.FIRE:
			var particles: CPUParticles3D = get_node("source")
			var shape: CollisionShape3D = get_node("source/area/shape")
			particles.emission_sphere_radius = r
			var sphere = SphereShape3D.new()
			sphere.radius = r
			shape.shape = sphere
			
		Spell.Element.ROCK:
			if not ignore_time:
				return
			var p_shape: CollisionShape3D = get_node("body/shape")
			var m_shape: CollisionShape3D = get_node("body/mesh/area/shape")
			var box = BoxShape3D.new()
			box.size.x = r
			box.size.y = r
			box.size.z = r
			p_shape.shape = box
			m_shape.shape = box
			var mesh: MeshInstance3D = get_node("body/mesh")
			var mbox = BoxMesh.new()
			mbox.size.x = r
			mbox.size.y = r
			mbox.size.z = r
			mbox.material = StandardMaterial3D.new()
			mbox.material.albedo_color = Color8(136, 30, 3)
			mbox.material.albedo_texture = NoiseTexture2D.new()
			mbox.material.albedo_texture.noise = FastNoiseLite.new()
			mesh.mesh = mbox
			

func update_movement(v: Vector3):
	match element:
		Spell.Element.FIRE:
			position += v
			print(position, " : ", v)
			var particles: CPUParticles3D = get_node("source")
			particles.direction = v.normalized()
			var s = v.length()
			particles.initial_velocity_min = s * 14.9
			particles.initial_velocity_max = s * 15.1
		
		Spell.Element.ROCK:
			position += v
			

func stop_emitting():
	match element:
		Spell.Element.FIRE:
			var particles: CPUParticles3D = get_node("source")
			particles.emitting = false
			var area: Area3D = get_node("source/area")
			area.collision_mask = 0
			free_after(particles.lifetime)
			
		Spell.Element.ROCK:
			queue_free()
			
func free_after(duration: float):
	await get_tree().create_timer(duration).timeout
	queue_free()		
			
