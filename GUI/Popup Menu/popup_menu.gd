class_name PopupDialog
extends Control

@onready var label: Label = $confirmation/Panel/Label
@onready var cancel: Button = $confirmation/Panel/Cancel
@onready var confirm: Button = $confirmation/Panel/Confirm

var label_message: String = ""
var cancel_title: String = ""
var confirm_title: String = ""

signal cancelled
signal confirmed

static func display(message: String, cancel_str: String = "Cancel", confirm_str: String = "Confirm") -> PopupDialog:
	var dialog := (load("res://GUI/Popup Menu/popup_menu.tscn") as PackedScene).instantiate() as PopupDialog
	
	dialog.label_message = message
	dialog.cancel_title = cancel_str
	dialog.confirm_title = confirm_str
	
	return dialog
	
func _ready() -> void:
	label.text = label_message
	cancel.text = cancel_title
	confirm.text = confirm_title
	
func _on_cancel_pressed() -> void:
	cancelled.emit()
	if get_parent():
		get_parent().remove_child(get_node("."))

func _on_confirm_pressed() -> void:
	confirmed.emit()
	if get_parent():
		get_parent().remove_child(get_node("."))
