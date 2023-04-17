class_name SpellBody
extends Node3D

signal world_hit

var spell: Spell

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	var is_world  = body.collision_layer & 0b0001 != 0
	var is_player = body.collision_layer & 0b0010 != 0
	var is_enemy  = body.collision_layer & 0b0100 != 0
	match spell.element:
		Spell.Element.FIRE:
			if is_world:
				world_hit.emit(self, body)
		Spell.Element.ROCK:
			if body != get_node("body"):
				if is_world:
					world_hit.emit(self, body)
				elif is_player or is_enemy:
					CharacterCollision.handle(body, self)
		Spell.Element.WATER:
			if is_world:
				world_hit.emit(self, body)

func update_shape(r: float, ignore_time: bool):
	match spell.element:
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
			
			var body: RigidBody3D = get_node("body")
			body.mass = r
			
		Spell.Element.WATER:
#			if not ignore_time:
#				return
			var m_shape: CollisionShape3D = get_node("source/area/shape")
			var box = SphereShape3D.new()
			box.radius = r
			m_shape.shape = box
			var mesh: MeshInstance3D = get_node("source")
			var mbox = SphereMesh.new()
			mbox.radius = r
			mbox.height = r * 2
			mbox.material = water_mat
			mbox.material.set_shader_parameter("radius", r)
			mbox.material.set_shader_parameter("displacement", clamp((1.0 / r) / 10.0, 0, 0.5))
			mesh.mesh = mbox
#			mesh.mesh.radius = r
#			mesh.mesh.height = r * 2
			
			

func update_movement(v: Vector3, instance: bool):
	match spell.element:
		Spell.Element.FIRE:
			position += v
			var particles: CPUParticles3D = get_node("source")
			particles.direction = v.normalized()
			var s = v.length()
			particles.initial_velocity_min = s * 14.9
			particles.initial_velocity_max = s * 15.1
		
		Spell.Element.ROCK:
			position += v
				
		Spell.Element.WATER:
			position += v
			

func stop_emitting():
	match spell.element:
		Spell.Element.FIRE:
			var particles: CPUParticles3D = get_node("source")
			particles.emitting = false
			var area: Area3D = get_node("source/area")
			area.collision_mask = 0
			free_after(particles.lifetime)
			
		Spell.Element.ROCK:
			queue_free()
			
		Spell.Element.WATER:
			queue_free()
			
func free_after(duration: float):
	await get_tree().create_timer(duration).timeout
	queue_free()		
			
var water_mat = load("res://Projectiles/water_mat.tres")
