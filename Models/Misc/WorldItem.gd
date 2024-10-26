class_name WorldItem
extends Node3D

var is_active: bool = true
var kind: World.Item = World.Item.NONE
var custom_free: Callable = func() -> void:
	queue_free()

func setup(rng: RandomNumberGenerator, biome: World.Biome) -> void:
	pass
