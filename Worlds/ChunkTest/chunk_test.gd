class_name ChunkTest
extends Node3D

@onready var info: Label = $info
@onready var camera: DebugCam = $camera

var chunker: Chunker

func _ready() -> void:
	var blender := NoiseBlender.version1(0)
	chunker = Chunker.new(256, 0.0625, blender, [2, 8, 16])
	chunker.set_world(self)

func _physics_process(delta: float) -> void:
	info.text = "%v" % camera.position
	
	if chunker.has_chunks_to_update():
		var updated := chunker.update_chunks_in_queue(Time.get_ticks_msec(), 5)
		print(updated)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ev := event as InputEventKey
		if not ev.is_released():
			return
		match ev.keycode:
			KEY_UP: chunker.update_chunks(Vector2i(0, 1))
			KEY_DOWN: chunker.update_chunks(Vector2i(0, -1))
			KEY_LEFT: chunker.update_chunks(Vector2i(-1, 0))
			KEY_RIGHT: chunker.update_chunks(Vector2i(1, 0))
