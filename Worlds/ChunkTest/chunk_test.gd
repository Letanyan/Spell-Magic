class_name ChunkTest
extends Node3D

@onready var info: Label = $info
@onready var camera: DebugCam = $camera

var chunker: Chunker
var my_scale := 1.0

func _ready() -> void:
	var blender := NoiseBlender.version1(0)
	chunker = Chunker.new(256, 0.0625, blender, [2, 4, 5])
	for coord: Vector2i in chunker.chunks:
		add_child(chunker.chunks[coord] as MeshInstance3D)

func _physics_process(delta: float) -> void:
	info.text = "%v" % camera.position

func update_all_chunks() -> void:
	for coord: Vector2i in chunker.chunks:
		var chunk := chunker.chunks[coord] as MeshInstance3D
		var res := chunker.chunk_resolution / pow(2.0, chunker.vertex_indices[coord] as int)
		chunker.update_chunk(chunk, chunk.position.x, chunk.position.z, res, my_scale)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ev := event as InputEventKey
		match ev.keycode:
			KEY_1:
				update_all_chunks()
			KEY_2:
				my_scale *= 0.95
				print("scale: ", my_scale)
				update_all_chunks()
			KEY_3:
				my_scale *= 1.05
				print("scale: ", my_scale)
				update_all_chunks()
