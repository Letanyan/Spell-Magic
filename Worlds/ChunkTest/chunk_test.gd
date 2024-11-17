class_name ChunkTest
extends Node3D

@onready var info: Label = $info
@onready var camera: DebugCam = $camera

var chunker: Chunker

func _ready() -> void:
	var blender := NoiseBlender.version1(0)
	chunker = Chunker.new(256, 0.0625, blender, [2, 8, 16])
	chunker.set_world(get_world_3d())

func _physics_process(delta: float) -> void:
	info.text = "%v" % camera.position

func update_all_chunks() -> void:
	for coord: Vector2i in chunker.chunk_rids:
		var pos := chunker.chunk_positions[coord] as Vector2
		var res := chunker.chunk_resolution / pow(2.0, chunker.vertex_indices[coord] as int)
		chunker.update_chunk(coord, pos.x, pos.y, res)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ev := event as InputEventKey
		match ev.keycode:
			KEY_1:
				update_all_chunks()
