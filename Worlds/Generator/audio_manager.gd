extends Node

const audio_streams: Array[AudioStream] = [
	preload("res://Audio/projectile/fire.mp3") as AudioStreamMP3,
	preload("res://Audio/projectile/rock.mp3") as AudioStreamMP3,
	preload("res://Audio/projectile/electric.mp3") as AudioStreamMP3,
	preload("res://Audio/projectile/water.mp3") as AudioStreamMP3,
	preload("res://Audio/projectile/wind.mp3") as AudioStreamMP3,
	preload("res://Audio/projectile/ice.mp3") as AudioStreamMP3,
	preload("res://Audio/projectile/explosion/fire.mp3") as AudioStreamMP3,
	preload("res://Audio/projectile/explosion/electric.mp3") as AudioStreamMP3,
	preload("res://Audio/projectile/explosion/rock.mp3") as AudioStreamMP3,
	preload("res://Audio/projectile/explosion/water.mp3") as AudioStreamMP3,
	preload("res://Audio/projectile/explosion/wind.mp3") as AudioStreamMP3,
	preload("res://Audio/projectile/explosion/ice.mp3") as AudioStreamMP3,
	preload("res://Audio/projectile/explosion/steam.mp3") as AudioStreamMP3,
	
	preload("res://Audio/characters/attack_beast.wav") as AudioStreamWAV,
	preload("res://Audio/characters/attack_fly.wav") as AudioStreamWAV,
	preload("res://Audio/characters/attack_med.wav") as AudioStreamWAV,
	preload("res://Audio/characters/hurt_beast.wav") as AudioStreamWAV,
	preload("res://Audio/characters/hurt_fly.wav") as AudioStreamWAV,
	preload("res://Audio/characters/hurt_med.wav") as AudioStreamWAV,
]


enum AudioStreamKind {
	FIRE, ROCK, ELECTRIC, WATER, AIR, ICE,
	FIRE_EXPLOSION, ROCK_EXPLOSION, ELECTRIC_EXPLOSION, WATER_EXPLOSION, AIR_EXPLOSION, ICE_EXPLOSION, STEAM_EXPLOSION,
	
	ATTACK_BEAST, ATTACK_FLY, ATTACK_MED,
	HURT_BEAST, HURT_FLY, HURT_MED,
	# TODO: add enemy idle sounds
}

class FadeParam:
	var time_stamp: float
	var time_delay: float
	var duration: float
	var start_value: float
	var final_value: float
	
class Stereo:
	var left_dist: float = INF
	var left_player: AudioStreamPlayer3D
	var left_stop_time: float = 0.0
	var right_dist: float = INF
	var right_player: AudioStreamPlayer3D
	var right_stop_time: float = 0.0
	
	func _init(stream: AudioStream) -> void:
		left_player = AudioStreamPlayer3D.new()
		left_player.stream = stream
		left_player.bus = "SFX"
		right_player = AudioStreamPlayer3D.new()
		right_player.stream = stream
		right_player.bus = "SFX"
	
var streams: Array[Stereo] = []
var fade_params: Dictionary = {} ## [AudioStreamPlayer3D]FadeParam
	
var camera: Camera3D = null
var world: Node3D = null: # set in Demo._ready and TestArena._ready
	set(value):
		if value == world:
			return
		for stream in streams:
			if world != null:
				world.remove_child(stream.left_player)
				world.remove_child(stream.right_player)
			if value != null:
				value.add_child(stream.left_player)
				value.add_child(stream.right_player)
		world = value

func _ready() -> void:
	for i in AudioStreamKind.size():
		streams.append(Stereo.new(audio_streams[i]))

func play(kind: AudioStreamKind, position: Vector3, stop_time: float, reset: bool, pitch_scale: Vector2 = Vector2(1, 1)) -> void:	
	var cam_dir := camera.global_transform.basis.z
	var rel_pos := position - camera.global_position
	var cam_right := cam_dir.cross(Vector3.UP)
	var is_right := rel_pos.dot(cam_right) > 0
	var stream := streams[kind]
	var dist := position.distance_squared_to(camera.global_position)
	var player: AudioStreamPlayer3D = null
	
	if is_right:
		if dist < stream.right_dist:
			stream.right_dist = dist
			if is_nan(stop_time):
				stream.right_stop_time = Time.get_unix_time_from_system() + stream.right_player.stream.get_length()
			else:
				stream.right_stop_time = stop_time
			player = stream.right_player
	else:
		if dist < stream.left_dist:
			stream.left_dist = dist
			if is_nan(stop_time):
				stream.left_stop_time = Time.get_unix_time_from_system() + stream.left_player.stream.get_length()
			else:
				stream.left_stop_time = stop_time
			player = stream.left_player
			
	if player == null:
		return
			
	player.position = position
	if fade_params.has(player):
		player.volume_db = 0
		fade_params.erase(player)
	if not player.playing:
		player.volume_db = 0
		player.pitch_scale = randf_range(pitch_scale.x, pitch_scale.y)
		player.play()
	if reset:
		player.pitch_scale = randf_range(pitch_scale.x, pitch_scale.y)
		player.seek(0.0)
	
func stop_all(kind: AudioStreamKind) -> void:
	for stream: Stereo in streams:
		stream.left_player.stop()
		stream.right_player.stop()
	
func fade_audio(player: AudioStreamPlayer3D, final: float, duration: float) -> void:
	var params := FadeParam.new()
	params.time_stamp = 0.0
	params.time_delay = 0.0
	params.duration = duration
	params.start_value = player.volume_db
	params.final_value = final
	fade_params[player] = params

func update(delta: float) -> void:
	var to_remove: Array[AudioStreamPlayer3D] = []
	for player: AudioStreamPlayer3D in fade_params:
		var param := fade_params[player] as FadeParam
		param.time_stamp += delta
		if param.time_stamp > param.duration + param.time_delay:
			player.stop()
			to_remove.append(player)
		elif param.time_stamp >= param.time_delay:
			player.volume_db = lerpf(param.start_value, param.final_value, (param.time_stamp - param.time_delay) / param.duration)
		
	for player in to_remove:
		fade_params.erase(player)
		
	var current_time := Time.get_unix_time_from_system()
	for stream in streams:
		if stream.left_player.playing and (is_inf(stream.left_dist) or stream.left_stop_time <= current_time) and not fade_params.has(stream.left_player):
			fade_audio(stream.left_player, -40, 0.7)
			stream.left_stop_time = INF
		stream.left_dist = INF
		
		if stream.right_player.playing and (is_inf(stream.right_dist) or stream.right_stop_time <= current_time) and not fade_params.has(stream.right_player):
			fade_audio(stream.right_player, -40, 0.7)
			stream.right_stop_time = INF
		stream.right_dist = INF
