extends Node3D

var spell: Spell = null
var eaten: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.play("idle")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_3d_body_entered(body: Node3D) -> void:
	if not eaten and body is Player and spell != null:
		eaten = true
		if not body.magic_book.spell_exists(spell.name):
			body.magic_book.add(spell)
			SignalBus.pick_up_world_item_spell.emit(spell, "Spell '%s' picked up" % spell.name)		
		else:
			SignalBus.pick_up_world_item_spell.emit(spell, "Spell already in Magic Book")
		queue_free()
