class_name ScrollNote
extends WorldItem

var note_id: String = ""
var eaten: bool = false

static func make() -> ScrollNote:
	var result := (preload("res://Models/Misc/Note/Scroll.tscn") as PackedScene).instantiate() as ScrollNote
	result.kind = World.Item.NOTE
	result.height = 1.0
	result.name = "Note" + Rand.id(5, Time.get_ticks_usec())
	return result

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup(0, World.Biome.WATER)

func setup(seedling: int, biome: World.Biome) -> void:
	($AnimationPlayer as AnimationPlayer).play("idle")

func _on_area_3d_body_entered(body: Node3D) -> void:
	if not eaten and body is Player:
		if not (body as Player).world_settings.is_level_editor:
			eaten = true
			SignalBus.pick_up_world_item_scroll_note.emit(self, note_id, "Note '%s' picked up" % note_id)
			var tween := create_tween_for_world_item_pick_up(body, 0.25) 
			tween.finished.connect(custom_free.bind(self))
			tween.play()
		else:
			SignalBus.observe_world_item_scroll_note.emit(self, note_id, "")
			
func save_to_dict(dict: Dictionary) -> void:
	super.save_to_dict(dict)
	dict["note_id"] = note_id

func load_from_dict(dict: Dictionary) -> void:
	super.load_from_dict(dict)
	note_id = dict.get("note_id", "") as String
