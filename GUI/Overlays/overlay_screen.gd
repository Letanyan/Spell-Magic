class_name OverlayScreen
extends Control

@onready var title_label: Label = $background/title
@onready var subtitle_label: Label = $background/subtitle
@onready var confirm_label: Button = $background/confirm

var title_text: String = ""
var subtitle_text: String = ""
var confirm_text: String = ""

signal confirmed

static func display(title: String, subtitle: String, confirm: String) -> OverlayScreen:
	var overlay := (load("res://GUI/Overlays/OverlayScreen.tscn") as PackedScene).instantiate() as OverlayScreen
	
	overlay.title_text = title
	overlay.subtitle_text = subtitle
	overlay.confirm_text = confirm
	
	return overlay
	
func _ready() -> void:
	title_label.text = title_text
	subtitle_label.text = subtitle_text
	confirm_label.text = confirm_text

func _on_confirm_pressed() -> void:
	confirmed.emit()
	if get_parent():
		queue_free()

func show_in_node(node: Node) -> void:
	node.add_child(self)
	
func show_in_root(node: Node) -> void:
	node.get_tree().root.add_child(self)
