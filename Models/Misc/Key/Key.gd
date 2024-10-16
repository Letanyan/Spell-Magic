class_name KeyPrism
extends WorldItem

var key: int = 0
var eaten: bool = false

static func make() -> KeyPrism:
	var result := (preload("res://Models/Misc/Key/Key.tscn") as PackedScene).instantiate() as KeyPrism
	result.kind = World.Item.KEY
	return result

func _ready() -> void:
	setup(null, World.Biome.WATER)
	
func setup(rng: RandomNumberGenerator, biome: World.Biome) -> void:
	($AnimationPlayer as AnimationPlayer).play("idle")
	update_mesh_color()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if not eaten and body is Player and key != 0:
		eaten = true
		if (body as Player).pick_up_key(key):
			SignalBus.pick_up_world_item_key.emit(key, "Key '%d' picked up" % key)
		else:
			SignalBus.pick_up_world_item_key.emit(key, "Key '%d' already obtained" % key)
		var tween := Player.create_tween_for_world_item_pick_up(self, body.position, 0.25)
		tween.finished.connect(func() -> void: queue_free())
		tween.play()

func update_mesh_with_color(color: Color) -> void:
	var mat := ($Key as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial
	mat.set_shader_parameter("albedo", color)
	
func update_mesh_color() -> void:
	match key:
		1: update_mesh_with_color(Color(1, 0, 0))
		2: update_mesh_with_color(Color(0, 1, 0))
		4: update_mesh_with_color(Color(0, 0, 1))
		8: update_mesh_with_color(Color(1, 1, 0))
		16: update_mesh_with_color(Color(1, 0, 1))
		32: update_mesh_with_color(Color(0, 1, 1))
