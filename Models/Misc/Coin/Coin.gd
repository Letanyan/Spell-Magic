class_name CoinDisc
extends WorldItem

var amount: int = 0
var eaten: bool = false

static func make() -> CoinDisc:
	var result := (preload("res://Models/Misc/Coin/Coin.tscn") as PackedScene).instantiate() as CoinDisc
	result.kind = World.Item.COIN
	return result

func _ready() -> void:
	setup(null, World.Biome.WATER)
	
func setup(rng: RandomNumberGenerator, biome: World.Biome) -> void:
	($AnimationPlayer as AnimationPlayer).play("idle")
	update_mesh_color()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if not eaten and body is Player and amount != 0:
		eaten = true
		(body as Player).world_settings.upgrade_settings.currency += amount
		SignalBus.pick_up_world_item_coin.emit(amount, "'%d' coin collected" % amount)
		var tween := create_tween_for_world_item_pick_up(body, 0.25)
		tween.finished.connect(custom_free.bind(self))
		tween.play()

func update_mesh_with_color(color: Color) -> void:
	var mat := ($Coin as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial
	mat.set_shader_parameter("albedo", color)
	
func update_mesh_color() -> void:
	var gold := Color(0.78, 0.637, 0)
	var silver := Color(0.78, 0.78, 0.78)
	var bronze := Color(0.78, 0.325, 0)
	if amount == 0.0:
		update_mesh_with_color(Color.BLACK)
	if amount == 1:
		update_mesh_with_color(bronze)
	elif amount == 5:
		update_mesh_with_color(silver)
	elif amount == 10:
		update_mesh_with_color(gold)
	elif 1 < amount and amount < 5:
		update_mesh_with_color(bronze.lerp(silver, (amount - 1) / 4.0))
	elif 5 < amount and amount < 10:
		update_mesh_with_color(silver.lerp(gold, (amount - 5) / 5.0))
	else:
		update_mesh_with_color(gold.lerp(Color(gold.r * 10, gold.g * 10, gold.b * 10), (amount - 100.0) / 100.0))
		
