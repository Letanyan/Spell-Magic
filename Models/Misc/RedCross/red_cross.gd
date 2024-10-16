class_name RedCross
extends WorldItem

var health: float = 0.0
var eaten: bool = false

static func make() -> RedCross:
	var result := (preload("res://Models/Misc/RedCross/RedCross.tscn") as PackedScene).instantiate() as RedCross
	result.kind = World.Item.HEALTH
	return result

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup(null, World.Biome.WATER)

func setup(rng: RandomNumberGenerator, biome: World.Biome) -> void:
	($AnimationPlayer as AnimationPlayer).play("idle")

func _on_area_3d_body_entered(body: Node3D) -> void:
	if not eaten and body is Player:
		eaten = true
		SignalBus.pick_up_world_item_red_cross.emit(health, "%d%% health gained back" % roundi(health * 100))
		var tween := Player.create_tween_for_world_item_pick_up(self, body.position, 0.25)
		tween.finished.connect(func() -> void: queue_free())
		tween.play()
