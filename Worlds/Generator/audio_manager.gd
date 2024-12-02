extends Node

const audio_streams: Array[AudioStreamMP3] = [
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
]

enum AudioStreamKind {
	FIRE, ROCK, ELECTRIC, WATER, AIR, ICE,
	FIRE_EXPLOSION, ROCK_EXPLOSION, ELECTRIC_EXPLOSION, WATER_EXPLOSION, AIR_EXPLOSION, ICE_EXPLOSION,
}

class FadeParam:
	var time_stamp: float
	var duration: float
	var start_value: float
	var final_value: float
	
var fade_params: Dictionary = {} ## [AudioStreamPlayer3D]FadeParam
	

var world: Node3D = null: # set in Demo._ready and TestArena._ready
	set(value):
		if value == world:
			return
		if world != null:
			for players: Array in audio_players:
				for player: AudioStreamPlayer3D in players:
					world.remove_child(player)
					if value != null:
						value.add_child(player)
		world = value
var audio_players: Array[Array] = [] # [(AudioStreamKind)][(int)]AudioStreamPlayers

func _ready() -> void:
	for i in AudioStreamKind.size():
		audio_players.append([])

func play(kind: AudioStreamKind, positions: PackedVector3Array) -> void:
	var current: Array[AudioStreamPlayer3D] = []
	current.assign(audio_players[kind])
	while current.size() < positions.size():
		var player := AudioStreamPlayer3D.new()
		player.stream = audio_streams[kind]
		player.autoplay = false
		world.add_child(player)
		current.append(player)
	audio_players[kind] = current
	
	for i in range(positions.size(), current.size()):
		if not fade_params.has(current[i]) and current[i].playing:
			fade_audio(current[i], -40, 0.7)
		
	for i in positions.size():
		var pos := positions[i]
		var player := current[i]
		if not pos.is_finite(): 
			if player.playing and not fade_params.has(player):
				fade_audio(player, -40, 0.7)
			continue
		player.position = pos
		if fade_params.has(player):
			player.volume_db = 0
			fade_params.erase(player)
		if not player.playing:
			player.volume_db = 0
			player.play()
			
	
func stop_all(kind: AudioStreamKind) -> void:
	for players: Array in audio_players[kind]:
		for player: AudioStreamPlayer3D in players:
			player.stop()
	
func fade_audio(player: AudioStreamPlayer3D, final: float, duration: float) -> void:
	var params := FadeParam.new()
	params.time_stamp = 0.0
	params.duration = duration
	params.start_value = player.volume_db
	params.final_value = final
	fade_params[player] = params

func update(delta: float) -> void:
	var to_remove: Array[AudioStreamPlayer3D] = []
	for player: AudioStreamPlayer3D in fade_params:
		var param := fade_params[player] as FadeParam
		param.time_stamp += delta
		if param.time_stamp > param.duration:
			player.stop()
			to_remove.append(player)
		else:
			player.volume_db = lerpf(param.start_value, param.final_value, param.time_stamp / param.duration)
		
	for player in to_remove:
		fade_params.erase(player) 
		
