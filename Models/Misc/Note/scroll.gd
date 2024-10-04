class_name ScrollNote
extends WorldItem


var note_id: String = ""
var eaten: bool = false

static func make() -> ScrollNote:
	var result := (preload("res://Models/Misc/Note/Scroll.tscn") as PackedScene).instantiate() as ScrollNote
	result.kind = World.Item.NOTE
	return result

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup()


func setup() -> void:
	($AnimationPlayer as AnimationPlayer).play("idle")

func _on_area_3d_body_entered(body: Node3D) -> void:
	if not eaten and body is Player:
		eaten = true
		SignalBus.pick_up_world_item_scroll_note.emit(note_id, "Note '%s' picked up" % note_id)
		var tween := Player.create_tween_for_world_item_pick_up(self, body.position, 0.25)
		tween.finished.connect(func() -> void: queue_free())
		tween.play()
