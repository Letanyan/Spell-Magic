class_name KeyPrism
extends Node3D

var key: int = 0
var eaten: bool = false

func _ready() -> void:
	pass

func _on_area_3d_body_entered(body: Node3D) -> void:
	if not eaten and body is Player and key != 0:
		eaten = true
		if (body as Player).pick_up_key(key):
			SignalBus.pick_up_world_item_key.emit(key, "Key '%d' picked up" % key)
		else:
			SignalBus.pick_up_world_item_key.emit(key, "Key '%d' already obtained" % key)
		queue_free()
