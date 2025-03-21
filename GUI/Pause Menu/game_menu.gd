class_name GameMenu
extends Control

signal continue_game
signal main_menu
signal save_game
signal settings
signal exit_game

func _on_continue_pressed() -> void:
	UIAudioPlayer.click()
	continue_game.emit()

func _on_main_menu_pressed() -> void:
	UIAudioPlayer.click()
	main_menu.emit()


func _on_save_game_pressed() -> void:
	UIAudioPlayer.click()
	save_game.emit()

func _on_settings_pressed() -> void:
	UIAudioPlayer.click()
	settings.emit()

func _on_quit_pressed() -> void:
	UIAudioPlayer.click()
	exit_game.emit()
