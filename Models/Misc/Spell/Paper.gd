class_name SpellPaper
extends Node3D

var spell: Spell = null
var eaten: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	($AnimationPlayer as AnimationPlayer).play("idle")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_3d_body_entered(body: Node3D) -> void:
	if not eaten and body is Player and spell != null:
		eaten = true
		if not (body as Player).magic_book.spell_exists(spell.name):
			SignalBus.pick_up_world_item_spell.emit(spell, "Spell '%s' picked up" % spell.name)		
		else:
			SignalBus.pick_up_world_item_spell.emit(spell, "Spell '%s' already in Magic Book" % spell.name)
		var tween := Player.create_tween_for_world_item_pick_up(self, body.position, 0.25)
		tween.finished.connect(func() -> void: queue_free())
		tween.play()
