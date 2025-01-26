class_name KeyPrism
extends WorldItem

var key: int = 0
var eaten: bool = false

static func make() -> KeyPrism:
	var result := (preload("res://Models/Misc/Key/Key.tscn") as PackedScene).instantiate() as KeyPrism
	result.kind = World.Item.KEY
	return result

func _ready() -> void:
	setup(0, World.Biome.WATER)
	
func setup(seedling: int, biome: World.Biome) -> void:
	($AnimationPlayer as AnimationPlayer).play("idle")
	update_mesh_color()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if not eaten and body is Player:
		eaten = true
		if (body as Player).pick_up_key(key):
			UIAudioPlayer.pick_up_key()
			Steamworks.set_achievement(Steamworks.achievement_pick_up_key(key_to_biome()))
			SignalBus.pick_up_world_item_key.emit(key, "Key '%d' picked up" % key)
		elif key != 0:
			SignalBus.pick_up_world_item_key.emit(key, "Key '%d' already obtained" % key)
		else:
			SignalBus.pick_up_world_item_key.emit(key, "Key 0 shouldn't exist")
		var tween := create_tween_for_key_pick_up(body as Player, 2.0)
		tween.finished.connect(custom_free.bind(self))
		tween.play()

func update_mesh_with_color(color: Color) -> void:
	var mat := ($Key as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial
	mat.set_shader_parameter("albedo", color)
	
func key_to_biome() -> World.Biome:
	var result := 0
	var k := key
	while k > 0:
		result += 1
		k >>= 1
	return (result - 1) as World.Biome
	
func update_mesh_color() -> void:
	match key:
		1 <<  0: update_mesh_with_color(Color(0.23, 0.83, 0.23)) # GRASSLAND
		1 <<  1: update_mesh_with_color(Color(0, 1, 1)) # TAIGA
		1 <<  2: update_mesh_with_color(Color(0.55, 0.28, 0.0)) # FOREST
		1 <<  3: update_mesh_with_color(Color(1, 1, 0)) # DESERT
		1 <<  4: update_mesh_with_color(Color(0, 0.4, 0.0)) # JUNGLE
		1 <<  5: update_mesh_with_color(Color(1, 0.5, 0.0)) # SAVANNAH
		1 <<  6: update_mesh_with_color(Color(0, 0, 0)) # TUNDRA
		1 <<  7: update_mesh_with_color(Color(1, 1, 1)) # OTHERWORLD
		1 <<  8: update_mesh_with_color(Color(1, 0, 0)) # HFIL
		
		1 <<  9: update_mesh_with_color(Color(0.5, 1, 0))
		1 << 10: update_mesh_with_color(Color(0.5, 0, 1))
		1 << 11: update_mesh_with_color(Color(0, 0.5, 1))
		
		1 << 12: update_mesh_with_color(Color(1, 0.5, 0.5))
		1 << 13: update_mesh_with_color(Color(0.5, 1, 0.5))
		1 << 14: update_mesh_with_color(Color(0.5, 0.5, 1))
		1 << 15: update_mesh_with_color(Color(1, 1, 0.5))
		1 << 16: update_mesh_with_color(Color(1, 0.5, 1))
		1 << 17: update_mesh_with_color(Color(0.5, 1, 1))
		
