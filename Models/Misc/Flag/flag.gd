class_name Flag
extends WorldItem

var tag: int = -1
var eaten: bool = false
@onready var flag_01_lod_1: MeshInstance3D = $Flag_01_LOD1

static func make() -> Flag:
	var result := (preload("res://Models/Misc/Flag/Flag.tscn") as PackedScene).instantiate() as Flag
	result.height = 1.5
	result.kind = World.Item.FLAG
	result.name = "Flag" + Rand.id(5, Time.get_ticks_usec())
	return result

func _ready() -> void:
	setup(0, World.Biome.WATER)
	
func setup(seedling: int, biome: World.Biome) -> void:
	($AnimationPlayer as AnimationPlayer).play("idle")
	update_color()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if not eaten and body is Player and tag != -1 and not (body as Player).world_settings.is_editing_level:
		eaten = true
		UIAudioPlayer.ringing()
		SignalBus.pick_up_world_item_flag.emit(self, tag, "Flag picked up")
		var tween := create_tween_for_world_item_pick_up(body, 0.25)
		tween.finished.connect(custom_free.bind(self))
		tween.play()

func update_color() -> void:
	var mat := flag_01_lod_1.get_surface_override_material(0) as StandardMaterial3D
	if tag == 0:
		mat.albedo_color = Color(1, 0.75, 0)
	else:
		mat.albedo_color = Color(0, 0.75, 1)
		
func save_to_dict(dict: Dictionary) -> void:
	super.save_to_dict(dict)
	dict["tag"] = tag

func load_from_dict(dict: Dictionary) -> void:
	super.load_from_dict(dict)
	tag = dict.get("tag", -1) as int
