extends Node

@onready var ui_player: AudioStreamPlayer = $UIAudioStreamPlayer
@onready var d3_player: AudioStreamPlayer = $D3AudioStreamPlayer

const source_click = preload("res://Audio/ui/click.wav") as AudioStreamWAV
const source_click_fail = preload("res://Audio/ui/click_fail.wav") as AudioStreamWAV
const source_switch = preload("res://Audio/ui/switch.wav") as AudioStreamWAV
const source_delete = preload("res://Audio/ui/delete.wav") as AudioStreamWAV
const source_focus = preload("res://Audio/ui/focus.wav") as AudioStreamWAV
const source_check = preload("res://Audio/ui/check.wav") as AudioStreamWAV
const source_uncheck = preload("res://Audio/ui/uncheck.wav") as AudioStreamWAV
const source_open = preload("res://Audio/ui/open.ogg") as AudioStreamOggVorbis
const source_close = preload("res://Audio/ui/close.ogg") as AudioStreamOggVorbis

const source_hurt_human = preload("res://Audio/characters/hurt_human.wav") as AudioStreamWAV
const source_attack_human_1 = preload("res://Audio/characters/attack_human_1.wav") as AudioStreamWAV
const source_attack_human_2 = preload("res://Audio/characters/attack_human_2.wav") as AudioStreamWAV
const source_attack_human_3 = preload("res://Audio/characters/attack_human_3.wav") as AudioStreamWAV

func play(player: AudioStreamPlayer, source: AudioStream, pitch_scale: Vector2 = Vector2(1, 1)) -> void:
	player.stop()
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
