class_name Totem
extends Node3D

@onready var message_label: RichTextLabel = $MessageLabel
var is_active: bool = false

static func make() -> Totem:
	var result := (preload("res://Models/Misc/Totem/Totem.tscn") as PackedScene).instantiate() as Totem
	return result
	
func hide_message() -> void:
	message_label.visible = false
	
func show_message() -> void:
	message_label.visible = is_active

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide_message()
	($AnimationPlayer as AnimationPlayer).play("idle")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_area_3d_body_entered(body: Node3D) -> void:
	if not body is Player:
		return
		
	var player := body as Player
	
	is_active = true
	show_message()
	if GDNavigator.popcnt(player.keys) < player.world_settings.max_keys():
		message_label.text = "[center][font_size=30]%d / %d Keys Found[/font_size][/center]" % [GDNavigator.popcnt(player.keys), player.world_settings.max_keys()]
	else:
		message_label.text = "[center][font_size=30]All Keys Found\nClick to Level Up World[/font_size][/center]"
		player.can_level_up_world = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	is_active = false
	hide_message()
	if body is Player:
		(body as Player).can_level_up_world = false
