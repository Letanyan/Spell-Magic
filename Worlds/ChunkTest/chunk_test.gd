class_name ChunkTest
extends Node3D

@onready var info: Label = $info
@onready var camera: DebugCam = $camera

var chunker: Chunker

func _ready() -> void:
	var blender := NoiseBlender.version1(0)
	chunker = Chunker.new(256, 0.0625, 120.0, blender, [3, 8, 16, 24], true)
	chunker.init_chunks(0, 0)
	chunker.set_world(self)

func _physics_process(delta: float) -> void:
	info.text = "%.1v" % camera.position
	
	if chunker.has_chunks_to_update():
		var updated := chunker.update_chunks_in_queue(Time.get_ticks_msec(), 5)
		print(updated)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ev := event as InputEventKey
		if not ev.is_released():
			return
		var player_pos := chunker.convert_coord_to_position(chunker.player_coord.x, chunker.player_coord.y)
		match ev.keycode:
			KEY_UP: chunker.update_chunks(player_pos.x, player_pos.y + chunker.chunk_width)
			KEY_DOWN: chunker.update_chunks(player_pos.x, player_pos.y - chunker.chunk_width)
			KEY_LEFT: chunker.update_chunks(player_pos.x - chunker.chunk_width, player_pos.y)
			KEY_RIGHT: chunker.update_chunks(player_pos.x + chunker.chunk_width, player_pos.y)
			KEY_1:
				for i in 20:
					var p := Vec3.xz(Rand.point_in_disc_2d(0, 256 * 10))
					var res := chunker.terrain_normal(p.x, p.z)
					if res.is_empty():
						print("error: ", p)
						continue
					p.y = (res["position"] as Vector3).y
					DebugDraw3D.draw_sphere(p, 32, Color.DEEP_PINK, 20)
