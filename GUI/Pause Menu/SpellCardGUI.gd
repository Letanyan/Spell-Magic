class_name SpellCardGUI
extends Panel

@onready var title: Label = $Title
@onready var preview: TextureRect = $Preview

signal info_pressed
signal bind_pressed

func _on_bind_pressed() -> void:
	bind_pressed.emit()

func _on_info_pressed() -> void:
	info_pressed.emit()
