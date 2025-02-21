extends Node

@onready var ui_player: AudioStreamPlayer = $UIAudioStreamPlayer
@onready var d3_player: AudioStreamPlayer = $D3AudioStreamPlayer
@onready var wx_audio_stream_player: AudioStreamPlayer = $WXAudioStreamPlayer

const source_click = preload("res://Audio/ui/click.wav") as AudioStreamWAV
const source_click_fail = preload("res://Audio/ui/click_fail.wav") as AudioStreamWAV
const source_switch = preload("res://Audio/ui/switch.wav") as AudioStreamWAV
const source_delete = preload("res://Audio/ui/delete.wav") as AudioStreamWAV
const source_focus = preload("res://Audio/ui/focus.wav") as AudioStreamWAV
const source_check = preload("res://Audio/ui/check.wav") as AudioStreamWAV
const source_uncheck = preload("res://Audio/ui/uncheck.wav") as AudioStreamWAV
const source_open = preload("res://Audio/ui/open.ogg") as AudioStreamOggVorbis
const source_close = preload("res://Audio/ui/close.ogg") as AudioStreamOggVorbis
const source_ringing = preload("res://Audio/ui/ringing.wav") as AudioStreamWAV
const source_grabbing = preload("res://Audio/ui/grabbing.wav") as AudioStreamWAV
const source_drinking = preload("res://Audio/ui/drinking.wav") as AudioStreamWAV
const source_world_level_up = preload("res://Audio/ui/world_level_up.wav") as AudioStreamWAV
const source_pick_up_key = preload("res://Audio/ui/pick_up_key.wav") as AudioStreamWAV
const source_truck_crash = preload("res://Audio/ui/pick_up_key.wav") as AudioStreamWAV # FIXME: get actual crash sound

const source_hurt_human = preload("res://Audio/characters/hurt_human.wav") as AudioStreamWAV
const source_attack_human_1 = preload("res://Audio/characters/attack_human_1.wav") as AudioStreamWAV
const source_attack_human_2 = preload("res://Audio/characters/attack_human_2.wav") as AudioStreamWAV
const source_attack_human_3 = preload("res://Audio/characters/attack_human_3.wav") as AudioStreamWAV

const source_water = preload("res://Audio/walking/water.mp3") as AudioStreamMP3
const source_taiga = preload("res://Audio/walking/taiga.ogg") as AudioStreamOggVorbis
const source_grassland = preload("res://Audio/walking/grassland.ogg") as AudioStreamOggVorbis
const source_forest = preload("res://Audio/walking/forest.ogg") as AudioStreamOggVorbis
const source_desert = preload("res://Audio/walking/desert.ogg") as AudioStreamOggVorbis
const source_jungle = preload("res://Audio/walking/jungle.ogg") as AudioStreamOggVorbis
const source_savannah = preload("res://Audio/walking/savannah.ogg") as AudioStreamOggVorbis
const source_tundra = preload("res://Audio/walking/tundra.ogg") as AudioStreamOggVorbis
const source_otherworld = preload("res://Audio/walking/otherworld.ogg") as AudioStreamOggVorbis
const source_hfil = preload("res://Audio/walking/hfil.ogg") as AudioStreamOggVorbis

var silence: bool = false

func play(player: AudioStreamPlayer, source: AudioStream, pitch_scale: Vector2 = Vector2(1, 1)) -> void:
	if silence:
		return
	player.stop()
	player.pitch_scale = randf_range(pitch_scale.x, pitch_scale.y)
	player.stream = source
	player.play()
	
func try_play(player: AudioStreamPlayer, source: AudioStream, pitch_scale: Vector2 = Vector2(1, 1)) -> void:
	if silence or player.playing:
		return
	player.pitch_scale = randf_range(pitch_scale.x, pitch_scale.y)
	player.stream = source
	player.play()

func click() -> void:
	play(ui_player, source_click)

func failed_click() -> void:
	play(ui_player, source_click_fail)
	
func check(is_checked: bool) -> void:
	play(ui_player, source_check if is_checked else source_uncheck)

func switch(bus: StringName = &"") -> void:
	if bus != &"":
		ui_player.bus = bus
	elif ui_player.bus != &"UI":
		ui_player.bus = &"UI"
	play(ui_player, source_switch)

func delete() -> void:
	play(ui_player, source_delete)
	
func focus() -> void:
	play(ui_player, source_focus)

func open() -> void:
	play(ui_player, source_open)
	
func close() -> void:
	play(ui_player, source_close)

func hurt() -> void:
	play(d3_player, source_hurt_human)
	
func attack(version: int = -1) -> void:
	if version < 1 or version > 3:
		version = randi_range(1, 3)
		
	var source: AudioStream
	match version:
		1: source = source_attack_human_1
		2: source = source_attack_human_2
		3: source = source_attack_human_3
		_: source = source_attack_human_1
		
	play(d3_player, source, Vector2(0.8, 1.2))

func ringing() -> void:
	play(ui_player, source_ringing)
	
func grabbing() -> void:
	play(ui_player, source_grabbing)
	
func drinking() -> void:
	play(ui_player, source_drinking)
	
func world_level_up() -> void:
	play(ui_player, source_world_level_up)
	
func pick_up_key() -> void:
	play(ui_player, source_pick_up_key)

func walk(biome: World.Biome) -> void:
	match biome:
		World.Biome.WATER: play(wx_audio_stream_player, source_water, Vector2(0.8, 1.2))
		World.Biome.TAIGA: try_play(wx_audio_stream_player, source_taiga, Vector2(0.8, 1.2))
		World.Biome.GRASSLAND: try_play(wx_audio_stream_player, source_grassland, Vector2(0.8, 1.2))
		World.Biome.FOREST: try_play(wx_audio_stream_player, source_forest, Vector2(0.8, 1.2))
		World.Biome.DESERT: try_play(wx_audio_stream_player, source_desert, Vector2(0.8, 1.2))
		World.Biome.JUNGLE: try_play(wx_audio_stream_player, source_jungle, Vector2(0.8, 1.2))
		World.Biome.SAVANNAH: try_play(wx_audio_stream_player, source_savannah, Vector2(0.8, 1.2))
		World.Biome.TUNDRA: try_play(wx_audio_stream_player, source_tundra, Vector2(0.8, 1.2))
		World.Biome.OTHERWORLD: try_play(wx_audio_stream_player, source_otherworld, Vector2(0.8, 1.2))
		World.Biome.HFIL: try_play(wx_audio_stream_player, source_hfil, Vector2(0.8, 1.2))

func crash() -> void:
	play(ui_player, source_truck_crash)
