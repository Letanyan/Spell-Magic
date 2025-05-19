class_name RedCross
extends WorldItem

var health: float = 0.0
var eaten: bool = false

static func make() -> RedCross:
	var result := (preload("res://Models/Misc/RedCross/RedCross.tscn") as PackedScene).instantiate() as RedCross
	result.kind = World.Item.HEALTH
	result.height = 2.0
	result.name = "Health" + Rand.id(5, Time.get_ticks_usec())
	return result

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup(0, World.Biome.WATER)

func setup(seedling: int, biome: World.Biome) -> void:
	($AnimationPlayer as AnimationPlayer).play("idle")

func _on_area_3d_body_entered(body: Node3D) -> void:
	if not eaten and body is Player and not (body as Player).world_settings.is_level_editor:
		eaten = true
		SignalBus.pick_up_world_item_red_cross.emit(health, "%d%% health gained back" % ceili(health * 100))
		var tween := create_tween_for_world_item_pick_up(body, 0.25)
		tween.finished.connect(custom_free.bind(self))
		tween.play()

func save_to_dict(dict: Dictionary) -> void:
	super.save_to_dict(dict)
	dict["health"] = health

func load_from_dict(dict: Dictionary) -> void:
	super.load_from_dict(dict)
	health = dict.get("health", 0.0) as float
