class_name CoinDisc
extends Node3D

var amount: int = 0
var eaten: bool = false

func _ready() -> void:
	($AnimationPlayer as AnimationPlayer).play("idle")

func _on_area_3d_body_entered(body: Node3D) -> void:
	if not eaten and body is Player and amount != 0:
		eaten = true
		(body as Player).world_settings.upgrade_settings.currency += amount
		SignalBus.pick_up_world_item_coin.emit(amount, "'%d' coin collected" % amount)
		var tween := Player.create_tween_for_world_item_pick_up(self, body.position, 0.25)
		tween.finished.connect(func() -> void: queue_free())
		tween.play()
