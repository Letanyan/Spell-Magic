extends Node

@onready var player: AudioStreamPlayer = $AudioStreamPlayer

const source_click = preload("res://Audio/ui/click.wav") as AudioStreamWAV
const source_click_fail = preload("res://Audio/ui/click_fail.wav") as AudioStreamWAV
const source_switch = preload("res://Audio/ui/switch.wav") as AudioStreamWAV
const source_delete = preload("res://Audio/ui/delete.wav") as AudioStreamWAV
const source_focus = preload("res://Audio/ui/focus.wav") as AudioStreamWAV
const source_check = preload("res://Audio/ui/check.wav") as AudioStreamWAV
const source_uncheck = preload("res://Audio/ui/uncheck.wav") as AudioStreamWAV

func click() -> void:
	player.stop()
	player.stream = source_click
	player.play()

func failed_click() -> void:
	player.stop()
	player.stream = source_click_fail
	player.play()
	
func check(is_checked: bool) -> void:
	player.stop()
	player.stream = source_check if is_checked else source_uncheck
	player.play()

func switch() -> void:
	player.stop()
	player.stream = source_switch
	player.play()

func delete() -> void:
	player.stop()
	player.stream = source_delete
	player.play()
	
func focus() -> void:
	player.stop()
	player.stream = source_focus
	player.play()
