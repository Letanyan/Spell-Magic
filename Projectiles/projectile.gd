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
	world_hit.emit()

func update_shape(r: float):
	match element:
		Spell.Element.FIRE:
			var particles: CPUParticles3D = get_node("CPUParticles3D")
			var shape: CollisionShape3D = get_node("CPUParticles3D/Area3D/CollisionShape3D")
			particles.emission_sphere_radius = r
			var sphere = SphereShape3D.new()
			sphere.radius = r
			shape.shape = sphere

func stop_emitting():
	match element:
		Spell.Element.FIRE:
			var particles: CPUParticles3D = get_node("CPUParticles3D")
			particles.emitting = false
			free_after(particles.lifetime)
			
func free_after(duration: float):
	await get_tree().create_timer(duration).timeout
	queue_free()		
			
